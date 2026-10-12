use strict;
use warnings;

use lib qw{ . lib };

use Test::More;

plan tests => 6;

use_ok qw( Module::ScanDeps::Static );

# --- shared fixture ----------------------------------------------------
#
# Exercises the four behaviours that interacted badly before this fix:
#
#   * pragmas (strict/warnings/...) must never appear in ANY tier -- not
#     as a hard require, not (via an eval-wrapped `use warnings FATAL`)
#     as a suggests, and therefore never as a spurious tier-conflict.
#     This includes `feature`, whose first release (5.9.4) is ABOVE the
#     default min_core_version, so an is_core-based filter would miss it.
#
#   * a module named after a pragma but distinct (warnings::register) is
#     a real module and must survive -- the filter is exact-match.
#
#   * `## scandeps: requires` must promote an eval-wrapped require to the
#     hard-require tier (the annotation parser previously recognised only
#     suggests|recommends and silently ignored requires).
#
#   * a module appearing at two strengths (eval-wrapped AND plain
#     require) must resolve to the single strongest tier, not sit in
#     both.

my $CODE = <<'END_CODE';
package Foo;
use strict;
use warnings;
use warnings FATAL => qw(all);
use feature qw(say);
use lib qw(blib/lib);

use warnings::register;

eval { require XML::Simple; };  ## scandeps: requires
require XML::Simple;

eval { require Only::In::Eval; };

require Plain::Only;

1;
END_CODE

sub scan {
  my (%opts) = @_;
  open my $fh, '<', \$CODE or die "could not open in-memory handle: $!";
  my $scanner = Module::ScanDeps::Static->new(
    { handle => $fh, core => 0, add_version => 0, %opts } );
  $scanner->parse;
  return $scanner;
}

########################################################################
subtest 'pragmas never appear in any tier' => sub {
########################################################################
  my $scanner    = scan();
  my $require    = $scanner->get_require;
  my $recommends = $scanner->get_recommends;
  my $suggests   = $scanner->get_suggests;

  for my $pragma (qw(strict warnings feature lib)) {
    ok( !exists $require->{$pragma},    "$pragma absent from require" );
    ok( !exists $recommends->{$pragma}, "$pragma absent from recommends" );
    ok( !exists $suggests->{$pragma},   "$pragma absent from suggests" );
  }
};

########################################################################
subtest 'feature is filtered despite being newer than min_core_version'
  => sub {
########################################################################
  # 'feature' first appeared in 5.9.4, above the 5.8.9 default floor, so
  # is_core() would return false and let it leak. The pragma filter is
  # version-independent, so it must be gone regardless.
  my $scanner = scan( min_core_version => '5.8.9' );

  ok( !exists $scanner->get_require->{feature},
    'feature does not leak even though is_core would pass it through' );
};

########################################################################
subtest 'is_pragma is exact-match, not a prefix' => sub {
########################################################################
  my $scanner = scan();

  ok( $scanner->is_pragma('warnings'),
    'warnings is recognised as a pragma' );
  ok( !$scanner->is_pragma('warnings::register'),
    'warnings::register is NOT a pragma (distinct real module)' );
  ok( exists $scanner->get_require->{'warnings::register'},
    'warnings::register survives as a real dependency' );
};

########################################################################
subtest '## scandeps: requires promotes an eval-wrapped require' => sub {
########################################################################
  my $scanner  = scan();
  my $require   = $scanner->get_require;
  my $suggests  = $scanner->get_suggests;

  ok( exists $require->{'XML::Simple'},
    'annotated eval-wrapped require lands in the hard-require tier' );
  ok( !exists $suggests->{'XML::Simple'},
    'and is NOT left in suggests' );
};

########################################################################
subtest 'strongest tier wins across duplicate occurrences' => sub {
########################################################################
  # XML::Simple appears both as an (annotated) eval require and as a
  # plain require; it must resolve to exactly one tier.
  my $scanner    = scan();
  my $require    = $scanner->get_require;
  my $recommends = $scanner->get_recommends;
  my $suggests   = $scanner->get_suggests;

  my $count = ( exists $require->{'XML::Simple'} ? 1 : 0 )
    + ( exists $recommends->{'XML::Simple'} ? 1 : 0 )
    + ( exists $suggests->{'XML::Simple'} ? 1 : 0 );

  is( $count, 1, 'XML::Simple appears in exactly one tier' );

  # an un-annotated eval require stays in suggests (default behaviour
  # preserved); a plain require is a hard require.
  ok( exists $suggests->{'Only::In::Eval'},
    'un-annotated eval require still defaults to suggests' );
  ok( exists $require->{'Plain::Only'},
    'plain require is a hard require' );
};

1;
