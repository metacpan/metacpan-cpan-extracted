#############################################################################
## Name:        Parser.pm
## Purpose:     Pod::HtmlEasy::Parser
## Author:      Graciliano M. P.
## Modified by: Geoffrey Leach
## Created:     11/01/2004
## Updated:	    2010-06-13
## Copyright:   (c) 2004 Graciliano M. P. (c) 2007 - 2013 Geoffrey Leach
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Pod::HtmlEasy::Parser;
use 5.006003;

use base qw{ Pod::Parser };
use Pod::Parser;
use Pod::ParseLink;
use Readonly;
use Pod::HtmlEasy::Data qw(EMPTY NUL);

use Carp;
use English qw{ -no_match_vars };
use Regexp::Common qw{ whitespace number URI };
use Regexp::Common::URI::RFC2396 qw { $escaped };
use Pod::Escapes qw{ e2char };

our $VERSION = version->declare("v1.1.11");    

# Provided for RT 82400. Use native switch if available.
BEGIN {
        if ($PERL_VERSION >= 5.012) {
                require feature;
                "feature"->import(qw(switch));
        } else {
                require Switch;
                "Switch"->import(qw(Perl6));
        }
}

use strict;
use warnings;

########
# VARS #
########

Readonly::Scalar my $NUL => NUL;

# RT 58274 [\w-]+ => [\w\.-]
# Commented patterns temp test
Readonly::Scalar my $MAIL_RE => qr{
         (         # grab all of this
         [\w\.-]+  # some word chars with '-' and '.'included  foo
         \0?       # possible NUL escape
         \@        # literal '@'                               @
         [\w\.-]+  # another word                              bar
         (?:       # non-grabbing pattern
#         \.       # literal '.'                               .
          [\w\.-]+ # that word stuff                           stuff
#         \.       # another literal '.'                       .
          [\w\.-]+ # another word                              and
          |        # or
#         \.       # literal '.'                               .   
          [\w\.-]+ # word                                      nonsense
          |        # or empty?
         )         # end of non-grab
         )         # end of grab
        }smx;    # [6062]



# Treatment of embedded HTML-significant characters and embedded URIs.

# There are some characters (%HTML_ENTITIES below) which may in some
# circumstances be interpreted by a browser, and you probably don't want that
# Consequently, they are replaced by names defined by the W3C UNICODE spec,
# http://www.w3.org/TR/MathML2/bycodes.html, bracketed by '&' and ';'
# Thus, '>' becomes '&lt;' This is handled by _encode_entities()
# There's a "gotchya" in this process. As we are generating HTML,
# the encoding needs to take place _before_ any HTML is generated.

# If the HTML appears garbled, and UNICODE entities appear where they
# shouldn't, this encoding has happened to late at some point.

# This is all further complicated by the fact that the POD formatting
# codes syntax uses some of the same characters, as in "L<...>", for example,
# and we can't expand those first, because some of them generate
# HTML. This is resolved by tagging the characters that we want
# to distinguish from HTML with ASCII NUL ('\0', $NUL). Thus, '$lt;' becomes
# '\0&amp;' in _encode_entities().  Generated HTML is also handled
# this way by _nul_escape(). After all processing of the  POD formatting
# codes are processed, this is reversed by _remove _nul_escapes().

# Then there's the issue of embedded URIs. URIs are also generated
# by the processing of L<...>, and can show up _inside L<...>, we
# delay processing of embedded URIs until after all of the POD
# formatting codes is complete. URIs that result from that processing
# are tagged (you guessed it!) with a NUL character, but not preceeding
# the generated URI, but after the first character. These NULs are removed
# by _remove _nul_escapes()

