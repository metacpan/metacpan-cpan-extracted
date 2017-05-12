#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.02';   # automatically generated file
$DATE = '2003/07/27';
$FILE = __FILE__;

use Getopt::Long;
use Cwd;
use File::Spec;

##### Test Script ####
#
# Name: Netid.t
#
# UUT: Net::Netid
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Net::Netid;
#
# Don't edit this test script file, edit instead
#
# t::Net::Netid;
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
#

######
#
# T:
#
# use a BEGIN block so we print our plan before Module Under Test is loaded
#
BEGIN { 
   use vars qw( $__restore_dir__ @__restore_inc__);

   ########
   # Working directory is that of the script file
   #
   $__restore_dir__ = cwd();
   my ($vol, $dirs) = File::Spec->splitpath(__FILE__);
   chdir $vol if $vol;
   chdir $dirs if $dirs;
   ($vol, $dirs) = File::Spec->splitpath(cwd(), 'nofile'); # absolutify

   #######
   # Add the library of the unit under test (UUT) to @INC
   # It will be found first because it is first in the include path
   #
   use Cwd;
   @__restore_inc__ = @INC;

   ######
   # Find root path of the t directory
   #
   my @updirs = File::Spec->splitdir( $dirs );
   while(@updirs && $updirs[-1] ne 't' ) { 
       chdir File::Spec->updir();
       pop @updirs;
   };
   chdir File::Spec->updir();
   my $lib_dir = cwd();

   #####
   # Add this to the include path. Thus modules that start with t::
   # will be found.
   # 
   $lib_dir =~ s|/|\\|g if $^O eq 'MSWin32';  # microsoft abberation
   unshift @INC, $lib_dir;  # include the current test directory

   #####
   # Add lib to the include path so that modules under lib at the
   # same level as t, will be found
   #
   $lib_dir = File::Spec->catdir( cwd(), 'lib' );
   $lib_dir =~ s|/|\\|g if $^O eq 'MSWin32';  # microsoft abberation
   unshift @INC, $lib_dir;

   #####
   # Add tlib to the include path so that modules under tlib at the
   # same level as t, will be found
   #
   $lib_dir = File::Spec->catdir( cwd(), 'tlib' );
   $lib_dir =~ s|/|\\|g if $^O eq 'MSWin32';  # microsoft abberation
   unshift @INC, $lib_dir;
   chdir $dirs if $dirs;
 
   #####
   # Add lib under the directory where the test script resides.
   # This may be used to place version sensitive modules.
   #
   $lib_dir = File::Spec->catdir( cwd(), 'lib' );
   $lib_dir =~ s|/|\\|g if $^O eq 'MSWin32';  # microsoft abberation
   unshift @INC, $lib_dir;

   ##########
   # Pick up a output redirection file and tests to skip
   # from the command line.
   #
   my $test_log = '';
   GetOptions('log=s' => \$test_log);

   ########
   # Using Test::Tech, a very light layer over the module "Test" to
   # conduct the tests.  The big feature of the "Test::Tech: module
   # is that it takes a expected and actual reference and stringify
   # them by using "Data::Dumper" before passing them to the "ok"
   # in test.
   #
   # Create the test plan by supplying the number of tests
   # and the todo tests
   #
   require Test::Tech;
   Test::Tech->import( qw(plan ok skip skip_tests tech_config) );
   plan(tests => 18);

}



END {

   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @__restore_inc__;
   chdir $__restore_dir__;
}

   # Perl code from C:
    use File::Package;
    my $fp = 'File::Package';

    my $nid = 'Net::Netid';
    my $loaded;

ok(  $loaded = $fp->is_package_loaded($nid), # actual results
      '', # expected results
     '',
     'UUT not loaded');

#  ok:  1

   # Perl code from C:
my $errors = $fp->load_package( $nid);


####
# verifies requirement(s):
# L<DataPort::DataFile/general [1] - load>
# 

