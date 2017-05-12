package MooseX::Getopt::Defanged::Exception;

use 5.010;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v1.18.0');


use Exception::Class (
    'MooseX::Getopt::Defanged::Exception' => {
        description =>
            'Something went wrong that is somehow associated with MooseX::Getopt::Defanged.',
        fields      => [ qw< argv > ],
    },
);


1;

__END__

=encoding utf8

=for stopwords

=head1 NAME

MooseX::Getopt::Defanged::Exception - Something went wrong that is somehow associated with L<MooseX::Getopt::Defanged>.


=head1 SYNOPSIS

    use Exception::Class (
        'MooseX::Getopt::Defanged::Exception::Something' => {
            isa         => 'MooseX::Getopt::Defanged::Exception',
            description => 'Something went wrong with MooseX::Getopt::Defanged.',
        },
    );


=head1 VERSION

This document describes MooseX::Getopt::Defanged::Exception version 1.18.0.


=head1 DESCRIPTION

This is a base exception for things related to L<MooseX::Getopt::Defanged> that all
subclasses can be caught in one go.  This is an abstract class and should
never be instantiated, merely subclassed.


=head1 INTERFACE

There are no subroutines, only methods.


=over

=item C<argv()>

The command line that was being looked at by L<MooseX::Getopt::Defanged>, as an array
reference.


=back


=head1 DIAGNOSTICS

This class I<is> a diagnostic.


=head1 CONFIGURATION AND ENVIRONMENT

None.


=head1 DEPENDENCIES

perl 5.10

L<Exception::Class>


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright ©2008-2010, Elliot Shank


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :
