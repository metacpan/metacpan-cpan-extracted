use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Test::Auto

=abstract

Test Automation, Docs Generation

=includes

method: document
method: parser
method: subtests

=synopsis

  #!/usr/bin/env perl

  use Test::Auto;
  use Test::More;

  my $test = Test::Auto->new(
    't/Test_Auto.t'
  );

  # automation

  # my $subtests = $test->subtests->standard;

  # ...

  # done_testing;

=description

This package aims to provide, a standard for documenting Perl 5 software
projects, a framework writing tests, and automation for validating the tests,
documentation, and usage examples.

=headers

+=head1 REASONING

This framework lets you write documentation in test files using pod-like
comment blocks. By using a particular set of comment blocks (the specification)
this framework can run certain kinds of tests automatically. For example, we
can automatically ensure that the package the test is associated with is
loadable, that the test file comment blocks meet the specification, that any
super-classes or libraries are loadable, and that the functions, methods, and
routines are properly documented.

+=cut

=libraries

Data::Object::Library

=attributes

file: ro, req, Str
data: ro, opt, DataObject

=method document

This method returns a L<Test::Auto::Document> object.

=signature document

document() : InstanceOf["Test::Auto::Document"]

=example-1 document

  # given: synopsis

  my $document = $test->document;

=method parser

This method returns a L<Test::Auto::Parser> object.

=signature parser

parser() : InstanceOf["Test::Auto::Parser"]

=example-1 parser

  # given: synopsis

  my $parser = $test->parser;

=method subtests

This method returns a L<Test::Auto::Subtests> object.

=signature subtests

subtests() : InstanceOf["Test::Auto::Subtests"]

=example-1 subtests

  # given: synopsis

  my $subtests = $test->subtests;

=footers

+=head1 SPECIFICATION

  # [required]

  =name
  =abstract
  =includes
  =synopsis
  =description

  # [optional]

  =libraries
  =inherits
  =integrates
  =attributes

  # [repeatable; optional]

  =method $name
  =signature $name
  =example-$number $name # [repeatable]

  # [repeatable; optional]

  =function $name
  =signature $name
  =example-$number $name # [repeatable]

  # [repeatable; optional]

  =routine $name
  =signature $name
  =example-$number $name # [repeatable]

The specification is designed to accommodate typical package declarations. It
is used by the parser to provide the content used in the test automation and
document generation.

+=head2 name

  =name

  Path::Find

  =cut

The C<name> block should contain the package name. This is tested for
loadability.

+=head2 abstract

  =abstract

  Find Paths using Heuristics

  =cut

The C<abstract> block should contain a subtitle describing the package. This is
tested for existence.

+=head2 includes

  =includes

  function: path
  method: children
  method: siblings
  method: new

  =cut

The C<includes> block should contain a list of C<function>, C<method>, and/or
C<routine> names in the format of C<$type: $name>. Empty lines are ignored.
This is tested for existence. Each function, method, and/or routine is tested
to be documented properly. Also, the package must recognize that each exists.

+=head2 synopsis

  =synopsis

  use Path::Find 'path';

  my $path = path; # get path using cwd

  =cut

The C<synopsis> block should contain the normative usage of the package. This
is tested for existence. This block should be written in a way that allows it
to be evaled successfully and should return a value.

+=head2 description

  =description

  interdum posuere lorem ipsum dolor sit amet consectetur adipiscing elit duis
  tristique sollicitudin nibh sit amet

  =cut

The C<description> block should contain a thorough explanation of the purpose
of the package. This is tested for existence.

+=head2 libraries

  =libraries

  Types::Standard
  Types::TypeTiny

  =cut

The C<libraries> block should contain a list of packages, each of which is
itself a L<Type::Library>. These packages are tested for loadability, and to
ensure they are type library classes.

+=head2 inherits

  =inherits

  Path::Tiny

  =cut

The C<inherits> block should contain a list of parent packages. These packages
are tested for loadability.

+=head2 integrates

  =integrates

  Path::Find::Upable
  Path::Find::Downable

  =cut

The C<integrates> block should contain a list of packages that are involved in
the behavior of the main package. These packages are not automatically tested.

+=head2 attributes

  =attributes

  cwd: ro, req, Object

  =cut

The C<attributes> block should contain a list of package attributes in the form
of C<$name: $is, $presence, $type>, where C<$is> should be C<ro> (read-only) or
C<rw> (read-wire), and C<$presence> should be C<req> (required) or C<opt>
(optional), and C<$type> can be any valid L<Type::Tiny> expression. Each
attribute declaration must be recognized to exist by the main package and have
a type which is recognized by one of the declared type libraries.

+=head2 methods

  =method children

  quis viverra nibh cras pulvinar mattis nunc sed blandit libero volutpat

  =signature children

  children() : [Object]

  =example-1 children

  # given: synopsis

  my $children = $path->children;

  =example-2 children

  # given: synopsis

  my $filtered = $path->children(qr/lib/);

  =cut

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

  =example-1 path

  package Test::Path::Find;

  use Path::Find;

  my $path = path;

  =cut

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

  =example-1 algorithms

  # given: synopsis

  $path->algorithms

  =example-2 algorithms

  package Test::Path::Find;

  use Path::Find;

  Path::Find->algorithms;

  =cut

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

+=head1 AUTOMATION

  $test->standard;

This is the equivalent of writing:

  $test->package;
  $test->document;
  $test->libraries;
  $test->inherits;
  $test->attributes;
  $test->methods;
  $test->routines;
  $test->functions;

This framework provides a set of automated subtests based on the package
specification, but not everything can be automated so it also provides you with
two powerful hooks into the framework for manual testing.

  my $subtests = $test->subtests;

  $subtests->synopsis(fun($tryable) {
    ok my $result = $tryable->result, 'result ok';

    $result; # for automated testing after the callback
  });

The code examples documented can be automatically evaluated (evaled) and
returned using a callback you provide for further testing. Because the code
examples are returned as L<Data::Object::Try> objects, this makes capturing and
testing exceptions simple, for example:

  my $subtests = $test->subtests;

  $subtests->synopsis(fun($tryable) {
    # synopsis throws an exception
    $tryable->catch('Path::Find::Error', sub {
      return $_[0];
    });
    ok my $result = $tryable->result, 'result ok';
    ok $result->isa('Path::Find::Error'), 'exception caught';

    $result;
  });

Finally, The other manual testing hook (with some automation) is the C<example>
method. This hook evaluates (evals) a given example and returns the result as
a L<Data::Object::Try> object.

  my $subtests = $test->subtests;

  $subtests->example(-1, 'children', 'method', fun($tryable) {
    ok my $result = $tryable->result, 'result ok';

    $result;
  });

The test automation and document generation enabled through this framework
makes it easy to maintain source/test/documentation parity. This also
increases reusability and reduces the need for complicated state and test setup.

+=cut

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subs = $test->subtests->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is ref($result), 'Test::Auto', 'isa ok';

  $result;
});

$subs->example(-1, 'document', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'parser', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'subtests', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

ok 1 and done_testing;
