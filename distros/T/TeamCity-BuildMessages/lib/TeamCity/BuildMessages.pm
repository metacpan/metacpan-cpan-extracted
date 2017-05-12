package TeamCity::BuildMessages;

use 5.008004;
use utf8;
use strict;
use warnings;


use version; our $VERSION = qv('v0.999.3');


use autodie qw< :default >;
use Carp qw< croak >;
use Readonly;


use IO::Handle; # Create methods on standard filehandles like STDOUT.


use Exporter qw< import >;

our @EXPORT_OK =
    qw<
        teamcity_escape
        teamcity_emit_build_message
    >;
our %EXPORT_TAGS    = (
    all => [@EXPORT_OK],
);


Readonly::Scalar my $IDENTIFIER_REGEX => qr< \A \w [\w\d]* \z >xms;


sub teamcity_escape {
    my ($original) = @_;

    (my $escaped = $original) =~ s< ( ['|\]] ) ><|$1>xmsg;
    $escaped =~ s< \n ><|n>xmsg;
    $escaped =~ s< \r ><|r>xmsg;

    return $escaped;
} # end teamcity_escape()


sub teamcity_emit_build_message { ## no critic (RequireArgUnpacking)
    _emit_build_message_to_handle(\*STDOUT, @_);

    return;
} # end teamcity_emit_build_message()


sub _emit_build_message_to_handle {
    my ($handle, $message, @values) = @_;

    croak 'No message specified.' if not $message;
    croak 'No values specified.' if not @values;
    croak qq<"$message" is not a valid message name.>
        if $message !~ $IDENTIFIER_REGEX;

    print {$handle} "##teamcity[$message";

    if (@values == 1) {
        print {$handle} q< '>, teamcity_escape($values[0]), q<'>;
    } else {
        if (@values % 2) {
            croak 'Message property given without a value.';
        } # end if

        while (@values) {
            my $name  = shift @values;
            my $value = shift @values;

            croak qq<"$name" is not a valid property name.>
                if $name !~ $IDENTIFIER_REGEX;

            print {$handle} qq< $name='>, teamcity_escape($value), q<'>;
        } # end while
    } # end if

    print {$handle} "]\n";

    return;
} # end _emit_build_message_to_handle()


1; # Magic true value required at end of module.

__END__

=encoding utf8

=for stopwords perl STDOUT TeamCity

=head1 NAME

TeamCity::BuildMessages - Encode and emit messages that TeamCity can interpret during a build.


=head1 VERSION

This document describes TeamCity::BuildMessages version 0.999.3.


=head1 SYNOPSIS

    use TeamCity::BuildMessages qw< :all >;

    my $escaped = teamcity_escape('stuff with weird characters');

    teamcity_emit_build_message('messageName', 'value');
    teamcity_emit_build_message(
        'messageName',
        propertyName => 'property value',
    );
    teamcity_emit_build_message('messageName', %properties);


=head1 DESCRIPTION

The code in this module is based upon the documentation at
L<http://www.jetbrains.net/confluence/display/TCD3/Build+Script+Interaction+with+TeamCity>.


=head1 INTERFACE

Nothing is exported by default, but you can import everything using the
C<:all> tag.


=over

=item C<teamcity_escape($text)>

Returns a version of the parameter with TeamCity escapes applied to it, e.g.
C<\n> becomes C<|n>.


=item C<teamcity_emit_build_message($message_name, $property_value)> or C<< teamcity_emit_build_message($message_name, property1 => 'value1', property2 => 'value2', ...) >>

Writes a message to STDOUT in a form that TeamCity can understand.  See the
TeamCity documentation for valid messages.


=back


=head1 DIAGNOSTICS

=over

=item No message specified.

C<teamcity_emit_build_message()> was called without a C<$message_name>
parameter.


=item No values specified.

C<teamcity_emit_build_message()> was called without any message values.


=item "%s" is not a valid message name.

C<teamcity_emit_build_message()> was called with a <$message_name> parameter
that didn't consist of a letter or underscore followed by any number of
alphanumerics and underscores.


=item Message property given without a value.

C<teamcity_emit_build_message()> was called with an odd number of property
values.  If there is more than one value given, each value must have a name,
e.g. this is wrong:

    teamcity_emit_build_message('message', 'one', 'two', 'three');


=item "%s" is not a valid property name.

C<teamcity_emit_build_message()> was called with a property name that didn't
consist of a letter or underscore followed by any number of alphanumerics and
underscores.


=back


=head1 CONFIGURATION AND ENVIRONMENT

None, currently.


=head1 DEPENDENCIES

perl 5.8.4

L<Readonly>


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright ©2008-2009, Elliot Shank C<< <perl@galumph.com> >>.  Some rights
reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


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
# setup vim: set foldmethod=indent foldlevel=0 :
