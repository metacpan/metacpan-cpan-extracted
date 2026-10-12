use strict;
use warnings;

use lib qw( . lib );

use Test::More;
use Data::Dumper;

use_ok qw( Module::ScanDeps::Static );

# --- shared fixture ----------------------------------------------------
#
# Deliberately combines everything that interacted badly during
# development: a single-line eval, a multi-line eval (with a nested
# if-brace inside it, to stress brace-depth tracking), a plain
# non-eval indented require, and a with() -- all in one file, followed
# by more content after the multi-line eval block. That trailing
# content is the regression check for a real bug: an early return
# value of `undef` from a multi-line eval block was silently
# terminating the *entire* parse, not just that block, so anything
# after it in the file was never seen at all.

my $CODE = <<'END_CODE';
package Foo;
use strict;
use Carp;

eval { require Term::ReadLine } or die $@;

eval {
    # require these
    # use Commented::out
    require Multi::Line::Eval::Module;
    Multi::Line::Eval::Module->import;
};

eval {
    if (1) {
        # require that
        require Nested::Brace::Module;
    }
};

if (1) {
    # require those
    require Indented::NoEval::Module;
}

with 'Some::Role';

1;
END_CODE

sub scan {
  my (%opts) = @_;
  open my $fh, '<', \$CODE or die "could not open in-memory handle: $!";
  my $scanner = Module::ScanDeps::Static->new( { handle => $fh, core => 0, add_version => 0, %opts } );
  $scanner->parse;
  return $scanner;
}

########################################################################
subtest 'ordinary require/use/with are unaffected' => sub {
########################################################################
  my $scanner = scan();
  my $require = $scanner->get_require;

  ok( exists $require->{Carp},         'Carp (left-flushed use) is a hard require' );
  ok( exists $require->{'Some::Role'}, 'Some::Role (with) is a hard require' );
};

########################################################################
subtest 'single-line eval routes to suggests, not recommends or require' => sub {
########################################################################
  my $scanner    = scan();
  my $require    = $scanner->get_require;
  my $recommends = $scanner->get_recommends;
  my $suggests   = $scanner->get_suggests;

  ok( exists $suggests->{'Term::ReadLine'},    'present in suggests' );
  ok( !exists $recommends->{'Term::ReadLine'}, 'absent from recommends' );
  ok( !exists $require->{'Term::ReadLine'},    'absent from require' );
};

########################################################################
subtest 'multi-line eval is detected, including nested braces' => sub {
########################################################################
  # this is also the regression check for the premature-parse-
  # termination bug: if it recurs, everything below the FIRST
  # multi-line eval block (including this one, which is the second)
  # silently stops being seen at all.

  my $scanner  = scan();
  my $suggests = $scanner->get_suggests;

  ok( exists $suggests->{'Multi::Line::Eval::Module'}, 'plain multi-line eval body is found' );
  ok( exists $suggests->{'Nested::Brace::Module'}, 'multi-line eval containing a nested if-brace is still tracked correctly' );
};

########################################################################
subtest 'recommend_require does not clobber eval-detected suggests' => sub {
########################################################################
  # regression check for the second interaction bug: the rewritten
  # body of a single-line eval carries leading whitespace, which
  # looks like an indented require to the recommend_require check --
  # with recommend_require on, that check must not override the more
  # specific suggests classification eval-detection already assigned.

  my $scanner    = scan( recommend_require => 1 );
  my $require    = $scanner->get_require;
  my $recommends = $scanner->get_recommends;
  my $suggests   = $scanner->get_suggests;

  ok( exists $suggests->{'Term::ReadLine'},    'eval-wrapped require is still suggests, not reclassified' );
  ok( !exists $recommends->{'Term::ReadLine'}, 'eval-wrapped require did not leak into recommends' );

  ok( exists $recommends->{'Indented::NoEval::Module'}, 'plain indented (non-eval) require correctly lands in recommends' );
  ok( !exists $suggests->{'Indented::NoEval::Module'},  'plain indented require is a different tier than eval-wrapped' );

  for my $m (
    qw(Term::ReadLine Multi::Line::Eval::Module
    Nested::Brace::Module Indented::NoEval::Module)
  ) {
    ok( !exists $require->{$m}, "$m never leaked into hard require" );
  }
};

########################################################################
subtest 'comments with dependency signals in eval' => sub {
########################################################################
  my $scanner = scan();

  my @dependencies;

  push @dependencies, keys %{ $scanner->get_require };
  push @dependencies, keys %{ $scanner->get_suggests };
  push @dependencies, keys %{ $scanner->get_recommends };

  my ($found) = grep { $_ =~ /these|those|that|Commented::Out/xsm } @dependencies;

  ok( !$found, 'skips dependency signals in eval commments' );
};

done_testing;

1;
