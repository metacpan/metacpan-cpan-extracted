#!/usr/bin/perl5.8.1 -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'lib/NCustom.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 106 lib/NCustom.pm

use Carp;
use File::Compare ;
use File::Copy ;
use File::Path ;
use File::Spec ;
use vars qw($output $input);

# test setup
$output = File::Spec->rel2abs("./t/embedded-NCustom.o");
$input  = File::Spec->rel2abs("./t/embedded-NCustom.i");
ok( -d $input) 
  || diag("TEST:<test setup> requires the data input directory be present");
-d $input || die; # as if we have that wrong we could clobber allsorts
rmtree  $output;
mkpath  $output;
$ENV{HOME} = $output ; # lets be non-intrusive

use_ok( "NCustom", qw(:all) ) 
  || diag("TEST:<NCustom> is a package");

sub test_reset {
  #Test::Inline doesnt execute test blocks in order
  #it does all basic tests first (seemingly in declaration order),
  #then examples tests (seemingly in declaration order).
  #hmmm.. test_rest can erase "why test failed" data
  rmtree  $output;
  mkpath  $output;
  &NCustom::constructor();
  transaction("tx1");
  system("cp -r $input/subject/* $output");

}
sub output {
  $_STDOUT_ && diag($_STDOUT_);
  $_STDERR_ && diag($_STDERR_);
}
output();


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 153 lib/NCustom.pm

NCustom::load_config();
is($NCustom::Config{'test_data1'}, "global_value")
  || diag("TEST:<load_config> sets variables from global conf file 1/3");
is($NCustom::Config{'test_data2'}, "global_value")
  || diag("TEST:<load_config> sets variables from global conf file 2/3");
is($NCustom::Config{'save_dir'}, "$output/.ncustom/save",)
  || diag("TEST:<load_config> sets variables from global conf file 3/3");

mkpath	"$output/.ncustom/NCustom" ;
copy("$input/MyConfig.pm", "$output/.ncustom/NCustom");
NCustom::load_config();
is($NCustom::Config{'test_data1'}, "global_value")
  || diag(<<'  EOF');
  TEST:<load_config>
  TEST:   - will use a local conf file if present
  TEST:   - will still inheirit settings from global conf file
  EOF
is($NCustom::Config{'test_data2'}, "local_value")
  || diag(<<'  EOF');
  TEST:<load_config>
  TEST:   - local conf file settings will override global conf file settings
  EOF

my $subref = $NCustom::Config{'get_url'};
my $target_url = "dummy_url";
my $target_dir = "dummy_dir";
&$subref($target_url, $target_dir);
open(STUBSLOG, "< $output/stubs.log");
my @lines = <STUBSLOG>;
close(STUBSLOG);
ok( grep( /get_url ${target_url} ${target_dir}/, @lines) > 0 )
  || diag("TEST:<load_config> override works for get_url handler");

TODO: {
  local $TODO = "Unload and reload modules, eg Symbol::delete_package.";

  #testing can reset / toggle 
  #Q: is this useful outside of testing context ?
  #A: no

  rmtree 	"$output/.ncustom/NCustom" ;
  NCustom::load_config();
  is($NCustom::Config{'test_data1'}, "global_value")
    || diag("TEST:<load_config> is re-runnable and resets configuration 1/2");
  is($NCustom::Config{'test_data2'}, "global_value")
    || diag("TEST:<load_config> is re-runnable and resets configuration 2/2");
}
output();


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 241 lib/NCustom.pm

test_reset();

&NCustom::apply_config();

ok( -d "$output/.ncustom/save/all")
  || diag("TEST:<NCustom> uses a save directory");
ok( -d "$output/.ncustom/tmp")
  || diag("TEST:<NCustom> uses a tmp directory");
-d "$output/.ncustom/save/all" || die; # as we could be way off course
output();


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 277 lib/NCustom.pm

