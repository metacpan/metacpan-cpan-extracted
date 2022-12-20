package main;

use 5.018;

use strict;
use warnings;

use Test::Auto;
use Test::More;

my $test = test(__FILE__);

=name

Test::Auto

=cut

$test->for('name');

=version

0.14

=cut

$test->for('version');

=tagline

Test Automation

=cut

$test->for('tagline');

=abstract

Test Automation for Perl 5

=cut

$test->for('abstract');

=includes

function: test
method:data
method: for
method: render

=cut

$test->for('includes');

=synopsis

  package main;

  use Test::Auto;
  use Test::More;

  my $test = Test::Auto->new(
    't/Test_Auto.t'
  );

  # ...

  # =synopsis
  #
  # use Path::Find 'path';
  #
  # my $path = path; # get path using cwd
  #
  # =cut

  # $test->for('synopsis', sub {
  #   my ($tryable) = @_;
  #   ok my $result = $tryable->result;
  #
  #   # more test for the synopsis ...
  #
  #   $result
  # });

  # ...

  # $test->render('lib/Path/Find.pod');

  # done_testing

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Test::Auto');
  ok $result->isa('Venus::Test');
  ok $result->value eq 't/Test_Auto.t';

  $result
});

=description

This package aims to provide, a standard for documenting Perl 5 software
projects, a framework writing tests, test automation, and documentation
generation.

+=head1 AUTOMATION

  # ...

  $test->for('name');

This framework provides a set of automated subtests based on the package
specification, but not everything can be automated so it also provides you with
powerful hooks into the framework for manual testing.

  # ...

  $test->for('synopsis', sub {
    my ($tryable) = @_;

    ok my $result = $tryable->result, 'result ok';

    # must return truthy to continue
    $result;
  });

The code examples documented can be automatically evaluated (evaled) and
returned using a callback you provide for further testing. Because the code
examples are returned as L<Venus::Try> objects this makes capturing and testing
exceptions simple, for example:

  # ...

  $test->for('synopsis', sub {
    my ($tryable) = @_;

    # catch exception thrown by the synopsis
    $tryable->catch('Path::Find::Error', sub {
      return $_[0];
    });

    # test the exception
    ok my $result = $tryable->result, 'result ok';
    ok $result->isa('Path::Find::Error'), 'exception caught';

    # must return truthy to continue
    $result;
  });

Additionally, another manual testing hook (with some automation) is the
C<example> method. This hook evaluates (evals) a given example and returns the
result as a L<Venus::Try> object. The first argument is the example ID (or
  number), for example:

  # ...

  $test->for('example', 1, 'children', sub {
    my ($tryable) = @_;

    ok my $result = $tryable->result, 'result ok';

    # must return truthy to continue
    $result;
  });

Finally, the lesser-used but useful manual testing hook is the C<feature>
method. This hook evaluates (evals) a documented feature and returns the result
as a L<Venus::Try> object, for example:

  # ...

  $test->for('feature', 'export-path-make', sub {
    my ($tryable) = @_;

    ok my $result = $tryable->result, 'result ok';

    # must return truthy to continue
    $result;
  });

The test automation and documentation generation enabled through this framework
makes it easy to maintain source/test/documentation parity. This also increases
reusability and reduces the need for complicated state and test setup.

+=head1 SPECIFICATION

  # Version 0.13+

  # [required]

  =name
  =abstract
  =includes
  =synopsis
  =description

  # [optional]

  =tagline
  =libraries
  =inherits
  =integrates

  # [optional; repeatable]

  =feature $name
  =example $name

  # [optional; repeatable]

  =attribute $name
  =signature $name
  =example-$number $name # [repeatable]

  # [optional; repeatable]

  =method $name
  =signature $name
  =example-$number $name # [repeatable]

  # [optional; repeatable]

  =function $name
  =signature $name
  =example-$number $name # [repeatable]

  # [optional; repeatable]

  =routine $name
  =signature $name
  =example-$number $name # [repeatable]

The specification is designed to accommodate typical package declarations. It
is used by the parser to provide the content used in test automation and
document generation. B<Note:> When code blocks are evaluated, the
I<"redefined"> warnings are now automatically disabled.

