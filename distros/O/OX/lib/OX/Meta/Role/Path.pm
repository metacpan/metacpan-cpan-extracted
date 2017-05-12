package OX::Meta::Role::Path;
BEGIN {
  $OX::Meta::Role::Path::AUTHORITY = 'cpan:STEVAN';
}
$OX::Meta::Role::Path::VERSION = '0.14';
use Moose::Role;
use namespace::autoclean;

use OX::Util;

requires 'type';

has path => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has definition_location => (
    is      => 'ro',
    isa     => 'Str',
    default => '(unknown)',
);

sub canonical_path {
    my $self = shift;

    return OX::Util::canonicalize_path($self->path);
}

=for Pod::Coverage
  canonical_path

=cut

1;
