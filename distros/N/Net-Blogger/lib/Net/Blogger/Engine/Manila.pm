{

=head1 NAME

Net::Blogger::Manila - UserLand Manila Blogger API engine

=head1 SYNOPSIS

 TBW

=head1 DESCRIPTION

This package inherits I<Net::Blogger::Engine::Userland> and implements methods 
specific to  UserLand Manila server.

=cut

package Net::Blogger::Engine::Manila;
use strict;

$Net::Blogger::Engine::Manila::VERSION   = '1.0';
@Net::Blogger::Engine::Manila::ISA       = qw ( Exporter Net::Blogger::Engine::Userland );
@Net::Blogger::Engine::Manila::EXPORT    = qw ();
@Net::Blogger::Engine::Manila::EXPORT_OK = qw ();

use Exporter;
use Net::Blogger::Engine::Userland;

=head1 PACKAGE METHODS

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
	return 0;
    }

    return $self;
}

=head1 Blogger API OBJECT METHODS

=cut

=head2 $pkg->getUsersBlogs()

=cut

sub getUsersBlogs {
    my $self = shift;
    $self->LastError("Unsupported method.");
    return 0;
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 19:29:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<Net::Blogger>

http://frontier.userland.com/emulatingBloggerInManila

=head1 LICENSE

Copyright (c) 2001-2005 Aaron Straup Cope.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;

}