+=head2 name

  =name

  Path::Find

  =cut

  $test->for('name');

The C<name> block should contain the package name. This is tested for
loadability.

+=head2 tagline

  =tagline

  Path Finder

  =cut

  $test->for('tagline');

The C<tagline> block should contain a tagline for the package. This is optional
but if present is concatenated with the C<name> during POD generation.

+=head2 abstract

  =abstract

  Find Paths using Heuristics

  =cut

  $test->for('abstract');

The C<abstract> block should contain a subtitle describing the package. This is
tested for existence.

+=head2 includes

  =includes

  function: path
  method: children
  method: siblings
  method: new

  =cut

  $test->for('includes');

The C<includes> block should contain a list of C<function>, C<method>, and/or
C<routine> names in the format of C<$type: $name>. Empty lines are ignored.
This is tested for existence. Each function, method, and/or routine is tested
to be documented properly, i.e. has the requisite counterparts (e.g. signature
and at least one example block). Also, the package must recognize that each
exists.

+=head2 synopsis

  =synopsis

  use Path::Find 'path';

  my $path = path; # get path using cwd

  =cut

  $test->for('synopsis', sub {
    my ($tryable) = @_;
    my $result = $tryable->result;

    # must return truthy to continue
    $result
  });

The C<synopsis> block should contain the normative usage of the package. This
is tested for existence. This block should be written in a way that allows it
to be evaled successfully and should return a value.

+=head2 description

  =description

  interdum posuere lorem ipsum dolor sit amet consectetur adipiscing elit duis
  tristique sollicitudin nibh sit amet

  =cut

  $test->for('description');

The C<description> block should contain a thorough explanation of the purpose
of the package. This is tested for existence.

+=head2 libraries

  =libraries

  Types::Standard
  Types::TypeTiny

  =cut

  $test->for('libraries');

The C<libraries> block should contain a list of packages, each of which is
itself a L<Type::Library>. These packages are tested for loadability, and to
ensure they are type library classes.

+=head2 inherits

  =inherits

  Path::Tiny

  =cut

  $test->for('inherits');

The C<inherits> block should contain a list of parent packages. These packages
are tested for loadability.

+=head2 integrates

  =integrates

  Path::Find::Upable
  Path::Find::Downable

  =cut

  $test->for('integrates');

The C<integrates> block should contain a list of packages that are involved in
the behavior of the main package. These packages are not automatically tested.

+=head2 features

  =feature export-path-make

  quisque egestas diam in arcu cursus euismod quis viverra nibh

  =example export-path-make

  # given: synopsis

  package main;

  use Path::Find 'path_make';

  path_make 'relpath/to/file';

  =cut

  $test->for('example', 'export-path-make', sub {
    my ($tryable) = @_;
    my $result = $tryable->result;

    # must return truthy to continue
    $result
  });

There are situation where a package can be configured in different ways,
especially where it exists without functions, methods or routines for the
purpose of configuring the environment. The feature directive can be used to
automate testing and documenting package usages and configurations. Describing
a feature requires two blocks, i.e. C<feature $name> and C<example $name>. The
C<feature> block should contain a description of the feature and its purpose.
The C<example> block must exist when documenting a feature and should contain
valid Perl code and return a value. The block may contain a "magic" comment in
the form of C<given: synopsis> or C<given: example $name> which if present will
include the given code example(s) with the evaluation of the current block.
Each feature is tested and must be recognized to exist by the main package.

+=head2 attributes

  =attribute cwd

  quis viverra nibh cras pulvinar mattis nunc sed blandit libero volutpat

  =signature cwd

  cwd(Str $path) : (Object)

  =cut

  =example-1 cwd

  # given: synopsis

  my $cwd = $path->cwd;

  =cut

  $test->for('example', 1, 'cwd', sub {
    my ($tryable) = @_;
    my $result = $tryable->result;

    # must return truthy to continue
    $result
  });

  =example-2 cwd

  # given: synopsis

  my $cwd = $path->cwd('/path/to/file');

  =cut

  $test->for('example', 2, 'cwd', sub {
    my ($tryable) = @_;
    my $result = $tryable->result;

    # must return truthy to continue
    $result
  });

