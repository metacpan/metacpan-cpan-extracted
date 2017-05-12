package SnipMate::Snippets;

use 5.14.0;

use strict;
use warnings;

use Method::Signatures;

use Moose;

use MooseX::Types::Path::Class;

use Template::Caribou::Utils;

use Template::Caribou::Tags::HTML qw/ :all /;

use Template::Caribou::Tags
    mytag => { -as => 'span_placeholder', class => 'placeholder', tag => 'span' },
    map { ( mytag => { -as => "div_$_", class => $_ } ) } qw/
        comment code snippet keyword snippets header
    /
    ;


with 'Template::Caribou';

has snippet_file => (
    is => 'ro',
    isa => 'Path::Class::File',
    coerce => 1,
    required => 1,
);

has snippets => (
    is => 'ro',
    lazy => 1,
    builder => '_build_snippets',
);


method _build_snippets {
    my @lines = $self->snippet_file->slurp;

    my @all_snippets;
    my $current_title;
    my @current_snippets;

    my $i = -1;
    LINE:
    while( my $line = $lines[++$i] ) {
        if ( $line =~ s/^##\s*(.*?)\s*/$1/ ) {
            if ( @current_snippets ) {
                push @all_snippets, [ $current_title => @current_snippets ];
            }
            $current_title = $line;
            @current_snippets = ();
            next LINE;
        }

        if ( $line =~ s/^\s*snippet\s+(.*)// ) {
            my $snippet = $1;
            my $comment;
            if ( $i > 0 and $lines[$i-1] =~ /^#(.*)/ ) {
                $comment = $1;
            }
            my $code = $lines[++$i];
            $code =~ s/^(\s+)//;
            my $spaces = $1;
            $code .= $lines[$i] while $lines[++$i] =~ s/^$spaces//;

            push @current_snippets, [ $snippet, $comment, $code ];
        }
    }

    push @all_snippets, [ $current_title => @current_snippets ] 
        if @current_snippets;

    return \@all_snippets;

}

template webpage => method {
    html {
        head { 
            show('style');
        };
        body { 
            h1 {  $self->snippet_file->basename };
            div_snippets {
                show( 'section' => @$_ ) for @{ $self->snippets };
            }
        };
    }
};

template section => method( $title,@snippets ) {

    h2 { $title } if $title;

    show( 'snippet' => @$_ ) for @snippets;
};

template snippet => method ( $label, $comment, $code ) {
    div_snippet {
        div_header { 
            div_keyword { $label; };
            div_comment { $comment; };
        };
        div_code sub {
            my $regex = qr#(\$\{\d+.*?\})#;

            for ( split $regex, $code ) {
                if ( /$regex/ ) {
                    span_placeholder { $_ };
                }
                else {
                    print $_;
                }
            }
        };
    }

};

template style => sub {
    css <<'END_CSS';

@page { size: landscape; }

body {
    font-family: monospace;
}

h2 { 
    background-color: 
    darkblue; color: white; 
    padding: 3px;
    text-align: center;
}

.header { border-bottom: 1px black solid; }

.keyword {
    display: inline-block;
    font-size: 1.5em;
}

.comment {
    float: right;
    font-style: italic;
}

.desc {
    margin-top: 0.5em;
}

.code {
    padding-left: 0.5em;
    white-space: pre;
    margin-top: 1em;
    overflow: hidden;
}

.placeholder {
   color: red;
}

.snippets {
    -moz-column-count: 3;
    -moz-column-gap: 20px;
    -moz-column-rule: 1px solid black;
}

.snippet {
    column-break-inside: avoid; /* doesn't work. boo */
    display: inline-block;      /* workaround for column-break suckiness */
    width: 100%;
    margin-bottom: 1em;
}

END_CSS

};

__PACKAGE__->meta->make_immutable;

1;

