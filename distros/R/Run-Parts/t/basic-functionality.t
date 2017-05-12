#!perl -T

use strict;
use warnings;
use 5.010;

use Test::More;
END {
    # Hack to work around
    # https://rt.cpan.org/Public/Bug/Display.html?id=66485
    done_testing();
}
use Test::NoWarnings;
use Test::Differences;
use File::Slurp 9999.06;

delete @ENV{qw{PATH ENV IFS CDPATH BASH_ENV}};

my $runpartsbin = '/bin/run-parts';
my $d = 't/basic-dummy';
my $expected_output = read_file(\*DATA);
my @expected_output = read_file(\*DATA, { chomp => 1 });

use_ok( 'Run::Parts' );
use_ok( 'Run::Parts::Perl' );

# Only run the Debian backend tests if /bin/run-parts exists
if (-x $runpartsbin) {
    run_test_on_rp($d, 'debian');
    run_test_on_rp($d, 'run-parts');
}

# Testing the perl backend
run_test_on_rp($d, 'perl');
run_test_on_rp($d, 'module');

# Testing the automatically chosen backend
run_test_on_rp($d);

# Testing the perl backend, passed as reference
run_test_on_rp($d, Run::Parts::Perl->new);

sub run_test_on_rp {
    my ($d, $desc) = @_;
    my $rp = Run::Parts->new($d, $desc);

    $desc ||= 'default';
    $desc = ref($desc) if ref($desc);

    ok($rp, 'Run::Parts->new($desc) returned non-nil');

    # List files
    eq_or_diff([$rp->list],
               [map { "$d/$_" } qw[bar foo script script2]],
               "Returns list of files in array context ($desc)");

    eq_or_diff(''.$rp->list,
               "$d/bar\n$d/foo\n$d/script\n$d/script2\n",
               "Returns list of files in string context ($desc)");

    # Concatenate files
    eq_or_diff([$rp->concat], \@expected_output,
               "Returns concatenated contents of all files in array context ($desc)");

    eq_or_diff(''.$rp->concat, $expected_output,
               "Returns concatenated contents of all files in string context ($desc)");

  SKIP: {
      skip("Listing unix executables on DOS or Windows does not work", 3)
          if ($^O eq 'dos' or $^O eq 'os2' or $^O eq 'MSWin32');

      # List executable files
      eq_or_diff([$rp->test],
                 [map { "$d/$_" } qw[script script2]],
                 "Returns list of executables in array context ($desc)");
      eq_or_diff(''.$rp->test,
                 "$d/script\n$d/script2\n",
                 "Returns list of executables in string context ($desc)");

      # Executes executable files
      eq_or_diff(''.$rp->run,
                 "Works\nWorks, too!\n",
                 "Returns output of ran executables ($desc)");
    }
}

__DATA__
Bar
Foo
#!/usr/bin/perl

print "Works\n";
#!/usr/bin/perl

print "Works, too!\n";
