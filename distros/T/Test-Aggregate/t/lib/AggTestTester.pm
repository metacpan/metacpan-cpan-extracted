# vim: set ft=perl ts=2 sts=2 sw=2 et sta:
use strict;
use warnings;

package # no_index
  AggTestTester;

use Test::Aggregate;
use File::Spec::Functions qw(catfile); # core
use Test::More;
use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
  aggregate
  catfile
  only_with_nested
);

sub only_with_nested (&) {
  my $sub = shift;
  SKIP: {
    # We use done_testing so skip(1) is sufficient.
    skip 'Need Test::More::subtest() for nested tests', 1
        if !Test::More->can('subtest');

    require Test::Aggregate::Nested;
    $sub->();
  }
}

sub aggregate {
  AggTestTester->new(@_)->run;
}

sub new {
  my ($class, $mod, $tests, $exp, %extra) = @_;
  eval "require $mod" or die $@;
  bless {
    mod   => $mod,
    tests => $tests,
    exp   => $exp,
    diag  => delete($extra{diag}) || [],
    args  => { %extra },
  }, $class;
}

sub aggregator {
  my ($self) = shift;

  return $self->{mod}->new({
    tests   => $self->{tests},
    verbose => 2,
    %{ $self->{args} },
    @_,
  });
}

sub run {
  my $self = shift;
  my $mod = $self->{mod};
  my $is_nested = ($mod =~ /::Nested$/);
  my $tb = {};
  my @ran;

  # Break the reference.
  my @exp_results = @{ $self->{exp} };

  # Test::Tester didn't work well with Test::Aggregate
  # so just override the functions used in the tests
  {
    no strict 'refs';
    no warnings 'redefine';

    # Keep copies to the originals so we can call them.
    my $ok   = \&Test::Builder::ok;
    my $diag = \&Test::Builder::diag;

    # Intercept calls to ok():
    # Make it "ok" if it's the test we expected and "not ok" if it isn't.
    local *Test::Builder::ok = sub {
      my ($self, $val, $msg) = @_;
      my $agg_ok = 0;
      my $exp = $exp_results[0];

      if( $exp && $val == $exp->[0] && $msg =~ $exp->[1] ){
        $agg_ok = 1;
        $msg = $exp->[2];
        shift @exp_results;
      }

      # For debugging.
      if( !$agg_ok ){
        $self->$diag(       "Intercepted: ok($val, $msg);");
        $self->$diag($exp ? "Expected:    ok($exp->[0], $exp->[1]);" : "No more expected");
      }

      $self->$ok($agg_ok, "(Aggregated) $msg");
    };
    # Hide most diag output, but track it for later.
    local *Test::Builder::diag = sub {
      my ($self, $msg) = @_;
      push @{ $tb->{diag} }, $msg;
    };

    my $agg = $self->aggregator(
      setup => sub { push @ran, $_[0] },
    );

    # Nested sets a plan so it needs to run in a subtest.
    if( $is_nested ){
      # Therefore we'll need to expect another ok().
      push @exp_results, [1, qr/Nested/, 'Tester subtest'];
      Test::More::subtest(Nested => sub { $agg->run })
    }
    else {
      $agg->run;
    }
  }

  is scalar(@exp_results), 0, "$mod - All expected tests found";

  is_deeply(\@ran, $self->{tests}, "$mod - All expected test scripts run");

  # Check diag to see that we ran each script.
  # This is redundant with the setup block test but it makes me feel good.
  my @exp_diags = (
    (map { (
      (!$is_nested && $ENV{TEST_VERBOSE} ? qr/[*]{8} running tests for \Q$_\E [*]{8}/ : ()),
      qr/ \Q$_\E \(\d out of ${\scalar @{ $self->{tests} }}\)/,
    ) } @{ $self->{tests} }),
    @{ $self->{diag} },
  );
  my @diags = @{ $tb->{diag} };
  my @unmatched;

  is scalar(@exp_diags), scalar(@diags), 'expected number of diagnostics';

  DIAG: while( my $diag = shift @diags ){
    foreach my $exp_msg ( @exp_diags ){
      $diag =~ $exp_msg
        and next DIAG;
    }
    push @unmatched, $diag;
  }

  is scalar(@unmatched), 0, 'all diagnostics matched'
    or diag explain \@unmatched;
}

1;
