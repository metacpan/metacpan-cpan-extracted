package Parse::HTTP::UserAgent::Constants;
use strict;
use warnings;
use vars qw( $VERSION $OID @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

$VERSION = '0.39';

use constant INIT_FIELD_COUNTER  => -1;
use constant NO_IMATCH           => -1; # for index()
use constant LAST_ELEMENT        => -1;

BEGIN { $OID = INIT_FIELD_COUNTER }

use constant UA_STRING           => ++$OID; # just for information
use constant UA_STRING_ORIGINAL  => ++$OID; # just for information
use constant UA_UNKNOWN          => ++$OID; # failed to detect?
use constant UA_GENERIC          => ++$OID; # parsed with a generic parser.
use constant UA_NAME             => ++$OID; # The identifier of the ua
use constant UA_VERSION_RAW      => ++$OID; # the parsed version
use constant UA_VERSION          => ++$OID; # used for numerical ops. via qv()
use constant UA_OS               => ++$OID; # Operating system
use constant UA_LANG             => ++$OID; # the language of the ua interface
use constant UA_TOOLKIT          => ++$OID; # [Opera] ua toolkit
use constant UA_EXTRAS           => ++$OID; # Extra stuff (Toolbars?) non parsable junk
use constant UA_DOTNET           => ++$OID; # [MSIE] List of .NET CLR versions
use constant UA_STRENGTH         => ++$OID; # [MSIE] List of .NET CLR versions
use constant UA_MOZILLA          => ++$OID; # [Firefox] Mozilla revision
use constant UA_ROBOT            => ++$OID; # Is this a robot?
use constant UA_WAP              => ++$OID; # unimplemented
use constant UA_MOBILE           => ++$OID; # partially implemented
use constant UA_TABLET           => ++$OID; # partially implemented
use constant UA_PARSER           => ++$OID; # the parser name
use constant UA_DEVICE           => ++$OID; # the name of the mobile device
use constant UA_ORIGINAL_NAME    => ++$OID; # original name if this is some variation
use constant UA_ORIGINAL_VERSION => ++$OID; # original version if this is some variation
use constant IS_PARSED           => ++$OID; # _parse() happened or not
use constant IS_MAXTHON          => ++$OID; # Is this the dumb IE faker?
use constant IS_EXTENDED         => ++$OID;
use constant MAXID               =>   $OID;

use constant TK_NAME             => 0;
use constant TK_ORIGINAL_VERSION => 1;
use constant TK_VERSION          => 2;

use constant INSIDE_UNIT_TEST    => $ENV{PARSE_HTTP_USERAGENT_TEST_SUITE};
use constant INSIDE_VERBOSE_TEST => INSIDE_UNIT_TEST && $ENV{HARNESS_IS_VERBOSE};
use constant RE_FIREFOX_NAMES    => qr{Firefox|Iceweasel|Firebird|Phoenix }xms;
use constant RE_DOTNET           => qr{ \A [.]NET (?: \s+ CLR \s+ )? (.+?) \z    }xms;
use constant RE_WINDOWS_OS       => qr{ \A Win(dows|NT|[0-9]+)?           }xmsi;
use constant RE_SLASH            => qr{ /                                 }xms;
use constant RE_SPLIT_PARSE      => qr{ \s? ([()]) \s?                    }xms;
use constant RE_OPERA_MINI       => qr{ \A (Opera \s+ Mini) / (.+?) \z    }xms;
use constant RE_TRIDENT          => qr{ \A (Trident) / (.+?) \z           }xmsi;
use constant RE_EPIPHANY_GECKO   => qr{ \A (Epiphany) / (.+?) \z          }xmsi;
use constant RE_WHITESPACE       => qr{ \s+ }xms;
use constant RE_SC_WS            => qr{;\s?}xms;
use constant RE_SC_WS_MULTI      => qr{;\s+?}xms;
use constant RE_HTTP             => qr{ http:// }xms;
use constant RE_DIGIT            => qr{[0-9]}xms;
use constant RE_IX86             => qr{ \s i\d86 }xms;
use constant RE_OBJECT_ID        => qr{ \A UA_ }xms;
use constant RE_CHAR_SLASH_WS    => qr{[/\s]}xms;
use constant RE_COMMA            => qr{ [,] }xms;
use constant RE_TWO_LETTER_LANG  => qr{ \A [a-z]{2} \z }xms;
use constant RE_DIGIT_DOT_DIGIT  => qr{\d+[.]?\d}xms;

use constant RE_WARN_OVERFLOW => qr{\QInteger overflow in version\E}xms;
use constant RE_WARN_INVALID  => qr{\QVersion string\E .+? \Qcontains invalid data; ignoring:\E}xms;

use constant ERROR_MAXTHON_VERSION  => 'Unable to extract Maxthon version from Maxthon UA-string';
use constant ERROR_MAXTHON_MSIE     => 'Unable to extract MSIE from Maxthon UA-string';
use constant OPERA9                 => 9;
use constant OPERA_TK_LENGTH        => 5;
use constant OPERA_FAKER_EXTRA_SIZE => 4;

use constant LIST_ROBOTS         => qw(
    Wget
    curl
    libwww-perl
    GetRight
    Googlebot
    Baiduspider+
    msnbot
    bingbot
), 'Yahoo! Slurp';

use base qw( Exporter );

BEGIN {
    %EXPORT_TAGS = (
        object_ids => [qw(
            IS_PARSED
            IS_MAXTHON
            IS_EXTENDED
            UA_STRING
            UA_STRING_ORIGINAL
            UA_UNKNOWN
            UA_GENERIC
            UA_NAME
            UA_VERSION_RAW
            UA_VERSION
            UA_OS
            UA_LANG
            UA_TOOLKIT
            UA_EXTRAS
            UA_DOTNET
            UA_MOZILLA
            UA_STRENGTH
            UA_ROBOT
            UA_WAP
            UA_MOBILE
            UA_TABLET
            UA_PARSER
            UA_DEVICE
            UA_ORIGINAL_NAME
            UA_ORIGINAL_VERSION
            MAXID
        )],
        re => [qw(
            RE_FIREFOX_NAMES
            RE_DOTNET
            RE_WINDOWS_OS
            RE_SLASH
            RE_SPLIT_PARSE
            RE_OPERA_MINI
            RE_TRIDENT
            RE_EPIPHANY_GECKO
            RE_WHITESPACE
            RE_SC_WS
            RE_SC_WS_MULTI
            RE_HTTP
            RE_DIGIT
            RE_IX86
            RE_OBJECT_ID
            RE_CHAR_SLASH_WS
            RE_COMMA
            RE_TWO_LETTER_LANG
            RE_DIGIT_DOT_DIGIT
            RE_WARN_OVERFLOW
            RE_WARN_INVALID
        )],
        list => [qw(
            LIST_ROBOTS
        )],
        tk => [qw(
            TK_NAME
            TK_ORIGINAL_VERSION
            TK_VERSION
        )],
        etc => [qw(
            NO_IMATCH
            LAST_ELEMENT
            INSIDE_UNIT_TEST
            INSIDE_VERBOSE_TEST
        )],
        error => [qw(
            ERROR_MAXTHON_VERSION
            ERROR_MAXTHON_MSIE
        )],
        opera => [qw(
            OPERA9
            OPERA_TK_LENGTH
            OPERA_FAKER_EXTRA_SIZE
        )],
    );

    @EXPORT_OK        = map { @{ $_ } } values %EXPORT_TAGS;
    $EXPORT_TAGS{all} = [ @EXPORT_OK ];
}

1;

__END__

=pod

=head1 NAME

Parse::HTTP::UserAgent::Constants - Various constants

=head1 DESCRIPTION

This document describes version C<0.39> of C<Parse::HTTP::UserAgent::Constants>
released on C<2 December 2013>.

Internal module

=head1 SEE ALSO

L<Parse::HTTP::UserAgent>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2009 - 2013 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.
=cut
