use 5.014;

use lib 't/lib';

BEGIN {
  use File::Temp 'tempdir';

  $ENV{STENCIL_HOME} = tempdir('cleanup', 1);
}

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Stencil::Source

=cut

=abstract

Source generator base class

=cut

=includes

method: make
method: process
method: render
method: template

=cut

=synopsis

  use Stencil::Repo;
  use Stencil::Source::Test;

  my $repo = Stencil::Repo->new;

  $repo->store->mkpath;

  my $source = Stencil::Source::Test->new;

  # $source->make($oper, $data);

=cut

=libraries

Types::Standard

=cut

=attributes

data: ro, opt, Object
repo: ro, opt, Object

=cut

=description

This package provides a source generator base class and is meant to be
extended.

=cut

=method make

The make method executes the instructions, then returns the file.

=signature make

make(HashRef $oper, HashRef $vars) : InstanceOf["Path::Tiny"]

=example-1 make

  # given: synopsis

  $source->make({ from => 'class', make => 'MyApp.pm' }, { name => 'MyApp' });

=cut

=method process

The process method renders the template, then creates and returns the file.

=signature process

process(Str $text, HashRef $vars, Str $file) : InstanceOf["Path::Tiny"]

=example-1 process

  # given: synopsis

  $source->process('use [% data.name %]', { name => 'MyApp' }, 'example.pl');

=cut

=method render

The render method processes the template and returns the content.

=signature render

render(Str $text, HashRef $vars) : Str

=example-1 render

  # given: synopsis

  $source->render('use [% data.name %]', { name => 'MyApp' });

=cut

=method template

The template method returns the named content declared in the C<__DATA__>
section of the generator.

=signature template

template(Str $name) : Str

=example-1 template

  # given: synopsis

  $source->template('class');

=example-2 template

  # given: synopsis

  $source->template('class-test');

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'make', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->exists;
  like scalar($result->slurp), qr/package MyApp/;

  $result
});

$subs->example(-1, 'process', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->exists;
  like scalar($result->slurp), qr/use MyApp/;

  $result
});

$subs->example(-1, 'render', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/use MyApp/;

  $result
});

$subs->example(-1, 'template', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/package \[\% data\.name \%\];/;

  $result
});

$subs->example(-2, 'template', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/use_ok '\[\% data\.name \%\]';/;

  $result
});

ok 1 and done_testing;
