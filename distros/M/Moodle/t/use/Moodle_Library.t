use 5.014;

use strict;
use warnings;

use Test::More;

=name

Moodle

=abstract

Moodle Type Library

=synopsis

  use Moodle::Library;

=description

Moodle::Library is the L<Moodle> type library derived from
L<Data::Object::Library> which is a L<Type::Library>

=cut

use_ok "Moodle::Library";

isa_ok "Moodle::Library", "Type::Library";

ok 1 and done_testing;