Readonly::Hash my %HTML_ENTITIES => (
    q{&} => q{amp},
    q{>} => q{gt},
    q{<} => q{lt},
    q{"} => q{quot},
);

my $HTML_ENTITIES_RE = join q{|}, keys %HTML_ENTITIES;
$HTML_ENTITIES_RE = qr{$HTML_ENTITIES_RE}msx;

#################
# _NUL_ESCAPE   #
#################

# Escape HTML-significant characters with ASCII NUL to differentiate them
# from the same characters that get converted to entity names
sub _nul_escape {
    my $txt_ref = shift;

    ${$txt_ref} =~ s{($HTML_ENTITIES_RE)}{$NUL$1}gsmx;
    return;
}

#######################
# _REMOVE_NUL_ESCAPSE #
#######################

sub _remove_nul_escapes {
    my $txt_ref = shift;

    ${$txt_ref} =~ s{$NUL}{}gsmx;
    return;
}

####################
# _ENCODE_ENTITIES #
####################

sub _encode_entities {
    my $txt_ref = shift;

    if ( !( defined $txt_ref && length ${$txt_ref} ) ) { return; }

    foreach my $chr ( keys %HTML_ENTITIES ) {

        # $chr gets a lookbehind to avoid converting flagged from E<...>
        my $re = qq{(?<!$NUL)$chr};
        ${$txt_ref} =~ s{$re}{$NUL&$HTML_ENTITIES{$chr};}gsmx;
    }

    return;
}

#################
# _ADD_URI_HREF #
#################

# process embedded URIs that are not noted in L<...> bracketing
# Note that the HTML-significant characters are escaped;
# The escapes are removed by _encode_entities
# Note that there's no presumption that there's a URI in the
# text, so not matching is _not_ and error.

sub _add_uri_href {
    my ($txt_ref) = @_;

    if ( ${$txt_ref} =~ m{https?:}smx ) {

# Replace escaped characters in URL with their ASCII equivalents
# Regexp::Common escapes in path part, but not in host part, which appears correct
# per the RFC. However, the Spamassassin folks use it in the host.
# $escaped is defined by Regexp::Common::URI::RFC2396, and matches %xx
# This is done first because if needed, the host part won't be parsed correctly
        while ( ${$txt_ref} =~ m{($escaped)}msx ) {
            my $esc = $1;
            my $new = $1;
            $new =~ s{%}{0x}msx;
            $new = e2char($new);
            ${$txt_ref} =~ s{$esc}{$new}gmsx;
        }

   # target='_blank' causes load to a new window or tab
   # See HTML 4.01 spec, section 6.16 Frame target names
   # Doing this because URI RE grabs non-word trailing characters
   #       ${$txt_ref} =~ m{$RE{URI}{HTTP}{-keep}{-scheme=>'https?'}}mx;
   #       my $uri = $1;
   #       my $host = $3;
   #       $uri =~ s{[^/\w]+\z}{}mx;
   #       ${$txt_ref} =~ s{$uri}{<a href='$uri' target='_blank'>$host</a>}mx;
        ${$txt_ref}
            =~ s{$RE{URI}{HTTP}{-keep}{-scheme=>'https?'}}{<a href='$1' target='_blank'>$3</a>}gsmx;

        return;
    }

    if ( ${$txt_ref} =~ m{ftp:}smx ) {
        ${$txt_ref} =~ s{$RE{URI}{FTP}{-keep}}{<a href='$1'>$5</a>}gsmx;
        return;
    }

    if ( ${$txt_ref} =~ m{file:}smx ) {
        ${$txt_ref} =~ s{$RE{URI}{file}{-keep}}{<a href='$1'>$3</a>}gsmx;
        return;
    }

    if ( ${$txt_ref} =~ m{$MAIL_RE}smx ) {
        ${$txt_ref} =~ s{mailto://}{}smx;
        ${$txt_ref} =~ s{($MAIL_RE)}{<a href='mailto:$1'>$1</a>}gsmx;
        return;
    }

    return;
}

###########
# COMMAND #
###########

# Index levels, which translate into indentation in the index
Readonly::Scalar my $LEVEL1 => 1;
Readonly::Scalar my $LEVEL2 => 2;
Readonly::Scalar my $LEVEL3 => 3;
Readonly::Scalar my $LEVEL4 => 4;
Readonly::Scalar my $LEVELL => 0;

# Overrides command() provided by base class in Pod::Parser
sub command {
    my ( $parser, $command, $paragraph, $line_num, $pod ) = @_;

    if ( defined $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER} ) {
        _verbatim($parser);
    }    # [6062]

    my $expansion = $parser->interpolate( $paragraph, $line_num );

    $expansion =~ s{$RE{ws}{crop}}{}gsmx;    # delete surrounding whitespace

    # Encoding puts in a NUL; we're finished with the text, so remove them
    _encode_entities( \$expansion );
    _remove_nul_escapes( \$expansion );

    my $html;
    no warnings; # 'experimental'
    given ($command) {
        when (q{head1}) {
            _add_index( $parser, $expansion, $LEVEL1 );
            $html = $parser->{POD_HTMLEASY}
                ->{ON_HEAD1}( $parser->{POD_HTMLEASY}, $expansion );
        }
        when (q{head2}) {
            _add_index( $parser, $expansion, $LEVEL2 );
            $html = $parser->{POD_HTMLEASY}
                ->{ON_HEAD2}( $parser->{POD_HTMLEASY}, $expansion );
        }
        when (q{head3}) {
            _add_index( $parser, $expansion, $LEVEL3 );
            $html = $parser->{POD_HTMLEASY}
                ->{ON_HEAD3}( $parser->{POD_HTMLEASY}, $expansion );
        }
        when (q{head4}) {
            _add_index( $parser, $expansion, $LEVEL4 );
            $html = $parser->{POD_HTMLEASY}
                ->{ON_HEAD4}( $parser->{POD_HTMLEASY}, $expansion );
        }
        when (q{begin}) {
            $html = $parser->{POD_HTMLEASY}
                ->{ON_BEGIN}( $parser->{POD_HTMLEASY}, $expansion );
        }
        when (q{end}) {
            $html = $parser->{POD_HTMLEASY}
                ->{ON_END}( $parser->{POD_HTMLEASY}, $expansion );
        }
        when (q{over}) {
            $html = $parser->{POD_HTMLEASY}
                ->{ON_OVER}( $parser->{POD_HTMLEASY}, $expansion );
        }
        when (q{item}) {

            # Items that begin with '* ' are ugly. Is it there for pod2man?
            # Which is not the same as _only_ '*'
            $expansion =~ s{\A\*\s+}{}msx;

            if ( $parser->{INDEX_ITEM} ) {
                _add_index( $parser, $expansion, $LEVELL );
            }

            # This is for the folks who use =item to list URLs
            if ( $expansion !~ m{<a\shref=}smx ) {

                # The URI's not already encoded (L<...> is already processed)
                _add_uri_href( \$expansion );
            }
            $html = $parser->{POD_HTMLEASY}
                ->{ON_ITEM}( $parser->{POD_HTMLEASY}, $expansion );
        }
        when (q{back}) {
            $html = $parser->{POD_HTMLEASY}
                ->{ON_BACK}( $parser->{POD_HTMLEASY}, $expansion );
        }
        when (q{for}) {
            $html = $parser->{POD_HTMLEASY}
                ->{ON_FOR}( $parser->{POD_HTMLEASY}, $expansion );
        }
        default {
            if ( defined $parser->{POD_HTMLEASY}->{qq{ON_\U$command\E}} ) {
                $html
                    = $parser->{POD_HTMLEASY}
                    ->{qq{ON_\U$command\E}}( $parser->{POD_HTMLEASY},
                    $expansion );
            }
            elsif ( $command !~ /^(?:pod|cut)$/imsx ) {
                $html = qq{<pre>=$command $expansion</pre>};
            }
            else { $html = EMPTY; }
        }
    };
    use warnings;

    if ( $html ne EMPTY ) {
        push @{ $parser->{POD_HTMLEASY}->{HTML} }, $html;
    }

    return;
}

############
# VERBATIM #
############

# Overrides verbatim() provided by base class in Pod::Parser
sub verbatim {
    my ( $parser, $paragraph, $line_num ) = @_;

    if ( exists $parser->{POD_HTMLEASY}->{IN_BEGIN} ) { return; }
    $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER} .= $paragraph;

    return;
}

