package CGI::Kwiki::Slides;
$VERSION = '0.18';
use strict;
use base 'CGI::Kwiki';
use CGI::Kwiki;

attribute 'title';
attribute 'subtitle';
attribute 'bgcolor';

sub process {
    my ($self) = @_;
    $self->title($self->loc('Title Goes Here'));
    $self->subtitle('');
    $self->bgcolor('');

    my $page_id = $self->cgi->page_id;
    my $wiki_text = $self->database->load($page_id);
    my @slides = split "----\n", $wiki_text;
    my ($slide_num, $line_num) = $self->get_position(\@slides);

    my $formatter = CGI::Kwiki::Slides::Formatter->new($self->driver);
    my $directives = join "\n", 
      ((join '', @slides[1..($slide_num - 1)]) =~ /(\[&.*?\])/g);
    $formatter->process($directives);
    my $slide = $formatter->process($slides[$slide_num]);

    return $self->template->process('slide_page', 
        slide => $slide,
        slide_num => $slide_num,
        line_num => $line_num,
        title => $self->title,
        subtitle => $self->subtitle,
        bgcolor => $self->bgcolor,
    );
}

sub get_position {
    my ($self, $slides) = @_;
    my $slide_num = $self->cgi->slide_num || 1;
    my $line_num = $self->cgi->line_num;
    
    my $control = $self->cgi->control;
    if (not length($line_num)) {
        if ($control eq 'advance') {
            $slide_num++;
        }
        elsif ($control eq 'goback') {
            $slide_num--;
        }
    }

    if ($slides->[$slide_num] =~ /\[&lf\]/) {
        if (not length $line_num) {
            $line_num = 0;
        }
        elsif ($control eq 'advance') {
            $line_num++;
            my @matches = $slides->[$slide_num] =~ /(^\*+ )/mg;
            if ($line_num > @matches) {
                $slide_num++;
                $line_num = '';
            }
        }
        elsif ($control eq 'goback') {
            $line_num--;
            if ($line_num == -1) {
                $slide_num--;
                $line_num = '';
            }
        }
        if ($slides->[$slide_num] =~ /\[&lf\]/) {
            if ($line_num) {
                my @matches = $slides->[$slide_num] =~ /(^\*+ )/mg;
                $slides->[$slide_num] =~ s/(.*?)((?:^\*+.*?\n.*?){$line_num}).*/$1$2/ms;
                if ($line_num >= @matches) {
                    $slides->[$slide_num] .= "----\n";
                }
            }
            else {
                $slides->[$slide_num] =~ s/^\*+.*//ms;
                $line_num = 0;
            }
        }
    }
    
    $slide_num = $#{$slides} if $slide_num >= @$slides;
    $slide_num = 1 if $slide_num <= 0;
    return ($slide_num, $line_num);
}

package CGI::Kwiki::Slides::Formatter;
use base 'CGI::Kwiki::Formatter';

sub process_order {
    my ($self) = @_;
    grep { not /link/ } $self->SUPER::process_order;
}

sub user_functions {
    return qw( title subtitle bgcolor img );
}

sub img {
    my ($self, $url, %options) = @_;
    my $height = defined $options{height} 
                 ? qq[height="$options{height}"] : '';
    my $width = defined $options{width} 
                 ? qq[width="$options{width}"] : '';
    my $border = $options{border} || 0;
    qq{<img src="$url" border="$border" $height $width align="right">\n};
}

sub bgcolor {
    my $self = shift;
    $self->driver->slides->bgcolor(shift || '');
    '';
}

sub title {
    my $self = shift;
    $self->driver->slides->title(join ' ', @_);
    '';
}

sub subtitle {
    my $self = shift;
    $self->driver->slides->subtitle(join ' ', @_);
    '';
}

# XXX - Use Stylesheet
sub code_postformat {
    my ($self, $text) = @_;
    return <<END;
<blockquote>
<table bgcolor="lightyellow" cellspacing="5"><tr><td>
<pre>$text</pre>
</table>
</blockquote>
END
}

1;

__END__

=head1 NAME 

CGI::Kwiki::Slides - Slide Show Plugin for CGI::Kwiki

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
