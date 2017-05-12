package Spork::Formatter;
use Kwiki::Formatter -Base;

sub formatter_classes {
    (
        (map { s/^Heading$/Spork::Formatter::Heading/; $_ } super),
        'Spork::Formatter::Inline',
    );
}  

const all_phrases => [qw(wafl_phrase asis strong em u tt tt2 hyper)];

sub wafl_classes { qw( Spork::Formatter::Image Spork::Formatter::File) }

################################################################################
package Spork::Formatter::Inline;
use base 'Spoon::Formatter::Unit';
use Kwiki ':char_classes';
const formatter_id => 'tt2';
const pattern_start => qr/(^|(?<=[^$ALPHANUM]))\|/;
const pattern_end => qr/\|(?=[^$ALPHANUM]|\z)/;
const html_start => "<tt>";
const html_end => "</tt>";

################################################################################
package Spork::Formatter::Heading;
use base 'Kwiki::Formatter::Heading';

sub to_html {
    my $text = join '', map {
        ref $_ ? $_->to_html : $_
    } @{$self->units};
    my $level = $self->level;
    $self->hub->slides->slide_heading($text)
      unless $self->hub->slides->slide_heading;
    return "<h$level>$text</h$level>\n";
}

################################################################################
package Spork::Formatter::File;
use base 'Spoon::Formatter::WaflPhrase';
const wafl_id => 'file';

sub html {
    require Cwd;
    my ($file, $link_text) = split /\s+/, $self->arguments, 2;
    $link_text ||= $file;
    $file = $self->hub->config->file_base . "/$file"
      unless $file =~ /^\.{0,1}\//;
    $file = Cwd::abs_path($file);
    qq{<a href="file://$file" } . 
      'target="file" style="text-decoration:underline">' . 
      $link_text . '</a>';
}

################################################################################
package Spork::Formatter::Image;
use base 'Spoon::Formatter::WaflPhrase';
const wafl_id => 'image';

sub to_html {
    $self->hub->slides->image_url($self->arguments);
    return '';
}

__END__

=head1 NAME

Spork::Formatter - Slide Presentations (Only Really Kwiki)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004, 2005. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
