#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Test::Tech;

use 5.001;
use strict;
use warnings;
use warnings::register;

use Test ();   # do not import the "Test" subroutines
use Data::Dumper;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.11';
$DATE = '2003/07/27';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(&tech_config &plan &ok &skip &skip_tests &stringify &demo);

#######
#
# Keep all data hidden in a local hash
# 
# Too bad "Test" and "Data::Dumper" are not objectified
#
# Senseless to objectify "Test::Tech" if unless "Test" and "Data::Dumper"
# are objectified
#

my %tech = ();
my $tech_p = \%tech;  # quasi objectify by using $tech_p instead of %tech

########
# Tend to Data::Dumper variables
#
$tech_p->{Dumper} = {};
$tech_p->{Dumper}->{Terse} = \$Data::Dumper::Terse;
$tech_p->{Dumper}->{Indent} = \$Data::Indent;
$tech_p->{Dumper}->{Purity} = \$Data::Purity;
$tech_p->{Dumper}->{Pad} = \$Data::Pad;
$tech_p->{Dumper}->{Varname} = \$Data::Varname;
$tech_p->{Dumper}->{Useqq} = \$Data::Useqq;
$tech_p->{Dumper}->{Freezer} = \$Data::Freezer;
$tech_p->{Dumper}->{Toaster} = \$Data::Toaster;
$tech_p->{Dumper}->{Deepcopy} = \$Data::Deepcopy;
$tech_p->{Dumper}->{Quotekeys} = \$Data::Quotekeys;
$tech_p->{Dumper}->{Maxdepth} = \$Data::Maxdepth;

######
# Tend to Test variables
#  
$tech_p->{Test}->{ntest} = \$Test::ntest;
$tech_p->{Test}->{TESTOUT} = \$Test::TESTOUT;
$tech_p->{Test}->{TestLevel} = \$Test::TestLevel;
$tech_p->{Test}->{ONFAIL} = \$Test::ONFAIL;
$tech_p->{Test}->{todo} = \%Test::todo;
$tech_p->{Test}->{history} = \%Test::history;
$tech_p->{Test}->{planned} = \$Test::planned;
$tech_p->{Test}->{FAILDETAIL} = \@Test::FAILDETAIL;
$tech_p->{Test}->{Program_Lines} = \%Test::Program_Lines if defined %Test::Program_lines; 
$tech_p->{Test}->{TESTERR} = \$Test::TESTERR if defined $Test::TESTERR;
$tech_p->{Skip_Tests} = 0;

#######
# Probe for internal storage
#
# The &Data::Dumper::Dumper subroutine stringifies the iternal Perl variable. 
# Different Perls keep the have different internal formats for numbers. Some
# keep them as binary numbers, while others as strings. The ones that keep
# them as strings may be well spec. In any case they have been let loose in
# the wild so the test scripts that use Data::Dumper must deal with them.
#
# This is perl, v5.6.1 built for MSWin32-x86-multi-thread 
# (with 1 registered patch, see perl -V for more detail)
#
# Copyright 1987-2001, Larry Wall 
#
# Binary build 631 provided by ActiveState Tool Corp. http://www.ActiveState.com
# Built 17:16:22 Jan 2 2002
#
#
# Perl may be copied only under the terms of either the Artistic License or the
# GNU General Public License, which may be found in the Perl 5 source kit.
# 
# Complete documentation for Perl, including FAQ lists, should be found on
# this system using `man perl' or `perldoc perl'. If you have access to the
# Internet, point your browser at http://www.perl.com/, the Perl Home Page.
#
# ~~~~~~~
#
# Wall, Christiansen and Orwant on Perl internal storage
#
# Page 351 of Programming Perl, Third Addition, Overloadable Operators
# quote: 
#
# Conversion operators: ``'', 0+, bool
#
# These three keys let you provide behaviors for Perl's automatic conversions
# to strings, numbers, and Boolean values, respectively.
#
# ~~~~~~~
#
# Internal Storage of Perls that are in the wild
#
# string - Perl v5.6.1 MSWin32-x86-multi-thread, ActiveState build 631, binary
# number - Perl version 5.008 for solaris
#
# Perls in the wild with internal storage of string may be mutants that need to
# be hunted down killed.
#
my $probe = 3;
my $actual = Dumper([0+$probe]);
if( $actual eq Dumper([3]) ) {
   $tech_p->{Internal_Number} = 'number';
}
elsif ( $actual eq Dumper(['3']) ) {
   $tech_p->{Internal_Number} = 'string';
}
else {
   $tech_p->{Internal_Number} = 'undetermine';
}
  