Describing an attribute requires at least three blocks, i.e. C<attribute
$name>, C<signature $name>, and C<example-1 $name>. The C<attribute> block
should contain a description of the attribute and its purpose. The C<signature>
block should contain a routine signature in the form of C<$signature :
$return_type>, where C<$signature> is a valid typed signature and
C<$return_type> is any valid L<Type::Tiny> expression. The C<example-$number>
block is a repeatable block, and at least one block must exist when documenting
an attribute. The C<example-$number> block should contain valid Perl code and
return a value. The block may contain a "magic" comment in the form of C<given:
synopsis> or C<given: example-$number $name> which if present will include the
given code example(s) with the evaluation of the current block. Each attribute
is tested and must be recognized to exist by the main package.

+=head2 methods

  =method children

  quis viverra nibh cras pulvinar mattis nunc sed blandit libero volutpat

  =signature children

  children() : [Object]

  =cut

  =example-1 children

  # given: synopsis

  my $children = $path->children;

  =cut

  $test->for('example', 1, 'children', sub {
    my ($tryable) = @_;
    my $result = $tryable->result;

    # must return truthy to continue
    $result
  });

  =example-2 children

  # given: synopsis

  my $filtered = $path->children(qr/lib/);

  =cut

  $test->for('example', 2, 'children', sub {
    my ($tryable) = @_;
    my $result = $tryable->result;

    # must return truthy to continue
    $result
  });

Describing a method requires at least three blocks, i.e. C<method $name>,
C<signature $name>, and C<example-1 $name>. The C<method> block should contain
a description of the method and its purpose. The C<signature> block should
contain a method signature in the form of C<$signature : $return_type>, where
C<$signature> is a valid typed signature and C<$return_type> is any valid
L<Type::Tiny> expression. The C<example-$number> block is a repeatable block,
and at least one block must exist when documenting a method. The
C<example-$number> block should contain valid Perl code and return a value. The
block may contain a "magic" comment in the form of C<given: synopsis> or
C<given: example-$number $name> which if present will include the given code
example(s) with the evaluation of the current block. Each method is tested and
must be recognized to exist by the main package.

+=head2 functions

  =function path

  lectus quam id leo in vitae turpis massa sed elementum tempus egestas

  =signature children

  path() : Object

  =cut

  =example-1 path

  package Test::Path::Find;

  use Path::Find;

  my $path = path;

  =cut

  $test->for('example', 1, 'path', sub {
    my ($tryable) = @_;
    my $result = $tryable->result;

    # must return truthy to continue
    $result
  });

Describing a function requires at least three blocks, i.e. C<function $name>,
C<signature $name>, and C<example-1 $name>. The C<function> block should
contain a description of the function and its purpose. The C<signature> block
should contain a function signature in the form of C<$signature :
$return_type>, where C<$signature> is a valid typed signature and
C<$return_type> is any valid L<Type::Tiny> expression. The C<example-$number>
block is a repeatable block, and at least one block must exist when documenting
a function. The C<example-$number> block should contain valid Perl code and
return a value. The block may contain a "magic" comment in the form of C<given:
synopsis> or C<given: example-$number $name> which if present will include the
given code example(s) with the evaluation of the current block. Each function
is tested and must be recognized to exist by the main package.

+=head2 routines

  =routine algorithms

  sed sed risus pretium quam vulputate dignissim suspendisse in est ante

  =signature algorithms

  algorithms() : Object

  =cut

  =example-1 algorithms

  # given: synopsis

  $path->algorithms

  =cut

  $test->for('example', 1, 'algorithms', sub {
    my ($tryable) = @_;
    my $result = $tryable->result;

    # must return truthy to continue
    $result
  });

  =example-2 algorithms

  package Test::Path::Find;

  use Path::Find;

  Path::Find->algorithms;

  =cut

  $test->for('example', 2, 'algorithms', sub {
    my ($tryable) = @_;
    my $result = $tryable->result;

    # must return truthy to continue
    $result
  });

