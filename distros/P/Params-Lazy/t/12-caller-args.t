use strict;
use warnings;

use Test::More;

sub delay;
sub delay_local;
use Params::Lazy qw(delay ^ delay_local ^);

my $freed = 0;
sub Freed::DESTROY { $freed++ }

sub delay {
    my $f    = $_[0];
    my @orig = @_;
    
    my $ret = force $f;
    
    is_deeply(\@_, \@orig, "a delayed argument ");
    
    return $ret;
}

sub delay_local {
    my $f    = $_[0];
    local @_ = "localized in delay_local";
    my @orig = @_;
    
    my $ret = force $f;
    
    is_deeply(\@_, \@orig, "");
    
    return $ret;
}

sub shift_at_underscore {
    my @orig = @_;
    my $ret  = delay shift @_;
    is_deeply([$ret, @_], \@orig, "");
}

$freed = 0;
shift_at_underscore("arg", "arg2", bless {}, "Freed");
is($freed, 1, "no local \@_ + caller args doesn't preserve \@_ forever");

sub shift_localized_at_underscore {
    my @orig = @_;
    my $ret  = delay_local shift @_;
    is_deeply([$ret, @_], \@orig, "");
}

shift_localized_at_underscore("arg", "arg2");

sub localize_at_underscore {
    my @orig  = @_;
    my @local = ("localized in localize_at_underscore", "same but arg2");
    local @_  = @local;
    
    my $ret  = delay shift @_;
    is($ret, $local[0], "local");
    is_deeply([$ret, @_], \@local, "");
}

localize_at_underscore("arg", "arg2");

sub replace_at_underscore_local {
    my @orig  = @_;
    my @local = ("localized in replace_at_underscore_local", "same but arg2");
    my @copy  = @local;
    local *_  = \@local;
    
    my $ret  = delay_local shift @_;
    is($ret, $copy[0], "local local");
    is_deeply([$ret, @_], \@copy, "");
    is_deeply(\@_, \@local, );
}

replace_at_underscore_local("arg", "arg2");

sub indirectly_use_at_underscore {
    my @orig  = @_;
    my @local = ("localized in replace_at_underscore_local", "same but arg2", bless {}, "Freed");
    my @copy  = @local;
    local *_  = \@local;
    
    no strict 'refs';
    my $under = \"_";
    my $ret  = delay_local shift @{$$under};
    is($ret, $copy[0], "indirect local local");
    is_deeply([$ret, @_], \@copy, "");
    is_deeply(\@_, \@local, );

}

$freed = 0;
indirectly_use_at_underscore("arg", "arg2");
is($freed, 1, "local \@_ + caller args doesn't preserve \@_ forever");

use Params::Lazy passover     => q(^),
                 passover_amp => q(^),
                 run     => q(^),
                 run_amp => q(^);
sub run          { force $_[0]      }
sub run_amp      { &force           }
sub passover     { (&run, &run, &run) }
sub passover_amp { (&run_amp, &run_amp, &run_amp) }

sub {
    my @local = qw(localized1 localized2 localized3);
    local @_  = @local;
    my @ret = passover shift @_;
    is_deeply(\@_, [], "");
    is_deeply(\@ret, \@local, "");
    
    local @_  = @local;
    @ret = passover_amp shift @_;
    is_deeply(\@_, [], "");
    is_deeply(\@ret, \@local, "");

}->();

use Params::Lazy qw( delay_1 ^$ delay_2 ^$ );
sub delay_1 { my $delayed = shift; delay_2 "noop", $delayed }
sub delay_2 { my ($d1, $d2) = @_; force $d2 }

SKIP: {
    skip('caller-args magic not yet attached to the delayed arguments', 2);
    
    my $saw = '';
    @_ = 'delay_1 should see this';
    delay_1 $saw .= $_[0], "delay_2 should see this";

    is(
        $saw,
        "delay_1 should see this",
        "Multiple delayed subs passing delayed args use the correct \@_"
    );

    $saw = '';
    sub {
        delay_1 $saw .= $_[0], "delay_2 should see this";
    }->('delay_1 should see this');

}

done_testing;