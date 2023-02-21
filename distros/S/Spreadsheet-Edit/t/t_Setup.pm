use strict; use warnings  FATAL => 'all';
use feature qw/say/;

#
# Parses standard options (--debug etc.) if present in @ARGV.
# Exports global variables used by all my tests.
# Exports a "standard" collection of modules with Unicode support.
#
# USAGE: 
#   use FindBin qw($Bin);
#   use lib $Bin;
#   use t_Setup;
#
#   (then probably use t_Utils;)

package t_Setup;

use parent "Exporter::Tiny";

our @EXPORT = qw($debug $verbose $silent);

require v5.9.5; # for mro
use mro; # enables next::method

use Import::Into;

our ($debug, $verbose, $silent);

# Parse and remove our standard args from @ARGV
# Set the corresponding $Spreadsheet::Edit::Variables
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure("pass_through");
GetOptions(
  "d|debug"           => sub{ $debug=$verbose=1; $silent=0 },
  "s|silent"          => \$silent,
  "v|verbose"         => \$verbose,
) or die "bad args";
Getopt::Long::Configure("default");

require Spreadsheet::Edit;
$Spreadsheet::Edit::Verbose = $verbose;  # all remain undef by default
$Spreadsheet::Edit::Silent  = $silent;
$Spreadsheet::Edit::Debug   = $debug;

say "t_Setup: Debug is on\n" if $debug;

sub import {
  my $target = caller;

  for (qw/5.030000 5.020000 5.018000 5.010000/) {
    if ($] >= $_) {
      /^(\d+)\.(\d\d\d)(\d\d\d)$/ or die;
      feature->import::into($target, sprintf ":%d.%d.%d", $1, $2, $3);
      last;
    }
  }

  mro->import::into($target, "c3");
  
  require utf8;
          utf8->import::into($target);

  require "open.pm";
          "open"->import::into($target, ':std', ':encoding(UTF-8)');

  strict->import::into($target);

  warnings->import::into($target, FATAL => 'all');

  require indirect; 
          indirect->unimport::out_of($target); 

  require multidimensional;
          multidimensional->unimport::out_of($target);

  require autovivification;
          autovivification->unimport::out_of($target);
  
  # Stuff I often use

  require Carp; 
          Carp->import::into($target);

  require Data::Dumper::Interp; 
          Data::Dumper::Interp->import::into($target);

  require List::Util;           
          List::Util->import::into($target, qw(min max first sum0));

  require Guard; 
          Guard->import::into($target, qw(scope_guard guard));

  require Spreadsheet::Edit::IO;
          Spreadsheet::Edit::IO->import::into($target, qw(let2cx cx2let));

  # Disable buffering
  STDERR->autoflush(1);
  STDOUT->autoflush(1);

  # Catch unintended warnings (that is, while in 'silent' mode)
  $SIG{__WARN__} = sub { 
    Carp::confess("warning while in <silent> mode") if $silent; 
    die "bug:$_[0]" if $_[0] =~ "uninitialized value";
    warn @_;
  };
  #$SIG{__DIE__} = sub{ return unless defined($^S) && $^S==0; confess @_ };

  # chain to Exporter::Tiny to export our local definitions
  my $this = $_[0];
  goto &{ $this->next::can }; # see 'perldoc mro'  goto __SUPER__
}

1;
