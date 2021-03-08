package
    Pinto::Remote::SelfContained::Httptiny;

use v5.10;
use strict;
use warnings;

use Class::Method::Modifiers qw(around);
use Pinto::Remote::SelfContained::Httptiny::Handle;

use namespace::clean;

our $VERSION = '0.900';

use parent 'HTTP::Tiny';

around _open_handle => sub {
    my ($orig, $self, @args) = @_;
    my $handle = $self->$orig(@args);
    return bless $handle, 'Pinto::Remote::SelfContained::Httptiny::Handle';
};

1;
__END__

=head1 NAME

Pinto::Remote::SelfContained::Httptiny - HTTP/1.0 subclass of HTTP::Tiny

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2020 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
