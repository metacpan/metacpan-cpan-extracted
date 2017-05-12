{

=head1 NAME

Net::Blogger::Engine::Slash::slashcode - Adds support for the Slashcode SOAP API.

=head1 SYNOPSIS

There is none since this is the black box you're not supposed to look in.

Please docs for consult L<Net::Blogger::Engine::Slash>.

=head1 DESCRIPTION

Adds support for the Slashcode SOAP API.

=cut

package Net::Blogger::Engine::Slash::slashcode;
use strict;

use Exporter;
use Digest::MD5 'md5_hex';
use HTTP::Cookies;
use URI;

use Net::Blogger::Engine::Base;

$Net::Blogger::Engine::Slash::slashcode::VERSION   = '1.0';

@Net::Blogger::Engine::Slash::slashcode::ISA       = qw ( Net::Blogger::Engine::Base );
@Net::Blogger::Engine::Slash::slashcode::EXPORT    = qw ();
@Net::Blogger::Engine::Slash::slashcode::EXPORT_OK = qw ();

sub Transport {
  return "SOAP";
}

sub Proxy {
  my $self  = shift;
  my $proxy = shift;

  if ($proxy) {
    $self->{'_cookie'} = undef;
    $self->{'_client'} = undef;

    $self->{'_Proxy'} = $proxy;
  }

  return (
	  $self->{'_Proxy'},
	  cookie_jar => $self->_setUserCookie(),
	  );
}

=head1 OBJECT METHODS

=head2 $pkg->Proxy()

Return the URI of the Slashcode XML-RPC proxy

=head2 $pkg->Transport

Just returns SOAP by default

=head1 SLASHCODE SOAP METHODS

=head2 $pkg->add_entry(\%args)

Valid arguments are

=over

=item *

B<subject>

=item *

B<body>

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns a postid or false.

=cut

sub add_entry {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

  my $call = $self->_Client()->call(
				    "add_entry",
				    $self->_Type(string=>$args->{"subject"}),
				    $self->_Type(string=>$args->{"body"}),
				   );

  return ($call) ? $call->result() : return 0;
}

=head2 $pkg->get_entry($id)

Returns a hash ref whose keys are :

=over 4

=item *

B<body>

=item *

B<discussion_id>

=item *

B<subject>

=item *

B<url>

=item *

B<posttype>

=item *

B<id>

=item *

B<date>

=item *

B<tid>

=item *

B<nickname>

=item *

B<uid>

=back

=cut

sub get_entry {
  my $self = shift;

  my $call = $self->_Client()->call(
				    "get_entry",
				    $self->_Type(int=>$_[0]),
				   );

  return ($call) ? $call->result() : return 0;
}

=head2 $pkg->get_entries($offset)

Returns an array of hashrefs (see docs for I<get_entry>), or false.

=cut

sub get_entries {
  my $self = shift;

  my $call = $self->_Client()->call("get_entries",
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(int=>$_[0]),
				   );

  return ($call) ? $call->result() : return 0;
}

=head2 $pkg->modify_entry($id,\%args)

Returns a postid or false.

=cut

sub modify_entry {
  my $self   = shift;
  my $postid = shift;
  my $args   = (ref($_[0]) eq "HASH") ? shift : { @_ };

  my $call = $self->_Client()->call("modify_entry",
				    $self->_Type(int=>$postid),
				    $self->_Type(string=>$args->{"subject"}),
				    $self->_Type(string=>$args->{"body"}),
				   );

  return ($call) ? $call->result() : return 0;
}

=head2 $pkg->delete_entry($id)

Returns true or false.

=cut

sub delete_entry {
  my $self = shift;

  my $call = $self->_Client()->call("delete_entry",
				    $self->_Type(int=>$_[0]),
				   );

  return ($call) ? $call->result() : return 0;
}

sub _setUserCookie {
  my $self = shift;

  if (! $self->{'_cookie'}) {
    my $cookie = join("::",$self->Username(),md5_hex($self->Password()));

    $cookie =~ s/(.)/sprintf("%%%02x", ord($1))/ge;
    $cookie =~ s/%/%25/g;
    $self->{'_cookie'} = HTTP::Cookies->new()->set_cookie(0,
							  user=>$cookie,
							  '/',
							  URI->new($self->{'_Proxy'})->host(),
							 ),
  }

  return $self->{'_cookie'};
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 19:29:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 TO DO

=over 4

=item *

Add full support for arguments that may be passed to I<add_entry> and I<modify_entry>

=back

=head1 SEE ALSO

L<Net::Blogger::Engine::Slash>

http://use.perl.org/~pudge/journal/3294

=head1 LICENSE

Copyright (c) 2002-2005, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
