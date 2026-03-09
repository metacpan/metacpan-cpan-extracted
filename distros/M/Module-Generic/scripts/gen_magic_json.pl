#!/usr/bin/env perl
##----------------------------------------------------------------------------
## Module::Generic::File::Magic - scripts/gen_magic_json.pl
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created  2026/03/08
## Modified 2026/03/08
##
## Converts a freedesktop.org shared-mime-info XML file into the compact JSON
## magic database used by Module::Generic::File::Magic's pure-Perl backend.
##
## Usage:
##   perl scripts/gen_magic_json.pl [XML_FILE] [OUT_FILE]
##
## Defaults:
##   XML_FILE : /usr/share/mime/packages/freedesktop.org.xml
##   OUT_FILE : lib/Module/Generic/File/magic.json
##
## Requirements:
##   XML::LibXML  (preferred)  OR  XML::Parser  OR  XML::Twig
##   JSON
##
## Output format:
##   A JSON array of objects, sorted by descending priority then MIME type:
##   [
##     {
##       "mime"     : "application/gzip",
##       "priority" : 80,
##       "matches"  : [
##         {
##           "offset" : 0,        int — start offset in the file
##           "range"  : 0,        int — scan [offset .. offset+range-1]; 0 = exact
##           "type"   : "string", string|byte|big16|big32|little16|little32|host16|host32
##           "bytes"  : "1f8b",   hex-encoded bytes to match
##           "mask"   : null,     hex-encoded AND mask or null
##           "and"    : [...]     optional sub-matches (all must pass)
##         }
##       ]
##     },
##     ...
##   ]
##----------------------------------------------------------------------------
use strict;
use warnings;
use File::Spec ();

my $XML_FILE = $ARGV[0] // '/usr/share/mime/packages/freedesktop.org.xml';
my $OUT_FILE = $ARGV[1] // File::Spec->catfile(
    File::Spec->curdir, 'lib', 'Module', 'Generic', 'File', 'magic.json'
);

die( "Cannot read XML file: $XML_FILE\n" ) unless( -r $XML_FILE );

my $NS = 'http://www.freedesktop.org/standards/shared-mime-info';

# NOTE: Load an XML parser — try in order of preference
my $parser_type = _detect_xml_parser();
die(
    "No XML parser found. Please install one of:\n"
    . "  cpanm XML::LibXML\n"
    . "  cpanm XML::Twig\n"
    . "  cpanm XML::Parser\n"
) unless( defined( $parser_type )) ;

printf( "Using XML parser: %s\n", $parser_type );
printf( "Parsing: %s\n", $XML_FILE );

my @entries = _parse_xml( $XML_FILE, $parser_type );

# Sort: highest priority first, then MIME type for determinism
@entries = sort{
    $b->{priority} <=> $a->{priority} || $a->{mime} cmp $b->{mime}
} @entries;

printf( "Generated %d magic entries.\n", scalar( @entries ) );

# NOTE: Write JSON
require JSON;
my $json = JSON->new->utf8->canonical(1)->pretty(1)->encode( \@entries );

open( my $fh, '>:raw', $OUT_FILE ) or
    die( "Cannot write $OUT_FILE: $!\n" );
print( $fh $json );
close( $fh );

printf( "Written to %s (%.1f KB)\n", $OUT_FILE, ( -s $OUT_FILE ) / 1024 );
exit(0);

# NOTE: Detect available XML parser
sub _detect_xml_parser
{
    for my $mod ( qw( XML::LibXML XML::Twig XML::Parser ) )
    {
        local $@;
        eval{ require $mod; 1 } and return( $mod );
    }
    return( undef );
}

# NOTE: Parse XML using the available parser
sub _parse_xml
{
    my( $file, $parser_type ) = @_;

    if( $parser_type eq 'XML::LibXML' )
    {
        return( _parse_with_libxml( $file ) );
    }
    else
    {
        # XML::Twig and XML::Parser: use a SAX-style approach via XML::Twig
        # or fall back to slurp + regex for XML::Parser
        return( _parse_with_twig_or_parser( $file, $parser_type ) );
    }
}

