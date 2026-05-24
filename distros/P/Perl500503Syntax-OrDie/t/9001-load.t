######################################################################
#
# 9001-load.t  Module load and interface check
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub ok {
    my ($ok, $name) = @_;
    $T_RUN++; $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN" . ($name ? " - $name" : '') . "\n";
    return $ok;
}
sub diag { print "# $_[0]\n" }
END { exit 1 if $T_PLAN && $T_FAIL }

plan_tests(15);

######################################################################
# Section 1: Perl500503Syntax::OrDie module
######################################################################

eval { require Perl500503Syntax::OrDie };
ok(!$@, 'Perl500503Syntax::OrDie loads without error');
diag("load error: $@") if $@;

ok(defined $Perl500503Syntax::OrDie::VERSION,
   'Perl500503Syntax::OrDie: $VERSION defined');

ok($Perl500503Syntax::OrDie::VERSION =~ /^\d+\.\d+/,
   'Perl500503Syntax::OrDie: $VERSION looks like a version number');

ok($Perl500503Syntax::OrDie::VERSION eq '0.01',
   'Perl500503Syntax::OrDie: $VERSION is 0.01');

# Public API subs
ok(defined &Perl500503Syntax::OrDie::check_file,
   'Perl500503Syntax::OrDie: check_file() defined');

ok(defined &Perl500503Syntax::OrDie::check_source,
   'Perl500503Syntax::OrDie: check_source() defined');

# Internal subs
ok(defined &Perl500503Syntax::OrDie::_check_file,
   'Perl500503Syntax::OrDie: _check_file() defined');

ok(defined &Perl500503Syntax::OrDie::_check_source,
   'Perl500503Syntax::OrDie: _check_source() defined');

ok(defined &Perl500503Syntax::OrDie::_mask_source,
   'Perl500503Syntax::OrDie: _mask_source() defined');

ok(defined &Perl500503Syntax::OrDie::_mask_dquote,
   'Perl500503Syntax::OrDie: _mask_dquote() defined');

ok(defined &Perl500503Syntax::OrDie::_mask_squote,
   'Perl500503Syntax::OrDie: _mask_squote() defined');

ok(defined &Perl500503Syntax::OrDie::_mask_delimited,
   'Perl500503Syntax::OrDie: _mask_delimited() defined');

ok(defined &Perl500503Syntax::OrDie::_install_runtime_guards,
   'Perl500503Syntax::OrDie: _install_runtime_guards() defined');

ok(defined &Perl500503Syntax::OrDie::_mask_comments,
   'Perl500503Syntax::OrDie: _mask_comments() defined');

######################################################################
# Section 2: INA_CPAN_Check
######################################################################

eval { require INA_CPAN_Check };
ok(!$@, 'INA_CPAN_Check loads without error');
diag("load error: $@") if $@;

