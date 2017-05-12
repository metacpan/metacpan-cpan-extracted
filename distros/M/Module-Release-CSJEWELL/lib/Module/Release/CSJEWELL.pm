package Module::Release::CSJEWELL;

use 5.006001;
use warnings;
use strict;

our $VERSION = '0.101';
$VERSION = eval { return $VERSION };

1;                                     # Magic true value required at end of module

__END__

=begin readme text

Module::Release::CSJEWELL version 0.005

=end readme

=for readme stop

=head1 NAME

Module::Release::CSJEWELL - Plugins for Module::Release.

=head1 VERSION

This document describes Module::Release::CSJEWELL version 0.101

=for readme continue

=head1 DESCRIPTION

This distribution contains plugins for Module::Release that CSJEWELL uses 
in his release automation, and the script that he currently uses.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

This method of installation will install a current version of Module::Build 
if it is not already installed.
    
Alternatively, to install with Module::Build, you can use the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install
	
=end readme

=for readme stop

=head1 SYNOPSIS

    # use Module::Release::CSJEWELL;

This is a documentation-only module. Instead of this module, you'll be using 
specific classes in this distribution.

See those classes for documentation.

=head1 CONFIGURATION AND ENVIRONMENT
  
The modules included in this distribution use the .releaserc or releaserc that is 
in the root directory of the distribution being released, and also use some 
environment variables.

Specific parameters or environment variables used are mentioned in each module.

=for readme continue

=head1 DEPENDENCIES

L<Net::Twitter|Net::Twitter> version 3.04006, L<Archive::Tar|Archive::Tar> (more to add later)

=head1 WARNING

This distribution is not nearly complete yet - it is still in an alpha state.

=for readme stop

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Release-CSJEWELL>
if you have an account there.

2) Email to E<lt>bug-Module-Release-CSJEWELL@rt.cpan.orgE<gt> if you do not.

=head1 SEE ALSO

L<Module::Release|Module::Release>

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=for readme continue

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Curtis Jewell C<< <csjewell@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic> and L<perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=for readme stop

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
