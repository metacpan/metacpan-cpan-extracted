package main;
use Signals::XSIG;
use lib '.';
use t::SignalHandlerTest;
use Test::More tests => 26;
use Config;
use strict;
use warnings;
no warnings 'signal';

# does our %XSIG signal handling framework still work after we
# local'ize an element of %XSIG or %SIG? If we local'ize all
# of %XSIG or %SIG?
#
# (Partial answer:  local %SIG  doesn't work well with this
# module after Perl v5.12)

sub foo { 42 }
sub bar { 43 }

my $s = appropriate_signals();

ok(!defined($SIG{$s}));
$SIG{$s} = 'main::foo';
ok($SIG{$s} eq 'main::foo', 'scalar assignment to $SIG{sig}');
ok($XSIG{$s}[0] eq 'main::foo', '... makes assignment to $XSIG{sig}[0]');
my $oldreg = $XSIG{$s}[0];

my %z = %SIG;
{
  local $SIG{$s} = 'DEFAULT';
  ok($SIG{$s} eq 'DEFAULT', 'assignment after local $SIG{sig}');
  ok(tied %SIG, '%SIG still tied after local');
  ok($XSIG{$s}[0] eq 'DEFAULT', '$XSIG{sig}[0] assignment ok after local');
}

ok(tied %SIG, "tied hash restored after local \$SIG{...}");
ok($SIG{$s} eq 'main::foo', "hash val restored after local \$SIG{...}");
ok($XSIG{$s}[0] eq $oldreg, "XSIG val restored");

my $restored = 1;
for my $k (keys %z) {
    next unless defined($z{$k}) || defined($SIG{$k});
    if ($z{$k} ne $SIG{$k}) {
        $restored = 0;
        diag "Not restored: $k";
    }
}
ok($restored, "hash val restored after local \$SIG{...}");


#
#     { local %SIG; ... }
#
# will break the tied functionality, so don't do that and avoid
# modules that do that:
#
#     PAR::Dist::_unzip
#
#     { local $SIG{signal} = ... }  is ok, though.
#
# only workaround is to save and restore the whole table
# when the local var goes out of scope.

ok(tied %SIG, "\%SIG tied before localization");
%z = %SIG;
my $still_tied = 0;
{
  local %SIG;
  $SIG{$s} = 'IGNORE';
  ok($SIG{$s} eq 'IGNORE', 'set $SIG{sig}');

  # Affect of local %SIG is not consistent across different Perls
  # perl 5.8.1: %SIG is still tied, %SIG affects %XSIG
  # perl 5.16.3: %SIG not tied, does not affect %XSIG
  # perl 5.24.0: %SIG not tied, does not affect %XSIG
  # perl 5.26.1: %SIG not tied, does not affect %XSIG
  # perl 5.30.0: %SIG not tied, does not affect %XSIG
  # perl 5.35.11: %SIG not tied, does not affect %XSIG
  if (tied %SIG) {
      diag 'local %SIG is still tied on ',$],', ',ref(tied %SIG);
      ok(tied %SIG, "\%SIG still tied during localization");         # 13 
      ok($XSIG{$s}[0] eq 'IGNORE', 'local %SIG still affects %XSIG');# 14
      $still_tied = 1;
  } else {
      diag 'local %SIG is not tied on ',$];
      ok(!tied %SIG, "\%SIG untied during localization");              # 13 
      ok($XSIG{$s}[0] ne 'IGNORE', 'local %SIG does not affect %XSIG');# 14
  }
}
ok(tied %SIG, "tied hash restored after local \%SIG");
if ($still_tied) {
    ok($SIG{$s} eq 'IGNORE',
       '$SIG{sig} still has same value from when it was local');
    ok($XSIG{$s}[0] eq $SIG{$s},);
} else {
    ok($SIG{$s} eq 'main::foo', "hash val restored after local \%SIG");
    ok($XSIG{$s}[0] eq $oldreg, "XSIG val restored");
}
$restored = 1;
for my $k (keys %z) {
    no warnings 'uninitialized';
    next if $k eq $s;
    next unless defined($z{$k}) || defined($SIG{$k});
    if ($z{$k} ne $SIG{$k}) {
        $restored = 0;
        diag "Not restored: $k";
    }
}
ok($restored, "hash val restored after local \%SIG");


# trigger tests.
# do extended signal handlers run when %SIG is local?

%z = %SIG;
ok(tied %SIG, '%SIG is tied before trigger test');
my ($x,$y,$z) = (0,0,0);
$XSIG{$s} = [ sub { $x=1 }, sub { $y=$z=1 } ];
trigger($s);
ok($x==1 && $y==1 && $z==1, '%XSIG governs signal handling');
{
  local %SIG;
  $SIG{$s} = sub { $x=2 };
  $x = $y = $z = 0;
  trigger($s);
  if ($still_tied) {
      ok($x == 2, 'local %SIG still updates $XSIT{sig}[0]');
  } else {
      ok($x == 1, '%XSIG governs signal handling, not local %SIG');
  }
  ok($y == 1 && $z == 1, '%XSIG handlers run after local %SIG');
}

{
    local $SIG{$s} = sub {$x = 3; $y = 4;};
    $x = $y = $z = 0;
    trigger($s);
    ok($x == 3, 'local $SIG{signal} is used');
    ok($y == 1, '$XSIG{sig} posthandler active under local $SIG{sig}');
}

$x = $y = $z = 0;
trigger($s);
if ($still_tied) {
    ok($x == 2, '$SIG{signal} restored');
} else {
    ok($x == 1, '$SIG{signal} restored');
}
ok($y == 1, '$XSIG{sig} posthandler active under local $SIG{sig}');
