#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use File::pushd;
use File::Path qw/mkpath/;
use IO::File;
use Parse::RecDescent;

use ExtUtils::MakeMaker;
use vars qw( $VERSION );
$VERSION = MM->parse_version('lib/Pod/WikiDoc.pm');

# Load Text::Balanced into Parse::RecDescent
package Parse::RecDescent;
use Text::Balanced qw( extract_bracketed extract_delimited extract_tagged );
package main;

# Load grammar from __DATA__

my $grammar = do { local $/; <DATA> };

# Write to blib if exists or lib if it doesn't

my $blib_path = -d 'blib' ? 'blib/' : '';
$blib_path .= 'lib/Pod/WikiDoc';
mkpath $blib_path;

my $target_file = IO::File->new( "$blib_path/Parser.pm", ">" ) or die $!;

# Temporarily change to temp directory since PRD Precompile writes to
# current directory only
my $cd = tempd();

# Generate Parser file

$Parse::RecDescent::skip = q{};
$RD_HINT = 0;
Parse::RecDescent->Precompile( $grammar, "Pod::WikiDoc::Parser" );

# open it up and open destination
my $precompile = IO::File->new( "Parser.pm" ) or die $!;

# copy up to the package statement line

while ( my $line = <$precompile> ) {
    print {$target_file} $line;
    last if $line =~ /^package\s/;
}

# interpolate version and add it with strictures

print {$target_file} << "HERE";

use strict;

our \$VERSION = '$VERSION';

=for Pod::Coverage new

=cut

HERE

# copy the rest of the precompiled parser

print {$target_file} <$precompile>;

# Append version and grammar for reference

print {$target_file} << "HERE";

__END__

=begin grammar

$grammar

=end grammar

HERE

exit;

#--------------------------------------------------------------------------#
# parser grammer is kept in __DATA__
#--------------------------------------------------------------------------#