sub _verbatim {
    my ($parser) = @_;

    if ( exists $parser->{POD_HTMLEASY}->{IN_BEGIN} ) { return; }
    my $expansion = $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER};
    $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER} = EMPTY;

    _encode_entities( \$expansion );

    # If we had "=item *", we should now be looking at the text that will
    # appear as the item. The "*" was passed over initially, so we need
    # the text to index. Save the flag as ON_VERBATIM deletes IN_ITEM

    my $add_index = $parser->{INDEX_ITEM} && $parser->{POD_HTMLEASY}{IN_ITEM};

    my $html = $parser->{POD_HTMLEASY}
        ->{ON_VERBATIM}( $parser->{POD_HTMLEASY}, $expansion );

    # Now look for any embedded URIs
    _add_uri_href( \$html );

    # And remove any NUL escapes
    _remove_nul_escapes( \$html );

    if ( $html ne EMPTY ) {
        if ($add_index) { _add_index( $parser, $expansion, $LEVELL ); }
        push @{ $parser->{POD_HTMLEASY}->{HTML} }, $html;
    }    # [6062]

    return;
}

#############
# TEXTBLOCK #
#############

# Overrides textblock() provided by base class in Pod::Parser
sub textblock {
    my ( $parser, $paragraph, $line_num ) = @_;

    if ( exists $parser->{POD_HTMLEASY}->{IN_BEGIN} ) { return; }
    if ( defined $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER} ) {
        _verbatim($parser);
    }    # [6062]

    my $expansion = $parser->interpolate( $paragraph, $line_num );

    $expansion =~ s{$RE{ws}{crop}}{}gsmx;    # delete surrounding whitespace
    $expansion =~ s{\s+$}{}gsmx;

    # Encode HTML-specific characters before adding any HTML (eg <p>)
    _encode_entities( \$expansion );

    # If we had "=item *", we should now be looking at the text that will
    # appear as the item. The "*" was passed over initially, so we need
    # the text to index. Save the flag as ON_TEXTBLOCK deletes IN_ITEM

    my $add_index = $parser->{INDEX_ITEM} && $parser->{POD_HTMLEASY}{IN_ITEM};

    my $html = $parser->{POD_HTMLEASY}
        ->{ON_TEXTBLOCK}( $parser->{POD_HTMLEASY}, $expansion );

    # Now look for any embedded URIs
    _add_uri_href( \$html );

    # And remove any NUL escapes
    _remove_nul_escapes( \$html );

    if ( $html ne EMPTY ) {
        if ($add_index) { _add_index( $parser, $expansion, $LEVELL ); }
        push @{ $parser->{POD_HTMLEASY}->{HTML} }, $html;
    }

    return;
}

