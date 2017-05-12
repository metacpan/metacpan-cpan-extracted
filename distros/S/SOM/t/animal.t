# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
  open SAVEOUT, '>&STDOUT' or die "Cannot duplicate STDOUT: $!";
  open STDOUT, '> .tout' or die "Cannot reopen STDOUT to .tout: $!";
}

BEGIN { $| = 1; print  SAVEOUT "1..37\n"; }
END {print  SAVEOUT "not ok 1\n" unless $loaded;}
use SOM ':types', ':class';
$loaded = 1;
print  SAVEOUT "ok 1\n";

######################### End of black magic.

$ext = Cwd::extLibpath(1);		# 1: endLIBPATH
$ext ||= '';
$ext =~ /;$/ or $ext .= ';';
$cwd = Cwd::sys_cwd();
$dir = -d 't' ? 'utils' : '..\utils';
Cwd::extLibpath_set("$ext;$cwd\\$dir", 1);
$ENV{SOMIR} .= ";$cwd\\$dir\\ORXSMP.IR";

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$class = Find_Class("Animal", 0, 0);

print  SAVEOUT <<EOP unless $class;
# Error: $^E
# Could not find class Animal from the toolkit's REXX SOM sample:
# Make sure you build this class in \$TOOLKIT/samples/rexx/som
# put animals.dll on LIBPATH, and have \$ENV{SOMIR} contain
#   \$TOOLKIT\\SAMPLES\\REXX\\SOM\\ANIMAL\\ORXSMP.IR
# (\$TOOLKIT is the location of your OS/2 toolkit), or do the same with
#   \$OREXX/samples                       directory instead of
#   \$TOOLKIT\\SAMPLES\\REXX\\SOM\\ANIMAL directory.
EOP

print  SAVEOUT "not " unless $class;
print  SAVEOUT "ok 2\n";

$obj = $class->NewObject;
print  SAVEOUT "not " unless $obj;
print  SAVEOUT "ok 3\n";

$class1 = Find_Class("Dog", 0, 0);
print  SAVEOUT "not " unless $class1;
print  SAVEOUT "ok 4\n";

$obj1 = $class1->NewObject;
print  SAVEOUT "not " unless $obj1 and $obj1->GetClassName eq "Dog";
print  SAVEOUT "ok 5\n";

$obj->Dispatch0("display");
print  SAVEOUT "ok 6\n";

$obj->Dispatch0("talk");
print  SAVEOUT "ok 7\n";

$obj1->Dispatch0("display");
print  SAVEOUT "ok 8\n";

$obj1->Dispatch0("talk");
print  SAVEOUT "ok 9\n";

sub make_template_oidl {
  join '', 'o', map chr(33 + $_), @_;
}

sub make_template {
  join '', 'n', map chr(33 + $_), @_;
}

$get_string = make_template_oidl tk_string;
print  SAVEOUT "# '$get_string'\nok 10\n";
print  SAVEOUT "# '", tk_string. "'\n";

$set_string = make_template_oidl tk_void, tk_string;
print  SAVEOUT "# '$set_string'\nok 11\n";
print  SAVEOUT "# '", tk_void. "'\n";

$genus = $obj->Dispatch_templ("_get_genus", $get_string);
print  SAVEOUT "ok 12\n";
print  SAVEOUT "# '$genus'\n";

$genus1 = $obj1->Dispatch_templ("_get_genus", $get_string);
print  SAVEOUT "ok 13\n";
print  SAVEOUT "# '$genus1'\n";

$obj1->Dispatch_templ("_set_breed", $set_string, "chachacha");
print  SAVEOUT "ok 14\n";

$obj1->Dispatch0("display");
print  SAVEOUT "ok 15\n";

$breed1 = $obj1->Dispatch_templ("_get_breed", $get_string);
print  SAVEOUT "ok 16\n";
#print  SAVEOUT "# '$breed1'\n";
$breed1 eq 'chachacha' or print  SAVEOUT "not ";
print  SAVEOUT "ok 17\n";

$repo = RepositoryNew;
print  SAVEOUT "ok 18\n";
ref $repo eq 'RepositoryPtr' or print  SAVEOUT "not ";
print  SAVEOUT "ok 19\n";

$classmgrO = SOMClassMgrObject;
print  SAVEOUT "ok 20\n";
ref $classmgrO eq 'SOMObjectPtr' or print  SAVEOUT "#'$classmgrO'\nnot ";
print  SAVEOUT "ok 21\n";

$classmgr = SOMClassMgr;
print  SAVEOUT "ok 22\n";
ref $classmgr eq 'SOMClassPtr' or print  SAVEOUT "not ";
print  SAVEOUT "ok 23\n";

$SOMclass = SOMClass;
print  SAVEOUT "ok 24\n";
ref $SOMclass eq 'SOMClassPtr' or print  SAVEOUT "not ";
print  SAVEOUT "ok 25\n";

$SOMobject = SOMObject;
print  SAVEOUT "ok 26\n";
ref $SOMobject eq 'SOMClassPtr' or print  SAVEOUT "not ";
print  SAVEOUT "ok 27\n";

$clcl = $SOMclass->GetClass;
print  SAVEOUT "ok 28\n";
$$clcl eq $$SOMclass or print  SAVEOUT "not ";
print  SAVEOUT "ok 29\n";

$clob = $SOMobject->GetClass;
print  SAVEOUT "ok 30\n";
$$clob eq $$SOMclass or print  SAVEOUT "not ";
print  SAVEOUT "ok 31\n";

$clclm = $classmgr->GetClass;
print  SAVEOUT "ok 32\n";
$$clclm eq $$SOMclass or print  SAVEOUT "not ";
print  SAVEOUT "ok 33\n";

$clclmo = $classmgrO->GetClass;
print  SAVEOUT "ok 34\n";
$$clclmo eq $$classmgr or print  SAVEOUT "not ";
print  SAVEOUT "ok 35\n";

$isa_string = make_template_oidl tk_boolean, tk_objref;
$dog_is_animal = $class1->Dispatch_templ("somDescendedFrom",
					 $isa_string, $class);
$dog_is_animal or print  SAVEOUT "not ";
print  SAVEOUT "ok 36\n";

$animal_is_dog = $class->Dispatch_templ("somDescendedFrom",
					 $isa_string, $class1);
$animal_is_dog and print  SAVEOUT "not ";
print  SAVEOUT "ok 37\n";

