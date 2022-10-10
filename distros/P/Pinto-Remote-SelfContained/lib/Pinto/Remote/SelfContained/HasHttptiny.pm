package
    Pinto::Remote::SelfContained::HasHttptiny; # hide from PAUSE

use v5.10;
use Moo::Role;

use Pinto::Remote::SelfContained::Httptiny;
use Types::Standard qw(InstanceOf);

use namespace::clean;

our $VERSION = '1.000';

has httptiny => (
    is => 'lazy',
    isa => InstanceOf['Pinto::Remote::SelfContained::Httptiny'],
    default => sub { Pinto::Remote::SelfContained::Httptiny->new(verify_SSL => 1) },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pinto::Remote::SelfContained::HasHttptiny

=head1 NAME

Pinto::Remote::SelfContained::HasHttptiny

=head1 NAME

Pinto::Remote::SelfContained::HasHttptiny - role providing an HTTP::Tiny instance

=head1 AUTHOR

Aaron Crane E<lt>arc@cpan.orgE<gt>, Brad Lhotsky E<lt>brad@divisionbyzero.netE<gt>

=head1 COPYRIGHT

Copyright 2020 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