#####
# Stringify the variable and compare the string.
#
# This is the code that adds the big new capability of testing complex data
# structures to the "Test" module
#
sub stringify
{
   my ($var_p) = @_;

   return '' unless $var_p;
   
   my ($result, $ref);
   if($ref = ref($var_p)) {
       if( $ref eq 'ARRAY' ) { 
           if( 1 < @$var_p ) {
               $result = Dumper(@$var_p);
           }
           else {
               $result = shift @$var_p;
           }
        }
        elsif( $ref eq 'HASH' ) {
           $result = Dumper(%$var_p);
        } 
        else {
           $result = Dumper($var_p);
        }
   }
   else {
       $result  = $var_p;
   }
   $result;
}



######
# Cover function for &Test::plan that sets the proper 'Test::TestLevel'
# and outputs some info on the current site
#
sub plan
{
   &Test::plan( @_ );

   ###############
   #  
   # Establish default for Test and Data::Dumper
   #
   # Test 1.24 resets global variables in plan which
   # never happens in 1.15
   #
   $Data::Dumper::Terse = 1; 
   $Test::TestLevel = 1;

   my $loctime = localtime();
   my $gmtime = gmtime();

   my $perl = "$]";
   if(defined(&Win32::BuildNumber) and defined &Win32::BuildNumber()) {
       $perl .= " Win32 Build " . &Win32::BuildNumber();
   }
   elsif(defined $MacPerl::Version) {
       $perl .= " MacPerl version " . $MacPerl::Version;
   }

   print $Test::TESTOUT <<"EOF" unless 1.20 < $Test::VERSION ;
# OS            : $^O
# Perl          : $perl
# Local Time    : $loctime
# GMT Time      : $gmtime
# Test          : $Test::VERSION
EOF

   print $Test::TESTOUT <<"EOF";
# Number Storage: $tech_p->{Internal_Number}
# Test::Tech    : $VERSION
# Data::Dumper  : $Data::Dumper::VERSION
# =cut 
EOF

   1
}


######
#
# Cover function for &Test::ok that adds capability to test 
# complex data structures.
#
sub ok
{
   my ($actual_result, $expected_result, $diagnostic, $name) = @_;

   print $Test::TESTOUT "# $name\n" if $name;
   if($tech_p->{Skip_Tests}) { # skip rest of tests switch
       print $Test::TESTOUT "# Test invalid because of previous failure.\n";
       &Test::skip( 1, 0, '');
       return 1; 
   }

   &Test::ok(stringify($actual_result), stringify($expected_result), $diagnostic);
}


######
#
#
sub skip
{
   my ($mod, $actual_result, $expected_result, $diagnostic, $name) = @_;

   print $Test::TESTOUT "# $name\n" if $name;

   if($tech_p->{Skip_Tests}) {  # skip rest of tests switch
       print $Test::TESTOUT "# Test invalid because of previous failure.\n";
       &Test::skip( 1, 0, '');
       return 1; 
   }
  
   &Test::skip($mod, stringify($actual_result), stringify($expected_result), $diagnostic);

}


######
#
#
sub skip_tests
{
   my ($value) =  @_;
   my $result = $tech_p->{Skip_Tests};
   $tech_p->{Skip_Tests} = $value if defined $value;
   $result;   
}



#######
# This accesses the values in the %tech hash
#
# Use a dot notation for following down layers
# of hashes of hashes
#
sub tech_config
{
    my ($key, @values) = @_;
    my @keys = split /\./, $key;

    #########
    # Follow the hash with the current
    # dot index until there are no more
    # hashes. Hopefully the dot hash 
    # notation matches the structure.
    #
    my $key_p = $tech_p;
    while (@keys) {

        $key = shift @keys;

        ######
        # Do not allow creation of new configs
        #
        if( defined( $key_p->{$key}) ) {

            ########
            # Follow the hash
            # 
            if( ref($key_p->{$key}) eq 'HASH' ) { 
                $key_p  = $key_p->{$key};
            }
            else {
               if(@keys) {
                    warn( "More key levels than hashes.\n");
                    return undef; 
               } 
               last;
            }
        }
    }


    #########
    # References to arrays and scalars in the config may
    # be transparent.
    #
    my $current_value = $key_p->{$key};
    return $current_value if ref($current_value) eq 'HASH';
    if (defined $values[0]) {
        if(ref($key_p->{$key}) eq 'ARRAY') {
            if( ref($values[0]) eq 'ARRAY' ) {
                $key_p->{$key} = $values[0];
            }
            else {
                my @current_value = @{$key_p->{$key}};
                $key_p->{$key} = \@values;
                return @current_value;
            }
        }
        elsif( ref($key_p->{$key}) ) {
            $current_value = ${$key_p->{$key}};
            ${$key_p->{$key}} = $values[0];
        }
        else {
            $key_p->{$key} = $values[0];
        }
    }

    $current_value;

}



