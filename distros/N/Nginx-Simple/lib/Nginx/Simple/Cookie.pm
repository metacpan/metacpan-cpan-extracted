package Nginx::Simple::Cookie;

use strict;

use CGI::Cookie;

=head1 MODULE

Nginx::Simple::Cookie

=head1 METHODS

=over 4

=cut

=item $self->new

Return cookie dispatcher.

=cut

sub new
{
    my ($class, $ns) = @_;
    my $self = { nginx_simple => $ns };
    bless($self);
    return $self;
}

=item Cookie->set

Set cookie.

=cut

sub set 
{
    my ($self, %params) = @_;

    $self->{nginx_simple}->header_set('Set-Cookie', new CGI::Cookie(%params));
}

=item my %params = Cookie->read

Read all cookies.

=cut

sub read
{
    my ($self, %params) = @_;

    my $cookies = $self->{nginx_simple}->header_in('Cookie');
    
    return parse CGI::Cookie($cookies);
}

=head1 Author

Michael J. Flickinger, C<< <mjflick@gnu.org> >>

=head1 Copyright & License

You may distribute under the terms of either the GNU General Public
License or the Artistic License.

=cut

1;
