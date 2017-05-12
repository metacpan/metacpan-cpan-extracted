package Bin::Test;

#
# Test all the exes in the TBin. Running with --help and --man options
# comparing output to files in t/bin.ok/
#

use 5.010;
use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Capture::Tiny qw(:all);
use Test::Differences;
use File::Slurp qw(slurp);
use File::Basename;

use FindBin qw($Bin);
our $TBin = "$Bin/bin";

# Grab the perl exe we are running under as recommended here:
# http://wiki.cpantesters.org/wiki/CPANAuthorNotes
# We need to run the test scripts under this perl to get the right includes in
# automated environmenst like cpan testers running perlbrew.
use Config;
our $PerlPath = $Config{perlpath};

# Generate test methods for all the exes in TBin
opendir(my $dh, $TBin) || die "Can't open $TBin: $!";
my @cmds = grep {
    /^[^\.].*\.pl$/   # Not hidden and pl extention
    && -f "$TBin/$_"  # Normal file
    && -x "$TBin/$_"  # Executable
    } readdir($dh);
closedir($dh);
foreach my $cmd (@cmds) {
    my $meth_name = $cmd;
    $meth_name =~ s/\..*?$//g;
    no strict 'refs';
    my $meth = __PACKAGE__ . "::$meth_name";
    *{$meth} = sub {
        my $self = shift;
        $self->cmd_line_ok($cmd);
    };
    __PACKAGE__->add_testinfo($meth_name, test => 4);
}

sub capture_ok {
    my ($cmd, $stdout_ok, $stderr_ok, $testmsg) = @_;
    my ($script, @args) = @{$cmd};
    my $msg = $testmsg ? " - $testmsg" : "";
    my ($stdout, $stderr) = capture { system($PerlPath, "$TBin/$script", @args) };
    eq_or_diff $stdout, $stdout_ok, "$script @args STDOUT$msg";
    eq_or_diff $stderr, $stderr_ok, "$script @args STDERR$msg";
}

sub cmd_line_ok {
    my $self = shift;
    my $cmd  = shift;
    (my $name = $cmd) =~ s/\..*?$//g;

    my $ok_file = "$Bin/bin.ok/$name.usage.ok";
    SKIP: {
        skip "No $ok_file to test with", 2 unless -f $ok_file;

        my $stdout_ok = slurp($ok_file);
        capture_ok( [$cmd, "--usage"], $stdout_ok, "" );
    }
    
    $ok_file = "$Bin/bin.ok/$name.man.ok";
    SKIP: {
        skip "No $ok_file to test with", 2 unless -f $ok_file;

        my $stdout_ok = slurp($ok_file);
        capture_ok( [$cmd, "--man"], $stdout_ok, "" );
    }
}

# Make sure -? --help and --usage do the same thing
sub help_flags : Test(6) {
    my $self = shift;

    my $stdout_ok = slurp("$Bin/bin.ok/basic.usage.ok");
    foreach my $flag (qw/-? --help --usage/) {
        capture_ok( ["basic.pl", $flag], $stdout_ok, "" );
    }
}

1;
