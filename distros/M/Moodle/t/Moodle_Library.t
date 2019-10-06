use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Moodle::Library

=cut

=abstract

Moodle Type Library

=cut

=synopsis

  use Moodle::Library;

=cut

=libraries

Data::Object::Library

=cut

=description

Moodle::Library is the Moodle type library derived from
L<Data::Object::Library> which is a L<Type::Library>.

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

ok 1 and done_testing;