Typically, a Perl subroutine is declared as a function or a method. Rarely, but
sometimes necessary, you will need to describe a subroutine where the invocant
is either a class or class instance. Describing a routine requires at least
three blocks, i.e. C<routine $name>, C<signature $name>, and C<example-1
$name>. The C<routine> block should contain a description of the routine and
its purpose. The C<signature> block should contain a routine signature in the
form of C<$signature : $return_type>, where C<$signature> is a valid typed
signature and C<$return_type> is any valid L<Type::Tiny> expression. The
C<example-$number> block is a repeatable block, and at least one block must
exist when documenting a routine. The C<example-$number> block should contain
valid Perl code and return a value. The block may contain a "magic" comment in
the form of C<given: synopsis> or C<given: example-$number $name> which if
present will include the given code example(s) with the evaluation of the
current block. Each routine is tested and must be recognized to exist by the
main package.

=cut

$test->for('description');

=inherits

Venus::Test

=cut

$test->for('inherits');

=function test

The test function takes a file path and returns a L<Test::Auto> object for use
in test automation and documentation rendering. This function is exported
automatically unless a routine of the same name already exists in the calling
package.

=signature test

  test(Str $file) (Auto)

=metadata test

{
  since => '0.13',
}

=example-1 test

  # given: synopsis

  $test = test('t/Test_Auto.t');

  # =synopsis
  #
  # use Path::Find 'path';
  #
  # my $path = path; # get path using cwd
  #
  # =cut

  # $test->for('synopsis', sub {
  #   my ($tryable) = @_;
  #   ok my $result = $tryable->result;
  #
  #   # more test for the synopsis ...
  #
  #   $result
  # });

  # ...

  # $test->render('lib/Path/Find.pod');

  # done_testing

=cut

$test->for('example', 1, 'test', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Test::Auto');
  ok $result->isa('Venus::Test');
  ok $result->value eq 't/Test_Auto.t';

  $result
});

=method data

The data method attempts to find and return the POD content based on the name
provided. If the content cannot be found an exception is raised.

=signature data

  data(Str $name, Any @args) (Str)

=metadata data

{
  since => '0.13',
}

=example-1 data

  # given: synopsis

  my $data = $test->data('name');

  # Test::Auto

=cut

$test->for('example', 1, 'data', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Test::Auto';

  $result
});

=example-2 data

  # given: synopsis

  my $data = $test->data('unknown');

  # Exception! isa (Test::Auto::Error)

=cut

$test->for('example', 2, 'data', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\my $error)->result;
  ok $error;
  ok $error->isa('Test::Auto::Error');

  $result
});

=method for

The for method attempts to find the POD content based on the name provided and
executes the corresponding predefined test, optionally accepting a callback
which, if provided, will be passes a L<Venus::Try> object containing the
POD-driven test. The callback, if provided, must always return a true value.
B<Note:> All automated tests disable the I<"redefine"> class of warnings to
prevent warnings when redeclaring packages in examples.

=signature for

  for(Str $name | CodeRef $code, Any @args) (Any)

=metadata for

{
  since => '0.13',
}

=example-1 for

  # given: synopsis

  my $data = $test->for('name');

  # Test::Auto

=cut

=example-2 for

  # given: synopsis

  my $data = $test->for('synopsis');

  # bless({value => 't/Test_Auto.t'}, 'Test::Auto')

=cut

=example-3 for

  # given: synopsis

  my $data = $test->for('example', 1, 'data', sub {
    my ($tryable) = @_;
    my $result = $tryable->result;
    ok length($result) > 1;

    $result
  });

  # Test::Auto

=cut

$test->for('example', 3, 'for', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq "Test::Auto";

  $result
});

=method render

The render method renders and writes a valid POD document, and returns a
L<Venus::Path> object representation the POD file specified.

=signature render

  render(Str $file) (Path)

=metadata render

{
  since => '0.13',
}

=example-1 render

  # given: synopsis

  my $path = $test->render('t/Path_Find.pod');

  # bless({value => 't/Path_Find.pod', 'Venus::Path'})

=cut

$test->for('example', 1, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Path');
  $result->unlink;

  $result
});

=authors

Awncorp, C<awncorp@cpan.org>

=cut

# END

$test->render('lib/Test/Auto.pod') if $ENV{RENDER};

ok 1 and done_testing;
