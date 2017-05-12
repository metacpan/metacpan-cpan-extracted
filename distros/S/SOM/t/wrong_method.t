# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
  open SAVEOUT, '>&STDOUT' or die "Cannot duplicate STDOUT: $!";
  open STDOUT, '>&STDERR' or die "Cannot reopen STDOUT to STDERR: $!";
}

BEGIN { $| = 1; print  SAVEOUT "1..5\n"; }
END {print  SAVEOUT "not ok 1\n" unless $loaded;}
use SOM ':types', ':class';
$loaded = 1;
print  SAVEOUT "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$ext = Cwd::extLibpath(1);		# 1: endLIBPATH
$ext ||= '';
$ext =~ /;$/ or $ext .= ';';
$cwd = Cwd::sys_cwd();
$dir = -d 't' ? 'utils' : '..\utils';
Cwd::extLibpath_set("$ext;$cwd\\$dir", 1);
$ENV{SOMIR} .= ";$cwd\\$dir\\ORXSMP.IR";

$class = Find_Class("Dog", 0, 0);

print  SAVEOUT <<EOP unless $class;
# Could not find class Dog from toolkit REXX SOM sample
# Make sure you build this class in \$TOOLKIT/samples/rexx/som
# put animals.dll on LIBPATH, and have \$ENV{SOMIR} contain
#   \$TOOLKIT\\SAMPLES\\REXX\\SOM\\ANIMAL\\ORXSMP.IR
# (\$TOOLKIT is the location of your OS/2 toolkit), or do the same with
#   \$OREXX/samples                       directory instead of
#   \$TOOLKIT\\SAMPLES\\REXX\\SOM\\ANIMAL directory.
EOP

print  SAVEOUT "not " unless $class;
print  SAVEOUT "ok 2\n";

$obj1 = $class->NewObject;
print  SAVEOUT "not " unless $obj1;
print  SAVEOUT "ok 3\n";

sub make_template_oidl {
  join '', 'o', map chr(33 + $_), @_;
}

print STDERR <<EOP if 0;

###
###     The following error (method 'nonesuch') should happen,
###	but should not be fatal!
###

EOP

$get_string = make_template_oidl tk_string;

eval { $obj1->Dispatch_templ("nonesuch", $get_string); 1 }
  and print  SAVEOUT "not ";
print  SAVEOUT "ok 4\n";

$@ =~ /error\s+(dispatching)|Can't\s+resolve/i or print  SAVEOUT "not ";
print  SAVEOUT "ok 5\n";