__DATA__
    { use Text::Balanced qw( extract_tagged ) }

    WikiDoc:        
            Block(s?)
                { $return = [ grep { $_->{type} ne 'Empty_Line' } @{ $item[1] } ] }

    Block:          
            Header 
                { $return = $item[1] }
        |   Unordered_List 
                { $return = $item[1] }
        |   Ordered_List 
                { $return = $item[1] }
        |   Preformat
                { $return = $item[1] }
        |   Paragraph
                { $return = $item[1] }
        |   Empty_Line
                { $return = $item[1] }

    Header:         
            /^=+/ /[\t\ ]+/ /[^\n]*/ "\n" 
                { 
                    $return = { 
                        type    => $item[0],
                        level   => length($item[1]),
                        content => $thisparser->Inline( $item[3] ),
                    }
                }

    Unordered_List: 
            Bullet_Item(s) Empty_Line(?)
                { 
                    $return = { 
                        type    => $item[0],
                        content => $item[1],
                    }
                }
    
    Bullet_Item:    
            Bullet_Line List_Continuation(s?)
                { 
                    $return = { 
                        type    => $item[0],
                        content => $thisparser->Inline( join( "\n", $item[1],  @{$item[2]} ) ),
                    }
                }
    
    Bullet_Line:    
            /^\*[\t\ ]*\n/
                { $return = q{} }
        |   /^\*[\t\ ]+/ /[^\n]*/ "\n"
                { $return = $item[2] }

    Ordered_List:   
            Numbered_Item(s) Empty_Line(?)
                { 
                    $return = { 
                        type    => $item[0],
                        content => $item[1],
                    }
                }
    
    Numbered_Item:  
            Numbered_Line List_Continuation(s?)
                { 
                    $return = { 
                        type    => $item[0],
                        content => $thisparser->Inline( 
                            join( "\n", $item[1],  @{$item[2]} ) 
                        ),
                    }
                }
    
    Numbered_Line:  
            /^0[\t\ ]*\n/ 
                { $return =  q{} }
        |   /^0[\t\ ]+/ /[^\n]*/ "\n"
                { $return = $item[2] }

    List_Continuation: 
            /^[^*0\s]/ /[^\n]*/ "\n"
                { $return = $item[1] . $item[2] }
    
    Preformat:      
            Indented_Line(s) Indent_Continuation(s?) Empty_Line(?)
                { 
                    $return = { 
                        type    => $item[0],
                        content => [ @{$item[1]}, map { @{$_} } @{$item[2]} ],
                    }
                }
    
    Indented_Line:  
            /^[\t\ ]+/ /[^\t\n\ ]+/ /[^\n]*/ "\n"
                { 
                    $return = { 
                        type    => $item[0],
                        content => $item[1] . $item[2] . $item[3],
                    }
                }

    Indent_Continuation:
            Empty_Line(s) Indented_Line(s)
                { $return = [ @{$item[1]}, @{$item[2]} ] }
                    
    Empty_Line:     
            /^[\t\ ]*/ "\n"
                { 
                    $return = { 
                        type    => $item[0],
                        content => $item[1],
                    }
                }
    
    Plain_Line:     
            /^[^*0\n\t\ ]|[*0][^\t\ ]/ /[^\n]+/ "\n"
                { $return =  $item[1] . $item[2] . $item[3] }

    Paragraph:      
            Plain_Line(s)
                { 
                    $return = { 
                        type    => $item[0],
                        content => $thisparser->Inline( 
                            join( q{}, @{$item[1]} )
                        ),
                    }
                }

    Inline: 
            Chunk(s?)
                { $return = $item[1] }

    Chunk:
            WhiteSpace
                { $return = $item[1] }
        |   InlineCode
                { $return = $item[1] }
        |   BoldText
                { $return = $item[1] }
        |   ItalicText
                { $return = $item[1] }
        |   LinkText
                { $return = $item[1] }
        |   EscapedChar
                { $return = $item[1] }
        |   KeyWord
                { $return = $item[1] }
        |   Parens
                { $return = $item[1] }
        |   RegularText
                { $return = $item[1] }

    InlineCode:   
            { extract_bracketed( $text, '{' ) }
                { 
                    $return = { 
                        type    => $item[0],
                        content => substr( substr( $item[1], 1), 0, -1 ),
                    }
                }


    BoldText:   
            { extract_delimited( $text, '*' ) }
                { 
                    $return = { 
                        type    => $item[0],
                        content => $thisparser->Inline(
                            substr( substr( $item[1], 1), 0, -1 )
                        ),
                    }
                }

    ItalicText: 
            { extract_delimited( $text, '~' ) }
                { 
                    $return = { 
                        type    => $item[0],
                        content => $thisparser->Inline(
                            substr( substr( $item[1], 1), 0, -1 )
                        ),
                    }
                }

    KeyWord:   
            { extract_tagged( $text, '%%', '%%' ) }
                { 
                    $return = { 
                        type    => $item[0],
                        content => substr( substr( $item[1], 2), 0, -2 ),
                    }
                }

    LinkText:   
            { extract_bracketed( $text, '[' ) }
                { 
                    $return = $thisparser->LinkContent( 
                        substr( substr( $item[1], 1), 0, -1 )
                    ),
                }

    EscapedChar:
            "E" { extract_bracketed( $text, '<' ) }
                {
                    $return = { 
                        type    => $item[0],
                        content => $item[1] . $item[2]
                    }
                }

    Parens:
            { extract_bracketed( $text, '(' ) }
                { 
                    $return = { 
                        type    => $item[0],
                        content => $thisparser->Inline(
                            substr( substr( $item[1], 1), 0, -1 )
                        ),
                    }
                }

    RegularText:  
            m{ ^ \S+ }x
                { 
                    $return = { 
                        type    => $item[0],
                        content => $item[1],
                    }
                }

    WhiteSpace:  
            m{ ^ \s+ }x
                { 
                    $return = { 
                        type    => $item[0],
                        content => $item[1],
                    }
                }

    LinkContent:
            LinkLabel "\|" LinkTarget
                {   
                    $return = { 
                        type    => $item[0],
                        content => [ $item[1], $item[3] ],
                    }
                }
        |   LinkTarget
                {
                    $return = { 
                        type    => $item[0],
                        content => [ $item[1] ],
                    }
                }

    LinkLabel:
            /^[^|]*/
                { 
                    $return = { 
                        type    => $item[0],
                        content => $thisparser->Inline( $item[1] ),
                    }
                }

    LinkTarget:
            /.+/
                { 
                    $return = { 
                        type    => $item[0],
                        content => $item[1],
                    }
                }
    
