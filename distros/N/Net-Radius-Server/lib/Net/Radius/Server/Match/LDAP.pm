#! /usr/bin/perl
#
#
# $Id: LDAP.pm 75 2009-08-12 22:08:28Z lem $

package Net::Radius::Server::Match::LDAP;

use 5.008;
use strict;
use warnings;

our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 75 $ =~ /\d+/g)[0]/1000 };

use Net::LDAP;
use Carp qw/croak/;
use Net::Radius::Server::Base qw/:match/;
use base qw/Net::Radius::Server::Match/;
__PACKAGE__->mk_accessors(qw/ldap_uri ldap_opts bind_dn bind_opts search_opts 
			  store_result max_tries tls_opts authenticate_from
			  /);

sub _expand
{
    my $self = shift;
    my $r_list = shift || [];
    my $r_data = shift || {};

    my @r = ();

    die $self->description . ": Odd number of arguments\n" 
	if @$r_list % 2;

    for (my $i = 0;
	 $i < @$r_list;
	 $i += 2)
    {
	my $k = $r_list->[$i];
	my $v = $r_list->[$i + 1];

	if ($k =~ m/^_nrs_(.+)$/ and ref($v) eq 'CODE')
	{
	    push @r, $1, $v->($self, $r_data);
	}
	else
	{
	    push @r, $k, $v;
	}
    }

    @r;				# Return the resulting set of arguments
}

sub _connect
{
    my $self = shift;
    my @args = $self->_expand($self->ldap_opts);

    $self->log(4, "Connecting to LDAP: " . $self->ldap_uri . " " 
	       . join(', ', @args));

    $self->{_ldap} = Net::LDAP->new($self->ldap_uri, @args);

    die $self->description . 
	": Failed to connect to LDAP server ", $self->ldap_uri, " ($!)\n"
	unless $self->{_ldap};
}

sub _bind
{
    my $self = shift;
    my $data = shift;

    $self->_connect($data, @_);

    my @args = $self->_expand($self->bind_opts, @_);

    my $dn = $self->bind_dn;

    if (ref($dn) eq 'CODE')
    {
	$dn = $dn->($self, $data, @_);
    }
    
    if ($self->authenticate_from)
    {
	my $attr = $self->authenticate_from;
	my $pass = undef;
	if (ref($attr) eq 'CODE')
	{
	    $pass = $attr->($self, $data, @_);
	}
	else
	{
	    $pass = $data->{request}->password($data->{secret}, $attr);
	}
	push @args, (password => $pass);
    }

    $self->log(4, "Binding to LDAP: " . ($dn || '(No DN)'));
    my $r = $self->{_ldap}->bind($dn, @args);

    # At this stage, a failure to bind is a fatal error...
    if ($r->code)
    {
	$self->log(2, "LDAP bind failure: ". $r->error);
	return;
    }
    return 1;
}

sub mk
{
    my $proto = shift;
    croak "->mk() cannot have arguments when in object-method mode\n" 
	if ref($proto) and $proto->isa('UNIVERSAL') and @_;

    my $self = ref($proto) ? $proto : $proto->new(@_);
    die "Failed to create new object\n" unless $self;

    die $self->description . ": Must specify ldap_uri property\n" 
	unless $self->ldap_uri;

    $self->_bind(@_) unless $self->authenticate_from;

    return sub { $self->_match(@_) };
}

sub match_ldap_uri
{
    my $self = shift;
    my $data = shift;

    my $r;
    my $tries = 0;

    if ($self->authenticate_from 
	and not $self->_bind($data, @_))
    {
	$self->log(2, "Not matched due to bind() failure - Aborting");
	return NRS_MATCH_FAIL;
    }

    return NRS_MATCH_OK if $self->authenticate_from 
	and not $self->search_opts;

    do
    {
	$r = $self->{_ldap}->search($self->_expand($self->search_opts, 
						   $data, @_));;
	if ($r->code)
	{
	    # Let's do a few attempts to query just in case...
	    if ($tries++ > ($self->max_tries || 2))
	    {
		$self->log(2, "Failed to issue the query - Aborting");
		return NRS_MATCH_FAIL;
	    }
	    
	    $self->log(2, "Failure to query: " . $r->error);
	    unless ($self->_bind($data, @_))
	    {
		$self->log(2, "bind() failure");
		return NRS_MATCH_FAIL if $self->authenticate_from;
	    }
	}
    } until (!$r->code);

    if ($self->store_result)
    {
	$self->log(4, "LDAP result stored");
	$data->{$self->store_result} = $r;
    }
    else
    {
	$self->log(4, "LDAP result discarded");
    }

    my $c = $r->count;
    if ($c)
    {
	$self->log(4, "LDAP query returned $c entries - match");
	return NRS_MATCH_OK;
    }
    else
    {
	$self->log(3, "LDAP query returned no entries - fail");
	return NRS_MATCH_FAIL;
    }
}

42;

__END__

=head1 NAME

Net::Radius::Server::Match::LDAP - Interaction with LDAP servers for RADIUS

