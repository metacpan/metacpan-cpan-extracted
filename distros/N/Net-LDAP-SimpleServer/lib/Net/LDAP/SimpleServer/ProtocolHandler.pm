package Net::LDAP::SimpleServer::ProtocolHandler;

use strict;
use warnings;

# ABSTRACT: LDAP protocol handler used with Net::LDAP::SimpleServer

our $VERSION = '0.0.20';    # VERSION

use constant MD5_PREFIX => '{md5}';

use Net::LDAP::Server;
use base 'Net::LDAP::Server';
use fields
  qw(store root_dn root_pw allow_anon user_passwords user_id_attr user_pw_attr user_filter);

use Carp;
use Net::LDAP::LDIF;
use Net::LDAP::Util qw{canonical_dn};
use Net::LDAP::Filter;
use Net::LDAP::FilterMatch;

use Net::LDAP::Constant qw/
  LDAP_SUCCESS LDAP_INVALID_CREDENTIALS LDAP_AUTH_METHOD_NOT_SUPPORTED
  LDAP_INVALID_SYNTAX LDAP_NO_SUCH_OBJECT LDAP_INVALID_DN_SYNTAX/;

use Net::LDAP::SimpleServer::LDIFStore;
use Net::LDAP::SimpleServer::Constant;

use Scalar::Util qw{reftype};
use UNIVERSAL::isa;

use Digest::MD5 qw/md5/;
use MIME::Base64;

sub _make_result {
    my $code = shift;
    my $dn   = shift // '';
    my $msg  = shift // '';

    return {
        matchedDN    => $dn,
        errorMessage => $msg,
        resultCode   => $code,
    };
}

sub new {
    my $class = shift;
    my $params = shift || croak 'Must pass parameters!';

    croak 'Parameter must be a HASHREF' unless reftype($params) eq 'HASH';
    for my $p (qw/store root_dn sock/) {
        croak 'Must pass option {' . $p . '}' unless exists $params->{$p};
    }
    croak 'Not a LDIFStore'
      unless $params->{store}->isa('Net::LDAP::SimpleServer::LDIFStore');

    croak 'Option {root_dn} can not be empty' unless $params->{root_dn};
    croak 'Invalid root DN'
      unless my $canon_dn = canonical_dn( $params->{root_dn} );

    my $self = $class->SUPER::new( $params->{sock} );
    $self->{store}          = $params->{store};
    $self->{root_dn}        = $canon_dn;
    $self->{root_pw}        = $params->{root_pw};
    $self->{allow_anon}     = $params->{allow_anon};
    $self->{user_passwords} = $params->{user_passwords};
    $self->{user_id_attr}   = $params->{user_id_attr};
    $self->{user_pw_attr}   = $params->{user_pw_attr};
    $self->{user_filter}    = $params->{user_filter};
    chomp( $self->{root_pw} );
    chomp( $self->{user_passwords} );

    return $self;
}

sub unbind {
    my $self = shift;

    $self->{store}   = undef;
    $self->{root_dn} = undef;
    $self->{root_pw} = undef;

    return _make_result(LDAP_SUCCESS);
}

sub _find_user_dn {
    my ( $self, $username ) = @_;

    my $filter =
      Net::LDAP::Filter->new( '(&'
          . $self->{user_filter} . '('
          . $self->{user_id_attr} . '='
          . $username
          . '))' );
    return _match( $filter, $self->{store}->list() );
}

sub _encode_password {
    my $plain = shift;

    my $hashpw = encode_base64( md5($plain), '' );
    return MD5_PREFIX . $hashpw;
}

sub bind {
    ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, $request ) = @_;

    # anonymous bind
    return _make_result(LDAP_SUCCESS)
      if (  $self->{allow_anon}
        and not $request->{name}
        and exists $request->{authentication}->{simple} );

    # As of now, accepts only simple authentication
    return _make_result(LDAP_AUTH_METHOD_NOT_SUPPORTED)
      unless exists $request->{authentication}->{simple};

    my $bind_pw = $request->{authentication}->{simple};
    chomp($bind_pw);

    my $bind_dn = canonical_dn( $request->{name} );
    unless ($bind_dn) {
        my $search_user_result = $self->_find_user_dn( $request->{name} );
        my $size               = scalar( @{$search_user_result} );

        return _make_result( LDAP_INVALID_DN_SYNTAX, '',
            'Cannot find user: ' . $request->{name} )
          if $size == 0;
        return _make_result( LDAP_INVALID_DN_SYNTAX, '',
            'Cannot retrieve an unique user entry for id: ' . $request->{name} )
          if $size > 1;

        $bind_dn = $search_user_result->[0];
    }
    elsif ( uc($bind_dn) ne uc( $self->{root_dn} ) ) {
        my $search_dn_result =
          $self->{store}->list_with_dn_scope( $bind_dn, SCOPE_BASEOBJ );
        return _make_result( LDAP_INVALID_DN_SYNTAX, '',
            'Cannot find user: ' . $request->{name} )
          unless $search_dn_result;

        $bind_dn = $search_dn_result->[0];
    }

    if ( $bind_dn->isa('Net::LDAP::Entry') ) {

        # user was not a dn, but it was found
        my $entry_pw = $bind_dn->get_value( $self->{user_pw_attr} );

        my $regexp = '^' . MD5_PREFIX;
        $entry_pw = _encode_password($entry_pw) if $entry_pw =~ /$regexp/;

        return _make_result( LDAP_INVALID_CREDENTIALS, undef,
            'entry dn: ' . $bind_dn->dn() )
          unless $entry_pw eq $bind_pw;
    }
    elsif ( uc($bind_dn) eq uc( $self->{root_dn} ) ) {
        return _make_result( LDAP_INVALID_CREDENTIALS, undef,
            'bind dn: ' . $bind_dn )
          unless $bind_pw eq $self->{root_pw};
    }
    else {
        return _make_result( LDAP_INVALID_DN_SYNTAX, '',
            'Cannot find user: ' . $request->{name} );
    }

    return _make_result(LDAP_SUCCESS);
}

