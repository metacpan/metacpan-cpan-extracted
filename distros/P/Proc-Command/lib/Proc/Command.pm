#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Proc::Command;

use strict;
use 5.001;
use warnings;
use warnings::register;


#####
# Connect up with the event log.
#
use vars qw( $VERSION $DATE $FILE);
$VERSION = '1.05';
$DATE = '2003/07/27';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(&command);

######
# backtick that does not use the shell for Perl under Windows
#
#
sub command
{

    shift @_ if $_[0] eq 'Proc::Command' || ref($_[0]);  # drop self on object call 
    my ($command, $trys, $sleep) = @_;

    $trys = 1 unless $trys;
    $sleep = 2 unless $sleep;

    my ($i, @response);
    for( $i=0; $i<$trys; $i++ ) {

        #######
        # This form does not use the shell to execute the command.
        #
        # Having the shell pop-up in middle of a long run, just ... bad.
        #
        $command = "MCR $command" if $^O eq 'VMS';
        unless (open (CMD, '-|', $command)) {
            unless( $i < $trys ) {
                warn "Cannot fork $command\n";
                return undef;
            }
            last unless $i < $trys;
            sleep( $sleep ); 
            next;
        }
        @response = <CMD>;
        unless( close CMD ) {
            unless( $i < $trys ) {
                warn "Error $? forking $command\n";
                return undef;
            }
            sleep( $sleep );
            next;
        }

   }
   @response = () unless @response;
   return wantarray ? @response : (join '',@response);

}

1

__END__


=head1 NAME

Proc::Command - backtick that does not use the shell for Perl under Windows

=head1 SYNOPSIS

 use Proc::Command

 @reponse = Proc::Command->command($command)
 @reponse = Proc::Command->command($command, $trys)
 @reponse = Proc::Command->command($command, $trys, $sleep)

 use Proc::Command qw(command)

 @reponse = command($command)
 @reponse = command($command, $trys)
 @reponse = command($command, $trys, $sleep)

=head1 DESCRIPTION

Some Perls under Microsoft windows suffers disabilities over Unix Perls.
One particular disability is a backtick without the console.
Altough the Microsoft console, may be started without a window
(start command with /b option or spawn program call), the Perl
system command on windows usually creates a window.
Creating a window causes immense user interface problem since 
it will randomly pop-up and take focus over the current window,
erasing current entries into that window.
Solutions such as "Proc::SafePipe" do not run on Perls for Window.

This module provides an answer by using the "open" command with
a pipe to provide a backtick without a console that will run
under Perls on Microsoft Windows.

=head1 REQUIREMENTS

Coming soon.

=head1 DEMONSTRATION

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Spec;
 =>     use File::Package;
 =>     my $fp = 'File::Package';
 =>     my $loaded = '';
 =>  
 =>     my $pc = 'Proc::Command';
 =>     my ($command,$actual);
 => my $errors = $fp->load_package($pc)
 => $errors
 ''

 => $actual = $pc->command('echo hello')
 'hello
 '


=head1 QUALITY ASSURANCE

The module "t::Proc::Command" is the Software
Test Description(STD) module for the "Proc::Command".
module. 

To generate all the test output files, 
run the generated test script,
run the demonstration script and include it results in the "Proc::Command" POD,
execute the following in any directory:

 tmake -test_verbose -replace -run  -pm=t::Proc::Command

Note that F<tmake.pl> must be in the execution path C<$ENV{PATH}>
and the "t" directory containing  "t::Proc::Command" on the same level as the "lib" 
directory that contains the "Proc::Command" module.

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
government practices, 490A (L<STD490A/3.2.3.6>).
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

=head2 SEE_ALSO:

=over 4

=item L<File::Spec|File::Spec>

=item L<Proc::Command|Proc::Command>

=back

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
### end of script  ######