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

my $Original_File = 'lib/NCustom/Config.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 70 lib/NCustom/Config.pm

use File::Copy ;
use File::Path ;
use File::Temp qw/ tempdir /;
use vars qw($output);

test_reset();

use_ok("NCustom::Config", qw(:all) )
  || diag("TEST:<general> can use ok");

my $dir = tempdir( CLEANUP => 1);
ok(-d $dir)
  || diag("TEST:<set up> require temporary directory");
my $rc = &NCustom::get_url($NCustom::Config{'test_url1'}, $dir);
$NCustom::Config{'test_url1'} =~ /([^\/]*)$/ ;
my $file = $1;
ok(-f "$dir/$file")
  || diag("TEST:<get_url> fetches file into dir from url");
ok($rc && -f "$dir/$file")
  || diag("TEST:<get_url> returns success when successful");
#
#
$rc = &NCustom::get_url( "www.bogus.bogus/dummy.html" , $dir);
ok(!$rc && ! -f "$dir/dummy.html")
  || diag("TEST:<get_url> returns fail when unsuccessful");
#
# supress expected error message:
#$_STDERR_ =~ s/get_url: unexpected return code \d+//;
#
output();

sub test_reset {
  $output = "./t/embedded-NCustom-Config.o";
  rmtree  $output;
  mkpath  $output;
  $ENV{HOME} = $output ; # lets be non-intrusive
}
sub output {
  $_STDOUT_ && diag($_STDOUT_);
  $_STDERR_ && diag($_STDERR_);
}


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

