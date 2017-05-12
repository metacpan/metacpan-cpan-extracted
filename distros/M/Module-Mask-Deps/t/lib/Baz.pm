package Baz;

=head1 NAME

Baz - Fake dependency to be listed in test distributions for Module::Mask::Deps

=cut

# We get loaded from a sub-package, make sure that we can load stuff too
use Baz::Qux;

our $VERSION = '1.00';

__END__
