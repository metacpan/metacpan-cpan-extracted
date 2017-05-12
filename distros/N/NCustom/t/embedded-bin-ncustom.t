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

my $Original_File = 'bin/ncustom';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 58 bin/ncustom

use Carp;
use File::Compare ;
use File::Copy ;
use File::Path ;
use File::Spec ;
use vars qw($ncustom $output $input);

# test setup
$output = File::Spec->rel2abs("./t/embedded-bin-ncustom.o");
$input  = File::Spec->rel2abs("./t/embedded-bin-ncustom.i");
ok( -d $input)
  || diag("TEST:<test setup> requires the data input directory be present");

-d $input || die; # as if we have that wrong we could clobber allsorts
rmtree  $output;
mkpath  $output;
$ENV{HOME} = $output ; # lets be non-intrusive

#system("ncustom") && $ncustom = "ncustom";
if(-f "./bin/ncustom"){$ncustom = "./bin/ncustom" }
ok($ncustom ne "")
  || diag("TEST:<test setup> must be able to find ncustom program");


sub test_reset {
  #Test::Inline doesnt execute test blocks in order
  #it does all basic tests first (seemingly in declaration order),
  #then examples tests (seemingly in declaration order).
  #hmmm.. test_rest can erase "why test failed" data
  rmtree  $output;
  mkpath  $output;
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
#line 139 bin/ncustom

test_reset();
my ($rc, $o);
$rc = system("$ncustom -junk > /dev/null 2>&1");
ok($rc != 0)
  || diag("TEST:<general> returns error for invalid arguments");
$o = `$ncustom 2>&1 `;
like( $o, qr/Usage:/m)
  || diag("TEST:<general> displays useage for invalid arguments");
$rc = system("$ncustom > /dev/null 2>&1");
ok($rc != 0)
  || diag("TEST:<general> returns error for no arguments");
$o = `$ncustom 2>&1 `;
like( $o, qr/Usage:/m)
  || diag("TEST:<general> displays useage for no arguments");

output();


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 170 bin/ncustom

test_reset();

ok(! -d "$output/.ncustom/save/all")
  || diag("TEST:<test setup> require void setup, ie no ~/.ncustom...");

my ($rc);
$rc = system("$ncustom -i");
ok($rc == 0)
  || diag("TEST:<initialise> returns success for void initialisation");

# NB: we just called $ncustom, which used NCustom, so ~/.ncustom now exists
ok(-d "$output/.ncustom/save/all")
  || diag("TEST:<test setup> require ~/.ncustom...");
system("mkdir -p $output/.ncustom/save/dummydir");
system("echo content > $output/.ncustom/save/dummydir/dummyfile");
ok(-f "$output/.ncustom/save/dummydir/dummyfile")
  || diag("TEST:<test setup> require dummy transaction");
$rc = system("$ncustom -i");
ok($rc == 0)
  || diag("TEST:<initialise> returns success for initialisation");
ok(! -f "$output/.ncustom/save/dummydir/dummyfile")
  || diag("TEST:<initialise> purges transactions");
output();


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 347 bin/ncustom

my $rc = system("$ncustom -b");
ok($rc == 0)
  || diag("TEST:<blat_myconfig> returns success for void initialisation");
is(compare("$output/.ncustom/NCustom/MyConfig.pm", "$input/Global.pm"), 0)
  || diag("TEST:<blat_myconfig> MyConfig.pm replaced by Config.pm");
output();


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 211 bin/ncustom

test_reset();
my $eg ;





  $eg = <<'  end_eg';
  
  grep -c incomplete ~/file1 >> ~/log 

  ncustom -n test5.ncus ;
  grep -c incomplete ~/file1 >> ~/log

  ncustom -n test6.ncus ;
  grep -c incomplete ~/file1 >> ~/log

  ncustom -u test6.ncus ;
  grep -c incomplete ~/file1 >> ~/log 
  
  cat ~/log # 7,3,1,3

  end_eg









;

  }
};
is($@, '', "example from line 211");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 211 bin/ncustom

test_reset();
my $eg ;





  $eg = <<'  end_eg';
  
  grep -c incomplete ~/file1 >> ~/log 

  ncustom -n test5.ncus ;
  grep -c incomplete ~/file1 >> ~/log

  ncustom -n test6.ncus ;
  grep -c incomplete ~/file1 >> ~/log

  ncustom -u test6.ncus ;
  grep -c incomplete ~/file1 >> ~/log 
  
  cat ~/log # 7,3,1,3

  end_eg









