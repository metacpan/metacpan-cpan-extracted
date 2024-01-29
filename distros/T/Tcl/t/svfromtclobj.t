# Ensure SvFromTclObj() behaves correctly,
# particularly for Tcl 8.7/9.0 which merged int/wideInt types
# and unregistered various types.

use warnings;
use strict;
use Config;
use Test;

# Can manually check Devel::Peek::Dump() output for correct SV types
sub D_P_Dump {
    if (@ARGV) {
        require Devel::Peek;
        Devel::Peek::Dump(@_);
    }
}

BEGIN { plan tests => 6; }

use Tcl;

my $i = new Tcl;


# Assume $Config{'charbits'} == 8
my $ivbits = 8 * $Config{'ivsize'};

print STDERR "# IV/UV is $ivbits-bit\n" if (@ARGV);

# Negative integer representable by IV
my $p_ivmin = -int(2**($ivbits - 1));
D_P_Dump $p_ivmin;
my $t_ivmin = $i->Eval("expr {$p_ivmin}");
D_P_Dump $t_ivmin;
ok($t_ivmin, $p_ivmin);

# Postive integer representable by UV (but not IV)
my $p_uvmax = int(2**($ivbits) - 1);
D_P_Dump $p_uvmax;
my $t_uvmax = $i->Eval("expr {$p_uvmax}");
D_P_Dump $t_uvmax;
ok($t_uvmax, $p_uvmax);

# Negative integer not representable by IV
# (Perl will use NV, result from Tcl will be PV)
my $p_below_ivmin = int($p_ivmin - 1);
D_P_Dump $p_below_ivmin;
my $t_below_ivmin = $i->Eval("expr {$p_below_ivmin}");
D_P_Dump $t_below_ivmin;
ok($t_below_ivmin, $p_below_ivmin);

# Positive integer not representable by UV
# (Perl will use NV, result from Tcl will be PV)
my $p_above_uvmax = int($p_uvmax + 1);
D_P_Dump $p_above_uvmax;
my $t_above_uvmax = $i->Eval("expr {$p_above_uvmax}");
D_P_Dump $t_above_uvmax;
ok($t_above_uvmax, $p_above_uvmax);


# Check that string booleans (i.e. "yes"/"no"/"true"/"false"/"on"/"off")
# are returned as 0 or 1
{

    $i->Eval(<<'EOS');

# Start with pure string type
set trueVar true

# Command which reliably causes trueVar to become a boolean type
# (maybe there is a better way to do so)
expr {!$trueVar}

EOS

    # Can manually check type (requires Tcl 8.6 or later)
    $i->Eval(<<'EOS') if (@ARGV);
catch {puts "# [::tcl::unsupported::representation $trueVar]"}
EOS

    ok($i->GetVar('trueVar'), 1);
}


# Check bytearray
if ($i->GetVar("tcl_version") >= 8.6) {
    # Command which returns a bytearray
    # (e.g. one whose contents are not valid UTF-8)
    my $hexdata = 'e08080ff';
    my $bytearraycmd = "binary decode hex $hexdata";

    # Can manually check type (requires Tcl 8.6 or later)
    $i->Eval(<<"EOS") if (@ARGV);
catch {puts "# [::tcl::unsupported::representation [$bytearraycmd]]"}
EOS

    ok(join('', (unpack 'H*', $i->Eval($bytearraycmd))), $hexdata);
}
else {
    print "skipped test for tcl version ". $i->GetVar("tcl_version") . "\n"; # TODO - better
    ok(1);
}

