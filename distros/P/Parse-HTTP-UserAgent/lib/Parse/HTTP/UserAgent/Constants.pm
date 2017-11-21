package Parse::HTTP::UserAgent::Constants;
$Parse::HTTP::UserAgent::Constants::VERSION = '0.42';
use strict;
use warnings;
use base qw( Exporter );

our(@EXPORT, @EXPORT_OK, %EXPORT_TAGS);

use constant LIST_ROBOTS => qw(
    Wget
    curl
    libwww-perl
    GetRight
    Googlebot
    Baiduspider+
    msnbot
    bingbot
), 'Yahoo! Slurp';

BEGIN {
    my @fields = (
        'IS_EXTENDED',
        'IS_MAXTHON',           # Is this the dumb IE faker?
        'IS_PARSED',            # _parse() happened or not
        'IS_TRIDENT',           # Thanks to Microsoft, this now has a meaning
        'UA_DEVICE',            # the name of the mobile device
        'UA_DOTNET',            # [MSIE] List of .NET CLR versions
        'UA_EXTRAS',            # Extra stuff (Toolbars?) non parsable junk
        'UA_GENERIC',           # parsed with a generic parser.
        'UA_LANG',              # the language of the ua interface
        'UA_MOBILE',            # partially implemented
        'UA_MOZILLA',           # [Firefox] Mozilla revision
        'UA_NAME',              # The identifier of the ua
        'UA_ORIGINAL_NAME',     # original name if this is some variation
        'UA_ORIGINAL_VERSION',  # original version if this is some variation
        'UA_OS',                # Operating system
        'UA_PARSER',            # the parser name
        'UA_ROBOT',             # Is this a robot?
        'UA_STRENGTH',          # [MSIE] List of .NET CLR versions
        'UA_STRING',            # just for information
        'UA_STRING_ORIGINAL',   # just for information
        'UA_TABLET',            # partially implemented
        'UA_TOOLKIT',           # [Opera] ua toolkit
        'UA_TOUCH',             # windows only?
        'UA_UNKNOWN',           # failed to detect?
        'UA_VERSION',           # used for numerical ops. via qv()
        'UA_VERSION_RAW',       # the parsed version
        'UA_WAP',               # unimplemented
    );

    my $oid   = -1;
    my %field = map { $_ => ++$oid } @fields;
    my %const = (
        %field,
        LAST_ELEMENT           => -1,
        MAXID                  => $oid,
        NO_IMATCH              => -1, # for index()

        RE_CHAR_SLASH_WS       => qr{ [/\s]                                 }xms,
        RE_COMMA               => qr{ [,]                                   }xms,
        RE_DIGIT               => qr{ [0-9]                                 }xms,
        RE_DIGIT_DOT_DIGIT     => qr{ \d+ [.]? \d                           }xms,
        RE_DOTNET              => qr{ \A [.]NET (?: \s+ CLR \s+ )? (.+?) \z }xms,
        RE_EPIPHANY_GECKO      => qr{ \A (Epiphany) / (.+?) \z              }xmsi,
        RE_FIREFOX_NAMES       => qr{ Firefox|Iceweasel|Firebird|Phoenix    }xms,
        RE_HTTP                => qr{ http://                               }xms,
        RE_IX86                => qr{ \s i\d86                              }xms,
        RE_OBJECT_ID           => qr{ \A UA_                                }xms,
        RE_OPERA_MINI          => qr{ \A (Opera \s+ Mini) / (.+?) \z        }xms,
        RE_SC_WS               => qr{ ; \s?                                 }xms,
        RE_SC_WS_MULTI         => qr{ ; \s+?                                }xms,
        RE_SLASH               => qr{ /                                     }xms,
        RE_SPLIT_PARSE         => qr{ \s? ([()]) \s?                        }xms,
        RE_TWO_LETTER_LANG     => qr{ \A [a-z]{2} \z                        }xms,
        RE_WARN_INVALID        => qr{ \QVersion string\E .+? \Qcontains invalid data; ignoring:\E}xms,
        RE_WARN_OVERFLOW       => qr{ \QInteger overflow in version\E       }xms,
        RE_WHITESPACE          => qr{ \s+ }xms,
        RE_WINDOWS_OS          => qr{ \A Win(dows|NT|[0-9]+)?               }xmsi,

        ERROR_MAXTHON_MSIE     => 'Unable to extract MSIE from Maxthon UA-string',
        ERROR_MAXTHON_VERSION  => 'Unable to extract Maxthon version from Maxthon UA-string',

        OPERA9                 => 9,
        OPERA_FAKER_EXTRA_SIZE => 4,
        OPERA_TK_LENGTH        => 5,

        TK_NAME                => 0,
        TK_ORIGINAL_VERSION    => 1,
        TK_VERSION             => 2,
    );

    $const{INSIDE_UNIT_TEST}    = $ENV{PARSE_HTTP_USERAGENT_TEST_SUITE} ? 1 : 0;
    $const{INSIDE_VERBOSE_TEST} = $const{INSIDE_UNIT_TEST}
                                    && $ENV{HARNESS_IS_VERBOSE} ? 1 : 0;

    require constant;
    constant->import( \%const );
}

BEGIN {
    %EXPORT_TAGS = (
        object_ids => [qw(
            IS_PARSED
            IS_MAXTHON
            IS_TRIDENT
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
            UA_TOUCH
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

=encoding UTF-8

=head1 NAME

Parse::HTTP::UserAgent::Constants

=head1 VERSION

version 0.42

=head1 DESCRIPTION

Internal module

=head1 NAME

Parse::HTTP::UserAgent::Constants - Various constants

=head1 SEE ALSO

L<Parse::HTTP::UserAgent>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
