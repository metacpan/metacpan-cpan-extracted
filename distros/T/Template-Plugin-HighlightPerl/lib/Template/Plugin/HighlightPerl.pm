#============================================================= -*-Perl-*-
#
# Template::Plugin::HighlightPerl
#
# DESCRIPTION
#   Template Toolkit Filter For Syntax Highlighting
#
# AUTHOR
#   Stephen Sykes <stephen@stephensykes.us>
#   http://www.stephensykes.us
#
# COPYRIGHT
#   Copyright (C) 2008 Stephen Sykes.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#============================================================================

package Template::Plugin::HighlightPerl;

use Syntax::Highlight::Perl;
use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );
use strict;

our $VERSION = '0.04';

sub init {
    my $self = shift;
    my $name = $self->{ _CONFIG }->{ name } || 'highlight_perl';
    $self->install_filter($name);
    return $self;
}

sub filter {
    my ($self, $text) = @_;
    
    if (($text !~ '\[perl]') && ($text !~ '\[code]') && ($text !~ '\[nobr]')) {
        $text = break($text);
    } else {
        if ($text =~ '\[perl]') {
            $text = perl($text);
        }
        if ($text =~ '\[code]') {
            $text = code($text);
        }
        if ($text =~ '\[nobr]') {
            $text = nobreak($text);
        }
    }
    return $text;
    
}

sub perl {
    my $text = shift;
    
    $text =~ s/<br>//g;
    
    my $color_table = {
        'Variable_Scalar'   => 'color:#FFFFFF;',
        'Variable_Array'    => 'color:#FFFFFF;',
        'Variable_Hash'     => 'color:#FFFFFF;',
        'Variable_Typeglob' => 'color:#f03;',
        'Subroutine'        => 'color:#FFFFFF;',
        'Quote'             => 'color:#DEDE73;',
        'String'            => 'color:#DEDE73;',
        'Comment_Normal'    => 'color:#ACAEAC;font-style:italic;',
        'Comment_POD'       => 'color:#ACAEAC;font-family:' .
                                   'garamond,serif;font-size:11pt;',
        'Bareword'          => 'color:#FFFFFF;',
        'Package'           => 'color:#FFFFFF;',
        'Number'            => 'color:#4AAEAC;',
        'Operator'          => 'color:#7BE283;',
        'Symbol'            => 'color:#7BE283;',
        'Keyword'           => 'color:#7BE283;',
        'Builtin_Operator'  => 'color:#7BE283;',
        'Builtin_Function'  => 'color:#7BE283;',
        'Character'         => 'color:#DEDE73;',
        'Directive'         => 'color:#ACAEAC;font-style:italic;',
        'Label'             => 'color:#939;font-style:italic;',
        'Line'              => 'color:#000;',
        'Print'             => 'color:#7BE283;',
        'Hash'              => 'color:#FFFFFF;',
        'Translation_Operation'           => 'color=#3199FF;',
    };
    
    my $formatter = Syntax::Highlight::Perl->new();
    
    $formatter->define_substitution('<' => '&lt;', 
                                    '>' => '&gt;', 
                                    '&' => '&amp;'); # HTML escapes.
    
    # install the formats set up above
    while ( my ( $type, $style ) = each %{$color_table} ) {
        $formatter->set_format($type, [ qq|<span style="$style">|, 
                                        '</span>' ] );
    }

    my @code = split(/\[perl]/, $text);
    for my $rec (@code) {
        my $format_code;
        
        if ($rec =~ '\[/perl]') {
            my @code_rec = split(/\[\/perl]/, $rec);
            my $count = 0;
            for my $ret (@code_rec) {
                $count++;
                if ($count % 2 == 1) {
                    my $formatter_code  = $formatter->format_string($ret);
                    my $line_count = 0;
                    my @line_ar = split(/\n/, $formatter_code);
                    for my $line ( @line_ar ) {
                        $line_count++;
                        if ($line_count == 1) {
                            $formatter_code = $line;
                        } else {
                            $formatter_code .= $line;
                        }
                    }
                    $format_code  = '<div class="highlight_perl_head">Perl Code:</div>';
                    $format_code .= '<div class="highlight_perl_body"><pre>' .$formatter_code. '</pre></div>';
                } else {
                    $ret =~ s/\n/<br>/g;
                    $format_code = $ret;
                }
                $text .= $format_code;
           }
            
        } else {
            $rec =~ s/\n/<br>/g;
            $text = $rec;
        }
    }
    return $text;
    
}