=head1 SYNOPSIS

  use Net::Radius::Server::Match::LDAP;

  my $match = Net::Radius::Server::Match::LDAP->new({ ... });
  my $match_sub = $match->mk;

=head1 DESCRIPTION

C<Net::Radius::Server::Match::LDAP> is a packet match method
factory. This allows a Net::Radius::Server(3) RADIUS server to process
requests based on information stored in an LDAP
directory. Additionally, information obtained from LDAP remains
available for further rule methods to process.

See C<Net::Radius::Server::Match> for general usage guidelines. The
matching of RADIUS requests is controlled through arguments passed to
the constructor, to specific accessors or to the factory method. There
are generally, two types of arguments:

=over

=item B<Extendable>

Those are arguments that are passed directly to a Net::LDAP(3)
method. Those arguments can receive either a scalar or a code ref.

If a scalar is supplied, this value is simply passed as-is to the
undelying Net::LDAP(3) method.

If a code ref is supplied, it will be called as in

    $sub->($obj, $hashref);

Where C<$obj> is the C<Net::Radius::Server::Match::LDAP> object and
C<$hashref> is the invocation hashref, as described in
Net::Radius::Server(3). Whatever is returned by this sub will be used
as the value for this attribute.

=item B<Indirect Extendable>

The options that will be passed as named arguments to an underlying
Net::LDAP(3) method. Generally speaking, those are attribute - value
tuples specified within a listref, as in the following example.

    ->bind_opts([ password => 'mySikritPzwrd' ]);

Arguments are filtered to provide increased functionality. By
prepending '_nrs_' to the argument name,
C<Net::Radius::Server::Match::LDAP> will use the return value of the
supplied code ref as the value of the argument. The following example
illustrates this:

    ->bind_ops([ _nrs_password => sub { 'mySikritPzwrd' } ]);

The code ref is invoked as in

    $sub->($obj, $hashref)

Where C<$obj> is the C<Net::Radius::Server::Match::LDAP> object and
C<$hashref> is the invocation hashref, as described in
Net::Radius::Server(3). Whatever is returned by this sub will be used
as the value for this attribute.

=back

The following arguments control the invocation of the Net::LDAP(3)
underlying methods:

=over

=item B<ldap_uri>

The URI or host specification passed as the first argument of
C<Net::LDAP->new()>. See Net::LDAP(3) for more information.

=item B<ldap_opts> (Indirect Extendable)

The additional, named parameters passed to C<Net::LDAP->new()>. See
Net::LDAP(3) for more information.

=item B<bind_dn> (Extendable)

The DN specification passed as the first argument of
C<Net::LDAP->bind()>. See Net::LDAP(3) for more information.

=item B<bind_opts> (Indirect Extendable)

The additional, named parameters passed to C<Net::LDAP->bind()>. See
Net::LDAP(3) for more information.

=item B<authenticate_from>

Specify an optional RADIUS attribute from which to extract the
password for binding to the LDAP directory. A B<password => $pass>
argument tuple will be added to whatever was specified with
B<bind_opts>.

Optionally, this parameter can also be a code ref, in which case it
will be called as in

    $obj->authenticate_from->($hashref)

Where C<$hashref> is the shared invocation hash. The return value of
the function will be used as the actual password to use in the LDAP
binding.

=item B<search_opts> (Indirect Extendable)

The named paramenters passed to C<Net::LDAP->search()>. See
Net::LDAP(3) for more information.

=back

The underlying Net::LDAP(3) object first attempts to C<-E<gt>bind()>
when C<-E<gt>mk()> is called. This binding is re-attempted later, when
errors are seen, depending on the configuration arguments specified.

The match method will return C<NRS_MATCH_OK> if no error results from
the LDAP C<-E<gt>search()>.

The following methods control other aspects of the
C<Net::Radius::Server::Match::LDAP>:

=over

=item B<store_result>

When this argument is specified, the Net::LDAP::Result(3) object
returned by the C<-E<gt>search()> method in Net::LDAP(3) will be
stored in the invocation hashref. The value of this argument controls
the name of the hash key where this result will be stored.

This allows further methods (either on the same rule or in following
rules) to use the information returned from an LDAP query for multiple
purposes. You could, for example, locate a user's profile and allow
later rules to translate that profile into RADIUS attributes in the
response packet.

=item B<max_tries>

When attempting LDAP queries, a failure will cause the re-attempt to
issue the C<-E<gt>bind()> call. This paramenter controls how many
attempts are made. 2 attempts are made by default.

=back

=head2 EXPORT

None by default.


=head1 HISTORY

  $Log$
  Revision 1.9  2006/12/14 16:33:17  lem
  Rules and methods will only report failures in log level 3 and
  above. Level 4 report success and failure, for deeper debugging

  Revision 1.8  2006/11/15 03:11:22  lem
  Minor indentation tweak

  Revision 1.7  2006/11/15 01:57:37  lem
  Fix CVS log in the docs


=head1 SEE ALSO

Perl(1), NetAddr::IP(3), Net::Radius::Server(3),
Net::Radius::Server::Match(3), Net::LDAP(3).

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.6 itself.

=cut


