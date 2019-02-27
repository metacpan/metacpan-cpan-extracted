# Test to check error reporting for a background error
#   that occurs due to a undefined sub 
use warnings;
use strict;
use Test;
BEGIN {plan tests=>3}
use Tcl::pTk;

# Filename and line numbers to look for in expected errors
my $ok_file = quotemeta(__FILE__);
my $ok3_line;

my $mw = MainWindow->new;

# Setup to redirect stderr to file, so we can check it.
# Save existing StdErr
*OLD_STDERR = *STDERR;
open(my $stderr, '>', 'serr.out');
*STDERR = $stderr;

# Setup label with a scroll command that is not defined
#   This will create a background error.
my $lb = $mw->Listbox->pack;
$lb->configure(-yscrollcommand =>  \&bogus);
$lb->insert(qw/0 foo/);
$lb->update;
$ok3_line = __LINE__ - 1; # Line to look for in error output

$mw->after(2000, [$mw, 'destroy']);
MainLoop;

# Redirect stderr back
*STDERR = *OLD_STDERR;

# Close error messages file and read it
close $stderr;

open(INFILE, 'serr.out');
my $errMessages = '';
while( <INFILE> ){
        $errMessages .= $_;
};
close INFILE;

# Check error messages for key components
ok( $errMessages =~ /Undefined subroutine\s+\&main\:\:bogus/);
ok( $errMessages =~ /vertical scrolling command executed by listbox/);
ok( $errMessages =~ /Error Started at $ok_file line $ok3_line/);


unlink 'serr.out';