sub _match {
    my ( $filter_spec, $elems ) = @_;

    my $f = bless $filter_spec, 'Net::LDAP::Filter';
    return [ grep { $f->match($_) } @{$elems} ];
}

sub _encode_pw_attr {
    my ( $pw_attr, $entry ) = @_;

    return $entry unless grep { /person/ } $entry->get_value('objectclass');
    return $entry unless $entry->exists($pw_attr);

    my $clone  = $entry->clone();
    my @pwlist = ();
    my $regexp = '^' . MD5_PREFIX;
    foreach ( $clone->get_value($pw_attr) ) {
        next if /$regexp/;
        push @pwlist, _encode_password($_);
    }
    $clone->delete($pw_attr);
    $clone->add( $pw_attr => [@pwlist] );
    return $clone;

}

sub _remove_pw_attr {
    my ( $pw_attr, $entry ) = @_;

    my $clone = $entry->clone();
    $clone->delete($pw_attr) if $clone->exists($pw_attr);
    return $clone;
}

sub _filter_attrs {
    my ( $self, $list ) = @_;

# TODO find a better way to keep the store read-only but not costly to return searches with filtered attributes
    return $list if $self->{user_passwords} eq USER_PW_ALL;

    return [ map { _remove_pw_attr( $self->{user_pw_attr}, $_ ) } @{$list} ]
      if $self->{user_passwords} eq USER_PW_NONE;

    return [ map { _encode_pw_attr( $self->{user_pw_attr}, $_ ) } @{$list} ]
      if $self->{user_passwords} eq USER_PW_MD5;
}

sub search {
    my ( $self, $request ) = @_;

    my $list;
    if ( defined( $request->{baseObject} ) ) {
        my $basedn = canonical_dn( $request->{baseObject} );
        my $scope = $request->{scope} || SCOPE_SUBTREE;

        $list = $self->{store}->list_with_dn_scope( $basedn, $scope );
        return _make_result( LDAP_NO_SUCH_OBJECT, '',
            'Cannot find BaseDN "' . $basedn . '"' )
          unless defined($list);
    }
    else {
        $list = $self->{store}->list();
    }

    my $match = $self->_filter_attrs( _match( $request->{filter}, $list ) );

    return ( _make_result(LDAP_SUCCESS), @{$match} );
}

1;    # Magic true value required at end of module

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::LDAP::SimpleServer::ProtocolHandler - LDAP protocol handler used with Net::LDAP::SimpleServer

=head1 VERSION

version 0.0.20

=head1 SYNOPSIS

    use Net::LDAP::SimpleServer::ProtocolHandler;

    my $store = Net::LDAP::SimpleServer::LDIFStore->new($datafile);
    my $handler =
      Net::LDAP::SimpleServer::ProtocolHandler->new({
          store   => $datafile,
          root_dn => 'cn=root',
          root_pw => 'somepassword'
      }, $socket );

=head1 DESCRIPTION

This module provides an interface between Net::LDAP::SimpleServer and the
underlying data store. Currently only L<Net::LDAP::SimpleServer::LDIFStore>
is available.

=head1 METHODS

=head2 new( OPTIONS, IOHANDLES )

Creates a new handler for the LDAP protocol, using STORE as the backend
where the directory data is stored. The rest of the IOHANDLES are the same
as in the L<Net::LDAP::Server> module.

=head2 bind( REQUEST )

Handles a bind REQUEST from the LDAP client.

=head2 unbind()

Unbinds the connection to the server.

=head2 search( REQUEST )

Performs a search in the data store. The search filter, baseObject and scope are supported.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Net::LDAP::SimpleServer|Net::LDAP::SimpleServer>

=back

=head1 AUTHOR

Alexei Znamensky <russoz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2017 by Alexei Znamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