#####################
# INTERIOR_SEQUENCE #
#####################

# Overrides interior_sequence() provided by base class in Pod::Parser
sub interior_sequence {
    my ( $parser, $seq_command, $seq_argument, $pod_seq ) = @_;

    my $ret;

    # Encode HTML-specific characters before adding any HTML (eg <p>)
    if ( $seq_command ne q{L} ) {
        _encode_entities( \$seq_argument );
    }

    no warnings; # 'experimental'
    given ($seq_command) {
        when (q{B}) {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_B}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when (q{C}) {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_C}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when (q{E}) {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_E}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when (q{F}) {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_F}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when (q{I}) {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_I}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when (q{L}) {

            # L<> causes problems, but not with parselink.
            if ( $seq_argument eq EMPTY ) {
                _errors( $parser, q{Empty L<>} );
                return EMPTY;
            }
            my @parsed = Pod::ParseLink::parselink($seq_argument);
            foreach (@parsed) {
                if ( defined $_ ) { _encode_entities( \$_ ); }
            }

            # Encoding handled in ON_L()
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_L}( $parser->{POD_HTMLEASY}, @parsed );
        }
        when (q{S}) {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_S}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        when (q{Z}) {
            $ret = $parser->{POD_HTMLEASY}
                ->{ON_Z}( $parser->{POD_HTMLEASY}, $seq_argument );
        }
        default {
            if ( defined $parser->{POD_HTMLEASY}->{qq{ON_\U$seq_command\E}} )
            {
                $ret
                    = $parser->{POD_HTMLEASY}
                    ->{qq{ON_\U$seq_command\E}}( $parser->{POD_HTMLEASY},
                    $seq_argument );
            }
            else {
                $ret = qq{$seq_command<$seq_argument>};
            }
        }
    }
    use warnings;

    # Escape HTML-significant characters
    _nul_escape( \$ret );

    return $ret;
}

