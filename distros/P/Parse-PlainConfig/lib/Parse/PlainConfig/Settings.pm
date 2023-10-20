# Parse::PlainConfig::Settings -- Settings Class
#
# (c) 2016, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Parse/PlainConfig/Settings.pm, 3.06 2023/09/23 19:24:20 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Parse::PlainConfig::Settings;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION);

($VERSION) = ( q$Revision: 3.06 $ =~ /(\d+(?:\.\d+)+)/sm );

use Paranoid;
use Paranoid::Debug;
use Parse::PlainConfig::Constants qw(:all);
use Class::EHierarchy qw(:all);
use vars qw(@ISA @_properties @_methods);

@ISA = qw(Class::EHierarchy);

@_properties = (
    [ CEH_PUB | CEH_SCALAR, 'tab stop',       DEFAULT_TAB ],
    [ CEH_PUB | CEH_SCALAR, 'subindentation', DEFAULT_SUBI ],
    [ CEH_PUB | CEH_SCALAR, 'comment',        DEFAULT_CMMT ],
    [ CEH_PUB | CEH_SCALAR, 'delimiter',      DEFAULT_PDLM ],
    [ CEH_PUB | CEH_SCALAR, 'list delimiter', DEFAULT_LDLM ],
    [ CEH_PUB | CEH_SCALAR, 'hash delimiter', DEFAULT_HDLM ],
    [ CEH_PUB | CEH_SCALAR, 'here doc',       DEFAULT_HDOC ],
    [ CEH_PUB | CEH_HASH,   'property types' ],
    [ CEH_PUB | CEH_HASH,   'property regexes' ],
    [ CEH_PUB | CEH_HASH,   'prototypes' ],
    [ CEH_PUB | CEH_HASH,   'prototype regexes' ],
    [ CEH_PUB | CEH_HASH,   'prototype registry' ],
    [ CEH_PUB | CEH_SCALAR, 'error' ],
    [ CEH_PUB | CEH_ARRAY,  '_ppcClasses' ],
    );

#####################################################################
#
# Module code follows
#
#####################################################################

sub tabStop {
    my $obj = shift;
    return $obj->get('tab stop');
}

sub subindentation {
    my $obj = shift;
    return $obj->get('subindentation');
}

sub comment {
    my $obj = shift;
    return $obj->get('comment');
}

sub delimiter {
    my $obj = shift;
    return $obj->get('delimiter');
}

sub listDelimiter {
    my $obj = shift;
    return $obj->get('list delimiter');
}

sub hashDelimiter {
    my $obj = shift;
    return $obj->get('hash delimiter');
}

sub hereDoc {
    my $obj = shift;
    return $obj->get('here doc');
}

sub propertyTypes {
    my $obj = shift;
    return $obj->get('property types');
}

sub propertyRegexes {
    my $obj = shift;
    return $obj->get('property regexes');
}

sub prototypes {
    my $obj = shift;
    return $obj->get('prototypes');
}

sub prototypeRegexes {
    my $obj = shift;
    return $obj->get('prototype regexes');
}

1;

__END__

=head1 NAME

Parse::PlainConfig::Settings - Settings Class

=head1 VERSION

$Id: lib/Parse/PlainConfig/Settings.pm, 3.06 2023/09/23 19:24:20 acorliss Exp $

=head1 SYNOPSIS

    use Parse::PlainConfig::Settings;

    my $settings = new Parse::PlainConfig::Settings;

    $ts         = $settings->tabStop;
    $subindent  = $settings->subindentation;
    $comment    = $settings->comment;
    $delim      = $settings->delimiter;
    $ldelim     = $settings->listDelimiter;
    $hdelim     = $settings->hashDelimiter;
    $hdoc       = $settings->hereDoc;
    %propTypes  = $settings->propertyTypes;
    %propRegex  = $settings->propertyRegexes;
    %prototypes = $settings->prototypes;
    %protoRegex = $settings->prototypeRegexes;

=head1 DESCRIPTION

The settings object is created and initialized automatically by
L<Parse::PlainConfig>.

=head1 SUBROUTINES/METHODS

=head2 tabStop

    $ts         = $settings->tabStop;

Default column width for tab stops.

=head2 subindentation

    $subindent  = $settings->subindentation;

Default columns for indentation on line continuations.

=head2 comment

    $comment    = $settings->comment;

Default character sequence for comments.

=head2 delimiter

    $delim      = $settings->delimiter;

Default character sequence used as the delimiter between the parameter name
and the parameter value.

=head2 listDelimiter

    $ldelim     = $settings->listDelimiter;

Default character sequence used as the delimiter between array elements.

=head2 hashDelimiter

    $hdelim     = $settings->hashDelimiter;

Default character sequence used as the delimiter between key/value pairs.

=head2 hereDoc

    $hdoc       = $settings->hereDoc;

Default character sequence used as the token marking the end of here docs.

=head2 propertyTypes

    %propTypes  = $settings->propertyTypes;

Hash of property names => data types.

=head2 propertyRegexes

    %propRegex  = $settings->propertyRegexes;

Hash of property names to regular expression to extract data from the line.

=head2 prototypes

    %prototypes = $settings->prototypes;

Hash of prototype names => data types.

=head2 prototypeRegexes

    %protoRegex = $settings->prototypeRegexes;

Hash of prototype names to regular expression to extract data from the line.

=head1 DEPENDENCIES

=over

=item o

L<Class::EHierarchy>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Parse::PlainConfig::Constants>

=back

=head1 BUGS AND LIMITATIONS 

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2016, Arthur Corliss (corliss@digitalmages.com)