test_reset();
my $msg;
ok( &NCustom::crud_gaurantee("$output/dir1/file1","read",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can read a file.");
ok( &NCustom::crud_gaurantee("$output/dir1/file1","update",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can update a file.");
ok(!&NCustom::crud_gaurantee("$output/dir1/file9","update",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you cant update a file.");
# should do more cant't testing
# and test that get $msg 
#
ok( &NCustom::crud_gaurantee("$output/dir1/file1","delete",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can delete a file.");
ok( &NCustom::crud_gaurantee("$output/dir1/file9","create",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can create a file.");
ok( &NCustom::crud_gaurantee("$output/dir1/subdir1/file9","create",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can create a file and its dirs.");
#
ok( &NCustom::crud_gaurantee("$output/dir1/file1","r",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can r a file (short notation).");
ok(!&NCustom::crud_gaurantee("$output/dir1/file9","r",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you cant r a file (short notation).");
ok( &NCustom::crud_gaurantee("$output/dir1/file1","ru",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can ru a file (short notation).");
# should do other crud combos
#
output();


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 634 lib/NCustom.pm

test_reset();

my $tmp = "$NCustom::Config{'tmp_dir'}";
#use tmp for files that will be altered/moved (to keep input unaltered)

copy("$input/dir5file1", "$tmp/dir5file1");
&NCustom::commit_file("$tmp/dir5file1", "$output/dir5/file1");
ok(-f "$output/dir5/file1")
  || diag("TEST:<commit_file> checks in a new file");
ok(! -f "$output/.ncustom/save/tx1/$output/dir5/file1")
  || diag("TEST:<commit_file> doesnt archive files that didnt already exist");
  #TODO# that is interesting, that means that restore wont delete it
  #TODO# could handle by save archiving filename.new, the resore knows to rm

copy("$input/dir5file1.v2", "$tmp/dir5file1.v2");
&NCustom::commit_file("$tmp/dir5file1.v2", "$output/dir5/file1");
is(compare("$output/dir5/file1", "$input/dir5file1.v2"), 0)
  || diag("TEST:<commit_file> checks in over an existing file");
is(compare("$output/.ncustom/save/tx1/$output/dir5/file1","$input/dir5file1"), 0)
  || diag("TEST:<commit_file> saves things before it clobbers them");

copy("$input/dir5file1", "$tmp/dir5file1");
&NCustom::commit_file("$tmp/dir5file1", "$output/dir5/subdir1/file1");
ok(-f "$output/dir5/subdir1/file1")
  || diag("TEST:<commit_file> checks in a new file, creating subdirs required");
output();


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 1226 lib/NCustom.pm

test_reset();
system('rpm -e perl-NCustomDummy > /dev/null 2>&1');

my $junk = "JUNK  gg";
ok(! &NCustom::check_pkg($junk))
  || diag("TEST:<check_pkg> checks input format");
# supress expected error message:
$_STDERR_ =~ s/check_pkg: invalid arguments. at lib\/NCustom.pm line \d+\n// ;
#
my $req = { match => "", version => "0.0.0", pkg => "", result => ""};
my $p = "perl-NCustomDummy";
#
$req = { match => "MINIMUM", version => "0.0.0", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "MISSING")
  || diag("TEST:<check_pkg> checks if package meets minimum version 1/4");
$req = { match => "MAXIMUM", version => "0.0.0", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "MISSING")
  || diag("TEST:<check_pkg> checks if package meets maximum version 1/4");
$req = { match => "EXACTLY", version => "0.0.0", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "MISSING")
  || diag("TEST:<check_pkg> checks if package meets exact version 1/4");
$req = { match => "NOTWANT", version => "0.0.0", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package present 1/4");
#  
system("rpm -i $input/perl-NCustomDummy-1.23-1.noarch.rpm");
#shouldnt assume this works
#
$req = { match => "MINIMUM", version => "1.09.1", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package meets minimum version 2/4");
$req = { match => "MINIMUM", version => "1.23", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package meets minimum version 3/4");
$req = { match => "MINIMUM", version => "1.99.9", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "BELOW")
  || diag("TEST:<check_pkg> checks if package meets minimum version 4/4");
#
$req = { match => "MAXIMUM", version => "1.09.1", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "ABOVE")
  || diag("TEST:<check_pkg> checks if package meets maximum version 2/4");
$req = { match => "MAXIMUM", version => "1.23", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package meets maximum version 3/4");
$req = { match => "MAXIMUM", version => "1.99.9", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package meets maximum version 4/4");
#
$req = { match => "EXACTLY", version => "1.09.1", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "ABOVE")
  || diag("TEST:<check_pkg> checks if package meets exact version 2/4");
$req = { match => "EXACTLY", version => "1.23", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package meets exact version 3/4");
$req = { match => "EXACTLY", version => "1.99.9", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "BELOW")
  || diag("TEST:<check_pkg> checks if package meets exact version 4/4");
#
$req = { match => "NOTWANT", version => "1.09.1", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "UNWELCOME")
  || diag("TEST:<check_pkg> checks if package present 2/4");
$req = { match => "NOTWANT", version => "1.23", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "UNWELCOME")
  || diag("TEST:<check_pkg> checks if package present 3/4");
$req = { match => "NOTWANT", version => "1.99.9", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "UNWELCOME")
  || diag("TEST:<check_pkg> checks if package present 4/4");
#
output();


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 1463 lib/NCustom.pm

test_reset();
SKIP: {
  skip "apt too intrusive", 6 unless (defined $ENV{'TEST_APT'} || defined $ENV{'TEST_ALL'});
#############
system('rpm -e perl-NCustomDummy > /dev/null 2>&1');
my ($version, $rc);
$version = `rpm -q perl-NCustomDummy --qf  \%{VERSION}`;
like($version, qr/package perl-NCustomDummy is not installed/)
  || diag("TEST:<test setup> must remove perl-NCustomDummy package");
#
#
can_ok("NCustom", qw(apt_fix)) 
  || diag("TEST:<apt_fix> is a public function of NCustom");
#
$rc = required_packages(<<'  EOF');
  EXACTLY;   9.9.9;   perl-NCustomDummy;   apt_fix()
  EOF
ok(! $rc)
  || diag("TEST:<required_packages> must return 0 if requirements arent met");
$version = `rpm -q perl-NCustomDummy --qf  \%{VERSION}`;
like($version, qr/1.23/)
  || diag("TEST:<apt_fix> must will install its version rather than nothing");
#
$rc = required_packages(<<'  EOF');
  NOTWANT;   9.9.9;   perl-NCustomDummy;   apt_fix()
  EOF
is($rc, 1)
  || diag("TEST:<required_packages> must return 1 if requirements are met");
$version = `rpm -q perl-NCustomDummy --qf  \%{VERSION}`;
like($version, qr/package perl-NCustomDummy is not installed/)
  || diag("TEST:<apt_fix> will remove unwanted packages");
############
}
output();


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 1517 lib/NCustom.pm

#FALSE
ok(! &NCustom::vcmp(1,"gt",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(! &NCustom::vcmp(1,"eq",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(! &NCustom::vcmp(3,"gt",3) )
  || diag("TEST:<vcmp> compares version strings");
ok(! &NCustom::vcmp(3,"lt",3) )
  || diag("TEST:<vcmp> compares version strings");
ok(! &NCustom::vcmp(3,"ne",3) )
  || diag("TEST:<vcmp> compares version strings");
#
#TRUE";
ok(&NCustom::vcmp(1,"lt",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp(1,"ne",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp(3,"eq",3) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","lt",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","gt","1.1.99") )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","eq","1.2.3") )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp(1,"ne",0) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","lt",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","gt","1.1.99") )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","eq","1.2.3") )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp(1,"ne",0) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","lt","1.03") )
  || diag("TEST:<vcmp> compares version strings");
output();


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 387 lib/NCustom.pm

test_reset();
ok(-f "$output/dir2/file1")
  || diag("TEST:<test setup> must copy over the subject dir");
can_ok("NCustom", qw(save_files)) 
  || diag("TEST:<save_files> is a public function of NCustom");




  
  save_files("~/dir2/file1");
  
  save_files(<<'    EOF');
    ~/dir2/file2
    ~/dir3/*
    EOF








;

  }
};
is($@, '', "example from line 387");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 387 lib/NCustom.pm

test_reset();
ok(-f "$output/dir2/file1")
  || diag("TEST:<test setup> must copy over the subject dir");
can_ok("NCustom", qw(save_files)) 
  || diag("TEST:<save_files> is a public function of NCustom");




  
  save_files("~/dir2/file1");
  
  save_files(<<'    EOF');
    ~/dir2/file2
    ~/dir3/*
    EOF








ok(-f "$output/.ncustom/save/all/$output/dir2/file1")
  || diag(<<'  EOF');
  TEST:<save_files> 
  TEST:   - saves given file(s) to the overall archive
  TEST:   - performs filename expansion eg ~/
  EOF
ok(-f "$output/.ncustom/save/tx1/$output/dir2/file1")
  || diag(<<'  EOF');
  TEST:<save_files> 
  TEST:   - also saves given file(s) to the current tx archive
  EOF
ok(-f "$output/.ncustom/save/all/$output/dir2/file2")
  || diag(<<'  EOF');
  TEST:<save_files> multiple arguments:
  TEST:   - accepts multiple arguments in one newline delimited string
  TEST:   - are also saved to both the overall, and current tx, archives 1/2
  EOF
ok(-f "$output/.ncustom/save/tx1/$output/dir2/file2")
  || diag(<<'  EOF');
  TEST:<save_files> multiple arguments:
  TEST:   - are also saved to both the overall, and current tx, archives 2/2
  EOF
ok(-f "$output/.ncustom/save/all/$output/dir3/file1")
  || diag("TEST:<save_files> supports wildcarding 1/4");
ok(-f "$output/.ncustom/save/tx1/$output/dir3/file1")
  || diag("TEST:<save_files> supports wildcarding 2/4");
ok(-f "$output/.ncustom/save/all/$output/dir3/file2")
  || diag("TEST:<save_files> supports wildcarding 3/4");
ok(-f "$output/.ncustom/save/tx1/$output/dir3/file2")
  || diag("TEST:<save_files> supports wildcarding 4/4");
#
# extra tests
#
transaction("tx2");
save_files("~/dir4/file1");
ok(-f "$output/.ncustom/save/tx2/$output/dir4/file1")
  || diag(<<'  EOF');
  TEST:<save_files> 
  TEST:   - saves to a corresponding tx archive when the tx changes 1/2
  EOF
ok(! -f "$output/.ncustom/save/tx1/$output/dir4/file1")
  || diag(<<'  EOF');
  TEST:<save_files> 
  TEST:	  - saves to a corresponding tx archive when the tx changes 2/2
  EOF
copy("$input/dir4file1.v2", "$output/dir4/file1");
save_files("~/dir4/file1");
my @matches = glob("$output/.ncustom/save/tx2/$output/dir4/*");
is($#matches, 1)
  || diag(<<'  EOF');
  TEST:<save_files> if a file is saved to an archive, and it is already there:
  TEST:	  - the file will be saved with a suffix
  EOF
  #this better test didnt work because of filename mangling with samba
  #ok(-f "$output/.ncustom/save/tx2/$output/dir4/file1.AT*")
save_files("~/dir4/file1");
@matches = glob("$output/.ncustom/save/tx2/$output/dir4/*");
is($#matches, 1)
  || diag(<<'  EOF');
  TEST:<save_files> if a file is saved to an archive, and it is already there:
  TEST:   - if there is no change it wont be saved again
  EOF
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 593 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(initialise)) 
  || diag("TEST:<initialise> is a public function of NCustom");




  
  initialise();






;

  }
};
is($@, '', "example from line 593");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 593 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(initialise)) 
  || diag("TEST:<initialise> is a public function of NCustom");




  
  initialise();






@matches = glob("$output/.ncustom/save/*");
is($#matches, 3) # ie 4 entries (all, all.new, tx1, tx1.new)
  || diag("TEST:<initialise> removes all save files");
ok(-d "$output/.ncustom/save/all")
  || diag("TEST:<initialise> creates an empty skeleton save dir");
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 696 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(overwrite_file)) 
  || diag("TEST:<overwrite_file> is a public function of NCustom");




  
  overwrite_file(file => "~/dir6/file1", text => ' some content');
  
  overwrite_file(file => "~/dir6/file2",
                strip => '^\s{4}',
                text  => <<'    EOF');
    This will be line 1 of the new content of the file.
    This will be line 2 of the new content of the file.
      This, line3, will still be indented. As will line 4.
      I bet there will be a dollar sign and two single quotes on the next line.
    'I told you so ! Now you owe me $20', I would then say.
    This will be the last line.
    EOF














;

  }
};
is($@, '', "example from line 696");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 696 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(overwrite_file)) 
  || diag("TEST:<overwrite_file> is a public function of NCustom");




  
  overwrite_file(file => "~/dir6/file1", text => ' some content');
  
  overwrite_file(file => "~/dir6/file2",
                strip => '^\s{4}',
                text  => <<'    EOF');
    This will be line 1 of the new content of the file.
    This will be line 2 of the new content of the file.
      This, line3, will still be indented. As will line 4.
      I bet there will be a dollar sign and two single quotes on the next line.
    'I told you so ! Now you owe me $20', I would then say.
    This will be the last line.
    EOF














is(compare("$output/dir6/file1", "$input/dir6file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<overwrite_file> 
  TEST:   - is logically equivalent to ">"
  TEST:   - will not strip anything by default
  TEST:   - performs filename expansion eg ~/
  TEST:   - will create new file if required
  EOF
is(compare("$output/dir6/file2", "$input/dir6file2.v2"), 0)
  || diag(<<'  EOF');
  TEST:<overwrite_file> 
  TEST:   - will strip a given pattern from the text
  EOF
overwrite_file(file => "~/dir6/subdir1/file1", text => ' some content');
is(compare("$output/dir6/subdir1/file1", "$input/dir6file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<overwrite_file>
  TEST:   - will create subdirs as needed for new files
  EOF
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 862 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(append_file)) 
  || diag("TEST:<append_file> is a public function of NCustom");




  
  append_file(file => "~/dir7/file1", text => 'an extra line');
  
  append_file(file => "~/dir7/file2",
             strip => '^\s{4}',
             text  => <<'    EOF');
    An extra line to add on to the file.
      This line, will be indented. 
    The last last line with some special chars *!@$%.'"
    EOF






;

  }
};
is($@, '', "example from line 862");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 862 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(append_file)) 
  || diag("TEST:<append_file> is a public function of NCustom");




  
  append_file(file => "~/dir7/file1", text => 'an extra line');
  
  append_file(file => "~/dir7/file2",
             strip => '^\s{4}',
             text  => <<'    EOF');
    An extra line to add on to the file.
      This line, will be indented. 
    The last last line with some special chars *!@$%.'"
    EOF






is(compare("$output/dir7/file1", "$input/dir7file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<append_file> 
  TEST:   - is logically equivalent to ">>"
  TEST:   - will not strip anything by default
  TEST:   - performs filename expansion eg ~/
  TEST:   - will create new file if required
  EOF
is(compare("$output/dir7/file2", "$input/dir7file2.v2"), 0)
  || diag(<<'  EOF');
  TEST:<append_file> 
  TEST:   - will strip a given pattern from the text
  EOF
append_file(file => "~/dir7/subdir1/file1", text => 'an extra line');
is(compare("$output/dir7/subdir1/file1", "$input/dir7file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<append_file>
  TEST:   - will create subdirs as needed for new files
  EOF
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 926 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(prepend_file)) 
  || diag("TEST:<prepend_file> is a public function of NCustom");




  
  prepend_file(file => "~/dir8/file1", text => 'an extra line');
  
  prepend_file(file => "~/dir8/file2",
             strip => '^\s{4}',
             text  => <<'    EOF');
    An extra line at the start of the file.
      This line, will be indented. 
    Some special chars *!@$%.'"
    The last extra line added to the start of the file.
    EOF






;

  }
};
is($@, '', "example from line 926");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 926 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(prepend_file)) 
  || diag("TEST:<prepend_file> is a public function of NCustom");




  
  prepend_file(file => "~/dir8/file1", text => 'an extra line');
  
  prepend_file(file => "~/dir8/file2",
             strip => '^\s{4}',
             text  => <<'    EOF');
    An extra line at the start of the file.
      This line, will be indented. 
    Some special chars *!@$%.'"
    The last extra line added to the start of the file.
    EOF






is(compare("$output/dir8/file1", "$input/dir8file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<prepend_file> 
  TEST:   - is logically equivalent to ">>"
  TEST:   - will not strip anything by default
  TEST:   - performs filename expansion eg ~/
  TEST:   - will create new file if required
  EOF
is(compare("$output/dir8/file2", "$input/dir8file2.v2"), 0)
  || diag(<<'  EOF');
  TEST:<prepend_file> 
  TEST:   - will strip a given pattern from the text
  EOF
prepend_file(file => "~/dir8/subdir1/file1", text => 'an extra line');
is(compare("$output/dir8/subdir1/file1", "$input/dir8file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<prepend_file>
  TEST:   - will create subdirs as needed for new files
  EOF
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 991 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(edit_file)) 
  || diag("TEST:<edit_file> is a public function of NCustom");




  
  edit_file(file => "~/dir9/file1", code => 's/file/FILE/g;');
  
  edit_file(file  => "~/dir9/file2",
            strip => '^\s{4}',
            code  => <<'    EOF');
    s/my\.example\.com/whatever\.com/g;
    s/^$/replace all blank lines with these three lines
        two of three, with 4 leading spaces
        and three of three/ ;
    s/might/WILL/g;
    EOF
  
  edit_file(file => <<'    EOF', strip => '^\s{6}', code => <<'    EOF');
      ~/dir9/file3
      ~/dir10/*
    EOF
      s/file/FILE/g;
      s/least/LEASTWAYS/g;
    EOF













;

  }
};
is($@, '', "example from line 991");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 991 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(edit_file)) 
  || diag("TEST:<edit_file> is a public function of NCustom");




  
  edit_file(file => "~/dir9/file1", code => 's/file/FILE/g;');
  
  edit_file(file  => "~/dir9/file2",
            strip => '^\s{4}',
            code  => <<'    EOF');
    s/my\.example\.com/whatever\.com/g;
    s/^$/replace all blank lines with these three lines
        two of three, with 4 leading spaces
        and three of three/ ;
    s/might/WILL/g;
    EOF
  
  edit_file(file => <<'    EOF', strip => '^\s{6}', code => <<'    EOF');
      ~/dir9/file3
      ~/dir10/*
    EOF
      s/file/FILE/g;
      s/least/LEASTWAYS/g;
    EOF













is(compare("$output/dir9/file1", "$input/dir9file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<edit_file> 
  TEST:   - simple edit file
  EOF
#
is(compare("$output/dir9/file2", "$input/dir9file2.v2"), 0)
  || diag(<<'  EOF');
  TEST:<edit_file> 
  TEST:   - multi substitution edit
  EOF
is(compare("$output/dir9/file3", "$input/dir9file3.v2"), 0)
  || diag("TEST:<edit_file> - edits multiple files 1/3.");
is(compare("$output/dir10/file1", "$input/dir10file1.v2"), 0)
  || diag("TEST:<edit_file> - edits multiple files 2/3.");
is(compare("$output/dir10/file2", "$input/dir10file2.v2"), 0)
  || diag("TEST:<edit_file> - edits multiple files 3/3.");
#
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 1071 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(undo_files)) 
  || diag("TEST:<undo_files> is a public function of NCustom");
save_files("~/dir11/file1 ~/dir11/file2");
transaction("tx2");
save_files("~/dir11/file3");
transaction("tx3");
save_files("~/dir11/file4");
transaction("tx4");
save_files("~/dir11/file5");
transaction("tx5");
save_files("~/dir11/file6");
transaction("tx6");
save_files("~/dir11/file7");
transaction("tx7");
save_files("~/dir11/file8");
rmtree("$output/dir11");
mkpath("$output/dir11");




  
  undo_files("tx1");

  undo_files("~/.ncustom/save/tx2");

  undo_files("tx3 tx4");

  undo_files(<<'  EOF');
    tx5
    ~/.ncustom/save/tx6
  EOF








;

  }
};
is($@, '', "example from line 1071");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 1071 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(undo_files)) 
  || diag("TEST:<undo_files> is a public function of NCustom");
save_files("~/dir11/file1 ~/dir11/file2");
transaction("tx2");
save_files("~/dir11/file3");
transaction("tx3");
save_files("~/dir11/file4");
transaction("tx4");
save_files("~/dir11/file5");
transaction("tx5");
save_files("~/dir11/file6");
transaction("tx6");
save_files("~/dir11/file7");
transaction("tx7");
save_files("~/dir11/file8");
rmtree("$output/dir11");
mkpath("$output/dir11");




  
  undo_files("tx1");

  undo_files("~/.ncustom/save/tx2");

  undo_files("tx3 tx4");

  undo_files(<<'  EOF');
    tx5
    ~/.ncustom/save/tx6
  EOF








ok(-f "$output/dir11/file1" && -f "$output/dir11/file2")
  || diag("TEST:<undo_files> restores files for a given customisation");
ok(-f "$output/dir11/file3")
  || diag("TEST:<undo_files> restores files for a given directory");
ok(-f "$output/dir11/file4" && -f "$output/dir11/file5")
  || diag("TEST:<undo_files> restores for multiple customisations at once");
ok(-f "$output/dir11/file6" && -f "$output/dir11/file7")
  || diag("TEST:<undo_files> handles mixed multi-line arguments");
ok(!-f "$output/dir11/file8")
  || diag("TEST:<undo_files> doesnt restore too much");
undo_files("all");
ok(-f "$output/dir11/file8")
  || diag("TEST:<undo_files> will restore all");
transaction("tx8");
mkpath("$output/dir12/subdir1");
overwrite_file(file => "~/dir12/file1", text => ' some content');
transaction("tx9");
overwrite_file(file => "~/dir12/file2", text => ' some content');
transaction("tx10");
overwrite_file(file => "~/dir12/file3", text => ' some content');
ok(  -f "$output/dir12/file1" 
  && -f "$output/dir12/file2" 
  && -f "$output/dir12/file3")
  || diag("TEST:<test setup> new files are setup ready for undo test");
undo_files("tx8");
ok(! -f "$output/dir12/file1")
  || diag("TEST:<undo_files> removes newly created files");
ok(-f "$output/dir12/file2" && -f "$output/dir12/file3")
  || diag("TEST:<undo_files> doesnt removes too much");
undo_files("all");
ok(  ! -f "$output/dir12/file1" 
  && ! -f "$output/dir12/file2" 
  && ! -f "$output/dir12/file3")
  || diag("TEST:<undo_files> removes all new files for \"all\" transaction");
#
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 1358 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(required_packages)) 
  || diag("TEST:<required_packages> is a public function of NCustom");
#that was test 93





  sub handler{
    my ($reqref, $url, $file) = @_;
    print "As $$reqref{'match'} version $$reqref{'version'} of ";
    print "$$reqref{'pkg'} was $$reqref{'result'} - ";
    print "we are going to fetch $file from $url and execute it.\n";
    print "This should set things right.\n";
    return 1;
  }

  required_packages(<<'  EOF');
    EXACTLY;   9.9.9;   acme;   handler($req, "URL", "FILE")
    NOTWANT;   0.0.0;   perl;   print "Dont be stupid\n"
    #MAXIMUM;  9.9.9;   perl;   carp("Warning: untested with this perl")
    #MINIMUM;  9.9.9;   perl;   apt_fix()
    NOTWANT;   0.0.0;   perl;	for($i = 0; $i < 10; $i++){$s="Hello"; print "${s}${i}\n"}
  EOF
















;

  }
};
is($@, '', "example from line 1358");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 1358 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(required_packages)) 
  || diag("TEST:<required_packages> is a public function of NCustom");
#that was test 93





  sub handler{
    my ($reqref, $url, $file) = @_;
    print "As $$reqref{'match'} version $$reqref{'version'} of ";
    print "$$reqref{'pkg'} was $$reqref{'result'} - ";
    print "we are going to fetch $file from $url and execute it.\n";
    print "This should set things right.\n";
    return 1;
  }

  required_packages(<<'  EOF');
    EXACTLY;   9.9.9;   acme;   handler($req, "URL", "FILE")
    NOTWANT;   0.0.0;   perl;   print "Dont be stupid\n"
    #MAXIMUM;  9.9.9;   perl;   carp("Warning: untested with this perl")
    #MINIMUM;  9.9.9;   perl;   apt_fix()
    NOTWANT;   0.0.0;   perl;	for($i = 0; $i < 10; $i++){$s="Hello"; print "${s}${i}\n"}
  EOF
















my $o = $_STDOUT_;
my $e = $_STDERR_;
like($o, qr/As EXACTLY version .* fetch FILE from URL and execute it.\n/)
  || diag("TEST:<required_packages> calls a handler");
like($o, qr/Dont be stupid/)
  || diag("TEST:<required_packages> executes simple statements");
like($o, qr/Hello9/)
  || diag("TEST:<required_packages> executes compound statements");
#
# supress expected output
$_STDOUT_ =~ s/Hello\d+\n//gm ;
$_STDOUT_ =~ s/Dont be stupid\n//gm ;
$_STDOUT_ =~ s/As EXACTLY version .* fetch FILE from URL and execute it.\n//gm ;
$_STDOUT_ =~ s/This should set things right.\n//gm ;
#
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 1664 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(blat_myconfig)) 
  || diag("TEST:<blat_myconfig> is a public function of NCustom");





  blat_myconfig();







;

  }
};
is($@, '', "example from line 1664");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 1664 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(blat_myconfig)) 
  || diag("TEST:<blat_myconfig> is a public function of NCustom");





  blat_myconfig();







is(compare("$output/.ncustom/NCustom/MyConfig.pm", "$input/Global.pm"), 0)
  || diag(<<'  EOF');
  TEST:<blat_config>
  TEST:   - MyConfig.pm replaced by Config.pm
  TEST:   - This test will fail if you change Config.pm and 
  TEST:     dont update reference copies used in test comparision.
  EOF
#
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 1748 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(config_edit)) 
  || diag("TEST:<config_edit> is a public function of NCustom");





  config_edit((src_fqdn  => '"install.baneharbinger.com"',
               test_url1 => '"install.baneharbinger.com/index.html"'));











;

  }
};
is($@, '', "example from line 1748");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 1748 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(config_edit)) 
  || diag("TEST:<config_edit> is a public function of NCustom");





  config_edit((src_fqdn  => '"install.baneharbinger.com"',
               test_url1 => '"install.baneharbinger.com/index.html"'));











my @lines ; 
open(MYCFG, "< $output/.ncustom/NCustom/MyConfig.pm");
@lines = <MYCFG>;
close(MYCFG);
ok( grep( /src_fqdn.*install.baneharbinger.com/, @lines) > 0 )
  || diag("TEST:<config_edit> can edit(add) src_fqdn");
ok( grep( /test_url1.*install.baneharbinger.com/, @lines) > 0 )
  || diag("TEST:<config_edit> can edit(add) test_url1");
#
&NCustom::blat_myconfig(); #TODO# hmmm tests should be independent 
&NCustom::config_edit((test_data1 => "wow", test_data2 => "whoopee doo"));
open(MYCFG, "< $output/.ncustom/NCustom/MyConfig.pm");
@lines = <MYCFG>;
close(MYCFG);
ok( grep( /test_data1.*wow/, @lines) > 0 )
  || diag("TEST:<config_edit> can edit(change) test_data1");
ok( grep( /test_data2.*whoopee doo/, @lines) > 0 )
  || diag("TEST:<config_edit> can edit(change) test_data2");
#
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 1870 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(ncustom))
  || diag("TEST:<ncustom> is a public function of NCustom");
copy("$input/test1.ncus", "$output");
chmod(0750,"$output/test1.ncus");
copy("$input/test2.ncus", "$output");
chmod(0750,"$output/test2.ncus");





  ncustom(<<'  EOF');
    ~/test1.ncus
    test2.ncus
  EOF










;

  }
};
is($@, '', "example from line 1870");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 1870 lib/NCustom.pm

test_reset();
can_ok("NCustom", qw(ncustom))
  || diag("TEST:<ncustom> is a public function of NCustom");
copy("$input/test1.ncus", "$output");
chmod(0750,"$output/test1.ncus");
copy("$input/test2.ncus", "$output");
chmod(0750,"$output/test2.ncus");





  ncustom(<<'  EOF');
    ~/test1.ncus
    test2.ncus
  EOF










open(STUBSLOG, "< $output/stubs.log");
my @lines = <STUBSLOG>;
close(STUBSLOG);
ok( grep( /NCustom test1.ncus/, @lines) > 0 )
  || diag("TEST:<ncustom> fetches and executes file 1/2");
ok( grep( /NCustom test2.ncus/, @lines) > 0 )
  || diag("TEST:<ncustom> fetches and executes file 2/2");
#
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

