package Spork::Hilite;
our $VERSION = '0.11';

use Kwiki::Plugin -Base;
use Kwiki::Installer -base;

const class_title => 'Color Hiliting for Spork';
const class_id => 'hilite';
const css_file => 'hilite.css';

sub register {
    my $registry = shift;
    $registry->add(preload => 'hilite');
    $registry->add(wafl => hilite => 'Spork::Hilite::Wafl');
}

sub init {
    $self->hub->css->add_file($self->css_file);
}

package Spork::Hilite::Wafl;
use Spoon::Formatter;
use base 'Spoon::Formatter::WaflBlock';

sub QQQ {
    no warnings;
    XXX(@_) if ++$::xxx == 3;
    @_;
}

sub to_html {
    my ($code, $directives) = $self->split;
    my $map = $self->parse($code, $directives);
    my $formatted = $self->format($code, $map);
    return $self->escape($formatted);
}

my %color_map = (
    r => 'red',
    g => 'green',
    b => 'blue',
    c => 'cyan',
    m => 'magenta',
    y => 'yellow',
    w => 'white',
);
sub escape {
    require CGI;
    my $output = CGI::escapeHTML(shift);
    $output =~ s/~([rgbycmw])~/qq[<span class="hilite_$color_map{$1}">]/eg;
    $output =~ s!~/~!</span>!g;
    join '', map "$_\n", "<pre>", $output, "</pre>";
}

sub format {
    my ($code, $map) = @_;
    my @output;
    for (my $i = 0; $i < @$code; $i++) {
        my $line = $code->[$i];
        $line = $self->markup($line, $map->[$i])
          if defined $map->[$i];
        push @output, $line;
    }
    join "\n", @output;
}

sub markup {
    my ($line, $mark) = @_;
    my $out = '';
    my $current = '';
    for (my $i = 0; $i < length($line); $i++) {
        my $hilite = $mark->[$i] ? $mark->[$i][0] : '';
        if ($current ne $hilite) {
            $out .= '~/~' if $current;
            $out .= "~$hilite~"
              if $hilite;
            $current = $hilite;
        }
        $out .= substr($line, $i, 1);
    }
    $out .= '~/~' if $current;
    return $out;
}

sub detect_paragraphs {
    my ($line, $number, $code) = @_;
    my $start = $number;
    while ($number < @$code) {
        last if $code->[$number] =~ /^\s*$/;
        $number++;
    }
    map {
        "$line$_";
    } $start .. $number;
}

sub parse {
    my ($code, $directives) = @_;
    my @directives = map {
        /(.*?)(\d+)-(\d+)$/
        ? do {
            my ($line, $start, $end) = ($1, $2, $3);
            map {
                "$line$_";
            } $start .. $end;
        }
        : /(.*?)(\d+)\@$/
          ? do {
              $self->detect_paragraphs($1, $2, $code);
          }
          : $_;
    } @$directives;
    my @map;
    my $num = 0;
    for my $line (@$code) {
        $num += 1;
        for (@directives) {
            my $dir = $_;
            next unless $dir =~ s/\s+$num$//;
            my $repeat_char = '';
            for (my $i = 0; $i < length($line); $i++) {
                no warnings;
                my $char = substr($dir, $i, 1) || '';
                $char = '' if $char eq ' ';
                $repeat_char = $char eq '+'
                  ? substr($dir, $i - 1, 1)
                  : $char
                    ? ''
                    : $repeat_char;
                $char = undef if $char eq '+';
                $char ||= $repeat_char
                  if $repeat_char;
                push @{$map[$num - 1]->[$i]}, $char
                  if $char;
            }
        }
    }
    return \ @map;
}

sub split {
    my $text = $self->text;
    my @lines = map {chomp; $_} ($text =~ /^(.*\n?)/gm);
    my(@code, @directives);
    
    while (@lines) {
        last if $lines[0] =~ /^[rgbycmw\+\ ]+\d+(-\d+|\@)?$/;
        push @code, shift @lines;
    }
    pop @code while (@code and $code[-1] eq '');
    for (reverse @lines) {
        next unless ($_ or @directives);
        last unless $_;
        unshift @directives, $_;
    }
    return (\@code, \@directives);
}

package Spork::Hilite;

__DATA__

=head1 NAME

Spork::Hilite - Hilite Code Snippets in Spork

=head1 SYNOPSIS

    ----
    == Watch The Pretty Colors Move
    
    .hilite
    sub spork {
        print "I Like Spork\n";
    }

               r 2
    +
                 gggg 2
    +
                      bbbbb 2
    ----
    == Next Slide. etc
                       

=head1 DESCRIPTION

This plugin lets you mark code snippets with specific colors. It is
especially good for changing colors several times on the same snippet.

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__css/hilite.css__
.hilite_red     { color: red;}
.hilite_green   { color: green;}
.hilite_blue    { color: blue;}
.hilite_yellow  { color: yellow;}
.hilite_cyan    { color: cyan;}
.hilite_magenta { color: magenta;}
.hilite_white   { color: white;}