copy("$input/file1", "$output");
copy("$input/test5.ncus", "$output");
copy("$input/test6.ncus", "$output");
chmod 750, "$output/test5.ncus", "$output/test6.ncus";  
#
$eg =~ s/ncustom/$ncustom/g ; # or insert ncustom in path ?
system("$eg");
#
open(LOG, "< $output/log");
my @lines = <LOG>;
close(LOG);
my @expected_lines = ("7\n", "3\n", "1\n", "3\n");
#
eq_array( \@lines, \@expected_lines )
  || diag("TEST:<undo> undoes transactions");
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

#line 277 bin/ncustom

test_reset();
my $eg ;





  $eg = <<'  end_eg';
  
  # default_dir contains test2.ncus 
  # default_url contains test3.ncus 
  
  ncustom -n ~/dir20/test1.ncus -n test2.ncus ;
  ncustom -n test3.ncus -n http://install/install/NCustom/test4.ncus ;
  
  end_eg










;

  }
};
is($@, '', "example from line 277");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 277 bin/ncustom

test_reset();
my $eg ;





  $eg = <<'  end_eg';
  
  # default_dir contains test2.ncus 
  # default_url contains test3.ncus 
  
  ncustom -n ~/dir20/test1.ncus -n test2.ncus ;
  ncustom -n test3.ncus -n http://install/install/NCustom/test4.ncus ;
  
  end_eg










mkpath  "$output/dir20";
copy("$input/test1.ncus", "$output/dir20");
copy("$input/test2.ncus", "$output");
chmod 0750, "$output/dir20/test1.ncus", "$output/test2.ncus";  
#now tell me again, how we are getting test3.ncus to url ?
#should make tests conditional on config - but hey test config test chicken egg
#
$eg =~ s/ncustom/$ncustom/g ; # or insert ncustom in path ?
system("$eg");
#
open(STUBSLOG, "< $output/stubs.log");
my @stubslog = <STUBSLOG>;
close(STUBSLOG);
#
ok( grep( /ncustom test1.ncus/, @stubslog) > 0 )
  || diag("TEST:<ncustom> fetches and executes file from given dir");
ok( grep( /ncustom test2.ncus/, @stubslog) > 0 )
  || diag("TEST:<ncustom> fetches and executes file from default dir");
ok( grep( /ncustom test3.ncus/, @stubslog) > 0 )
  || diag("TEST:<ncustom> fetches and executes file from default url");
ok( grep( /ncustom test4.ncus/, @stubslog) > 0 )
  || diag("TEST:<ncustom> fetches and executes file from given url");
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

#line 372 bin/ncustom

test_reset();
my $eg2 ;





  $eg2 = <<'  end_eg';

  # modify existing values
  ncustom -c src_fqdn=\"install.baneharbinger.com\" ;
  ncustom -c test_url1=\"install.baneharbinger.com/index.html\" ;

  # add new values
  ncustom -c my_number=5 -c my_text=\"blah\" ;

  # add new complex (eg hash) values
  ncustom -c my_hosts='{ mew => "192.168.0.10", pikachu => "192.168.0.20" }' ;

  end_eg










;

  }
};
is($@, '', "example from line 372");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 372 bin/ncustom

test_reset();
my $eg2 ;





  $eg2 = <<'  end_eg';

  # modify existing values
  ncustom -c src_fqdn=\"install.baneharbinger.com\" ;
  ncustom -c test_url1=\"install.baneharbinger.com/index.html\" ;

  # add new values
  ncustom -c my_number=5 -c my_text=\"blah\" ;

  # add new complex (eg hash) values
  ncustom -c my_hosts='{ mew => "192.168.0.10", pikachu => "192.168.0.20" }' ;

  end_eg










#
$eg2 =~ s/ncustom/$ncustom/g ; # or insert ncustom in path ?
system("$eg2");
#
my @lines ;
open(MYCFG, "< $output/.ncustom/NCustom/MyConfig.pm");
@lines = <MYCFG>;
close(MYCFG);
ok( grep( /src_fqdn.*"install.baneharbinger.com"/, @lines) > 0 )
  || diag("TEST:<config_edit> can edit(add) src_fqdn");
ok( grep( /test_url1.*"install.baneharbinger.com\/index.html"/, @lines) > 0 )
  || diag("TEST:<config_edit> can edit(add) test_url1");
#
output();

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

