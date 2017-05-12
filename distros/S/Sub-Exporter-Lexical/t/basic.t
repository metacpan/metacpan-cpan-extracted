#!perl
use strict;
use warnings;

use Test::More 'no_plan';
use lib 't/lib';

use TestExporter;
use Sub::Exporter::Lexical;

{
  use TestExporter { installer => Sub::Exporter::Lexical::lexical_installer },
    qw(foo);

  is( foo(), 'foo', "we can use foo in one scope");
}

my $ok    = eval { foo(); 1; };
my $error = $@;

ok(! $ok, "foo() failes outside of lexical import's scope");
like($@, qr{Undefined subroutine}i, "failed because foo() isn't found");

