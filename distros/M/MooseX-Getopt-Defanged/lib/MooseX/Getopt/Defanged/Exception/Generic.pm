package MooseX::Getopt::Defanged::Exception::Generic;

use 5.010;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v1.18.0');


use Readonly;


use Exporter qw< import >;

Readonly our @EXPORT_OK => qw< throw_generic >;


use Exception::Class (
    'MooseX::Getopt::Defanged::Exception::Generic' => {
        isa         => 'MooseX::Getopt::Defanged::Exception',
        description =>
            'An otherwise undifferentiated issue happened with command-line processing.',
        alias       => 'throw_generic',
    },
);

MooseX::Getopt::Defanged::Exception::Generic->Trace(1);


1;

__END__

=encoding utf8

=for stopwords

=head1 NAME

MooseX::Getopt::Defanged::Exception::Generic - Something went wrong with L<MooseX::Getopt::Defanged>, most likely a bug in the code using it.


=head1 SYNOPSIS

    use MooseX::Getopt::Defanged::Exception::Generic
        qw< throw_generic >;

    if ( ... something bad ... ) {
        throw_generic q<Hey! Something's wrong!>;

        or

        throw_generic
            message => q<Hey! Something's wrong!>,
            argv => [ @ARGV ];
    }

or

    use MooseX::Getopt::Defanged::Exception::Generic qw< >;

    if ( ... something bad ... ) {
        MooseX::Getopt::Defanged::Exception::Generic
            ->throw(
                message => q<Hey! Something's wrong!>,
                argv => [ @ARGV ],
            );
    }


=head1 VERSION

This document describes MooseX::Getopt::Defanged::Exception::Generic version
1.18.0.


=head1 DESCRIPTION

Something happened while talking to L<Getopt::Long>.
Usually this means there is a bug in the code using
L<MooseX::Getopt::Defanged>.


=head1 INTERFACE

Nothing is exported by default.


=head2 Importable Subroutines

=over

=item C<throw_generic( @message )>

Alternative for
C<MooseX::Getopt::Defanged::Exception::Generic->throw(@message)>.


=back


=head2 Methods

None other than those that are inherited.


=head1 DIAGNOSTICS

This class I<is> a diagnostic.


=head1 CONFIGURATION AND ENVIRONMENT

None.


=head1 DEPENDENCIES

perl 5.10

L<Exception::Class>

L<Readonly>


=head1 SEE ALSO

L<MooseX::Getopt::Defanged::Exception>.


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
