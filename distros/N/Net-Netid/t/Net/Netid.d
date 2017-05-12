#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.01';   # automatically generated file
$DATE = '2003/07/20';


##### Demonstration Script ####
#
# Name: Netid.d
#
# UUT: Net::Netid
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::Net::Netid 
#
# Don't edit this test script file, edit instead
#
# t::Net::Netid
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
#

######
#
# The working directory is the directory of the generated file
#
use vars qw($__restore_dir__ @__restore_inc__ );

BEGIN {
    use Cwd;
    use File::Spec;
    use File::TestPath;
    use Test::Tech qw(tech_config plan demo skip_tests);

    ########
    # Working directory is that of the script file
    #
    $__restore_dir__ = cwd();
    my ($vol, $dirs, undef) = File::Spec->splitpath(__FILE__);
    chdir $vol if $vol;
    chdir $dirs if $dirs;

    #######
    # Add the library of the unit under test (UUT) to @INC
    #
    @__restore_inc__ = File::TestPath->test_lib2inc();

    unshift @INC, File::Spec->catdir( cwd(), 'lib' ); 

}

END {

   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @__restore_inc__;
   chdir $__restore_dir__;

}

print << 'MSG';

 ~~~~~~ Demonstration overview ~~~~~
 
Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

MSG

demo( "\ \ \ \ use\ File\:\:Package\;\
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\
\ \ \ \ my\ \$nid\ \=\ \'Net\:\:Netid\'\;\
\ \ \ \ my\ \$loaded\;"); # typed in command           
          use File::Package;
    my $fp = 'File::Package';

    my $nid = 'Net::Netid';
    my $loaded;; # execution

demo( "my\ \$errors\ \=\ \$fp\-\>load_package\(\ \$nid\)"); # typed in command           
      my $errors = $fp->load_package( $nid); # execution

demo( "\$errors", # typed in command           
      $errors # execution
) unless     $loaded; # condition for execution                            

demo( "my\ \$net\ \=\ Net\:\:Netid\-\>dot2net\(\'240\.192\.31\.14\'\)", # typed in command           
      my $net = Net::Netid->dot2net('240.192.31.14')); # execution


demo( "Net\:\:Netid\-\>net2dot\(\$net\)", # typed in command           
      Net::Netid->net2dot($net)); # execution


demo( "Net\:\:Netid\-\>ip2dot\(\'google\.com\'\)", # typed in command           
      Net::Netid->ip2dot('google.com')); # execution


demo( "Net\:\:Netid\-\>ip2dot\(\'002\.010\.0344\.0266\'\)", # typed in command           
      Net::Netid->ip2dot('002.010.0344.0266')); # execution


demo( "my\ \@result\=\ \ Net\:\:Netid\-\>ipid\(\'google\.com\'\)"); # typed in command           
      my @result=  Net::Netid->ipid('google.com'); # execution

demo( "\$result\[1\]", # typed in command           
      $result[1]); # execution


demo( "\@result\ \=\ \ Net\:\:Netid\-\>ipid\(\$result\[2\]\)"); # typed in command           
      @result =  Net::Netid->ipid($result[2]); # execution

demo( "\$result\[1\]", # typed in command           
      $result[1]); # execution


demo( "\ \ \ \ my\ \$hash_p\ \=\ \ Net\:\:Netid\-\>netid\(\'google\.com\'\)\;\
\ \ \ \ \$hash_p\-\>\{mx_domain\}\ \=\ \'smtp\.google\.com\'\ if\ \$hash_p\-\>\{mx_domain\}\ \=\~\ \/smtp\\d\\\.google\.com\/\;"); # typed in command           
          my $hash_p =  Net::Netid->netid('google.com');
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;; # execution

demo( "\[\$hash_p\-\>\{host\}\,\$hash_p\-\>\{ns_domain\}\,\$hash_p\-\>\{mx_domain\}\]", # typed in command           
      [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]); # execution


