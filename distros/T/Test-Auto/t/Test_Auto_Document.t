use 5.014;

use lib 't/lib';

use strict;
use warnings;

use Test::Auto;
use Test::More;

=name

Test::Auto::Document

=abstract

Documentation Generator

=includes

method: render

=synopsis

  package main;

  use Test::Auto;
  use Test::Auto::Parser;
  use Test::Auto::Document;

  my $test = Test::Auto->new(
    't/Test_Auto.t'
  );

  my $parser = Test::Auto::Parser->new(
    source => $test
  );

  my $doc = Test::Auto::Document->new(
    parser => $parser
  );

  # render documentation

  # $doc->render

=description

This package use the L<Test::Auto::Parser> object to generate a valid Perl 5
POD document.

=libraries

Test::Auto::Types

=attributes

content: ro, opt, ArrayRef[Str]
template: ro, opt, Maybe[Str]
parser: ro, req, Parser

=method render

This method returns a string representation of a valid POD document. You can
also provide a template to wrap the generated document by passing it to the
constructor or specifying it in the C<TEST_AUTO_TEMPLATE> environment variable.

=signature render

render() : Str

=example-1 render

  # given: synopsis

  my $rendered = $doc->render;

=example-2 render

  # given: synopsis

  $ENV{TEST_AUTO_TEMPLATE} = './t/Test_Template.pod';

  # where ./t/Test_Template.pod has a {content} placeholder

  my $rendered = $doc->render;

  undef $ENV{TEST_AUTO_TEMPLATE};

  $rendered;

=example-3 render

  # given: synopsis

  my $tmpl = Test::Auto::Document->new(
    parser => $parser,
    template => './t/Test_Template.pod'
  );

  my $rendered = $tmpl->render;

=cut

package main;

my $subs = testauto(__FILE__);

$subs = $subs->standard;

$subs->plugin('ShortDescription')->tests;

$subs->synopsis(sub {
  my ($tryable) = @_;

  ok my $result = $tryable->result, 'result ok';
  is ref($result), 'Test::Auto::Document', 'isa ok';

  $result;
});

$subs->example(-1, 'render', 'method', sub {
  my ($tryable) = @_;

  ok my $result = $tryable->result, 'result ok';
  like $result, qr/=head1 NAME/, 'has =head1 name';
  like $result, qr/=head1 ABSTRACT/, 'has =head1 abstract';
  like $result, qr/=head1 SYNOPSIS/, 'has =head1 synopsis';
  like $result, qr/=head1 DESCRIPTION/, 'has =head1 description';
  unlike $result, qr/=head1 AUTHOR/, 'no =head1 author';
  unlike $result, qr/=head1 LICENSE/, 'no =head1 license';

  $result;
});

$subs->example(-2, 'render', 'method', sub {
  my ($tryable) = @_;

  ok my $result = $tryable->result, 'result ok';
  like $result, qr/=head1 NAME/, 'has =head1 name';
  like $result, qr/=head1 ABSTRACT/, 'has =head1 abstract';
  like $result, qr/=head1 SYNOPSIS/, 'has =head1 synopsis';
  like $result, qr/=head1 DESCRIPTION/, 'has =head1 description';
  like $result, qr/=head1 AUTHOR/, 'no =head1 author';
  like $result, qr/=head1 LICENSE/, 'no =head1 license';

  $result;
});

$subs->example(-3, 'render', 'method', sub {
  my ($tryable) = @_;

  ok my $result = $tryable->result, 'result ok';
  like $result, qr/=head1 NAME/, 'has =head1 name';
  like $result, qr/=head1 ABSTRACT/, 'has =head1 abstract';
  like $result, qr/=head1 SYNOPSIS/, 'has =head1 synopsis';
  like $result, qr/=head1 DESCRIPTION/, 'has =head1 description';
  like $result, qr/=head1 AUTHOR/, 'has =head1 author';
  like $result, qr/=head1 LICENSE/, 'has =head1 license';

  $result;
});

ok 1 and done_testing;