#####
skip_tests( 1 ) unless skip(
      $loaded, # condition to skip test   
      $errors, # actual results
      '',  # expected results
      '',
      'Load UUT');
 
#  ok:  2

ok(  my $net = Net::Netid->dot2net('240.192.31.14'), # actual results
     v240.192.31.14, # expected results
     '',
     'dot2net');

#  ok:  3

ok(  Net::Netid->net2dot($net), # actual results
     '240.192.31.14', # expected results
     '',
     'net2dot');

#  ok:  4

ok(  Net::Netid->ip2dot('google.com'), # actual results
     undef, # expected results
     '',
     'ip2dot - domain');

#  ok:  5

ok(  Net::Netid->ip2dot('002.010.0344.0266'), # actual results
     '2.8.228.182', # expected results
     '',
     'ip2dot - octal');

#  ok:  6

   # Perl code from C:
my @result=  Net::Netid->ipid('google.com');

ok(  $result[1], # actual results
     'www.google.com', # expected results
     '',
     'ipid - get info on domain name');

#  ok:  7

   # Perl code from C:
@result =  Net::Netid->ipid($result[2]);

ok(  $result[1], # actual results
     'www.google.com', # expected results
     '',
     'ipid - get info on an ip address name');

#  ok:  8

   # Perl code from C:
    my $hash_p =  Net::Netid->netid('google.com');
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;

ok(  [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}], # actual results
     ['www.google.com','ns1.google.com','smtp.google.com'], # expected results
     '',
     'netid - get info on domain name');

#  ok:  9

   # Perl code from C:
    $hash_p =  Net::Netid->netid($hash_p->{ip_addr_dot});
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;

ok(  [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}], # actual results
     ['www.google.com','ns1.google.com','smtp.google.com'], # expected results
     '',
     'netid - get info on an ip address name');

#  ok:  10

ok(  [my ($ip,$post) = Net::Netid->clean_ip_str(' <234.077.0xff.0b1010>')], # actual results
     ['234.077.0xff.0b1010',''], # expected results
     '',
     'clean_ip_str');

#  ok:  11

ok(  [($ip,$post) = Net::Netid->clean_ip_str(' [%32%33%34.077.0xff.0b1010]')], # actual results
     ['234.077.0xff.0b1010',''], # expected results
     '',
     'clean_ip_str');

#  ok:  12

   # Perl code from C:
@result=  Net::Netid->clean_ipid('google.com');

ok(  $result[1], # actual results
     'www.google.com', # expected results
     '',
     'clean_ipid - get info on domain name');

#  ok:  13

   # Perl code from C:
@result =  Net::Netid->clean_ipid($result[2]);

ok(  $result[1], # actual results
     'www.google.com', # expected results
     '',
     'clean_ipid - get info on an ip address name');

#  ok:  14

   # Perl code from C:
    $hash_p =  Net::Netid->clean_netid('google.com');
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;

ok(  [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}], # actual results
     ['www.google.com','ns1.google.com','smtp.google.com'], # expected results
     '',
     'clean_netid - get info on domain name');

#  ok:  15

   # Perl code from C:
    $hash_p =  Net::Netid->clean_netid($hash_p->{ip_addr_dot});
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;

ok(  [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}], # actual results
     ['www.google.com','ns1.google.com','smtp.google.com'], # expected results
     '',
     'clean_netid - get info on an ip address name');

#  ok:  16

ok(  Net::Netid->clean_ip2dot('google.com'), # actual results
     undef, # expected results
     '',
     'clean_ip2dot - domain');

#  ok:  17

ok(  Net::Netid->clean_ip2dot('002.010.0344.0266'), # actual results
     '2.8.228.182', # expected results
     '',
     'clean_ip2dot - octal');

#  ok:  18


=head1 NAME

Netid.t - test script for Net::Netid

=head1 SYNOPSIS

 Netid.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

Netid.t uses this option to redirect the test results 
from the standard output to a log file.

=back

=head1 COPYRIGHT

copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

## end of test script file ##

