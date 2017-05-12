package OX::Meta::Mount;
BEGIN {
  $OX::Meta::Mount::AUTHORITY = 'cpan:STEVAN';
}
$OX::Meta::Mount::VERSION = '0.14';
use Moose;
use namespace::autoclean;

with 'OX::Meta::Role::Path';

sub type { 'mount' }

__PACKAGE__->meta->make_immutable;

=for Pod::Coverage
  type

=cut

1;
