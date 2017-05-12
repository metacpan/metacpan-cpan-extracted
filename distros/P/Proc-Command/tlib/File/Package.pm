#!perl
#
# Documentation, copyright and license is at the end of this file.
#

package  File::Package;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.11';
$DATE = '2003/07/27';
$FILE = __FILE__;

use SelfLoader;

1

__DATA__


######
#
#
sub load_package
{

    my (undef, $package) = @_;
    unless ($package) { # have problem if there is no package
        my $error = "# The package name is empty. There is no package to load.\n";
        return $error;
    }
    if( $package =~ /\-/ ) {
        my $error =  "# The - in $package causes problems. Perl thinks - is subtraction when it evals it.\n";
        return $error;      
    }
    return '' if File::Package->is_package_loaded( $package );

    #####
    # Load the module
    #
    # On error when evaluating "require $package" only the last
    # line of STDERR, at least on one Perl, is return in $@.
    # Save the entire STDERR to a memory variable
    #
    my $restore_warn = $SIG{__WARN__};
    my $warn_string = '';
    $SIG{__WARN__} = sub { $warn_string .= join '', @_; };
    eval "require $package;";
    $SIG{__WARN__} = $restore_warn;
    $warn_string = $@ . $warn_string if $@;
    if($warn_string) {
        $warn_string =~ s/\n/\n\t/g;
        return "Cannot load $package\n\t" . $warn_string;
    }

    #####
    # Verify the package vocabulary is present
    #
    unless (File::Package->is_package_loaded( $package )) {
        return "# $package loaded but package vocabulary absent.\n";
    }
    ''
}


######
#
#
sub is_package_loaded
{
    my (undef, $package) = @_;
   
    $package .= "::";
    defined %$package

}




1

__END__


=head1 NAME

File::Package - test load a program module with a package of the same name

=head1 SYNOPSIS

  use File::Package

  $package       = File::Package->is_package_loaded($package)
  $error         = File::Package->load_package($package)

=head1 DESCRIPTION

One very useful test of the installation of a package is whether
or not the package loaded.
If it did not load, the reason it did not load is helpful
diagnostics.

This information is readily available when loaded at a local site.
However, it the load occurs at a remote site and the load crashes
Perl, the remote tester usually will not have this information
readily available.

The load_package method attempts to capture any load problems by
loading the package with a "require " under an eval and capturing
all the "warn" and $@ messages.
The error messages are returned so that they may be appropriately
tested and if not as expected the actual and expected included
in failure report back to the author of the package.

=head1 METHODS

=head2 is_package_loaded method

 $package = File::Package->is_package_loaded($package)

The I<is_package_loaded> method determines if a package
vocabulary is present.

For example, if I<File::Basename> is not loaded

 ==> File::Package->is_package_loaded('File::Basename')

 ''
=head1 REQUIREMENTS

Coming soon.

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

### end of file ###