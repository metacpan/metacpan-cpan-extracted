package MooseX::Getopt::Defanged::Exception::User;

use 5.010;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v1.18.0');


use Readonly;


use Exporter qw< import >;

Readonly our @EXPORT_OK => qw< throw_user >;

use Exception::Class (
    'MooseX::Getopt::Defanged::Exception::User' => {
        isa         => 'MooseX::Getopt::Defanged::Exception',
        description => 'There was a problem with user input.',
        alias       => 'throw_user',
    },
);



1;

__END__

=encoding utf8

=for stopwords

=head1 NAME

MooseX::Getopt::Defanged::Exception::User - A "normal", expected error, that should shut the application down.


=head1 SYNOPSIS

    use MooseX::Getopt::Defanged::Exception::User qw< throw_user >;

    if ( ... something bad ... ) {
        throw_user q<Hey! Something's wrong!>;
    }

or

    use MooseX::Getopt::Defanged::Exception::User qw< >;

    if ( ... something bad ... ) {
        MooseX::Getopt::Defanged::Exception::User->throw(q<Hey! Something's wrong!>);
    }


=head1 VERSION

This document describes MooseX::Getopt::Defanged::Exception::User version
1.18.0.


=head1 DESCRIPTION

A user gave us a bad command-line option.


=head1 INTERFACE

Nothing is exported by default.


=over

=item C<throw_user( @message )>

Alternative for C<MooseX::Getopt::Defanged::Exception::User->throw(@message)>.


=back


=head1 DIAGNOSTICS

This class I<is> a diagnostic.


=head1 CONFIGURATION AND ENVIRONMENT

None.


=head1 DEPENDENCIES

perl 5.10

L<Exception::Class>

L<Readonly>


=head1 SEE ALSO

L<Exception::Class>.


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
