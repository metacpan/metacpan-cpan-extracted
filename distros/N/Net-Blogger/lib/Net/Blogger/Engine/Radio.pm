{

=head1 NAME

Net::Blogger::Engine::Radio - UserLand Radio Blogger API engine

=head1 SYNOPSIS

 my $radio = Blogger->new(engine=>"radio");
 $radio->Proxy(PROXY);
 $radio->Username(USERNAME);
 $radio->Password(PASSWORD);

 $radio->newPost(
                 postbody => \"hello world",
		 publish=>1,
		 );

 $radio->metaWeblog()->newPost(
	   		       title=>"hello",
			       description=>"world",
			       publish=>1,
			      );

=head1 DESCRIPTION

This package inherits I<Net::Blogger::Engine::Userland> and implements 
methods specific to a RadioUserLand XML-RPC server.

=cut

package Net::Blogger::Engine::Radio;
use strict;

$Net::Blogger::Engine::Radio::VERSION   = '1.0';
@Net::Blogger::Engine::Radio::ISA       = qw (
                                         Exporter
                                         Net::Blogger::Engine::Userland
                                         );
@Net::Blogger::Engine::Radio::EXPORT    = qw ();
@Net::Blogger::Engine::Radio::EXPORT_OK = qw ();

use Exporter;
use Net::Blogger::Engine::Userland;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns an object. Woot!

=cut

sub new {
    my $pkg  = shift;

    my $self = {};
    bless $self,$pkg;
    
    if (! $self->SUPER::init(@_)) {
	return undef;
    }

    return $self;
}

=head1 Blogger API METHODS

=cut

=head2 $pkg->GetBlogId()

 "blogid is ignored. (Radio only manages one weblog, but something
  interesting could be done here with categories. In your code you
  must pass "home", all other blogid's cause an error.)"

   http://radio.userland.com/emulatingBloggerInRadio#howTheBloggerApiMapsOntoRadioWeblogs

This method overrides I<Net::Blogger::API::Extended::getBlogId> method

=cut

sub GetBlogId {
    my $self = shift;
    return "home";
}

=head2 $pkg->BlogId()

See docs for I<GetBlogId>

=cut

sub BlogId {
  my $self = shift;
  return $self->GetBlogId();
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 19:29:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<Net::Blogger::Engine::Userland>

L<Net::Blogger::Engine::Userland::metaWeblog>

http://frontier.userland.com/emulatingBloggerInManila

=head1 LICENSE

Copyright (c) 2001-2005 Aaron Straup Cope.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
