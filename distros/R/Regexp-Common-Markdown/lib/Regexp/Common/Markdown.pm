##----------------------------------------------------------------------------
## Markdown Common Regular Expressions - ~/lib/Regexp/Common/Markdown.pm
## Version v0.1.7
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/08/01
## Modified 2025/10/21
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Regexp::Common::Markdown;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use Regexp::Common qw( pattern );
    use Regexp::Common qw( URI );
    use Regexp::Common qw( Email::Address );
    use Regexp::Common::URI::RFC2396 qw /$host $port $path_segments $query/;
    ## We use URI::tel instead of Regexp::Common::tel because its regular expression is antiquated
    ## URI::tel uses the latest rfc3966
    use URI::tel;
    # no warnings qw( experimental::vlb );
    our $VERSION = 'v0.1.7';

    our $SPACE_RE = qr/[[:blank:]\h]/;
    ## Including vertical space like new lines
    our $SPACE_EXTENDED_RE = qr/[[:blank:]\h\v]/;
    # Guards to keep other patterns from firing inside code
    our $MD_SKIP_FENCED = qr/
        (?:(?<=\n)|\A)
        [ ]{0,3}
        (?<fence>`{3,}|~{3,})[^\n]*\n
        (?:
            (?![ ]{0,3}\k<fence>[ \t]*\r?(?:\n|\z))
            .*(?:\n|\z)
        )*
        [ ]{0,3}\k<fence>[ \t]*\r?(?:\n|\z)
        (*SKIP)(*F)
    /xms;

    our $MD_SKIP_INDENTED = qr/
        (?:(?<=\n)|\A)
        (?:
            (?:[ ]{4}|\t).*(?:\n|\z)
        )+
        (*SKIP)(*F)
    /xms;

    # `code` and `` code with ` inside ``
    our $MD_SKIP_INLINE_CODE = qr/
        (?<!`)
        (`+)(?!`)
        (?: .*? )
        \1(?!`)
        (*SKIP)(*F)
    /xms;

    our $ATTRIBUTE_RE = qr/
        [\w\-]+
        $SPACE_EXTENDED_RE*
        =
        $SPACE_EXTENDED_RE*
        (?:
            \"[^\"]+\"  # attribute="value"
            |
            \'[^\']+\'  # attribute='value'
            |
            \S+         # attribute=value
        )
        $SPACE_EXTENDED_RE*
    /x;
    our $LIST_TYPE_ORDERED = qr/(?<list_ordered>\d+[\.])/;

    our $LIST_TYPE_UNORDERED_MINUS = qr/
        (?<list_unordered_minus>
            [\-]
            (?!
                (?:
                    [ ]?[\-][ ]?
                ){2,}
            )
        )
    /x;

    our $LIST_TYPE_UNORDERED_PLUS = qr/(?<list_unordered_plus>[\+])/;

    our $LIST_TYPE_UNORDERED_STAR = qr/
        (?<list_unordered_star>
            [\*]
            (?!                     # Make sure not to catch horizontal lines marked with stars
                (?:
                    [ ]?[\*][ ]?
                ){2,}
            )
        )
    /x;

    our $LIST_TYPE_UNORDERED = qr/
        $LIST_TYPE_UNORDERED_STAR
        |
        $LIST_TYPE_UNORDERED_MINUS
        |
        $LIST_TYPE_UNORDERED_PLUS
    /x;

    # Taken from Markdown original author, John Gruber's original regular expression
    # See <https://regex101.com/r/RfhRVg/4/> to see it in action
    our $LIST_ALL = qr/
        (?<list_all>                                                            # whole list
            (?<list_prefix>                                                     # list prefix and type
                [\s]{0,3}
                (?<list_type_any>                                               # Any of posible list prefix, but that aviod atching also horizontal rules
                    (?:
                        (?<list_type_unordered_star>(?&list_unordered_star))
                        |
                        (?<list_type_unordered_minus>(?&list_unordered_minus))
                        |
                        (?<list_type_unordered_plus>(?&list_unordered_plus))
                        |
                        (?<list_type_ordered>(?&list_ordered))
                    )
                )
                [ \t]+
            )
            (?<list_content>(?s:.+?))                                           # list content
            (?<list_after>
                \z
                |
                \n{2,}
                (?=\S)
                (?!                                                             # Negative lookahead for another list item marker
                    [ \t]*
                    (?<list_type_any2>
                        (?:
                        (?<list_type_unordered_star2>(?&list_unordered_star))
                        |
                        (?<list_type_unordered_minus2>(?&list_unordered_minus))
                        |
                        (?<list_type_unordered_plus2>(?&list_unordered_plus))
                        |
                        (?<list_type_ordered2>(?&list_ordered))
                        )
                    )
                    [ \t]+
                )
            )
        )
        (?(DEFINE)                                      # Definition block for recursive pattern matching
$LIST_TYPE_UNORDERED_STAR
$LIST_TYPE_UNORDERED_MINUS
$LIST_TYPE_UNORDERED_PLUS
$LIST_TYPE_ORDERED
        )
    /mx;

    # NOTE: global variables to build URI regular expressions compatible with IDN (rfc3986)
    our $HTTP_RFC2396_HOST = qr/$host/;
    # RFC 3986 / IDN host helpers
    # Accept "." and the IDNA dot equivalents
    our $IDN_DOT = qr/[.\x{3002}\x{FF0E}\x{FF61}]/;
    # ACE punycode prefix
    our $ACE     = qr/xn--/i;

    # RFC 3986: IPv6 literal inside [ ... ]
    # (very permissive; we only need the bracketed form to avoid false positives)
    our $IP_LITERAL = qr/\[(?:[0-9A-Fa-f:.]+)\]/;

    # IDN label (≤63 chars) with ACE or Unicode 3rd–4th hyphen rule
    our $IDN_U_LABEL = qr/
        (?:                                     # punycode label… (xn--)
            $ACE [\p{L}\p{N}\p{M}\p{Pc}-]{1,59}
            |
            (?! [\p{L}\p{N}]{2}-- )             # forbid "--" at pos 3–4 unless ACE
            [\p{L}\p{N}]                        # first
            [\p{L}\p{N}\p{M}\p{Pc}-]{0,61}      # middle
            (?<!-)                              # no trailing hyphen
        )
    /ux;

    # IDN hostname: one or more labels separated by IDNA dots (atomic to reduce backtracking)
    our $IDN_HOST = qr/(?>$IDN_U_LABEL(?:$IDN_DOT$IDN_U_LABEL)*)/ux;
    # our $IDN_HOST = qr/(?>$IDN_U_LABEL(?:$IDN_DOT$IDN_U_LABEL)* $IDN_DOT?)/ux;

    # Unicode-friendly “tail” for path/query in inline links (non-<…> case).
    # RFC 3986 pchar allows pct-enc; for Markdown it is usually safer to “stop at obvious enders”.
    our $UNICODE_PATHQ = qr{ [^<>"'\s\)]* }ux;

    # RFC3986/IDN superset host: ASCII host-or-IPv4 (previous one based on RFC2396), or IDN host, or IPv6 literal
    my $HTTP_RFC3986_HOST = qr/
        (?:
            # (1) previous ASCII host-or-IPv4 branch based on RFC2396:
            $HTTP_RFC2396_HOST
            |
            # (2) New: Unicode IDN hostname
            $IDN_HOST
            |
            # (3) New: IPv6 literal in brackets
            $IP_LITERAL
        )
    /x;

    # Full HTTP(S) URI using RFC2396 path/query (strict ASCII), suitable for angle-bracket autolinks.
    our $HTTP_RFC3986_URI = qr{
        (?:
            (?:http|https)://
            $HTTP_RFC3986_HOST
            (?:: $port )?
            (?: /
                (?:
                    $path_segments
                    (?: \? $query )?
                )
            )?
        )
    }x;

    our $HTTP_R3986_URI_INLINE = qr{
        (?:
            (?:http|https)://
            $HTTP_RFC3986_HOST
            (?:: $port )?
            (?: / $UNICODE_PATHQ )?
            (?: \? $UNICODE_PATHQ )?
        )
    }x;

    our $REGEXP =
    {
    # NOTE: Bold
    # https://regex101.com/r/Jp2Kos/3
    bold => qr/
        (?<!\\)                         # Check it was not escaped with a \
        (?<bold_all>
            (?<bold_type>\*{2}|\_{2})   # Emphasis type: * or _
            (?=                         # followed by non-space
                (?:
                    (?:[_*`\$\\])       # avoid punctuation except those
                    |
                    (?![[:punct:]])
                )
            \S)
            (?<bold_text>.+?[*_]*)      # enclosed text
            (?<=\S)                     # making sure preceding stuff was a non-space
            \g{bold_type}               # Balanced closing tag
        )
    /x,

    # NOTE: blockquote
    # Code borrowed from original Markdown author: John Gruber
    # https://regex101.com/r/TdKq0K/1
    bquote => qr/
        (?<bquote_all>                  # Wrap whole match in $1
            (?>
                ^[ \t]*>[ \t]?          # '>' at the start of a line
                .+\n                    # rest of the first line
                (?<bquote_other>.+\n)*  # subsequent consecutive lines
                \n*                     # blanks
            )+
        )
    /xm,

    # NOTE: code block
    # ```
    # Some code
    # ```
    # https://regex101.com/r/M6W99K/7
    # 2025-10-21: Updated
    # - Allows optional info string after the opening fence (ignored in base mode)
    # - Closes with the same fence run length & char
    # - Works with up to 3 leading spaces per CommonMark
    code_block => qr/
        (?:(?<=\n)|(?<=\A))            # Necessarily at the begining of a new line or start of string
        (?<code_all>
            [ ]{0,3}                   # Possibly up to 3 leading spaces
            (?<code_start>             # CAPTURE ONLY the fence run
                \`{3,}
            )
            [ \t]* [^\n]*              # optional info string (ignored in base)
            \n
            (?<code_content>.*?)       # enclosed content
            \n
            [ ]{0,3}                   # up to 3 leading spaces on the closer line
            (?<!`)                     # closer not preceded by a backtick
            \g{code_start}             # close with the SAME fence run
            (?!`)                      # not followed by a backtick
            [ \t]*                     # optional trailing spaces
            \n                         # final newline (keep strict like your original)
        )
    /xms,

    # NOTE: code line
    # Marked by left hand indentation
    # https://regex101.com/r/toEboU/3
    code_line => qr/
        (?:(?<=^\n)|(?<=\A))            # Starting at beginning of string or with 2 new lines
        (?<code_all>
            (?:
                (?<code_prefix>         # Lines must start with a tab or a tab-width of spaces
                    [ ]{4}
                    |
                    \t
                )
                (?<code_content>.*\n+)  # with some content, possibly nothing followed by a new line
            )+
        )
        (?<code_after>
            (?=^[ ]{0,4}\S)             # Lookahead for non-space at line-start
            |
            \Z                          # or end of doc
        )
    /xm,

    # NOTE: code span
    # \x{0060} is ` in unicode; see perl -le 'printf "\\x%x", ord( "`" )'
    # Updated on 2025-10-19 to change the 'code_start', and 'code_content'
    # from (?<code_content>.+?) to (?:[^`]|`(?!\g{code_start}))*?
    # Updated on 2025-10-21 to guard from capturing fenced blocks and indented codes
    code_span => qr{
        (?: $MD_SKIP_FENCED | $MD_SKIP_INDENTED )
        |
        (?<!\\)                             # Ensuring this is not escaped
        (?<code_all>
            (?!^[ ]{0,3}`{3,}[^\n]*\n)      # not a fence opener (needs /m)
            (?<code_start>`+)               # opening, capture N backticks
            (?<code_content>                # allow single ` inside when using more ticks
                (?:[^`]|`(?!\g{code_start}))*?
            )
            (?<!`)                          # close not preceded by `
            \g{code_start}                  # balanced closing ticks
        )
    }xms,

    # NOTE: emphasis
    # https://regex101.com/r/eDb6RN/5
    em => qr/
        (?<!\\|\*|\_)               # Check it was not escaped with a \
        (?<em_all>
            (?<em_type>\*|\_)       # Emphasis type: * or _
            (?=\S)                  # followed by non-space
            (?<em_text>.+?)         # enclosed text
            (?<=\S)                 # making sure preceding stuff was a non-space
            (?<!\\|\*|\_)           # no preceded by any * or _
            \g{em_type}             # Balanced closing tag
        )
   /x,

    # NOTE: headers
    # Headers: #, ##, ###, ####, #####, ###### become h1..6
    # atx-style headers:
    #   # Header 1
    #   ## Header 2
    #   ## Header 2 with closing hashes ##
    #   ...
    #   ###### Header 6
    # https://regex101.com/r/9uQwBk/6
    # 2025-10-19: Added safeguards $MD_SKIP_FENCED and $MD_SKIP_INDENTED
    # other change avoids “#######” lines with no content and the occasional 7+ “#” oddity.
    header => qr/
        (?: $MD_SKIP_FENCED | $MD_SKIP_INDENTED )
        |
        (?<header_all>
            ^
            (?<!\\)                         # Make sure this is not escaped
            (?<header_level>\#{1,6})        # 1..6 # only
            [ \t]*                          # Possibly followed by some spaces or tabs
            (?![ \t]*$)                     # must have some content
            (?<header_content>.*?)          # Possibly followed by some spaces or tabs or some dashes (don't need to match the opening ones)
            [ \t\#]*                        # optional closing hashes or spaces
            \n
        )
    /mx,

    # NOTE: setext-style headers
    # Setext-style headers:
    #     Header 1
    #     ========
    #  
    #     Header 2
    #     --------
    #
    # This is to be on a single line of its own
    # https://regex101.com/r/sQLEqz/4
    # 2025-10-19: Added safeguards $MD_SKIP_FENCED and $MD_SKIP_INDENTED
    header_line => qr/
        (?: $MD_SKIP_FENCED | $MD_SKIP_INDENTED ) |
        (?<header_all>
            ^
            (?<header_content>.+?)          # Header content
            [ \t]*                          # Possibly followed by spaces or tabs
            \n                              # With then a new line
            (?<!\\)                         # Making sure this is not escaped
            (?<header_type>={3,}|-{3,})     # underline, 3+ to avoid list dashes noise
            [ \t]*                          # Possibly followed by spaces or tabs
            \n                              # Terminated by a new line
        )
    /mx,

    # NOTE: html
    # https://regex101.com/r/SH8ki3/4
    # 2025-10-18: Added safeguards to exclude html embedded within code blocks
    html => qr/
        #---------------------------------------------------------
        # 0) Indented-code guard
        #---------------------------------------------------------
        $MD_SKIP_INDENTED
        |
        #---------------------------------------------------------
        # 1) Ignore fenced code blocks (```lang … ``` or ~~~ … ~~~)
        #    We match them first, then (*SKIP)(*F) so the engine
        #    jumps past the whole block and resumes searching after it.
        #---------------------------------------------------------
        (?:
            (?<=\n) | \A                  # start of line or start of string
        )
        [ ]{0,3}                          # up to 3 leading spaces per CommonMark
        (?<fence>`{3,}|~{3,})[^\n]*\n     # opening fence with optional info string
        (?:
            (?![ ]{0,3}\k<fence>[ \t]*\r?(?:\n|\z))   # not the closing fence line
            .*(?:\n|\z)                               # consume a whole line
        )*
        [ ]{0,3}\k<fence>[ \t]*\r?(?:\n|\z) # closing fence
        (*SKIP)(*F)                         # skip this whole region and fail this alt
        |
        #---------------------------------------------------------
        # 2) The actual HTML matcher
        #---------------------------------------------------------
        (?:(?<=\n)|(?<=\A))                # Necessarily at the begining of a new line or start of string
        (?<leading_space>[ ]{0,3})
        (?<tag_all>
            (?:
                (?<tag_open>
                    <(?<tag_name>\S+)
                        [^\>]*
                    >\n*
                )
                (?<html_content>.+?)
                \n*
                (?<tag_close>
                    (?(<leading_space>)                     # If leading spaces were found
                        (?:
                            (?<=\n)\g{leading_space}        # Either there is a symmetry in leading space for open and closing tag
                            |
                            (?:(?<=\S)[[:blank:]\h]*)       # or the closing tag is on the same line with preceding data
                        )
                        |
                        (?=<[[:blank:]\h\v]*\/[[:blank:]\h\v]*\g{tag_name}[[:blank:]\h\v]*>)                # No leading space, so we don't expect anything before the closing tag other than what has already been caught in the 'content'
                    )
                    <[[:blank:]\h\v]*\/[[:blank:]\h\v]*\g{tag_name}[[:blank:]\h\v]*>
                )
                [[:blank:]\h]*\n
            )
            |
            (?:
                <!--[[:blank:]\h\v]*(?<html_comment>.*?)[[:blank:]\h\v]*-->
            )
            |
            (?:
                <
                    [[:blank:]\h\v]*
                    (?<tag_name>[a-zA-Z0-9][\w\-]+)
                    (?<tag_attributes>(?&tag_attr))*
                    [[:blank:]\h\v]*
                    \/?
                    [[:blank:]\h\v]*
                >
            )
        )
        (?(DEFINE)
            (?<tag_attr>
                (?:
                    [[:blank:]\h]*
                    [\w\-]+
                    [[:blank:]\h]*
                    =
                    [^\"\'[:blank:]\h]+
                    [[:blank:]\h]*
                )
                |
                (?:
                    [[:blank:]\h]*
                    [\w\-]+
                    [[:blank:]\h]*
                    =
                    [[:blank:]\h]*
                    (?<quote>["'])
                    (.*?)
                    \g{quote}
                    [[:blank:]\h]*
                )
            )
        )
    /xsm,

    # NOTE: image
    # Basically same as link, except there is an exclamation mark (!) just before:
    # Ex: ![alt text](url "optional title")
    # https://regex101.com/r/z0yH2F/10
    # 2025-10-19: Added safeguard $MD_SKIP_INLINE_CODE
    img => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<!\\)                                             # Check it was not escaped with a \
        (?<img_all>
            \!\[(?<img_alt>.+?)\]                           # image alternative text, i.e. the text used when the image does not
            (?:
                (?:
                    [ ]?                                    # possibly followed by some spaces
                    (?:\n[ ]*)?                             # and a new line with some space
                    \[(?<img_id>.*?)\]                      # with the link id in brackets, but may be empty
                )
                |
                (?:
                    (?:
                        \(
                            [ \t]*
                            <(?<img_url>                    # link url within <>; or
                                .+?
                            )>
                            [ \t]*                              # possibly followed by some spaces or tabs
                            (?:
                                (?<img_title_container>['"])    # Title is surrounded ether by double or single quotes
                                (?<img_title>.*?)               # actual title, but could be empty as in ""
                                \g{img_title_container}         # make the sure enclosing mark balance
                            )?
                            [ \t]*
                        \)
                    )
                    |
                    (?:
                        \(
                            [ \t]*
                            (?<img_url>                    # link url within <>; or
                                (?:((?!["']).)*+|.*)
                            )
                            [ \t]*
                            (?:
                                (?<img_title_container>['"])    # Title is surrounded ether by double or single quotes
                                (?<img_title>.*?)               # actual title, but could be empty as in ""
                                \g{img_title_container}         # make the sure enclosing mark balance
                            )?
                            [ \t]*
                        \)
                    )
                )
            )
        )
    /xm,

#     ^[ ]{0,2}([ ]?\*[ ]?){3,}[ \t]*$
    # NOTE: line
    # Horizontal line
    # https://daringfireball.net/projects/markdown/syntax#hr
    # https://regex101.com/r/Vlew4X/2
    # 20215-10-19: group the repeated unit atomically.
    line => qr/
        ^                               # At start of line
        $SPACE_RE{0,2}                  # with up to 3 spaces before
        (?<!\\)                         # Make sure this is not escaped
        (?<line_all>
            (?:
                $SPACE_RE?
                (?<line_type>\*|\-|\_)  # asterisk, hyphen or underscore
                $SPACE_RE?              # possibly followed by spaces
            ){3,}                       # 3 or more occurences
        )
        [ \t]*
        $                               # end of line or end of string
    /mx,

    # NOTE: line break
    # https://regex101.com/r/6VG46H/1
    line_break => qr/
        (?<br_all>
            [ ]{2,}\n
        )
    /mx,

    # NOTE: Link
    # https://daringfireball.net/projects/markdown/syntax#link
    # https://regex101.com/r/sGsOIv/10
    # Links' id can be multiline, so we need the /s modifier
    # 2025-10-19 Added safeguard $MD_SKIP_INLINE_CODE
    link => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<link_all>                                        # Check it was not escaped with a \
            (?:(?:\\|\!)\[(*SKIP)(*FAIL)|\[)                # Cannot be preceded by an anti-slash nor an exclamation mark (image)
            (?<link_name>
                (?!\^)                                      # Make sure, this is not confused with a footnote
                (?>\\[\[\]]|[^\[\]])*+                      # Link text
            )
            (?<!\\)
            \]
            (?:
                (?:
                    [ ]?                                    # possibly followed by some spaces
                    (?:\n[ ]*)?                             # and a new line with some space
                    (?<!\\)\[
                        (?!\^)                              # Make sure, this is not confused with a footnote
                        (?<link_id>.*?)
                    (?<!\\)\]                               # with the link id in brackets, but may be empty
                )
                |
                (?:
                    (?<!\\)\(                               # Get the link, from the most specific to the least one
                        [ \t]*
                        (?:
                            <(?<link_url>.*?)>              # link url within <>; or
                            |
                            (?<link_url>                    # link url without <>
                                $HTTP_R3986_URI_INLINE
                            )
                            |
                            (?<link_url>.*?)
                        )
                        [ \t]*                              # possibly followed by some spaces or tabs
                        (?:
                            (?<link_title_container>['"])   # Title is surrounded ether by double or single quotes
                            (?<link_title>.*?)              # actual title, but could be empty as in ""
                            \g{link_title_container}        # make sure the enclosing mark balance
                        )?
                        [ \t]*
                    (?<!\\)\)
                    (?![[:blank:]\h]+["'][^"']+["'])
                )
            )
        )
    /xms,

    # NOTE: link auto
    # https://regex101.com/r/bAUu1E/4/
    # 2025-10-19: Added safeguard $MD_SKIP_INLINE_CODE
    #             Added labels 'link_idn_http', 'link_idn_https', 'link_v6_http', and 'link_v6_https'
    link_auto => qr{
        $MD_SKIP_INLINE_CODE
        |
        (?<!\\)                     # Make sure this is not escaped
        (?<link_all>
            <
            (?<link_url>
                (?<link_http>$RE{URI}{HTTP})                        # http
                |
                (?<link_https>$RE{URI}{HTTP}{-scheme => 'https'})   # https
                |
                (?<link_ftp>$RE{URI}{FTP})                          # ftp
                |
                (?<link_tel>$URI::tel::TEL_URI)                     # tel
                |
                (?<link_file>$RE{URI}{file})                        # file
                |
                (?<link_news>$RE{URI}{news})                        # news
                |
                (?<link_mailto>(?:mailto\:)?$RE{Email}{Address})    # email address: mailto:john@example.com or simply john@example.com
                |
                (?<link_idn_http>  http://  $IDN_HOST  (?::(?:$port))?(?:/(?:(?:$path_segments)(?:[?](?:$query))?))? )  # IDN http hosts
                |
                (?<link_idn_https> https:// $IDN_HOST  (?::(?:$port))?(?:/(?:(?:$path_segments)(?:[?](?:$query))?))? )  # IDN https hosts
                |
                (?<link_v6_http>   http://  $IP_LITERAL (?::(?:$port))?(?:/(?:(?:$path_segments)(?:[?](?:$query))?))? ) # IPv6 http hosts
                |
                (?<link_v6_https>  https:// $IP_LITERAL (?::(?:$port))?(?:/(?:(?:$path_segments)(?:[?](?:$query))?))? ) # IPv6 https hosts
            )
            >
        )
    }x,

    # NOTE: link definition
    # Definition
    # https://daringfireball.net/projects/markdown/syntax#link
    # https://regex101.com/r/edg2F7/3
    link_def => qr/
        ^[ ]{0,3}                                       # Leading space up to 3
        (?<link_all>
            (?<!\\)\[                                   # ID within brackets
                (?!\^)                                  # Make sure, this is not confused with a footnote
                (?<link_id>.+?)
            (?<!\\)\]
            [ \t]*                                      # Possibly with some space before colon
            \:
            [ \t]*\n?[ \t]*                             # Possibly with some space after the colon, possibly with a new line in between?
            (?:
                <(?<link_url>[^\>]+)>                   # link within <>
                |
                (?<link_url>\S+)                        # or link without <>
            )
            (?:
                (?:
                    [ \t]+                              # Either some space or tabs
                    |
                    [ \t]*\n[ \t]*                      # or a new line surrounded by 0 or more spaces or tabs
                )
                (?:
                    (?:
                        (?<link_title_container>['"])   # Title is surrounded ether by double or single quotes
                        (?<link_title>.+?)
                        \g{link_title_container}        # make the sure enclosing mark balance
                    )
                    |                                   # or
                    \((?<link_title>[^\)]+)\)           # by parenthesis
                )
            )?
            [ \t]*                      # Possibly ending with some trailing spaces or tab
        )
        (?:\n+|\Z)                      # terminated by a new line or end of file
    /xm,

    # NOTE: link reference
    # Link with reference to link definition id
    # https://daringfireball.net/projects/markdown/syntax#link
    # https://regex101.com/r/QmyfnH/1/
    # The /s switch is required for link name spawning multiple lines: [Some\nlink][]
    # 2025-10-19: Added safeguard $MD_SKIP_INLINE_CODE
    link_ref => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<link_all>
            (?<!\\)\[(?<link_name>.+?)(?<!\\)\] # link name in brackets, but could also be used as the link id if link id is empty
            [ ]?                                # possibly followed by some spaces
            (?:\n[ ]*)?                         # and a new line with some space
            (?<!\\)\[(?<link_id>.*?)(?<!\\)\]   # with the link id in brackets, but may be empty
        )
    /xms,

    # NOTE: list type ordered
    # regular expression for list, ordered or unordered
    list_type_ordered => $LIST_TYPE_ORDERED,

    # NOTE: list type unordered
    list_type_unordered => $LIST_TYPE_UNORDERED,

    # NOTE: list all
    # Taken from Markdown original author, John Gruber's original regular expression
    list => $LIST_ALL,

    # NOTE: list first level
    # https://regex101.com/r/RfhRVg/5
    list_first_level => qr/
        (?:(?<=^\n)|(?<=\A))
        $LIST_ALL
    /mx,

    # NOTE: list nth level
    list_nth_level => qr/
        ^
        $LIST_ALL
    /mx,

    # NOTE: list item
    # Minor deviation from John Gruber's original regular expression
    # Changed [ \t]+ to [ \t]* and .+? to .*? so that it catches empty list item, like:
    # *
    # * Something
    # https://regex101.com/r/bulBCP/1/
    list_item => qr/
        (?<li_all>
            (?<li_lead_line>\n)?                                                        # leading line
            (?<li_lead_space>^[ \t]*)                                                   # leading whitespace
            (?<list_type_any>                                                           # list marker
                (?:
                    (?:
                        (?<list_type_unordered_star>(?&list_unordered_star))
                        |
                        (?<list_type_unordered_minus>(?&list_unordered_minus))
                        |
                        (?<list_type_unordered_plus>(?&list_unordered_plus))
                    )
                    |
                    (?<list_type_ordered>(?&list_ordered))
                )
            )
            [ \t]*
            (?<li_content>(?s:.*?)                                                      # list item text
            (\n{1,2}))
            (?= \n*
                (
                    \z
                    |
                    \g{li_lead_space}
                    (?<list_type_any2>
                        (?:
                            (?:
                                (?<list_type_unordered_star2>(?&list_unordered_star))
                                |
                                (?<list_type_unordered_minus2>(?&list_unordered_minus))
                                |
                                (?<list_type_unordered_plus2>(?&list_unordered_plus))
                            )
                            |
                            (?<list_type_ordered2>(?&list_ordered))
                        )
                    )
                    [ \t]*
                )
            )
        )
        (?(DEFINE)                                      # Definition block for recursive pattern matching
$LIST_TYPE_UNORDERED_STAR
$LIST_TYPE_UNORDERED_MINUS
$LIST_TYPE_UNORDERED_PLUS
$LIST_TYPE_ORDERED
        )
    /xm,

    # NOTE: paragraph
    # https://regexr.com/5929n
    # https://regex101.com/r/0B3gR4/5
    # 2025-10-19: updated to add safeguard, and improved 'para_content' to avoid swallowing definitions/footnotes/HTML starts.
    paragraph => qr/
        (?: $MD_SKIP_FENCED | $MD_SKIP_INDENTED )
        |
        (?:(?<=^\n)|(?<=\A))                        # Needs 1 or more new lines or start of string
        (?<para_all>
            (?<para_prefix>[ ]{0,3})                # Possibly some leading spaces, but less than a tab worth
            (?<para_content>
                (?:
                    (?!                             # some line content not starting with those exceptions
                        [[:blank:]\h]{0,3}
                        (?:
                            \*{1}[ \t]+                 # a list
                            |
                            (?:\*(?:[ ]?\*){2,})        # a horizontal line
                            |
                            (?:\-*(?:[ ]?\-){2,})       # a horizontal line
                            |
                            (?:\_*(?:[ ]?\_){2,})       # a horizontal line
                            |
                            [>+-=\#]                    # bq, heading, setext line, etc.
                            |
                            \d+\.                       # ordered list
                            |
                            \`{3,}                      # code block (fenced)
                            |
                            \~{3,}                      # code block extended
                            |
                            \[ [^\]\n]+ \] [ \t]*:      # link def [id]:
                            |
                            \[\^ [^\]\n]+ \] [ \t]*:    # footnote def [^id]:
                            |
                            <[A-Za-z]                   # HTML block start
                        )
                    )
                    .+
                    (?!\n(?:[=-]+))
                    (?:\n|$)
                )+
            )
        )
    /mx
    };

    # NOTE: extended regular expressions
    # Extended regular expression
    our $REGEXP_EXT =
    {
    # NOTE: abbreviation
    # Ex: *[HTML]: Hyper Text Markup Language
    # This is similar, but different from definitions
    # https://regex101.com/r/ztM2Pw/2/
    ex_abbr => qr/
        (?<abbr_all>
            (?<!\\)\*
            (?<!\\)\[(?<abbr_name>.+?)(?<!\\)\]
            [[:blank:]\h]*
            \:
            [[:blank:]\h]+
            (?<abbr_value>.*?)
            (?:\n|\z)
        )
    /x,

    # NOTE: checkbox
    # https://regex101.com/r/ezMwsv/1/
    ex_checkbox => qr/
        (?<check_all>
            [ ]?
            \[(?<check_content>X|[[:blank:]\h])\]
            [ ]+
            (?=\S+)
        )
    /xi,

    # NOTE: code block extended
    # This is same as the regular code block, except this allows for a code class or a code definition with class, id, etc.
    # https://regex101.com/r/Y9lPAz/10
    # 2025-10-21: Updated
    ex_code_block => qr/
        (?:(?<=\n)|(?<=\A))                            # Necessarily at the begining of a new line or start of string
        (?<code_all>
            [ ]{0,3}                                   # Possibly up to 3 leading spaces
            (?<code_start>                             # CAPTURE ONLY the fence run
                (?<with_backtick>[`]{3,})              # 3 code marks (backticks) or more
                |
                (?<with_tilde>[~]{3,})                 # or 3 code marks (tilde) or more
            )
            [ \t]*
            (?:
                (?:                                    # .class[.class] {attrs}?   OR   .class only
                    (?<code_class>(?&_code_class))
                    (?:
                        [ \t]*
                        \{ [[:blank:]\h]* (?<code_attr>(?&_code_attr)) [[:blank:]\h]* \}
                    )?
                )
              |                                        # OR  {attrs} only
                \{ [[:blank:]\h]* (?<code_attr>(?&_code_attr)) [[:blank:]\h]* \}
            )?
            \n+
            (?<code_content>.*?)                       # enclosed content
            \n+
            [ ]{0,3}                                   # Possibly up to 3 leading spaces on the closing line
            \g{code_start}                             # balanced closing block marks (backticks or tildes)
            [ \t]*                                     # possibly followed by some space
            (?:\n|\Z)                                  # contrary to the vanilla version, we allow for no double line-break
        )
        (?(DEFINE)
            (?<_code_class>     [\w\-.]+)
            (?<_code_attr>      [^}]+)
        )
    /xms,

    # NOTE: footnote extended
    # https://regex101.com/r/WuB1FR/2/
    ex_footnote => qr/
        (?<footnote_all>
            ^[ ]{0,3}
            \[\^(?<footnote_id>.+?)\][ ]?:      # footnote id
            [ ]*
            \n?					                # maybe *one* newline
            (?<footnote_text>					# footnote text (no blank lines allowed)
                (?:
                    .+				            # actual text
                    |
                    \n				            # newlines but
                    (?!\[.+?\][ ]?:\s)          # negative lookahead for footnote or link definition marker.
                    (?!\n+[ ]{0,3}\S)           # ensure line is not blank and followed
                                                # by non-indented content
                )*
            )
        )
    /xm,

    # NOTE: footnote reference extended
    # https://regex101.com/r/3eO7rJ/1/
    ex_footnote_ref => qr/
        (?<footnote_all>                        # 3 possible patterns
            (?:
                \[\^(?<footnote_id>.*?)\]       # extended patterns with possibly null id
                [[:blank:]\h]*                  # possibly some spaces
                \((?<footnote_text>.+?)\)       # and some text in parenthesis
            )
            |
            (?:
                \[\^(?<footnote_id>.+?)\]       # regular footnote with a mandatory id
                (?![[:blank:]\h]*\((?:.+?)\))   # but not followed by enclosing parenthesis
            )
            |
            (?:
                \^\[(?<footnote_text>.+?)\]     # inline footnote with auto-generated id à la pandoc
            )
        )
    /xms,

    # NOTE: header extended
    # atx-style headers:
    #   # Header 1
    #   ## Header 2
    #   ## Header 2 with closing hashes ##
    #   ...
    #   ###### Header 6
    # ## Le Site ##    {.main .shine #the-site lang=fr}
    # Same as regular header + parameters insides curly braces in between
    # https://regex101.com/r/GyzbR2/3
    # 2025-10-19: Added safeguard
    #             Limited level to 6
    #             Must have some text in 'header_content'
    ex_header => qr/
        (?: $MD_SKIP_FENCED | $MD_SKIP_INDENTED )
        |
        (?<header_all>
            ^
            (?<!\\)                     # Make sure this is not escaped
            (?<header_level>\#{1,6})    # one or more #
            [ \t]*                      # Possibly followed by some spaces or tabs
            (?![ \t]*\{)                # Do not allow only attributes as “content”
            (?<header_content>.+?)      # Header content enclosed
            [ \t\#]*                    # Possibly followed by some spaces or tabs or some dashes (don't need to match the opening ones)
            (?<!\\)                     # Making sure it is not escaped
            \{
                [[:blank:]\h]*          # Possibly with some spaces
                (?<header_attr>[^\}]*)  # and attributes instead braces
            \}
            \n                          # Terminated by a new line
        )
    /xm,

    # NOTE: setext-style headers
    # Setext-style headers:
    #     Header 1 {.main .shine #the-site lang=fr}
    #     ========
    #  
    #     Header 2 {.main .shine #the-site lang=fr}
    #     --------
    #
    # This is to be on a single line of its own
    # https://regex101.com/r/berfAR/4
    # 2025-10-19: Added safeguard
    #             Added a limit to the number of header marker: up to 3
    ex_header_line => qr/
        (?: $MD_SKIP_FENCED | $MD_SKIP_INDENTED )
        |
        (?<header_all>
            ^
            (?<header_content>.+)       # Header content
            [ \t]*
            (?<!\\)                     # Making sure it is not escaped
            \{
                [[:blank:]\h]*          # Possibly with some spaces
                (?<header_attr>.+?)     # and attributes instead braces
                [[:blank:]\h]*
            \}
            [ \t]*                      # Possibly followed by spaces or tabs
            \n                          # With then a new line
            (?<!\\)                     # Making sure this is not escaped
            (?<header_type>={3,}|-{3,}) # Multiple = or -, up to 3
            [ \t]*                      # Possibly followed by spaces or tabs
            \n                          # Terminated by a new line
        )
    /mx,

    # NOTE: html extended
    # https://regex101.com/r/M6KCjp/3
    ex_html_markdown => qr/
        (?<html_markdown_all>
            (?<mark_pat1>
                (?:\n|\A)
                (?<div_open>
                    (?<leading_space>[[:blank:]\h]*)
                    <(?<tag_name>\S+)
                        (?>
                            [[:blank:]\h\v]+[\w\_]+(?:[[:blank:]\h]*\=[[:blank:]\h]*["'][^"']*['"])?
                        )*
                        [[:blank:]\h\v]+markdown[[:blank:]\h]*\=[[:blank:]\h]*(?<quote>["']?)1\g{quote}
                        [^\>]*
                    >\n*
                )
                (?<content>.+?)
                \n*
                (?<div_close>
                    (?(<leading_space>)                     # If leading spaces were found
                        (?:
                            (?<=\n)\g{leading_space}              # Either there is a symmetry in leading space for open and closing tag
                            |
                            (?:(?<=\S)[[:blank:]\h]*)       # or the closing tag is on the same line with preceding data
                        )
                        |
                        (?=<\/\g{tag_name}>)                # No leading space, so we don't expect anything before the closing tag other than what has already been caught in the 'content'
                    )
                    <\/\g{tag_name}>
                )
                [[:blank:]\h]*\n
            )
            |
            (?<mark_pat2>
                (?<=\S)
                (?<div_open>
                    (?<leading_space>[[:blank:]\h]*)
                    <(?<tag_name>\S+)
                        (?>
                            [[:blank:]\h\v]+[\w\_]+(?:[[:blank:]\h]*\=[[:blank:]\h]*["'][^"']*['"])?
                        )*
                        [[:blank:]\h\v]+markdown[[:blank:]\h]*\=[[:blank:]\h]*(?<quote>["'])?1\g{quote}
                        [^\>]*
                    >
                )
                (?<content>.+?)
                (?<div_close>
                    [[:blank:]\h]*
                    <\/\g{tag_name}>
                )
                (?=\S|[[:blank:]\h\v]*)
            )
        )
    /xms,

    # NOTE: image extended
    # https://regex101.com/r/xetHV1/4
    # 2025-10-19: Added safeguard $MD_SKIP_INLINE_CODE
    ex_img => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<!\\)                                             # Check it was not escaped with a \
        (?<img_all>
            \!\[(?<img_alt>.+?)\]                           # image alternative text, i.e. the text used when the image does not
            (?:
                (?:
                    [ ]?                                    # possibly followed by some spaces
                    (?:\n[ ]*)?                             # and a new line with some space
                    \[(?<img_id>.*?)\]                      # with the link id in brackets, but may be empty
                )
                |
                (?:
                    (?:
                        \(
                            [ \t]*
                            <(?<img_url>                    # link url within <>; or
                                .+?
                            )>
                            [ \t]*                              # possibly followed by some spaces or tabs
                            (?:
                                (?<img_title_container>['"])    # Title is surrounded ether by double or single quotes
                                (?<img_title>.*?)               # actual title, but could be empty as in ""
                                \g{img_title_container}         # make the sure enclosing mark balance
                            )?
                            [ \t]*
                        \)
                    )
                    |
                    (?:
                        \(
                            [ \t]*
                            (?<img_url>                    # link url within <>; or
                                (?:((?!["']).)*+|.*)
                            )
                            [ \t]*
                            (?:
                                (?<img_title_container>['"])    # Title is surrounded ether by double or single quotes
                                (?<img_title>.*?)               # actual title, but could be empty as in ""
                                \g{img_title_container}         # make the sure enclosing mark balance
                            )?
                            [ \t]*
                        \)
                    )
                )
            )
            [ \t]*
            (?<!\\)
            \{
                [[:blank:]\h]*
                (?<img_attr>.+?)
                [[:blank:]\h]*
            \}
        )
    /x,

    # NOTE: insertion extended
    # https://regex101.com/r/IZw4YU/1/
    # 2025-10-19: Added safeguard $MD_SKIP_INLINE_CODE
    ex_insertion => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<ins_all>                     # insertion can be multilines
            (?<!\\)\+{2}                # Start with 2 +
            (?!\n)                      # but not followed by a new line to avoid any previous + getting caught
            (?<ins_content>             # the content which excludes any + unless they are escaped
                (?>\\[\+]|[^\+])*+
            )
            (?<!\\)\+{2}                # terminated by 2 +
        )
    /xm,

    # NOTE: katex dollar
    # https://regex101.com/r/43OuNT/1/
    # 2025-10-19: Added safeguard $MD_SKIP_INLINE_CODE
    ex_katex_dollar2 => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<!\\|\$)
        (?<katex_open>\${2})
        (?!\$)
        \n?
        (?<katex_content>.+?)\n?
        (?<!\\|\$)
        (?<katex_close>\g{katex_open})
        (?!\$)
        \n?
    /mxs,
    ex_katex_dollar1 => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<!\\|\$)
        (?<katex_open>\${1})
        (?!\$)
        \n?
        (?<katex_content>.+?)\n?
        (?<!\\|\$)
        (?<katex_close>\g{katex_open})
        (?!\$)
        \n?
    /mxs,
    # NOTE: katex bracket
    ex_katex_bracket => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<!\\)
        (?<katex_open>\\\[)
        \n?
        (?<katex_content>.+?)\n?
        (?<!\\)
        (?<katex_close>
            \\\]
        )\n?
    /mxs,
    # NOTE: katex parens
    ex_katex_parens => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<!\\)
        (?<katex_open>\\\()
        \n?
        (?<katex_content>.+?)\n?
        (?<!\\)
        (?<katex_close>
            \\\)
        )\n?
    /mxs,

    # NOTE: line break extended
    # https://regex101.com/r/6VG46H/1
    ex_line_break => qr/
        (?<br_all>
            (?:[ ]{2,}\n|\n)
        )
    /mx,

    # NOTE: link extended
    # [Hyperlinked text](http://www.example.com)
    # [Hyperlinked text](http://www.example.com "Example Site")
    # https://regex101.com/r/7mLssJ/7
    # 2025-10-19: Added safeguard $MD_SKIP_INLINE_CODE
    ex_link => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<link_all>
            (?:(?:\\|\!)\[(*SKIP)(*FAIL)|\[)                # Cannot be preceded by an anti-slash nor an exclamation mark (image)
                (?<link_name>
                    (?!\^)                                  # Make sure, this is not confused with a footnote
                    (?>\\[\[\]]|[^\[\]])*+                  # Link text
                )
            (?<!\\)\]
            (?:
                (?:
                    [ ]?
                    (?:\n[ ]*)?
                    (?<!\\)\[
                        (?!\^)                              # Make sure, this is not confused with a footnote
                        (?<link_id>.*?)
                    (?<!\\)\]                               # with the link id in brackets, but may be empty
                )
                |
                (?:
                    (?<!\\)\(                               # Get the link, from the most specific to the least one
                        [ \t]*
                        (?:
                            <(?<link_url>.*?)>
                            |
                            (?<link_url>                    # link url without <>
                                $HTTP_R3986_URI_INLINE
                            )
                            |
                            (?<link_url>.*?)
                        )
                        [ \t]*
                        (?:
                            (?<link_title_container>['"])
                            (?<link_title>.*?)
                            \g{link_title_container}
                        )?
                        [ \t]*
                    (?<!\\)\)
                    (?![[:blank:]\h]+["'][^"']+["'])
                )
            )
            [ \t]*
            (?<!\\)
            \{
                [[:blank:]\h]*
                (?<link_attr>.+?)
                [[:blank:]\h]*
            \}
        )
    /x,

    # NOTE: link definition extended
    # https://regex101.com/r/hVfXCe/3
    ex_link_def => qr/
        ^[ ]{0,3}                                       # Leading space up to 3
        (?<link_all>
            (?<!\\)\[                                   # ID within brackets
                (?!\^)                                  # Make sure, this is not confused with a footnote
                (?<link_id>.+?)
            (?<!\\)\]
            [ \t]*                                      # Possibly with some space before colon
            \:
            [ \t]*\n?[ \t]*                             # Possibly with some space after the colon, possibly with a new line in between?
            (?:
                <(?<link_url>[^\>]+)>                   # link within <>
                |
                (?<link_url>\S+)                        # or link without <>
            )
            (?:
                (?:
                    [ \t]+                              # Either some space or tabs
                    |
                    [ \t]*\n[ \t]*                      # or a new line surrounded by 0 or more spaces or tabs
                )
                (?:
                    (?:
                        (?<link_title_container>['"])   # Title is surrounded ether by double or single quotes
                        (?<link_title>.+?)
                        \g{link_title_container}        # make the sure enclosing mark balance
                    )
                    |                                   # or
                    \((?<link_title>[^\)]+)\)           # by parenthesis
                )
            )?
            [ \t]*
            (?<!\\)
            \{
                [[:blank:]\h]*
                (?<link_attr>.+?)
                [[:blank:]\h]*
            \}
            [ \t]*                      # Possibly ending with some trailing spaces or tab
        )
        (?:\n+|\Z)                      # terminated by a new line or end of file
    /xm,

    # NOTE: markdown attributes
    # Ex: {#id1} or {.cl} or {#id.cl.class}
    md_attributes1 => qr/(?<!\\)\{$SPACE_RE*(?<attr>[^\}]*)\}/,

    # NOTE: subscript extended
    # https://regex101.com/r/gF6wVe/2
    # 2025-10-19: Added safeguard $MD_SKIP_INLINE_CODE
    ex_subscript => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<sub_all>
            (?:
                (?<!\\)\~
                (?<sub_text>
                    (?>\\[\~[:blank:]\h]|[^\~[:blank:]\h\v])*+
                )
                (?<!\\)\~
            )
            |
            (?:     # or the Microsoft way. Beurk
                \<sub\>
                (?<sub_text>
                    ((?!\v).)+
                )
                \<\/sub\>
            )
        )
    /x,

    # NOTE: superscript extended
    # https://regex101.com/r/yAcNcX/1/
    # 2025-10-19: Added safeguard $MD_SKIP_INLINE_CODE
    ex_superscript => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<sup_all>
            (?:
                (?<!\\)\^
                (?<sup_text>
                    (?>\\[\^[:blank:]\h]|[^\^[:blank:]\h\v])*+
                )
                (?<!\\)\^
            )
            |
            (?:     # or the Microsoft way. Beurk
                \<sup\>
                (?<sup_text>
                    ((?!\v).)+
                )
                \<\/sup\>
            )
        )
    /x,

    # NOTE: strikethrough extended
    # https://regex101.com/r/4Z3h4F/1/
    # 2025-10-19: Added safeguard $MD_SKIP_INLINE_CODE
    ex_strikethrough => qr/
        $MD_SKIP_INLINE_CODE
        |
        (?<strike_all>                  # strikethrough can be multilines
            (?<!\\)\~{2}                # Start with 2 tilde
            (?!\n)                      # but not followed by a new line to avoid any previous tildes getting caught
            (?<strike_content>          # the content which excludes any tilde unless they are escaped
                (?>\\[\~]|[^\~])*+
            )
            (?<!\\)\~{2}                # terminated by 2 tildes
        )
    /x,

    # NOTE: table extended
    # https://regex101.com/r/01XCqB/13
    # 2025-10-19: Added safeguard
    ex_table => qr/
        (?: $MD_SKIP_FENCED | $MD_SKIP_INDENTED )
        |
        (?:(?<=^\n)|(?<=\A))
        (?<table>
            (?<table_caption>(?&t_caption))?                    # maybe some caption at the top?
            (?<table_headers>
                (?<table_header>                                # Table header
                    (?<table_header_sep_top>(?&t_th_sep))?      # Possible top separator line
                    (?<table_header1>                           # First header row
                        [^\n]+\n
                    )
                    (?<table_header_sep>(?&t_th_sep))           # a separator
                    (?<table_header2>                           # and possibly a second row of header
                        [^\n]+\n
                        (?<table_header_sep>(?&t_th_sep))
                    )?
                )
            )
            (?<table_rows>                                      # Multiple table rows
                (?<table_row>(?&t_row))+
            )
            (?<table_bottom_sep>(?&t_th_sep))?                  # Possibly ended by a separator line
            (?<table_caption>(?&t_caption))?                    # and maybe with some caption at the bottom
            (?=\n|\Z)
        )
        (?(DEFINE)
            (?<t_th_sep>
                [\+\-\|](?:[\: ]*\-+[\: ]*[\+\-\|]?)+\n
            )
            (?<t_row>
                [ ]{0,3}
                (?!(?&t_th_sep)|(?&t_caption))
                (?:
                    (?<tr_start_mark>[\|\:]+)?
                    (?<tr_col_content>[^\|\:\n]+)
                    (?:
                        (?:[\|\:]{0,2}[ ]*(?=\n))
                        |
                        [\|\:]{1,2}
                    )
                )+
                (?:
                    (?:\n(?=(?&t_th_sep)))
                    |
                    (?:\n(?=(?&t_caption)))
                    |
                    \n
                )
            )
            (?<t_caption>
                [ ]{0,3}
                \[[^\]]+\]
                [ ]*
                \n
            )
        )
    /xms,
    },
};

pattern name    => [qw( Markdown -extended=1 ) ],
        create  => sub
        {
            my( $self, $flags ) = @_;
            my %re = %$REGEXP;
            ## Override vanilla regular expressions by the extended ones
            if( $flags->{'-extended'} )
            {
                my @k = keys( %$REGEXP_EXT );
                @re{ @k } = @$REGEXP_EXT{ @k };
            }
            my $pat =  join( '|' => values( %re ) );
            return( "(?k:$pat)" );
        };

pattern name    => [qw( Markdown Bold ) ],
        create  => $REGEXP->{bold};

pattern name    => [qw( Markdown Blockquote ) ],
        create  => $REGEXP->{bquote};

pattern name    => [qw( Markdown CodeBlock ) ],
        create  => $REGEXP->{code_block};

pattern name    => [qw( Markdown CodeLine ) ],
        create  => $REGEXP->{code_line };

pattern name    => [qw( Markdown CodeSpan ) ],
        create  => $REGEXP->{code_span};

pattern name    => [qw( Markdown Em ) ],
        create  => $REGEXP->{em};

pattern name    => [qw( Markdown Header ) ],
        create  => $REGEXP->{header};

pattern name    => [qw( Markdown HeaderLine ) ],
        create  => $REGEXP->{header_line};

pattern name    => [qw( Markdown Html ) ],
        create  => $REGEXP->{html};

pattern name    => [qw( Markdown Image ) ],
        create  => $REGEXP->{img};

pattern name    => [qw( Markdown Line ) ],
        create  => $REGEXP->{line};

pattern name    => [qw( Markdown LineBreak ) ],
        create  => $REGEXP->{line_break};

pattern name    => [qw( Markdown Link ) ],
        create  => $REGEXP->{link};

pattern name    => [qw( Markdown LinkAuto ) ],
        create  => $REGEXP->{link_auto};

pattern name    => [qw( Markdown LinkDefinition ) ],
        create  => $REGEXP->{link_def};

pattern name    => [qw( Markdown LinkRef ) ],
        create  => $REGEXP->{link_ref};

pattern name    => [qw( Markdown List ) ],
        create  => $REGEXP->{list};

pattern name    => [qw( Markdown ListFirstLevel ) ],
        create  => $REGEXP->{list_first_level};

pattern name    => [qw( Markdown ListNthLevel ) ],
        create  => $REGEXP->{list_nth_level};

pattern name    => [qw( Markdown ListItem ) ],
        create  => $REGEXP->{list_item};

pattern name    => [qw( Markdown Paragraph ) ],
        create  => $REGEXP->{paragraph};

pattern name    => [qw( Markdown ExtAbbr ) ],
        create  => $REGEXP_EXT->{ex_abbr};

pattern name    => [qw( Markdown ExtAttributes ) ],
        create  => $REGEXP_EXT->{md_attributes1};

pattern name    => [qw( Markdown ExtCheckbox ) ],
        create  => $REGEXP_EXT->{ex_checkbox};

pattern name    => [qw( Markdown ExtCodeBlock ) ],
        create  => $REGEXP_EXT->{ex_code_block};

pattern name    => [qw( Markdown ExtFootnote ) ],
        create  => $REGEXP_EXT->{ex_footnote};

pattern name    => [qw( Markdown ExtFootnoteReference ) ],
        create  => $REGEXP_EXT->{ex_footnote_ref};

pattern name    => [qw( Markdown ExtHeader ) ],
        create  => $REGEXP_EXT->{ex_header};

pattern name    => [qw( Markdown ExtHeaderLine ) ],
        create  => $REGEXP_EXT->{ex_header_line};

pattern name    => [qw( Markdown ExtHtmlMarkdown ) ],
        create  => $REGEXP_EXT->{ex_html_markdown};

pattern name    => [qw( Markdown ExtImage )],
        create  => $REGEXP_EXT->{ex_img};

pattern name    => [qw( Markdown ExtInsertion )],
        create  => $REGEXP_EXT->{ex_insertion};

# pattern name    => [qw( Markdown ExtKatex ), -delimiter=],
#         create  => $REGEXP_EXT->{ex_katex};
pattern name    => [qw( Markdown ExtKatex ), "-delimiter=\$\$,\$\$,\$,\$,\\\[,\\\],\\\(,\\\)"],
        create  => sub
        {
            my $delim = [split(/[[:blank:]\h]*\,[[:blank:]\h]*/, $_[1]->{'-delimiter'} )];
            my $map =
            {
            '$$$$'  => 'ex_katex_dollar2',
            '$$'    => 'ex_katex_dollar1',
            '\[\]'  => 'ex_katex_bracket',
            '\(\)'  => 'ex_katex_parens',
            };
            my $res = [];
            for( my $i = 0; $i < scalar( @$delim ); $i += 2 )
            {
                my $k = join( '', @$delim[ $i..$i+1 ] );
                push( @$res, $REGEXP_EXT->{ $map->{ $k } } ) if( exists( $map->{ $k } ) );
            }
            my $re;
            if( scalar( @$res ) )
            {
                my $re_spec = "(?<katex_all>\n" . join( "\n|\n", @$res ) . "\n)";
                $re = qr/$re_spec/mxs;
            }
            $re;
        };

pattern name    => [qw( Markdown ExtLineBreak ) ],
        create  => $REGEXP_EXT->{ex_line_break};

pattern name    => [qw( Markdown ExtLink ) ],
        create  => $REGEXP_EXT->{ex_link};

pattern name    => [qw( Markdown ExtLinkDefinition ) ],
        create  => $REGEXP_EXT->{ex_link_def};

pattern name    => [qw( Markdown ExtStrikeThrough ) ],
        create  => $REGEXP_EXT->{ex_strikethrough};

pattern name    => [qw( Markdown ExtSubscript ) ],
        create  => $REGEXP_EXT->{ex_subscript};

pattern name    => [qw( Markdown ExtSuperscript ) ],
        create  => $REGEXP_EXT->{ex_superscript};

pattern name    => [qw( Markdown ExtTable ) ],
        create  => $REGEXP_EXT->{ex_table};

1;
# NOTE: POD
__END__

=encoding utf-8

=pod

=head1 NAME

Regexp::Common::Markdown - Markdown Common Regular Expressions

=head1 SYNOPSIS

    use Regexp::Common qw( Markdown );

    while( <> )
    {
        my $pos = pos( $_ );
        /\G$RE{Markdown}{Header}/gmc   and  print "Found a header at pos $pos\n";
        /\G$RE{Markdown}{Bold}/gmc     and  print "Found bold text at pos $pos\n";
    }

=head1 VERSION

    v0.1.7

=head1 DESCRIPTION

This module provides Markdown regular expressions as set out by its original author L<John Gruber|https://daringfireball.net/projects/markdown/syntax>

There are different types of patterns: vanilla and extended. To get the extended regular expressions, use the C<-extended> switch.

You can use each regular expression by using their respective names: I<Bold>, I<Blockquote>, I<CodeBlock>, I<CodeLine>, I<CodeSpan>, I<Em>, I<HtmlOpen>, I<HtmlClose>, I<HtmlEmpty>, I<Header>, I<HeaderLine>, I<Image>, I<ImageRef>, I<Line>, I<Link>, I<LinkAuto>, I<LinkDefinition>, I<LinkRef>, I<List>

Almost all of the regular expressions use named capture. See L<perlvar/%+> for more information on named capture.

For example:

    if( $text =~ /$RE{Markdown}{LinkAuto}/ )
    {
        print( "Found https url \"$+{link_https}\"\n" ) if( $+{link_https} );
        print( "Found file url \"$+{link_file}\"\n" ) if( $+{link_file} );
        print( "Found ftp url \"$+{link_ftp}\"\n" ) if( $+{link_ftp} );
        print( "Found e-mail address \"$+{link_mailto}\"\n" ) if( $+{link_mailto} );
        print( "Found Found phone number \"$+{link_tel}\"\n" ) if( $+{link_tel} );
        my $url = URI->new( $+{link_https} );
    }

As a general rule, Markdown rule requires that the text being parsed be de-tabbed, i.e. with its tabs converted into 4 spaces. Those regular expressions reflect this principle.

=head1 STANDARD MARKDOWN

=head2 C<$RE{Markdown}>

This returns a pattern that recognises any of the supported vanilla Markdown formatting.
If you pass the C<-extended> parameter, some will be added and some of those regular expressions will be replaced by their extended ones, such as I<ExtAbbr>, I<ExtCodeBlock>, I<ExtLink>, I<ExtAttributes>

=head2 Blockquote

    $RE{Markdown}{Blockquote}

For example:

    > foo
    >
    > > bar
    >
    > foo

You can see example of this regular expression along with test units here: L<https://regex101.com/r/TdKq0K/1>

The capture names are:

=over 4

=item bquote_all

The entire capture of the blockquote.

=item bquote_other

The inner content of the blockquote.

=back

You can see also L<Markdown::Parser::Blockquote>

=head2 Bold

    $RE{Markdown}{Bold}

For example:

    **This is a text in bold.**

    __And so is this.__

You can see example of this regular expression along with test units here: L<https://regex101.com/r/Jp2Kos/3>

The capture names are:

=over 4

=item bold_all

The entire capture of the text in bold including the enclosing marker, which can be either C<**> or C<__>

=item bold_text

The text within the markers.

=item bold_type

The marker type used to highlight the text. This can be either C<**> or C<__>

=back

You can see also L<Markdown::Parser::Bold>

=head2 Code Block

    $RE{Markdown}{CodeBlock}

For example:

    ```
    Some text

        Indented code block sample code
    ```

You can see example of this regular expression along with test units here: L<https://regex101.com/r/M6W99K/7>

The capture names are:

=over 4

=item code_all

The entire capture of the code block, including the enclosing markers, such as C<```>

=item code_content

The content of the code enclosed within the 2 markers.

=item code_start

The enclosing marker used to mark the code. Typically C<```>.

=item code_trailing_new_line

The possible trailing new lines. This is used to detect if any were captured in order to put them back in the parsed text for the next markdown, since the last new lines of a markdown are alos the first new lines of the next ones and new lines are used to delimit markdowns.

=back

You can see also L<Markdown::Parser::Code>

=head2 Code Line

    $RE{Markdown}{CodeLine}

For example:

        the lines in this block  
        all contain trailing spaces  

You can see example of this regular expression along with test units here: L<https://regex101.com/r/toEboU/3>

The capture names are:

=over 4

=item code_after

This contains the data that follows the code block.

=item code_all

The entire capture of the code lines.

=item code_content

The content of the code.

=item code_prefix

This contains the leading spaces used to mark the code as code.

=back

You can see also L<Markdown::Parser::Code>

=head2 Code Span

    $RE{Markdown}{CodeSpan}

For example:

    This is some `inline code`

You can see example of this regular expression along with test units here: L<https://regex101.com/r/C2Vl9M/1>

The capture names are:

=over 4

=item code_all

The entire capture of the code lines.

=item code_start

Contains the marker that delimit the inline code. The delimiter is C<`>

=item code_content

The content of the code.

=back

You can see also L<Markdown::Parser::Code>

=head2 Emphasis

    $RE{Markdown}{Em}

For example:

    This routine parameter is _test_

You can see example of this regular expression along with test units here: L<https://regex101.com/r/eDb6RN/5>

You can see also L<Markdown::Parser::Emphasis>

=head2 Header

    $RE{Markdown}{Header}

For example:

    ### This is a H3 Header

    ### And so is this one ###

You can see example of this regular expression along with test units here: L<https://regex101.com/r/9uQwBk/4>

The capture names are:

=over 4

=item header_all

The entire capture of the code lines.

=item header_content

The text that is enclosed in the header marker.

=item header_level

This contains all the dashes that precedes the text. The number of dash indicates the level of the header. Thus, you could do something like this:

    length( $+{header_level} );

=back

You can see also L<Markdown::Parser::Header>

=head2 Header Line

    $RE{Markdown}{HeaderLine}

For example:

    This is an H1 header
    ====================

    And this is a H2
    -----------

You can see example of this regular expression along with test units here: L<https://regex101.com/r/sQLEqz/3>

The capture names are:

=over 4

=item header_all

The entire capture of the code lines.

=item header_content

The text that is enclosed in the header marker.

=item header_type

This contains the marker line used to mark the line above as header.

A line using C<=> is a header of level 1, while a line using C<-> is a header of level 2.

=back

You can see also L<Markdown::Parser::Header>

=head2 HTML

    $RE{Markdown}{Html}

For example:

    <div>
        foo
    </div>

You can see example of this regular expression along with test units here: L<https://regex101.com/r/SH8ki3/4>

The capture names are:

=over 4

=item html_all

The entire capture of the html block.

=item html_comment

If this html block is a comment, this will contain the data within the comment.

=item html_content

The inner content between the opning and closing tag. This could be more html block or some text.

This capture will not be available obviously for html tags that are "empty" by nature, such as C<<hr />>

=item tag_attributes

The attributes of the opening tag, if any. For example:

    <div title="Start" class="center large" id="extra_stuff">
        <span title="Brand name">MyWorld</span>
    </div>

Here, the attributes will be:

    title="Start" class="center large" id="extra_stuff"

=item tag_close

The closing tag, including enclosing brackets.

=item tag_name

This contains the name of the first html tag encountered, i.e. the one that starts the html block. For example:

    <div>
        <span title="Brand name">MyWorld</span>
    </div>

Here the tag name will be C<div>

=back

You can see also L<Markdown::Parser::HTML>

=head2 Image

    $RE{Markdown}{Image}

For example:

    ![Alt text](/path/to/img.jpg)

or

    ![Alt text](/path/to/img.jpg "Optional title")

or, with reference:

    ![alt text][foo]

You can see example of this regular expression along with test units here: L<https://regex101.com/r/z0yH2F/10>

The capture names are:

=over 4

=item img_all

The entire capture of the markdown, such as:

    ![Alt text](/path/to/img.jpg)

=item img_alt

The alternative tet to be displayed for this image. This is mandatory as per markdown, so it is guaranteed to be available.

=item img_id

If the image, is an image reference, this will contain the reference id. When an image id is provided, there is no url and no title, because the image reference provides those information.

=item img_title

This is the title of the image, which may not exist, since it is optional in markdown. The title is surrounded by single or double quote that are captured in I<img_title_container>

=item img_url

This is the url of the image.

=back

You can see also L<Markdown::Parser::Image>

=head2 Line

    $RE{Markdown}{Line}

For example:

    ---

or

    - - -

or

    ***

or

    * * *

or

    ___

or

    _ _ _


    $text =~ s{$RE{Markdown}{Line}}
    {
        # processing
    }gexm;

Note that this regular expression uses multiline switch and not the single line C</s> switch since a markdown horizontal line does not span multiple lines.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/Vlew4X/2>

The capture names are:

=over 4

=item line_all

The entire capture of the horizontal line.

=item line_type

This contains the marker used to set the line. Valid markers are C<*>, C<->, or C<_>

=back

See also L<Markdown original author reference for horizontal line|https://daringfireball.net/projects/markdown/syntax#hr>

You can see also L<Markdown::Parser::Line>

=head2 Line Break

    $RE{Markdown}{LineBreak}

For example:

    Mignonne, allons voir si la rose  
    Qui ce matin avait déclose  
    Sa robe de pourpre au soleil,  
    A point perdu cette vesprée,  
    Les plis de sa robe pourprée,  
    Et son teint au vôtre pareil.

To ensure arbitrary line breaks, each line ends with 2 spaces and 1 line break. This should become:

    Mignonne, allons voir si la rose<br />
    Qui ce matin avait déclose<br />
    Sa robe de pourpre au soleil,<br />
    A point perdu cette vesprée,<br />
    Les plis de sa robe pourprée,<br />
    Et son teint au vôtre pareil.

P.S.: If you're wondering, this is an extract from L<Ronsard|https://en.wikipedia.org/wiki/Pierre_de_Ronsard>.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/6VG46H/1/>

There is only one capture name: C<br_all>. This is basically used like this:

    if( $text =~ /\G$RE{Markdown}{LineBreak}/ )
    {
        print( "Found a line break\n" );
    }

Or

    $text =~ s/$RE{Markdown}{LineBreak}/<br \/>\n/gs;

You can see also L<Markdown::Parser::NewLine>

The capture name is:

=over 4

=item br_all

The entire capture of the line break.

=back

=head2 Link

    $RE{Markdown}{Link}

For example:

    [Inline link](https://www.example.com "title")

or

    [Inline link](/some/path "title")

or, without title

    [Inline link](/some/path)

or with a reference id:

    [reference link][refid]

    [refid]: /path/to/something (Title)

or, using the link text as the id for the reference:

    [My Example][]

    [My Example]: https://example.com (Great Example)

You can see example of this regular expression along with test units here: L<https://regex101.com/r/sGsOIv/10>

The capture names are:

=over 4

=item link_all

The entire capture of the link.

=item link_title_container

If there is a link title, this contains the single or double quote enclosing it.

=item link_id

The link reference id. For example here C<1> is the id.

    [Reference link 1 with parens][1]

=item link_name

The link text

=item link_title

The link title, if any.

=item link_url

The link url, if any

=back

You can see also L<Markdown::Parser::Link> and L<Regexp::Common::URI>

=head2 Link Auto

    $RE{Markdown}{LinkAuto}

Supports, http, https, ftp, newsgroup, local file, e-mail address or phone numbers

For example:

    <https://www.example.com>

would become:

    <a href="https://www.example.com">https://www.example.com</a>

An e-mail such as:

    <!#$%&'*+-/=?^_`.{|}~@example.com>

would become:

    <a href="mailto:!#$%&'*+-/=?^_`.{|}~@example.com>!#$%&'*+-/=?^_`.{|}~@example.com</a>

Other possible and valid e-mail addresses:

    <"abc@def"@example.com>

    <jsmith@[192.0.2.1]>

A file link:

    <file:///Volume/User/john/Document/form.rtf>

A newsgroup link:

    <news:alt.fr.perl>

A ftp uri:

    <ftp://ftp.example.com/plop/>

Phone numbers:

    <+81-90-1234-5678>

    <tel:+81-90-1234-5678>

You can see example of this regular expression along with test units here: L<https://regex101.com/r/bAUu1E/3>

The capture names are:

=over 4

=item link_all

The entire capture of the link.

=item link_file

A local file url, such as: C<ile:///Volume/User/john/Document/form.rtf>

=item link_ftp

Contains an ftp url

=item link_http

Contains an http url

=item link_https

Contains an https url

=item link_mailto

An e-mail address with or without the C<mailto:> prefix.

=item link_news

A newsgroup link url, such as C<news:alt.fr.perl>

=item link_tel

Contains a telephone url according to the L<rfc 3966|https://tools.ietf.org/search/rfc3966>

=item link_url

Contains the link uri, which contains one of I<link_file>, I<link_ftp>, I<link_http>, I<link_https>, I<link_mailto>, I<link_news> or I<link_tel>

=back

You can see also L<Markdown::Parser::Link>

=head2 Link Definition

    $RE{Markdown}{LinkDefinition}

For example:

    [1]: /url/  "Title"

    [refid]: /path/to/something (Title)

Extra care has been implemented to avoid link definition from being confused with footnotes:

    [^block]:
            Paragraph.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/edg2F7/3>

The capture names are:

=over 4

=item link_all

The entire capture of the link.

=item link_id

The link id

=item link_title

The link title

=item link_title_container

The character used to enclose the title, if any. This is either C<"> or C<'>

=item link_url

The link url

=back

You can see also L<Markdown::Parser::LinkDefinition>

=head2 Link Reference

    $RE{Markdown}{LinkRef}

Example:

    Foo [bar] [1].

    Foo [bar][1].

    Foo [bar]
    [1].

    [Foo][]

    [1]: /url/  "Title"
    [Foo]: https://www.example.com

You can see example of this regular expression along with test units here: L<https://regex101.com/r/QmyfnH/1>

The capture names are:

=over 4

=item link_all

The entire capture of the link.

=item link_id

The link reference id. For example here C<1> is the id.

    [Reference link 1 with parens][1]

=item link_name

The link text

=back

See also the L<reference on links by Markdown original author|https://daringfireball.net/projects/markdown/syntax#link>

You can see also L<Markdown::Parser::Link>

=head2 List

    $RE{Markdown}{List}

For example, an unordered list:

    *	asterisk 1

    *	asterisk 2

    *	asterisk 3

or, an ordered list:

    1. One item

    1. Second item

    1. Third item

You can see example of this regular expression along with test units here: L<https://regex101.com/r/RfhRVg/5>

The capture names are:

=over 4

=item list_after

The data that follows the list.

=item list_all

The entire capture of the markdown.

=item list_content

The content of the list.

=item list_prefix

Contains the first list marker possible preceded by some space. A list marker is C<*>, or C<+>, or C<-> or a digit with a dot such as C<1.>

=item list_type_any

Contains the list marker such as C<*>, or C<+>, or C<-> or a digit with a dot such as C<1.>

This is included in the I<list_prefix> named capture.

=item list_type_any2

Sale as I<list_type_any>, but matches the following item if any. If there is no matching item, then an end of string is expected.

=item list_type_ordered

Contains a digit followed by a dot if the list is an ordered one.

=item list_type_ordered2

Same as I<list_type_ordered>, but for the following list item, if any.

=item list_type_unordered_minus

Contains the marker of a minus C<-> value if the list marker uses a minus sign.

=item list_type_unordered_minus2

Same as I<list_type_unordered_minus>, but for the following list item, if any.

=item list_type_unordered_plus

Contains the marker of a plus C<+> value if the list marker uses a plus sign.

=item list_type_unordered_plus2

Same as I<list_type_unordered_plus>, but for the following list item, if any.

=item list_type_unordered_star

Contains the marker of a star C<*> value if the list marker uses a star.

=item list_type_unordered_star2

Same as I<list_type_unordered_star>, but for the following list item, if any.

=back

You can see also L<Markdown::Parser::List>

=head2 List First Level

    $RE{Markdown}{ListFirstLevel}

This regular expression is used for top level list, as opposed to the nth level pattern that is used for sub list. Both will match lists within list, but the processing under markdown is different whether the list is a top level one or an sub one.

You can see also L<Markdown::Parser::List>

=head2 List Nth Level

    $RE{Markdown}{ListNthLevel}

Regular expression to process list within list.

You can see also L<Markdown::Parser::List>

=head2 List Item

    $RE{Markdown}{ListItem}

You can see example of this regular expression along with test units here: L<https://regex101.com/r/bulBCP/1>

The capture names are:

=over 4

=item li_all

The entire capture of the markdown.

=item li_content

Contains the data contained in this list item

=item li_lead_line

The optional leding line breaks

=item li_lead_space

The optional leading spaces or tabs. This is used to check that following items belong to the same list level

=item list_type_any

This contains the list type marker, which can be C<*>, C<+>, C<-> or a digit with a dot such as C<1.>

=item list_type_any2

Sale as I<list_type_any>, but matches the following item if any. If there is no matching item, then an end of string is expected.

=item list_type_ordered

This contains a true value if the list marker contains a digit followed by a dot, such as C<1.>

=item list_type_ordered2

Same as I<list_type_ordered>, but for the following list item, if any.

=item list_type_unordered_minus

This contains a true value if the list marker is a minus sign, i.e. C<->

=item list_type_unordered_minus2

Same as I<list_type_unordered_minus>, but for the following list item, if any.

=item list_type_unordered_plus

This contains a true value if the list marker is a plus sign, i.e. C<+>

=item list_type_unordered_plus2

Same as I<list_type_unordered_plus>, but for the following list item, if any.

=item list_type_unordered_star

This contains a true value if the list marker is a star, i.e. C<*>

=item list_type_unordered_star2

Same as I<list_type_unordered_star>, but for the following list item, if any.

=back

You can see also L<Markdown::Parser::ListItem>

=head2 Paragraph

    $RE{Markdown}{Paragraph}

For example:

    The quick brown fox
    jumps over the lazy dog

    Lorem Ipsum

    > Why am I matching?
    1. Nonononono!
    * Aaaagh!
    # Stahhhp!

This regular expression would capture the whole block up until "Lorem Ipsum", but will be careful not to catch other markdown element after that. Thus, anything after "Lorem Ipsum" would not be caught because this is a blockquote.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/0B3gR4/5>

The capture names are:

=over 4

=item para_all

The entire capture of the paragraph.

=item para_content

Content of the paragraph

=item para_prefix

Any leading space (up to 3)

=back

You can see also L<Markdown::Parser::Paragraph>

=head1 EXTENDED MARKDOWN

=head2 Abbreviation

    $RE{Markdown}{ExtAbbr}

For example:

    Some discussion about HTML, SGML and HTML4.

    *[HTML4]: Hyper Text Markup Language version 4
    *[HTML]: Hyper Text Markup Language
    *[SGML]: Standard Generalized Markup Language

You can see example of this regular expression along with test units here: L<https://regex101.com/r/ztM2Pw/2>

The capture names are:

=over 4

=item abbr_all

The entire capture of the abbreviation.

=item abbr_name

Contains the abbreviation. For example C<HTML>

=item abbr_value

Contains the abbreviation value. For example C<Hyper Text Markup Language>

=back

You can see also L<Markdown::Parser::Abbr>

=head2 Attributes

    $RE{Markdown}{ExtAttributes}

For example, an header with attribute C<.cl.class#id7>

    ### Header  {.cl.class#id7 }

=head2 Checkbox

    $RE{Markdown}{ExtCheckbox}

L<Introduced by Github|https://github.github.com/gfm/#task-list-items-extension->, this markdown extension captures checkboxes whether checked or unchecked.

For example:

    - [ ] foo
    - [x] bar

would become:

=begin html

    <ul>
        <li><input disabled="" type="checkbox"> foo</li>
        <li><input checked="" disabled="" type="checkbox"> bar</li>
    </ul>

=end html

Those checkboxes can be placed anywhere, not just in a list.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/ezMwsv/2/>

The capture names are:

=over 4

=item check_all

The entire capture of the checkbox.

=item check_content

The value inside the square brackets, which is either a blank, or the letter C<X> in either lower or upper case.

=back

You can see also L<Markdown::Parser::Checkbox>

=head2 Code Block

    $RE{Markdown}{ExtCodeBlock}

This is the same as conventional blocks with backticks, except the extended version uses tilde characters.

For example:

    ~~~
    <div>
    ~~~

You can see example of this regular expression along with test units here: L<https://regex101.com/r/Y9lPAz/9>

The capture names are:

=over 4

=item code_all

The entire capture of the code.

=item code_attr

The class and/or id attributes for this code. This is something like:

    `````` .html {#codeid}
    </div>
    ``````

Here, I<code_class> would contain C<#codeid>

=item code_class

The class of code. For example:

    ``````html {#codeid}
    </div>
    ``````

Here the code class would be C<html>

=item code_content

The code data enclosed within the code markers (backticks or tilde)

=item code_start

Contains the code delimiter, which is either a series of backticks C<`> or tilde C<~>

=back

You can see also L<Markdown::Parser::Code>

=head2 Footnotes

    $RE{Markdown}{ExtFootnote}

This looks like this:

    [^1]: Content for fifth footnote.
    [^2]: Content for sixth footnote spaning on 
        three lines, with some span-level markup like
        _emphasis_, a [link][].

A reference to those footnotes could be:

    Some paragraph with a footnote[^1], and another[^2].

The I<footnote_id> reference can be anything as long as it is unique.

You can see also L<Markdown::Parser::Footnote>

=head3 Inline Footnotes

For consistency with links, footnotes can be added inline, like this:

    I met Jack [^jack](Co-founder of Angels, Inc) at the meet-up.

Inline notes will work even without the identifier. For example:

    I met Jack [^](Co-founder of Angels, Inc) at the meet-up.

However, in compliance with pandoc footnotes style, inline footnotes can also be added like this:

    Here is an inline note.^[Inlines notes are easier to write, since
    you don't have to pick an identifier and move down to type the
    note.]

You can see example of this regular expression along with test units here: L<https://regex101.com/r/WuB1FR/2/>

The capture names are:

=over 4

=item footnote_all

The entire capture of the footnote.

=item footnote_id

The footnote id which must be unique and will be referenced in text.

=item footnote_text

The footnote text

=back

You can see also L<Markdown::Parser::Footnote>

=head2 Footnote Reference

    $RE{Markdown}{ExtFootnoteReference}

This regular expression matches 3 types of footnote references:

=over 4

=item 1 Conventional

An id is specified referring to a footnote that provide details.

    Here's a simple footnote,[^1]

    [^1]: This is the first footnote.

=item 2 Inline

    I met Jack [^jack](Co-founder of Angels, Inc) at the meet-up.

Inline footnotes without any id, i.e. auto-generated id. For example:

    I met Jack [^](Co-founder of Angels, Inc) at the meet-up.

=item 3 Inline auto-generated, pandoc style

    Here is an inline note.^[Inlines notes are easier to write, since
    you don't have to pick an identifier and move down to type the
    note.]

See L<pandoc manual|https://pandoc.org/MANUAL.html#footnotes> for more information

=back

You can see example of this regular expression along with test units here: L<https://regex101.com/r/3eO7rJ/1/>

The capture names are:

=over 4

=item footnote_all

The entire capture of the footnote reference.

=item footnote_id

The footnote id which must be unique and must match a footnote declared anywhere in the document and not necessarily before. For example:

    Here's a simple footnote,[^1]

    [^1]: This is the first footnote.

B<1> here is the id fo the footnote.

If it is not provided, then an id will be auto-generated, but a footnote text is then required.

=item footnote_text

The footnote text is optional if an id is provided. If an id is not provided, the fotnote text is guaranteed to have some value.

=back

You can see also L<Markdown::Parser::FootnoteReference>

=head2 Header

    $RE{Markdown}{ExtHeader}

This extends regular header with attributes.

For example:

    ### Header  {.cl.class#id7 }

You can see example of this regular expression along with test units here: L<https://regex101.com/r/GyzbR2/3>

The capture names are:

=over 4

=item header_all

The entire capture of the code lines.

=item header_attr

Contains the extended attribute set. For example:

    {.class#id}

=item header_content

The text that is enclosed in the header marker.

=item header_level

This contains all the dashes that precedes the text. The number of dash indicates the level of the header. Thus, you could do something like this:

    length( $+{header_level} );

=back

You can see also L<Markdown::Parser::Header>

=head2 Header Line

    $RE{Markdown}{ExtHeaderLine}

Same as header line, but with attributes.

For example:

    Header  {#id5.cl.class}
    ======

You can see example of this regular expression along with test units here: L<https://regex101.com/r/berfAR/3>

The capture names are:

=over 4

=item header_all

The entire capture of the code lines.

=item header_attr

Contains the extended attribute set. For example:

    {.class#id}

=item header_content

The text that is enclosed in the header marker.

=item header_type

This contains the marker line used to mark the line above as header.

A line using C<=> is a header of level 1, while a line using C<-> is a header of level 2.

=back

You can see also L<Markdown::Parser::Header>

=head2 HTML Markdown

    $RE{Markdown}{ExtHtmlMarkdown}

This is markdown embedded in html using the html tag attribute C<markdown="1">

For example:

    <div>
        <div markdown="1">

        This is a code block however:

            </div>

        Funny isn't it? Here is a code span: `</div>`.

        </div>
    </div>

This would capture the following as markdown data:

    This is a code block however:

        </div>

    Funny isn't it? Here is a code span: `</div>`.

And since C<</div>> is indented, it would be treated as a line of code rather than html. The second C<</div>> snce it is surrounded by backticks.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/M6KCjp/3>

The capture names are:

=over 4

=item content

Contains the markdown data enclosed.

=item div_close

Contains the closing tag.

=item div_open

Contains the entire opening tag.

For example, in:

    <table>
    <tr><td markdown="1">test _emphasis_ (span)</td></tr>
    </table>

this would match:

    <td markdown="1">

=item leading_space

Contains any leading space before the start of the tag containing the markdown data.

=item html_markdown_all

Contains the entire block of data captured

=item mark_pat1

This contains the data captured in pattern type 1, which matches on-line html and multiline ones.

For example:

    <abbr markdown="1" title="`second backtick!">SB</abbr>

or

    <div>
        <div markdown="1">

        This is a code block however:

            </div>

        Funny isn't it? Here is a code span: `</div>`.

        </div>
    </div>


=item mark_pat2

This contains the data captured in pattern type 2, which matches html markdown

For example:

    <table>
    <tr><td markdown="1">test _emphasis_ (span)</td></tr>
    </table>

=item quote

Contains the type of quote used in:

    <table>
    <tr><td markdown="1">test _emphasis_ (span)</td></tr>
    </table>

This would be C<">

=item tag_name

This contains the tag name that contains the markdown data.

=back

=head2 Image

    $RE{Markdown}{ExtImage}

Same as regular image, but with attributes.

For example:

    This is an ![inline image](/img "title"){.class #inline-img}.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/xetHV1/4>

The capture names are:

=over 4

=item img_all

The entire capture of the markdown, such as:

    ![Alt text](/path/to/img.jpg)

=item img_alt

The alternative tet to be displayed for this image. This is mandatory as per markdown, so it is guaranteed to be available.

=item img_attr

Contains the extended attribute set. For example:

    {.class#id}

=item img_id

If the image, is an image reference, this will contain the reference id. When an image id is provided, there is no url and no title, because the image reference provides those information.

=item img_title

This is the title of the image, which may not exist, since it is optional in markdown. The title is surrounded by single or double quote that are captured in I<img_title_container>

=item img_url

This is the url of the image.

=back

You can see also L<Markdown::Parser::Image>

=head2 Insertion

    $RE{Markdown}{ExtInsertion}

This is an extension to the original Markdown.

For example:

    Tickets for the event are ~~€5~~ ++€10++

Which would become:

    Tickets for the event are <del>€5</del> <ins>€10</ins>

With C<€5> being stroken through and C<€10> being highlighted as being added. The actual representation depends on the web browser of course.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/IZw4YU/1/>

The capture names are:

=over 4

=item ins_all

The entire capture of the insertion.

=item ins_content

The content of the text being inserted. In the example above, this would be C<€10>

=back

You can see also L<Markdown::Parser::Insertion> and L<Mozilla explanation of the tag|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ins>

=head2 Katex Math Expression

    $RE{Markdown}{ExtKatex}

This is used to capture L<Katex math expression|https://katex.org/docs/autorender.html>.

It supports the following delimiters:

=over 4

=item 1.

open delimiter: $$

close delimiter: $$

=item 2.

open delimiter: $$

close delimiter: $$

=item 3.

open delimiter: \[

close delimiter: \]

=item 4.

open delimiter: \(

close delimiter: \)

=back

For example:

    $$
    \Gamma(z) = \int_0^\infty t^{z-1}e^{-t}dt\,.
    $$

or

    Other node \[ displaymath \frac{1}{2} \]

It does not matter whether the expression is in its own block (first example) or inline (second example)

You can see a demo L<here|https://katex.org/#demo>.

By default, it supports all 4 delimiters mentioned above, but if you have some expression in your doc that may conflict, such as:

    LD_PRELOAD=libusb-driver.so $0.bin $*

Then, you can chose which delimiter to activate by calling the regular expression like this:

    $RE{Markdown}{ExtKatex}{-delimiter => '$$,$$,\[,\],\(,\)'}

As you can see you can pass the argument C<-delimiter> and providing a comma delimited series of opening en closing delimiters. In the above example:

    $$,$$ # open, close
    \[,\] # open, close
    \(,\) # open, close

I would gladly allow for an array reference to be provided, but the L<Regexp::Common> api does not make that possible.

Since L<Katex|> only recognises those delimiters, you can only choose among those.

Also, in the above example, I used single quotes because of enclosed dolar sign. Of course, if you prefer to use double quote, then you need to escape the dollar signs.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/43OuNT/3/>

The capture names are:

=over 4

=item katex_all

The entire capture of the math expression, including its delimiters, typically C<$$>.

=item katex_close

Contains the closing delimiter, such as C<$$>, C<$>, C<\]> or C<\)>

=item katex_content

The content of the math expression, i.e. without the surrounding delimiters

=item katex_open

Contains the opening delimiter, such as C<$$>, C<$>, C<\[> or C<\(>

=back

=head2 Link

    $RE{Markdown}{ExtLink}

Same as regular links, but with attributes.

For example:

    This is an [inline link](/url "title"){.class #inline-link}.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/7mLssJ/7>

The capture names are:

=over 4

=item link_all

The entire capture of the link.

=item link_attr

Contains the extended attribute set. For example:

    {.class#id}

I<link_all> would contain C<.class#id>

=item link_title_container

If there is a link title, this contains the single or double quote enclosing it.

=item link_id

The link reference id. For example here C<1> is the id.

    [Reference link 1 with parens][1]

=item link_name

The link text

=item link_title

The link title, if any.

=item link_url

The link url, if any

=back

You can see also L<Markdown::Parser::Link>

=head2 Link Definition

    $RE{Markdown}{ExtLinkDefinition}

Same as regular link definition, but with attributes

For example:

    [refid]: /path/to/something (Title) { .class #ref data-key=val }

You can see example of this regular expression along with test units here: L<https://regex101.com/r/hVfXCe/3>

The capture names are:

=over 4

=item link_all

The entire capture of the link.

=item link_attr

Contains the extended attribute set. For example:

    {.class#id}

=item link_id

The link id

=item link_title

The link title

=item link_title_container

The character used to enclose the title, if any. This is either C<"> or C<'>

=item link_url

The link url

=back

You can see also L<Markdown::Parser::LinkDefinition>

=head2 Strikethrough

    $RE{Markdown}{ExtStrikeThrough}

This is an extension brought by L<Git Flavoured Markdown|https://github.github.com/gfm/#strikethrough-extension->.

For example:

    ~~Hi~~ Hello, world!

You can see example of this regular expression along with test units here: L<https://regex101.com/r/4Z3h4F/1/>

The capture names are:

=over 4

=item strike_all

The entire capture of the strikethrough.

=item strike_content

The content of the text being stroken through. In the example above, this would be C<Hi>

=back

You can see also L<Markdown::Parser::StrikeThrough> and L<Git Flavoured Markdown|https://github.github.com/gfm/#strikethrough-extension->

=head2 Subscript

    $RE{Markdown}{ExtSubscript}

For example:

    log~10~100 is 2.

would set C<10> as a subscript by the software using this regular expression.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/gF6wVe/2>

The capture names are:

=over 4

=item sub_all

The entire capture of the subscript.

=item sub_text

Contains the text of the subscript

=back

See also: L<Markdown::Parser::Subscript>, L<Pandoc manual|https://pandoc.org/MANUAL.html#superscripts-and-subscripts>

=head2 Superscript

    $RE{Markdown}{ExtSuperscript}

For example:

    2^10^ is 1024.

would set C<10> in superscript by the software using this regular expression.

You can see example of this regular expression along with test units here: L<https://regex101.com/r/yAcNcX/1>

The capture names are:

=over 4

=item sup_all

The entire capture of the superscript.

=item sup_text

Contains the text of the superscript

=back

See also: L<Markdown::Parser::Superscript>, L<Pandoc manual|https://pandoc.org/MANUAL.html#superscripts-and-subscripts>, L<https://facelessuser.github.io/pymdown-extensions/extensions/caret/>

=head2 Table

    $RE{Markdown}{ExtTable}

This is an extensive regular expression to capture all kinds of tables, including with caption on top or bottom.

For example:

=begin text

    |               |            Grouping            ||
    +---------------+---------------------------------+
    | First Header  |  Second Header  |  Third Header |
    +---------------+-----------------+---------------+
    | Content       |           *Long Cell*          ||
    : continued     :                                ::
    : content       :                                ::
    | Content       |    **Cell**     |          Cell |
    : continued     :                 :               :
    : content       :                 :               :
    | New section   |      More       |          Data |
    | And more      |             And more           ||
     [Prototype table]

=end text

You can see example of this regular expression along with test units here: L<https://regex101.com/r/01XCqB/12>

The capture names are:

=over 4

=item table

The entire capture of the table.

=item table_after

Contains the data that follows the table.

=item table_caption

Contains the table caption if set. A table caption, in markdown can be position before or after the table.

If you use L<perlvar/%-> then C<$-{table_caption}->[0]> will give you the table caption if it was set at the top of the table, and C<$-{table_caption}->[1]> will give you the table caption if it was set at the bottom of the table.

=item table_headers

Contains the entire header rows

=item table_header1

Contains the first row of the header. This is contained within the capture name I<table_headers>

=item table_header2

Contains the second row, if any, of the header. This is contained within the capture name I<table_headers>

A second is optional and there can be only two rows in the headers as per standards.

=item table_header_sep

Contain the separator line between the table header and the table body.

=item table_rows

Contains the table body rows

=back

Table format is taken from L<David E. Wheeler RFC|https://justatheory.com/2009/02/markdown-table-rfc/>

You can see also L<Markdown::Parser::Table>

=head1 SEE ALSO

L<Regexp::Common> for a general description of how to use this interface.

L<Markdown::Parser> for a Markdown parser using this module.

=head1 CHANGES & CONTRIBUTIONS

Feel free to reach out to the author for possible corrections, improvements, or suggestions.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 CREDITS

Credits to L<Michel Fortin|https://michelf.ca/projects/php-markdown> and L<John Gruber|http://six.pairlist.net/pipermail/markdown-discuss/2006-June/000079.html> for their test units.

Credits to Firas Dib for his online L<regular expression test tool|https://regex101.com>.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
