package OX::Meta::Mount::App;
BEGIN {
  $OX::Meta::Mount::App::AUTHORITY = 'cpan:STEVAN';
}
$OX::Meta::Mount::App::VERSION = '0.14';
use Moose;
use namespace::autoclean;

extends 'OX::Meta::Mount';

has app => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

=for Pod::Coverage

=cut

1;
