package Perldoc::Emitter::HTML;
use Perldoc::Base -Base;
use Perldoc::Writer;

use HTML::Entities;
my $prev_text;

field 'writer';

sub init {
    my $writer = Perldoc::Writer->new(@_);
    $self->writer($writer);
    return $self;
}

sub begins {
    my $tag = shift;
    $tag =~ s/ .*//;
    my $output = 
        $tag eq 'comment' ? "<!--\n" :
        $tag eq 'a'       ? '<a href="' :
                            "<$tag>\n";
    $self->writer->print($output);
    undef $prev_text;
}
sub ends {
    my $tag = shift;
    my $output = '';
    if ($tag eq 'comment') {
        $output .= "-->\n";
    }
    elsif ($tag =~ /a (.*)/) {
        $output .= $1 unless defined $prev_text;
        $output .= '">';
        $output .= (length($1) ? $1 : $prev_text);
        $output .= '</a>';
    }
    else {
        $output .= "</$tag>\n"
    }
    $self->writer->print($output);
}
sub text {
    my $output = shift;
    $output =~ s/\\(.)/$1/g;
    decode_entities($output);
    encode_entities($output, '<>&"');
    $prev_text = $output;
    $output .= "\n";
    $self->writer->print($output);
}

=head1 NAME

Perldoc::Emitter::HTML - HTML Emitter for Perldoc

=head1 SYNOPSIS

    package Perldoc::Emitter::HTML;

=head1 DESCRIPTION

This class receives Perldoc events and produces HTML.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

Audrey wrote the original code for this parser.

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
