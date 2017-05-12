##########################################################################
#                                                                        #
# © Copyright IBM Corporation 2001, 2007 All rights reserved.            #
#                                                                        #
# This program and the accompanying materials are made available under   #
# the terms of the Common Public License v1.0 which accompanies this     #
# distribution, and is also available at http://www.opensource.org       #
# Contributors:                                                          #
#                                                                        #
# William Spurlin - Creation and framework                               #
#                                                                        #
##########################################################################

package ClearCase::MtCmd;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(multitool);
$ClearCase::MtCmd::VERSION = '0.1';
bootstrap ClearCase::MtCmd $VERSION;


sub new {
  my $object = shift;
  my $this = {};
  %$this = @_;
  bless $this, $object;
  $this->{'status'} = 0;
  return $this;
}

sub status{
    my $this = shift;
    return $this->{'status'}
}

*multitool = \&exec;


1;
__END__

=head1 NAME

ClearCase::MtCmd - Perl extension for Rational ClearCase Multisite

=head1 PLATFORMS/VERSIONS

See INSTALL for a list of supported platforms and ClearCase versions.

=head1 SYNOPSIS

    use ClearCase::MtCmd;

    @aa = ClearCase::MtCmd::exec("lsepoch","-invob","/vobs/xyz");

    my $status_now = $aa[0];

    $stdout = $aa[1];

    @aa = ClearCase::MtCmd::exec("lsreplica");

    $error = $aa[2];

    die $error if $status_now;

    my $inst = ClearCase::MtCmd->new();

    die $x if &ClearCase::MtCmd::cmdstat;

=head1 DESCRIPTION


B<I/O>

ClearCase::MtCmd::exec() takes either a string or a list  as an input argument, and, in array context, returns a three element Perl array as output.  


The first output element is a status bit containing 0 on success, 1 on failure.The second output element is a scalar string corresponding to stdout, if any.  The third element contains any error message corresponding to output on stderr.  
In scalar context, ClearCase::MtCmd::exec() returns output corresponding to either stdout or stderr, as appropriate.  ClearCase::MtCmd::cmdstat() will return 0 upon success, 1 upon failure of the last previous command.

ClearCase::MtCmd->new()  may be used to create an instance of ClearCase::MtCmd.  There are three possible construction variables:

ClearCase::MtCmd->new(outfunc=>0,errfunc=>0,debug=>1);

Setting outfunc or errfunc to zero disables the standard output and error handling functions.  Output goes to stdout or stderr. The size of the output array is reduced correspondingly.


B<Exit Status>

I<Commands Performing a Single Operation>


For commands that perform only one operation if the first element has any content, the second element will be empty, and vice-versa.

Upon the return of class method exec:

    ($a,$b,$c) = ClearCase::MtCmd::exec( some command );   

the first returned element $a contains the status of "some command":  0 upon success, 1 upon failure.  

In scalar context  ClearCase::MtCmd::cmdstat() will return 0 upon success, 1 upon failure of the last previous command.

Upon the return of instance method exec:

    $x = ClearCase::MtCmd-new; $x->exec( some command );
  
instance method status() is available: 

 $status = $x->status();

status() returns 0 upon success, 1 upon failure.

I<Commands Performing Multiple Operations>

For commands that perform more than one operation, if an operation succeeds and an operation also fails, there may be content in both the second and third returned elements.  If any operation fails the first output element and the status() method will return 1.  If all operations succeed the first output element and the status() method will return 0.


=head1 SUPPORTED MULTISITE COMMANDS

 
=head1 QUOTING

 

B<ClearCase::MtCmd::exec( list ) >

Since in its initial lexical scanning phase the Perl tokenizer
will treat single characters preceded by a hyphen as 
file test operators ( C<-e>,  C<-s>,  C<-l> etc.), such constructs must 
be quoted when passed as arguments to ClearCase::MtCmd::exec().
Similar considerations apply to the % character, used in
multitool format conversion strings.  Otherwise list form arguments to
ClearCase::MtCmd->exec() do not need to be quoted, with the caveat that if
there is a name conflict between a multitool command and a function 
unexpected results will follow unless the multitool command is quoted,
e. g., 'desc' will protect function desc().


The qw operator eliminates the need to separately quote elements:


I<Example of list form with the qw operator>


I<Examples of the single-letter switch condition:>


=head1 CONTRIBUTORS



=head1 AUTHOR

wspurlin#us.ibm.com IBM Rational Software

=head1 SEE ALSO

perl(1).

=cut
