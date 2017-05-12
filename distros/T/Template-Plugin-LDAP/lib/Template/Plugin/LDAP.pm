# Copyright (c) 2001 Dominic Mitchell.
# Portions Copyright (c) 2007-2009 Gavin Henry - <ghenry@suretecsystems.com>, 
# Suretec Systems Ltd.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# @(#) $Id: LDAP.pm 1318 2007-03-29 12:05:03Z dom $
#

package Template::Plugin::LDAP;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );

use Template::Exception;
use Net::LDAP;

$VERSION = ( qw( $Revision: 1318 $ ) )[1];

sub new {
    my $class   = shift;
    my $context = shift;
    my $self    = {};
    bless $self, $class;
    $self->_context( $context );
    $self->connect( @_ ) if @_;
    return $self;
}

sub _context {
    my $self = shift;
    $self->{ _context } = $_[0] if @_;
    return $self->{ _context };
}

sub _ldap {
    my $self = shift;
    $self->{ _ldap } = $_[0] if @_;
    return $self->{ _ldap };
}

# connect(host[:port], user, password);
sub connect {
    my $self = shift;
    my $params = ref $_[-1] eq 'HASH' ? pop( @_ ) : {};
    my ( $host, $port, $user, $pass );

    $host = shift
      || $params->{ host }
      || $self->throw( "no ldap host specified" );
    $port = ( $host =~ m/:(\d+)$/ )[0]
      || $params->{ port }
      || getservbyname( "ldap", "tcp" )
      || 389;
    $user = shift || $params->{ user };
    $pass = shift || $params->{ pass };

    my $ldap = Net::LDAP->new( $host, port => $port )
      or return $self->throw( "ldap connect: $@" );
    if ( $user || $pass ) {
        $ldap->bind( $user, password => $pass );
    }
    else {
        $ldap->bind;    # Anonymous bind.
    }
    $self->_ldap( $ldap );

    return '';
}

# search takes the same arguments as Net::LDAP->search().
sub search {
    my $self = shift;
    my $params = ref $_[-1] eq 'HASH' ? pop( @_ ) : { @_ };

    my $mesg = $self->_ldap->search( %$params );
    $self->throw( $mesg->error )
      if $mesg->code;

    return Template::Plugin::LDAP::Iterator->new( $mesg );
}

sub throw {
	die Template::Exception->new( 'ldap', join('', @_) );
}

package Template::Plugin::LDAP::Iterator;

use strict;

use base qw( Template::Iterator );

sub new {
    my ( $class, $mesg, $params ) = @_;
    my $self = bless {}, $class;
    $self->_mesg( $mesg );
    return $self;
}

{
    my @accessors = qw( _mesg _started PREV NEXT ITEM FIRST LAST COUNT INDEX );
    foreach my $a ( @accessors ) {
        no strict 'refs';
        *{ $a } = sub {
            my $self = shift;
            $self->{ $a } = $_[0] if @_;
            return $self->{ $a };
          }
    }
}

sub get_first {
    my $self = shift;
    $self->_started( 1 );

    $self->PREV( undef );
    $self->ITEM( undef );
    $self->FIRST( 2 );    # ???
    $self->LAST( 0 );
    $self->COUNT( 0 );
    $self->INDEX( -1 );

    $self->_fetchentry;

    return $self->get_next;
}

sub get_next {
    my $self = shift;
    my $data;

    $self->INDEX( $self->INDEX + 1 );
    $self->COUNT( $self->COUNT + 1 );

    $self->FIRST( $self->FIRST - 1 )
      if $self->FIRST;

    return ( undef, Template::Constants::STATUS_DONE )
      unless $data = $self->NEXT;

    $self->PREV( $self->ITEM );

    $self->_fetchentry;

    $self->ITEM( $data );
    return ( $data, Template::Constants::STATUS_OK );
}

sub get {
    my $self = shift;
    my ( $data, $error ) = $self->STARTED ? $self->get_next : $self->get_first;
    return $data;
}

sub get_all {
    my $self = shift;
    my $mesg = $self->_mesg;
    my $error;

    my $data =
      [ map { Template::Plugin::LDAP::Entry->new( $_ ) } $mesg->entries ];
    unshift @$data, $self->NEXT    # XXX Is this needed?
      if $self->NEXT;
    $self->LAST( 1 );
    $self->NEXT( undef );

    return $data;
}

sub _fetchentry {
    my $self = shift;
    my $mesg = $self->_mesg;

    # XXX We should probably use our own wrapper object here.
    my $data = $mesg->shift_entry || do {
        $self->LAST( 1 );
        $self->NEXT( undef );
        return;
    };
    $data = Template::Plugin::LDAP::Entry->new( $data );
    $self->NEXT( $data );
    return;
}

package Template::Plugin::LDAP::Entry;

sub new {
    my ( $class, $entry ) = @_;
    my $self = { _entry => $entry };
    foreach my $attrib ( $entry->attributes(nooptions => 1)) {
	no strict 'refs';
	next if defined &{"$class\::\L$attrib"};
	*{"$class\::\L$attrib"} = sub {
		if ( $_[0]->{ _entry }->exists( $attrib ) ) {
                	return $_[0]->{ _entry }->get_value( $attrib );
		} else {
			return "";
		}
	}
    }
    bless $self, $class;
    return $self;
}

sub dn {
    my $self = shift;
    return $self->{ _entry }->dn;
}

1;
__END__

=head1 NAME

Template::Plugin::LDAP - Handle LDAP queries in TT pages.

=head1 SYNOPSIS

    # Bind anonymously.
    [% USE LDAP('ldap.lan') %]
    # Authenticate.
    [% USE LDAP('ldap.lan', 'user', 'password') %]

    # Connect explicitly
    [% USE LDAP %]
    [% LDAP.connect('ldap.lan') %]

    [% FOREACH entry = LDAP.search( base = 'dc=myco,dc=com',
                                    filter = '(objectClass=person)',
                                    attrs = [ 'email', 'cn' ] ) %]
       Distinguished Name Is [% entry.dn %]
       Email: [% entry.cn %] <[% entry.email %]>
    [% END %]

=head1 DESCRIPTION

This is a plugin for the Template Toolkit to do LDAP queries.  It does
not do updates.  Mostly, it is similiar in design to the DBI plugin,
except where I copied it wrong.  :-)

Basically, pass in a hostname and optionally a username/password to
the constructor.

To do a search, you need to specify at least base and filter arguments
to the search method, but have a look at Net::LDAP(3) (the search
method) because that is what is being used underneath and there are
quite a few options.

The entries that you get back from the search are at present very
simplistic and really only meant for display purposes only.  If I need
to do updates later, that functionality might be added.

=head1 METHODS

=head2 new

=head2 connect

=head2 search

=head2 get_first

=head2 get_next 

=head2 get 

=head2 get_all 

=head2 dn 

=head1 AUTHOR

Dominic Mitchell E<lt>dom@happygiraffe.netE<gt>

=head1 MAINTAINER

Suretec Systems Ltd., Gavin Henry E<lt>ghenry@suretecsystems.com<gt>

=head1 SEE ALSO

Net::LDAP(3),
Template::Plugin(3),
Template::Pluigin::DBI(3).

=cut

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim: ai et sw=4 :