######
# Demo
#
sub demo
{
   my ($quoted_expression, @expression_results) = @_;

   #######
   # A demo trys to simulate someone typing expresssions
   # at a console.
   #

   #########
   # Print quoted expression so that see the non-executed
   # expression. The extra space is so when pasted into
   # a POD, the POD will process the line as code.
   #
   $quoted_expression =~ s/(\n+)/$1 => /g;
   print $Test::TESTOUT ' => ' . $quoted_expression . "\n";   

   ########
   # @data is the result of the script executing the 
   # quoted expression.
   #
   # The demo output most likely will end up in a pod. 
   # The the process of running the generated script
   # will execute the setup. Thus the input is the
   # actual results. Putting a space in front of it
   # tells the POD that it is code.
   #
   return unless @expression_results;
  
   $Data::Dumper::Terse = 1;
   my $data = Dumper(@expression_results);
   $data =~ s/(\n+)/$1 /g;
   $data =~ s/\\\\/\\/g;
   $data =~ s/\\'/'/g;

   print $Test::TESTOUT ' ' . $data . "\n" ;

}

1


__END__

=head1 NAME
  
Test::Tech - adds skip_tests and test data structures capabilities to the "Test" module

=head1 SYNOPSIS

 use Test::Tech

 @args    = tech_config( @args );

 $success = plan(@args);

 $test_ok = ok(\@actual_results, \@expected_results, $diagnostic, $test_name);
 $test_ok = skip($skip_test, \@actual_results,  \@expected_results, $diagnostic, $test_name);

 $test_ok = ok($actual_results, $expected_results, $diagnostic, $test_name);
 $test_ok = skip($skip_test, $actual_results,  $expected_results, $diagnostic, $test_name);

 $state = skip_tests( $on_off );
 $state = skip_tests( );

 $string = stringify( $var );

=head1 DESCRIPTION
The "Test::Tech" module extends the capabilities of the "Test" module.

The design is simple. 
The "Test::Tech" module loads the "Test" module without exporting
any "Test" subroutines into the "Test::Tech" namespace.
There is a "Test::Tech" cover subroutine with the same name
for each "Test" module subroutine.
Each "Test::Tech" cover subroutine will call the &Test::$subroutine
before or after it adds any additional capabilities.
The "Test::Tech" module is a drop-in for the "Test" module.

The "Test::Tester" module extends the capabilities of
the "Test" module as follows:

=over 4

=item *

Compare almost any data structure by passing variables
through I<Data::Dumper> before making the comparision

=item *

Method to skip the rest of the tests upon a critical failure

=item *

Method to generate demos that appear as an interactive
session using the methods under test

=back

The Test::Tech module is an integral part of the US DOD SDT2167A bundle
of modules.
The dependency of the program modules in the US DOD STD2167A bundle is as follows:

 File::Package
   File::SmartNL Test::STD::Scrub
     Test::Tech
        DataPort::FileType::FormDB DataPort::DataFile Test::STD::STDutil
            Test::STDmaker ExtUtils::SVDmaker

=head2 plan subroutine

 $success = plan(@args);

The I<plan> subroutine is a cover method for &Test::plan.
The I<@args> are passed unchanged to &Test::plan.
All arguments are options. Valid options are as follows:

=over 4

=item tests

The number of tests. For example

 tests => 14,

=item todo

An array of test that will fail. For example

 todo => [3,4]

=item onfail

A subroutine that the I<Test> module will
execute on a failure. For example,

 onfail => sub { warn "CALL 911!" } 

=back

=head2 ok subroutine

 $test_ok = ok(\@actual_results, \@expected_results, $test_name);
 $test_ok = ok($actual_results, $expected_results, $test_name);

