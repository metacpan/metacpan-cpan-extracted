# Test to check error reporting for a background error (with TkHijack active)
#   that occurs due to a undefined sub 
use Test;
BEGIN {plan tests=>3}
use Tcl::pTk::TkHijack;
use Tk;

my $mw = MainWindow->new;

# Setup to redirect stderr to file, so we can check it.
# Save existing StdErr
*OLD_STDERR = *STDERR;
open(my $stderr, '>', 'serr.out');
*STDERR = $stderr;

# Setup label with a scroll command that is not defined
#   This will create a backgound error.
my $lb = $mw->Listbox->pack;
$lb->configure(-yscrollcommand =>  \&bogus);
$lb->insert(qw/0 foo/);
$lb->update;

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
ok( $errMessages =~ /Error Started at t\/tkHijack_bgerror1.t line 21/);

unlink 'serr.out';
