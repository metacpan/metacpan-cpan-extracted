package Sweet::HomeDir;
use latest;
use Moose;

use File::HomeDir;

use namespace::autoclean;

extends 'Sweet::Dir';

sub _build_path { File::HomeDir->my_home }

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Sweet::HomeDir

=head1 INHERITANCE

Inherits from L<Sweet::Dir>.

=head1 ATTRIBUTES

=head2 path

Defaults to value given by L<File::HomeDir>'s C<my_home> function.

=cut