The I<test> method is a cover function for the &Test::ok subroutine
that extends the &Test::ok routine as follows:

=over 4

=item *

Prints out the I<$test_name> to provide an English identification
of the test.

=item *

The I<ok> subroutine passes the arrays from an array reference
I<@actual_results> and I<@expectet_results> through &Data::Dumper::Dumper.
The I<test> method then uses &Test::ok to compare the text results
from &Data::Dumper::Dumper.

=item *

The I<ok> subroutine method passes variables that are not a reference
directly to &Test::ok unchanged.

=item *

Responses to a flag set by the L<skip_tests subroutine|Test::Tech/skip_tests> subroutine
and skips the test completely.

=back

=head2 skip subroutine

 $test_ok = skip(\@actual_results, \@expected_results, $test_name);
 $test_ok = skip($actual_results, $expected_results, $test_name);

The I<skip> subroutine is a cover function for the &Test::skip subroutine
that extends the &Test::skip the same as the 
L<ok subroutine|Test::Tech/ok> subroutine extends
the I<&Test::ok> subroutine.

=head2 skip_tests method

 $state = skip_tests( $on_off );
 $state = skip_tests( );

The I<skip_tests> subroutine sets a flag that causes the
I<ok> and the I<skip> methods to skip testing.

=head2 stringify subroutine

 $string = stringify( $var );

The I<stringify> subroutine will stringify I<$var> using
the "L<Data::Dumper|Data::Dumper>" module only if I<$var> is a reference;
otherwise, it leaves it unchanged.

For numeric arrays, "L<Data::Dumper|Data::Dumper>" module will not
stringify them the same for all Perls. The below Perl code will
produce different results for different Perls

 $probe = 3;
 $actual = Dumper([0+$probe]);

For Perl v5.6.1 MSWin32-x86-multi-thread, ActiveState build 631, binary,
the results will be '[\'3\']'  
while for Perl version 5.008 for solaris the results will be '[3]'. 

This module will automatically, when loaded, probe the site Perl
and will this statement and enter the results as 'string' or
'number' in the I<Internal_Number> configuration variable.

=head2 tech_config subroutine

 $old_value = tech_config( $dot_index, $new_value );

The I<tech_config> subroutine reads and writes the
below configuration variables

 dot index              contents 
 --------------------   --------------
 Dumper.Terse          \$Data::Dumper::Terse
 Dumper.Indent         \$Data::Indent
 Dumper.Purity         \$Data::Purity
 Dumper.Pad            \$Data::Pad
 Dumper.Varname        \$Data::Varname
 Dumper.Useqq          \$Data::Useqq
 Dumper.Freezer        \$Data::Freezer
 Dumper.Toaster        \$Data::Toaster
 Dumper.Deepcopy       \$Data::Deepcopy
 Dumper.Quotekeys      \$Data::Quotekeys
 Dumper.Maxdepth       \$Data::Maxdepth
 Test.ntest            \$Test::ntest
 Test.TESTOUT          \$Test::TESTOUT
 Test.TestLevel        \$Test::TestLevel
 Test.ONFAIL           \$Test::ONFAIL
 Test.todo             \%Test::todo
 Test.history          \%Test::history
 Test.planned          \$Test::planned
 Test.FAILDETAIL       \@Test::FAILDETAIL
 Test.Program_Lines    \%Test::Program_Lines
 Test.TESTERR          \$Test::TESTERR
 Skip_Tests            # boolean
 Internal_Number       # 'string' or 'number'

The I<tech_config> subroutine always returns the
I<$old_value> of I<$dot_index> and only writes
the contents if I<$new_value> is defined.

The 'SCALAR' and 'ARRAY' references are transparent.
The I<tech_config> subroutine, when it senses that
the I<$dot_index> is for a 'SCALAR' and 'ARRAY' reference,
will read or write the contents instead of the reference.

The The I<tech_config> subroutine will read 'HASH" references
but will never change them. 

The variables for the top level 'Dumper' I<$dot_index> are
established by "L<Data::Dumper|Data::Dumper>" module;
for the top level 'Test', the "L<Test|Test>" module.

=head1 NOTES

=head2 AUTHOR

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<US DOD 490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 LICENSE

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http::www.softwarediamonds.com,
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

=head1 SEE ALSO

L<Test> L<Test::TestUtil>

=for html
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="COPYRIGHT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

### end of file ###