########################
# PREPROCESS_PARAGRAPH #
########################

Readonly::Scalar my $INFO_DONE => 3;

# Overrides preprocess_paragraph() provided by base class in Pod::Parser
# NB: the text is _not_ altered.
sub preprocess_paragraph {
    my ( $parser, $text, $line_num ) = @_;

    if ( $parser->{POD_HTMLEASY}{INFO_COUNT} == $INFO_DONE ) {
        return $text;
    }

    if ( not exists $parser->{POD_HTMLEASY}{PACKAGE} ) {
        if ( $text =~ m{package}smx ) {
            my ($pack) = $text =~ m{package\s+(\w+(?:::\w+)*)}smx;
            if ( defined $pack ) {
                $parser->{POD_HTMLEASY}{PACKAGE} = $pack;
                $parser->{POD_HTMLEASY}{INFO_COUNT}++;
            }
        }
    }

    if ( not exists $parser->{POD_HTMLEASY}{VERSION} ) {
        if ( $text =~ m{VERSION}smx ) {
            my ($ver) = $text =~ m{($RE{num}{decimal})}smx;
            if ( defined $ver ) {
                $parser->{POD_HTMLEASY}{VERSION} = $ver;
                $parser->{POD_HTMLEASY}{INFO_COUNT}++;
            }
        }
    }

    # This situation is created by evt_on_head1()
    # _do_title has found nothing following =head1 NAME, so it
    # creates ...{TITLE}, and leaves it undef, so that it will be
    # picked up here when the paragraph following is processed.
    if (    ( exists $parser->{POD_HTMLEASY}{TITLE} )
        and ( not defined $parser->{POD_HTMLEASY}{TITLE} ) )
    {
        my @lines = split m{\n}smx, $text;
        my $tmp_text = shift @lines;
        if ( not defined $tmp_text ) { return $text; }
        $tmp_text =~ s{$RE{ws}{crop}}{}gsmx;   # delete surrounding whitespace
        $parser->{POD_HTMLEASY}{TITLE} = $tmp_text;
        $parser->{POD_HTMLEASY}{INFO_COUNT}++;
    }

    return $text;
}

##############
# _ADD_INDEX #
##############

sub _add_index {
    my ( $parser, $txt, $level ) = @_;

    # Don't index star items
    if ( $txt eq q{*} ) { return; }

    if ( exists $parser->{INDEX_ITEM} ) {
        my $max_len = $parser->{INDEX_LENGTH};
        if ( length $txt > $max_len ) {
            while ( substr( $txt, $max_len, 1 ) ne q{ } ) {
                $max_len++;
                last if $max_len >= length $txt;
            }
            if ( $max_len < length $txt ) {
                $txt = substr( $txt, 0, $max_len ) . "...";
            }
        }
    }

    _remove_nul_escapes( \$txt );
    push @{ $parser->{POD_HTMLEASY}->{INDEX} }, [ $level, $txt ];

    return;

}

#############
# BEGIN_POD #
#############

# Overrides begin_pod() provided by base class in Pod::Parser
sub begin_pod {
    my ($parser) = @_;

    delete $parser->{POD_HTMLEASY}->{INDEX};
    $parser->{POD_HTMLEASY}->{INDEX} = [];

    return 1;
}

###########
# END_POD #
###########

# Overrides end_pod() provided by base class in Pod::Parser
sub end_pod {
    my ($parser) = @_;

    if ( defined $parser->{POD_HTMLEASY}->{VERBATIM_BUFFER} ) {
        _verbatim($parser);
    }

    return 1;
}

###########
# _ERRORS #
###########

sub _errors {
    my ( $parser, $error ) = @_;

    carp "$error";
    $error =~ s{^\s*\**\s*errors?:?\s*}{}ismx;
    $error =~ s{\s+$}{}smx;

    my $html = $parser->{POD_HTMLEASY}
        ->{ON_ERROR}( $parser->{POD_HTMLEASY}, $error );
    if ( $html ne EMPTY ) {
        push @{ $parser->{POD_HTMLEASY}->{HTML} }, $html;
    }

    return 1;
}

###########
# DESTROY #
###########

sub DESTROY { }

#######
# END #
#######

1;

