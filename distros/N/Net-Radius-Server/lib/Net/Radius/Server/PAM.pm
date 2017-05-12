package Net::Radius::Server::PAM;

use 5.008;
use strict;
use warnings;
use Authen::PAM;
use Carp qw/croak/;
use Net::Radius::Packet;
use base qw/Net::Radius::Server::Match Net::Radius::Server::Set::Simple/;
use Net::Radius::Server::Base qw/:all/;

our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 75 $ =~ /\d+/g)[0]/1000 };

__PACKAGE__->mk_accessors(qw/service store_result/);

sub mk { croak __PACKAGE__ . " factories are ->fmatch() and ->fset()\n" }

sub fmatch	{ Net::Radius::Server::Match::mk(@_); }
sub fset	{ Net::Radius::Server::Set::mk(@_); }

sub _delay_dummy { 1; }

sub _pam_init
{
    my $self = shift;
    my $r_data = shift;

    my $store = '_pamh';
    $store = $self->store_result if $self->store_result;

    if ($r_data->{$store})
    {
	$self->log(4, "Already authenticated");
	return PAM_SUCCESS();
    }

    my $req = $r_data->{request};
    my $secret = $r_data->{secret};
    
    my $u_attr = 'User-Name';
    my $p_attr = 'User-Password';

    # Fail if no user and password
    return PAM_ABORT() unless $req->attr($u_attr) and $req->attr($p_attr);

    my $user = $req->attr($u_attr);
    my $pass = $req->password($secret, $p_attr);

    my $pamh = new Authen::PAM 
	(
	 ($self->service || 'login'), $user, sub 
	 {
	     my @res;
	     while (@_) 
	     {
		 my $msg_type = shift;
		 my $msg = shift;
		 $self->log(4, "(_conv_f) $msg_type -> $msg");
		 push @res, (0, $pass);
	     }
	     push @res, PAM_SUCCESS();
	     return @res;
	 },
	 );

    unless (ref($pamh))
    {
	$self->log(2, "Failed to init PAM: $pamh");
	return PAM_ABORT();
    }

    if ($pamh->pam_fail_delay(0) != PAM_SUCCESS()
	and $pamh->pam_set_item(PAM_FAIL_DELAY(), 
				\&_delay_dummy) != PAM_SUCCESS())
    {
	$self->log(2, "Cannot avoid PAM delay on failure");
    }

    my $res = $pamh->pam_authenticate(0x0);
    if ($res == PAM_SUCCESS())
    {
	$self->log(4, "Store pamh in $store");
	$r_data->{$store} = $pamh;
	$self->log(4, "Authentication succesful");
    }
    else
    {
	$self->log(2, "Failed to authenticate: $res");
    }

    return $res;
}

sub _match
{
    my $self = shift;
    my $r_data = shift;

    if ($self->_pam_init($r_data, @_) == PAM_SUCCESS())
    {
	return NRS_MATCH_OK;
    }
    else
    {
	return NRS_MATCH_FAIL;
    }
}

sub _set
{
    my $self = shift;
    my $r_data = shift;

    $self->code('Access-Accept') unless $self->code;

    return NRS_SET_CONTINUE 
	unless $self->_pam_init($r_data, @_) == PAM_SUCCESS();

    my $store = '_pamh';
    $store = $self->store_result if $self->store_result;

    my $pamh = $r_data->{$store};
    my $req = $r_data->{request};
    my $res = $r_data->{response};

    # Convert environment to RADIUS attribues;
    my %env = $pamh->pam_getenvlist;
    while (my ($k, $v) = each %env)
    {
	next unless defined $r_data->{dict}->attr_num($k);
	$self->log(4, "Set attr $k => $v");
	$res->set_attr($k, $v);
    }

    $self->SUPER::_set($r_data, @_);
}

42;

__END__

=head1 NAME

Net::Radius::Server::PAM - Authenticate users using the Linux-PAM framework

=head1 SYNOPSIS

  use Net::Radius::Server::PAM;
  my $pam = new Net::Radius::Server({@args});

  # As match-method factory
  $pam->fmatch();

  # As set-method factory
  $pam->fset();

=head1 DESCRIPTION

C<Net::Radius::Server::PAM> uses the PAM framework to authenticate and
populate a RADIUS response within the Net::Radius::Server
framework. The interface with the PAM infraestructure is provided by
Authen::PAM(3).

The following methods are supported:

=over

=item C<-E<gt>fmatch>

Equivalent to invoking C<-E<gt>mk> on a Net::Radius::Server::Match(3)
- derived class. This will return a sub providing match functionality
to Net::Server::Radius(3).


=item C<-E<gt>fset>

Equivalent to invoking C<-E<gt>mk> on a Net::Radius::Server::Set(3) -
derived class. This will return a sub providing set functionality to
Net::Server::Radius(3).

=back

The match method will attempt authentication via username and password
against the PAM framework. Succesful authentication causes the match
method to return B<NRS_MATCH_OK>. Failure, as expected, causes the
return of B<NRS_MATCH_FAIL>.

The C<Authen::PAM> object is left in the shared invocation hash at the
specified key.

The set method attempts to fetch the environment provided by the PAM
framework, translating any environment variables matching an attribute
in the current dictionary into RADIUS attribute/value pairs within the
response.

The set method will only perform its task if the account can be
authenticated by PAM. Otherwise, a B<NRS_SET_CONTINUE> will be
returned, causing the execution of the rules to continue.

The following properties or arguments can be specified to either the
constructor or any factory:

=over

=item B<auto>

Causes the RADIUS identifier and authenticator from the request to be
copied into the response.

=item B<code>

Sets the code of the RADIUS response. Defaults to 'Access-Accept'.

=item B<result>

What value to return when a succesful authentication occurs.

=item B<description>

Description of this rule, used for logging purposes.

=item B<store_result>

Specifies which key in the shared invocation hashref will be used to
store the C<Authen::PAM> object. Defaults to B<_pamh>.

=item B<service>

Defines the PAM service that must be used to authenticate. This
attribute defaults to B<login>.

=back

Note that this class inherits from
Net::Radius::Server::Set::Simple(3), so all its attributes are
available as well.

=head2 EXPORT

None by default.

=head1 HISTORY

  $Log$
  Revision 1.6  2006/12/14 16:33:17  lem
  Rules and methods will only report failures in log level 3 and
  above. Level 4 report success and failure, for deeper debugging

  Revision 1.5  2006/11/15 05:54:04  lem

  NRS::PAM now inherits from NRS::Set::Simple to increase functionality.

  Revision 1.4  2006/11/15 05:39:15  lem

  Corrected invocation of the factories


  Revision 1.2  2006/11/15 05:23:57  lem

  service now can be left unspecified. Defaults to 'login'

  Revision 1.1  2006/11/15 05:14:54  lem

  NRS::PAM has basic functionality.


=head1 SEE ALSO

Perl(1), Net::Radius::Server(3), Net::Radius::Server::Match(3),
Net::Radius::Server::Set(3), Net::Radius::Server::Set::Simple(3),
Authen::PAM(3).

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.6 itself.

=cut