sub code {
    my $text = shift;
    
    $text =~ s/<br>/\n/g;
    
    my @code = split(/\[code]/, $text);
    for my $rec (@code) {
        my $format_code;
        if ($rec =~ '\[/code]') {
            my @code_rec = split(/\[\/code]/, $rec);
            my $count = 0;
            for my $ret (@code_rec) {
                $count++;
                if ($count % 2 == 1) {
                    $ret =~ s/</&lt;/g;
                    $ret =~ s/>/&gt;/g;
                    $format_code  = '<div class="highlight_code_head">Code:</div>';
                    $format_code .= '<div class="highlight_code_body"><pre>' .$ret. '</pre></div>';
                } else {
                    $ret =~ s/\n/<br>/g;
                    $format_code = $ret;
                }
                $text .= $format_code;
           }
        } else {
            $rec =~ s/\n/<br>/g;
            $text = $rec;
        }
    }
    return $text;
    
}

sub nobreak {
    my $text = shift;
    $text =~ s/\[nobr\]//g;
    $text =~ s/\[\/nobr\]//g;
    return $text;
}

sub break {
    my $text = shift;
    $text =~ s/\n/<br>/g;
    return $text;
}

1;

__END__

=head1 NAME

Template::Plugin::HighlightPerl - Template Toolkit plugin which 
implements wrapper around L<Syntax::Highlight::Perl> module.

=head1 SYNOPSIS

    [% USE HighlightPerl -%]

    [% FILTER highligh_perl -%]
        [perl]Code block here[/perl]
        [code]None perl code here[/code]
        [nobr]No code and no line breaks[/nobr]
    [% END -%]

=head1 DESCRIPTION

Template::Plugin::HighlightPerl - Template Toolkit plugin which 
implements wrapper around L<Syntax::Highlight::Perl> module and provides filter
for converting perl code to syntax highlighted HTML. Also adds support for
non-perl code, see below.

If you plan to use this in a blog type application, just make sure to use
the proper code tags around you Perl code before you store to database.

Proper and required code tags are:
Open:  [perl]
Close: [/perl]

Your Perl code goes between opening and closing tags. ;)

If you need to format non-perl code, use the following tags:
Open:  [code]
Close: [/code]

If you are not using code tags and do not want line breaks:
Open: [nobr]
Close [/nobr]

Within your template file, use the following:

    [% USE HighlightPerl -%]

    [% FILTER highligh_perl -%]
        [% article.body %]
    [% END -%]

Where [% article.body %] is data passed to the template file from database query.

Please note that, unless you use [nobr] tags, line breaks are generated. So you
will not need to use other TT2 filters, such as html_line_break or html_para.
Also note that pre tags are automaticlly producted to maintain proper formatting
of your Perl code, so there is no need to add white space pre to css file.

This template filter also produces CSS div classes for user customization. 

Generated CSS classes for perl code:
    <div class="highlight_perl_head">Perl Code:</div>
    <div class="highlight_perl_body"><pre>Perl Code</pre></div>

Generated CSS for non-perl code:
    <div class="highlight_code_head">Code:<div>
    <div class="highlight_code_body"><pre>Non-Perl Code</pre></div>

For example, you can use the following in your css file:

    .highlight_perl_head {
        margin-left: 10px;
    }
    .highlight_perl_body {
        margin-left: 10px;
        margin-top:5px;
        margin-bottom: 5px;
        white-space: pre;
        background: #0a0a0a;
        color: #cccccc;
        font-family: monospace;
        font-size: 93%;
        border: 1px solid #555555;
        overflow: auto;
        padding: 10px;
        width: 640px;
    }
    .highlight_code_head {
        margin-left: 10px;
    }
    .highlight_code_body {
        margin-left: 10px;
        margin-top:5px;
        margin-bottom: 5px;
        white-space: pre;
        background: #0a0a0a;
        color: #cccccc;
        font-family: monospace;
        font-size: 93%;
        border: 1px solid #555555;
        overflow: auto;
        padding: 10px;
        width: 640px;
    }

This will produce nice div areas with head description and black background and auto-scoll bars for code overflow.

=head1 SEE ALSO

L<Template|Template>, L<Syntax::Highlight::Perl>

=head1 AUTHOR

Stephen Sykes, E<lt>stephen@stephensykes.usE<gt>

L<http://www.stephensykes.us/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 StephenSykes. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