# NOTE: XML::LibXML implementation
sub _parse_with_libxml
{
    my $file = shift( @_ );
    require XML::LibXML;
    my $doc  = XML::LibXML->load_xml( location => $file );
    my $root = $doc->documentElement;
    my @entries;

    foreach my $mime_node ( $root->getChildrenByTagNameNS( $NS, 'mime-type' ) )
    {
        my $mime_type = $mime_node->getAttribute('type') or next;
        foreach my $magic_node ( $mime_node->getChildrenByTagNameNS( $NS, 'magic' ) )
        {
            my $priority = int( $magic_node->getAttribute('priority') // 50 );
            my @matches;
            foreach my $match_node ( $magic_node->getChildrenByTagNameNS( $NS, 'match' ) )
            {
                my $m = _libxml_parse_match( $match_node );
                push( @matches, $m ) if( defined( $m ) );
            }
            next unless( @matches );
            push( @entries, {
                mime     => $mime_type,
                priority => $priority,
                matches  => \@matches
            });
        }
    }
    return( @entries );
}

sub _libxml_parse_match
{
    my $node = shift( @_ );
    my $type = $node->getAttribute('type')   // 'string';
    my $raw  = $node->getAttribute('value')  // '';
    my $off  = $node->getAttribute('offset') // '0';
    my $mask = $node->getAttribute('mask');

    my $bytes = _decode_value( $raw, $type ) // return( undef );
    return( undef ) unless( length( $bytes )) ;

    my( $offset, $range ) = _parse_offset( $off );

    my %m = (
        offset => $offset,
        range  => $range,
        type   => $type,
        bytes  => unpack( 'H*', $bytes ),
    );

    if( defined( $mask ) && length( $mask ) )
    {
        my $mb = _decode_value( $mask, $type );
        $m{mask} = unpack( 'H*', $mb ) if( defined( $mb ) );
    }

    my @and;
    for my $child ( $node->getChildrenByTagNameNS( $NS, 'match' ) )
    {
        my $sub = _libxml_parse_match( $child );
        push( @and, $sub ) if( defined( $sub ) );
    }
    $m{and} = \@and if( @and );

    return( \%m );
}

# NOTE: XML::Twig / XML::Parser implementation
sub _parse_with_twig_or_parser
{
    my( $file, $parser_type ) = @_;

    if( $parser_type eq 'XML::Twig' )
    {
        require XML::Twig;
    }
    else
    {
        require XML::Parser;
    }

    # Both can be driven through XML::Twig's interface
    # If only XML::Parser is available, XML::Twig may not be, so we handle both
    if( $parser_type eq 'XML::Twig' )
    {
        return( _parse_with_twig( $file ) );
    }
    # XML::Parser only — use a simple event-driven approach
    return( _parse_with_xmlparser( $file ) );
}

sub _parse_with_twig
{
    my $file = shift( @_ );
    my @entries;

    XML::Twig->new(
        twig_handlers => 
        {
            'mime-type' => sub
            {
                my( $t, $mime_node ) = @_;
                my $mime_type = $mime_node->att('type') or return;
                foreach my $magic_node ( $mime_node->children('magic') )
                {
                    my $priority = int( $magic_node->att('priority') // 50 );
                    my @matches;
                    foreach my $match_node ( $magic_node->children('match') )
                    {
                        my $m = _twig_parse_match( $match_node );
                        push( @matches, $m ) if( defined( $m ) );
                    }
                    next unless( @matches );
                    push( @entries, {
                        mime     => $mime_type,
                        priority => $priority,
                        matches  => \@matches,
                    });
                }
                $t->purge;
            },
        },
    )->parsefile( $file );

    return( @entries );
}

sub _twig_parse_match
{
    my $node = shift( @_ );
    my $type = $node->att('type')   // 'string';
    my $raw  = $node->att('value')  // '';
    my $off  = $node->att('offset') // '0';
    my $mask = $node->att('mask');

    my $bytes = _decode_value( $raw, $type ) // return( undef );
    return( undef ) unless( length( $bytes ) );

    my( $offset, $range ) = _parse_offset( $off );
    my %m = (
        offset => $offset,
        range  => $range,
        type   => $type,
        bytes  => unpack( 'H*', $bytes ),
    );
    if( defined( $mask ) && length( $mask ) )
    {
        my $mb = _decode_value( $mask, $type );
        $m{mask} = unpack( 'H*', $mb ) if( defined( $mb ) );
    }
    my @and;
    for my $child ( $node->children('match') )
    {
        my $sub = _twig_parse_match( $child );
        push @and, $sub if( defined( $sub ) );
    }
    $m{and} = \@and if( @and );
    return( \%m );
}

sub _parse_with_xmlparser
{
    # XML::Parser only — minimal SAX-style implementation
    # (complex nesting handled via a stack)
    my $file = shift( @_ );
    my @entries;
    my @stack;    # stack of current context: mime-type, magic, match
    my $cur_mime     = undef;
    my $cur_priority = 50;
    my @cur_matches;
    my @match_stack;

    my $p = XML::Parser->new(
        Handlers =>
        {
            Start => sub
            {
                my( $expat, $el, %attrs ) = @_;
                if( $el eq 'mime-type' || ( $el =~ /:/ && $el =~ /mime-type$/ ) )
                {
                    $cur_mime    = $attrs{type};
                    @cur_matches = ();
                }
                elsif( $el eq 'magic' || $el =~ /magic$/ )
                {
                    $cur_priority = int( $attrs{priority} // 50 );
                }
                elsif( $el eq 'match' || $el =~ /match$/ )
                {
                    my $type  = $attrs{type}   // 'string';
                    my $raw   = $attrs{value}  // '';
                    my $off   = $attrs{offset} // '0';
                    my $mask  = $attrs{mask};
                    my $bytes = _decode_value( $raw, $type );
                    my $m     = undef;
                    if( defined( $bytes ) && length( $bytes ) )
                    {
                        my( $offset, $range ) = _parse_offset( $off );
                        $m = 
                        {
                            offset => $offset,
                            range  => $range,
                            type   => $type,
                            bytes  => unpack( 'H*', $bytes ),
                        };
                        if( defined( $mask ) && length( $mask ) )
                        {
                            my $mb = _decode_value( $mask, $type );
                            $m->{mask} = unpack( 'H*', $mb ) if( defined( $mb ) );
                        }
                        $m->{and} = [];
                    }
                    push( @match_stack, $m );
                }
            },
            End => sub
            {
                my( $expat, $el ) = @_;
                if( $el eq 'match' || $el =~ /match$/ )
                {
                    my $m = pop( @match_stack );
                    if( @match_stack && defined( $match_stack[-1] ) )
                    {
                        # Sub-match: attach to parent's 'and' list
                        push( @{$match_stack[-1]{and}}, $m ) if( defined( $m ) );
                    }
                    else
                    {
                        # Top-level match
                        push( @cur_matches, $m ) if( defined( $m ) );
                    }
                }
                elsif( $el eq 'magic' || $el =~ /magic$/ )
                {
                    if( @cur_matches )
                    {
                        push( @entries,
                        {
                            mime     => $cur_mime,
                            priority => $cur_priority,
                            matches  => [@cur_matches],
                        });
                        @cur_matches = ();
                    }
                }
                elsif( $el eq 'mime-type' || $el =~ /mime-type$/ )
                {
                    $cur_mime = undef;
                }
            },
        }
    );
    $p->parsefile( $file );

    # Clean up empty 'and' arrays
    foreach my $entry ( @entries )
    {
        foreach my $m ( @{$entry->{matches}} )
        {
            delete( $m->{and} ) unless( @{$m->{and} // []} );
        }
    }
    return( @entries );
}

# NOTE: Shared utility functions
sub _parse_offset
{
    my $off = shift( @_ ) // '0';
    if( $off =~ /^(\d+):(\d+)$/ )
    {
        my $start = int( $1 );
        my $range = int( $2 ) - $start;
        return( $start, $range < 0 ? 0 : $range );
    }
    return( int( $off ), 0 );
}

sub _decode_value
{
    my( $raw, $type ) = @_;
    return( _unescape_string( $raw ) ) if( $type eq 'string' );
    my $n = _parse_number( $raw ) // return( undef );
    return( pack( 'C',  $n & 0xFF )       ) if( $type eq 'byte'     );
    return( pack( '>H', $n & 0xFFFF )     ) if( $type eq 'big16'    );
    return( pack( '<H', $n & 0xFFFF )     ) if( $type eq 'little16' );
    return( pack( '>H', $n & 0xFFFF )     ) if( $type eq 'host16'   );  # normalised to BE
    return( pack( '>I', $n & 0xFFFFFFFF ) ) if( $type eq 'big32'    );
    return( pack( '<I', $n & 0xFFFFFFFF ) ) if( $type eq 'little32' );
    return( pack( '>I', $n & 0xFFFFFFFF ) ) if( $type eq 'host32'   );  # normalised to BE
    return( undef );
}

sub _unescape_string
{
    my $raw = shift( @_ );
    my $out = '';
    my $i   = 0;
    my $len = length( $raw );
    while( $i < $len )
    {
        my $c = substr( $raw, $i, 1 );
        if( $c eq '\\' && $i + 1 < $len )
        {
            my $n = substr( $raw, $i + 1, 1 );
            if(    $n eq '\\' ) { $out .= '\\';    $i += 2 }
            elsif( $n eq 'n'  ) { $out .= "\n";    $i += 2 }
            elsif( $n eq 'r'  ) { $out .= "\r";    $i += 2 }
            elsif( $n eq 't'  ) { $out .= "\t";    $i += 2 }
            elsif( $n eq 'x' && $i + 3 < $len )
            {
                my $h = substr( $raw, $i + 2, 2 );
                if( $h =~ /^[0-9a-fA-F]{2}$/ )
                {
                    $out .= chr( hex( $h ) );
                    $i += 4
                }
                else
                {
                    $out .= $n;
                    $i += 2
                }
            }
            elsif( $n =~ /[0-7]/ )
            {
                my $j = $i + 1;
                my $oct = '';
                while( $j < $len && $j < $i + 4 && substr( $raw, $j, 1 ) =~ /[0-7]/ )
                {
                    $oct .= substr( $raw, $j++, 1 );
                }
                $out .= chr( oct( $oct ) );
                $i = $j;
            }
            else
            {
                $out .= $n;
                $i += 2;
            }
        }
        else
        {
            $out .= $c;
            $i++;
        }
    }
    return( $out );
}

sub _parse_number
{
    my $s = shift( @_ ) // return(undef);
    $s =~ s/^\s+|\s+$//g;
    return( hex( $s )   ) if( $s =~ /^0x[0-9a-fA-F]+$/i );
    return( oct( $s )   ) if( $s =~ /^0[0-7]+$/ );
    return( int( $s )   ) if( $s =~ /^\d+$/ );
    return( undef );
}

__END__
