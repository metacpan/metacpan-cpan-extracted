
require 5;
use Test;
BEGIN { plan tests => 1; }
use Sort::ArbBiLex;

# Time-stamp: "2004-03-27 17:16:15 AST"

print "#\n#\n",
 "# Sort::ArbBiLex v$Sort::ArbBiLex::VERSION\n",
 "#\n#\n",
;

print "# Running in a ",
      Sort::ArbBiLex::UNICODE ? "Unicodey" : "Unicodeless",
      " world\n";

print "# Running under perl version $] for $^O",
      (chr(65) eq 'A') ? "\n" : " in a non-ASCII world\n";

print "# Win32::BuildNumber ", &Win32::BuildNumber(), "\n"
 if defined(&Win32::BuildNumber) and defined &Win32::BuildNumber();

print "# MacPerl verison $MacPerl::Version\n"
 if defined $MacPerl::Version;

printf
 "# Current time local: %s\n# Current time GMT:   %s\n",
 scalar(   gmtime($^T)), scalar(localtime($^T));

print "# Using Test.pm v", $Test::VERSION || "?", "\n";

ok 1;


