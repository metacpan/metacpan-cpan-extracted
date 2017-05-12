{

=head1 NAME

Net::Blogger::Engine::Blogger - Pyra Blogger API engine

=head1 SYNOPSIS

 TBW

=head1 DESCRIPTION

This package inherits I<Net::Blogger::Engine::Base> and defines methods specific
the the Pyra (blogger.com) XML-RPC server.

=cut

package Net::Blogger::Engine::Blogger;
use strict;

use constant BLOGGER_PROXY  => "http://plant.blogger.com/api/RPC2";
use constant MAX_POSTLENGTH => 65536;

$Net::Blogger::Engine::Blogger::VERSION   = '1.0';
@Net::Blogger::Engine::Blogger::ISA       = qw ( Exporter Net::Blogger::Engine::Base );
@Net::Blogger::Engine::Blogger::EXPORT    = qw ();
@Net::Blogger::Engine::Blogger::EXPORT_OK = qw ();

use Exporter;
use Net::Blogger::Engine::Base;

sub new {
    my $pkg = shift;

    my $self = {};
    bless $self,$pkg;

    if (! $self->SUPER::init(@_)) {
	return 0;
    }

    return $self;
}

=head1 PACKAGE METHODS

=head2 __PACKAGE__->new()

Instantiate a new Blogger Engine object.

=head1 OBJECT METHODS

=pod

=head2 $pkg->Proxy()

Return the URI of the Blogger XML-RPC proxy

=cut

sub Proxy {
  my $self = shift;
  return $self->SUPER::Proxy(@_) || BLOGGER_PROXY;
}

=head2 $pkg->MaxPostLength()

Return the maximum number of characters a single post may contain.

=cut

sub MaxPostLength {
    return MAX_POSTLENGTH;
}

sub DESTROY {
    return 1;
}

=head1 KNOWN ISSUES

=over 4

=item *

B<Delays>

It remains uncertain how long a program needs to wait between the time that a new
post is submitted to the Blogger servers and that that may post may be acted upon.

The applies to the Blogger API I<getPost>, I<editPost> and I<deletePost> methods equally.
Anything under a 10 second will often result in a "post not found" fault. A delay of 10
seconds or more is usually successful. Your mileage may vary.

=item *

B<setTemplate()>

 <quote src = "ev">
  There are some blogs for which setTemplate will return a permission denied error. Newly
  created blogs will work. Sufficiently older blogs will work. A meanwhile work-around:
  edit the template through Blogger UI first.
 </quote>

=back

=cut

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 19:29:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<Net::Blogger::Engine::Base>

http://plant.blogger.com/api/

=head1 LICENSE

Copyright (c) 2001-2005 Aaron Straup Cope.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;

}
