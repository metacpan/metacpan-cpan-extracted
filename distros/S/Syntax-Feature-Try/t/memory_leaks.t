use strict;
use warnings;
use Test::More;
require Test::NoWarnings;
use Test::LeakTrace;
use Exception::Class qw/ Mock::AAA  Mock::BBB  Mock::CCC /;

use syntax 'try';

no_leaks_ok {
    eval q[
        {
            package Test::Import1;
            use syntax 'try';
        }
    ];
} "module setup does not generates memory-leaks";


no_leaks_ok {
    eval q[
        my $code = sub {
            try {
                try { }
                catch (Mock::AAA $foo) { }
                catch ($oth) { return 77 }
                finally { my $y=5; }
            }
            catch (Mock::BBB $b) {
            }
            catch (Mock::AAA) {
            }
            catch {
            }
            finally {
                my $a = 7;
            }
        }
    ];
} "compilation phase does not generates memory-leaks";


no_leaks_ok {
    my $res=0;
    try {
        try { Mock::BBB->throw }
        catch (Mock::AAA $e) { $res=1 }
        catch (Mock::BBB $e) { $res=2 }
        catch (Mock::CCC $e) { $res=3 }
        catch ($others) { $res=4 }
        finally { $res += 100 }
    }
    catch (Mock::DDD $ddd) {
        my $e = 'blax';
    }
    finally {
        $res += 7000;
    }

    die "Invalid response: $res" if $res != 7102;
} "execution phase does not generates memory-leaks";

no_leaks_ok {
    my $res=0;
    try {
        try { Mock::BBB->throw }
        catch (Mock::AAA) { $res=1 }
        catch (Mock::BBB) { $res=2 }
        catch { $res=4 }
        finally { $res += 100 }
    }
    catch (Mock::DDD) {
        my $e = 'blax';
    }
    finally {
        $res += 7000;
    }

    die "Invalid response: $res" if $res != 7102;
} "catch without var-name does not generates memory-leaks";

sub predefined_func {
    my $n = shift || 0;
    try {
        my $x = 0;
        predefined_func($n-1) if $n;
        Mock::AAA->throw if $n > 1;
        Mock::BBB->throw;
    }
    catch (Mock::AAA $e) { my $test1 = 44; }
    catch (Mock::BBB) { my $test2 = 55; }
    finally {
        my $y = 40;
    }
}

no_leaks_ok {
    predefined_func();
} "execution predefined function does not generates memory-leaks";

no_leaks_ok {
    predefined_func(3);
} "execution recursive function does not generates memory-leaks";

no_leaks_ok {
    our $res=0;

    sub test_return_call {
        try {
            try { Mock::BBB->throw }
            catch (Mock::AAA $e) { $res=1 }
            catch (Mock::BBB $e) { $res=2; return qw/ X Y /; }
            catch (Mock::CCC $e) { $res=3 }
            catch ($others) { $res=4 }
            finally { $res += 100 }
        }
        catch (Mock::DDD $ddd) {
            my $e = 'blax';
        }
        finally {
            $res += 7000;
        }
        $res += 990000;
    }

    # void context
    test_return_call();

    # scalar context
    my $return = test_return_call();

    # array context
    my @return = test_return_call();

    die "Invalid response: $res" if $res != 7102;
} "return inside blocks does not generates memory-leaks";

no_leaks_ok {
    sub test_override_return {
        try {
            my $x=[33];
            return $x;
        }
        finally {
            return 99;
        }
    }

    # void context
    test_override_return();

    # scalar context
    my $return = test_override_return();

    # array context
    my @return = test_override_return();
} "return inside blocks does not generates memory-leaks";

Test::NoWarnings::had_no_warnings();

done_testing;