demo( "\ \ \ \ \$hash_p\ \=\ \ Net\:\:Netid\-\>netid\(\$hash_p\-\>\{ip_addr_dot\}\)\;\
\ \ \ \ \$hash_p\-\>\{mx_domain\}\ \=\ \'smtp\.google\.com\'\ if\ \$hash_p\-\>\{mx_domain\}\ \=\~\ \/smtp\\d\\\.google\.com\/\;"); # typed in command           
          $hash_p =  Net::Netid->netid($hash_p->{ip_addr_dot});
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;; # execution

demo( "\[\$hash_p\-\>\{host\}\,\$hash_p\-\>\{ns_domain\}\,\$hash_p\-\>\{mx_domain\}\]", # typed in command           
      [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]); # execution


demo( "\[my\ \(\$ip\,\$post\)\ \=\ Net\:\:Netid\-\>clean_ip_str\(\'\ \<234\.077\.0xff\.0b1010\>\'\)\]", # typed in command           
      [my ($ip,$post) = Net::Netid->clean_ip_str(' <234.077.0xff.0b1010>')]); # execution


demo( "\[\(\$ip\,\$post\)\ \=\ Net\:\:Netid\-\>clean_ip_str\(\'\ \[\%32\%33\%34\.077\.0xff\.0b1010\]\'\)\]", # typed in command           
      [($ip,$post) = Net::Netid->clean_ip_str(' [%32%33%34.077.0xff.0b1010]')]); # execution


demo( "\@result\=\ \ Net\:\:Netid\-\>clean_ipid\(\'google\.com\'\)"); # typed in command           
      @result=  Net::Netid->clean_ipid('google.com'); # execution

demo( "\$result\[1\]", # typed in command           
      $result[1]); # execution


demo( "\@result\ \=\ \ Net\:\:Netid\-\>clean_ipid\(\$result\[2\]\)"); # typed in command           
      @result =  Net::Netid->clean_ipid($result[2]); # execution

demo( "\$result\[1\]", # typed in command           
      $result[1]); # execution


demo( "\ \ \ \ \$hash_p\ \=\ \ Net\:\:Netid\-\>clean_netid\(\'google\.com\'\)\;\
\ \ \ \ \$hash_p\-\>\{mx_domain\}\ \=\ \'smtp\.google\.com\'\ if\ \$hash_p\-\>\{mx_domain\}\ \=\~\ \/smtp\\d\\\.google\.com\/\;"); # typed in command           
          $hash_p =  Net::Netid->clean_netid('google.com');
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;; # execution

demo( "\[\$hash_p\-\>\{host\}\,\$hash_p\-\>\{ns_domain\}\,\$hash_p\-\>\{mx_domain\}\]", # typed in command           
      [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]); # execution


demo( "\ \ \ \ \$hash_p\ \=\ \ Net\:\:Netid\-\>clean_netid\(\$hash_p\-\>\{ip_addr_dot\}\)\;\
\ \ \ \ \$hash_p\-\>\{mx_domain\}\ \=\ \'smtp\.google\.com\'\ if\ \$hash_p\-\>\{mx_domain\}\ \=\~\ \/smtp\\d\\\.google\.com\/\;"); # typed in command           
          $hash_p =  Net::Netid->clean_netid($hash_p->{ip_addr_dot});
    $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;; # execution

demo( "\[\$hash_p\-\>\{host\}\,\$hash_p\-\>\{ns_domain\}\,\$hash_p\-\>\{mx_domain\}\]", # typed in command           
      [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]); # execution


demo( "Net\:\:Netid\-\>clean_ip2dot\(\'google\.com\'\)", # typed in command           
      Net::Netid->clean_ip2dot('google.com')); # execution


demo( "Net\:\:Netid\-\>clean_ip2dot\(\'002\.010\.0344\.0266\'\)", # typed in command           
      Net::Netid->clean_ip2dot('002.010.0344.0266')); # execution



=head1 NAME

Netid.d - demostration script for Net::Netid

=head1 SYNOPSIS

 Netid.d

=head1 OPTIONS

None.

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

## end of test script file ##

=cut

