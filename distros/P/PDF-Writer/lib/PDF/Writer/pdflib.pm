package PDF::Writer::pdflib;

use strict;
use warnings;

our $VERSION = '0.02';

use pdflib_pl;

=head1 NAME

PDF::Writer::pdflib - pdflib_pl backend

=head1 SYNOPSIS

(internal use only)

=head1 DESCRIPTION

No user-serviceable parts inside.

=cut

my %dispatch = (
    close           => 'close',
    info            => 'set_info',
    parameter       => 'set_parameter',
    font            => 'setfont',
    find_font       => 'findfont',
    begin_page      => 'begin_page',
    end_page        => 'end_page',
    save_state      => 'save',
    restore_state   => 'restore',
    linewidth       => 'setlinewidth',
    move            => 'moveto',
    line            => 'lineto',
    rect            => 'rect',
    fill            => 'fill',
    stroke          => 'stroke',
    fill_stroke     => 'fill_stroke',
    show_boxed      => 'show_boxed',
    show_xy         => 'show_xy',
    open_image      => 'open_image_file',
    close_image     => 'close_image',
    place_image     => 'place_image',
    circle          => 'circle',
    add_weblink     => 'add_weblink',
    add_bookmark    => 'add_bookmark',
);

sub new {
    my $class = shift;
    return bless({ pdf => pdflib_pl::PDF_new() }, $class);
}

sub open {
    my ($self, $f) = @_; my $p = $self->{pdf};
    $f = '' unless defined $f;
    return (pdflib_pl::PDF_open_file($p, $f) != -1);
}

sub stringify {
    my $self = shift; my $p = $self->{pdf};
    $self->close;
    return pdflib_pl::PDF_get_buffer($p);
}

sub save {
    goto &{$_[0]->can('close')};
}

sub color {
    my $self = shift; my $p = $self->{pdf};
    my ($mode, $palette, @colors) = @_;

    if (pdflib_pl->VERSION >= 4) {
        pdflib_pl::PDF_setcolor($p, $mode, $palette, @colors, 0);
    }
    elsif ($palette ne 'rgb') {
        die 'Palette other than "rgb" is not supported';
    }
    elsif ($mode eq 'fill') {
        pdflib_pl::PDF_setrgbcolor_fill($p, @colors);
    }
    elsif ($mode eq 'stroke') {
        pdflib_pl::PDF_setrgbcolor_stroke($p, @colors);
    }
    else { # both
        pdflib_pl::PDF_setrgbcolor($p, @colors);
    }
}

sub font_size {
    my $self = shift; my $p = $self->{pdf};
    return pdflib_pl::PDF_get_value($p, 'fontsize', 0);
}

sub image_width {
    my $self = shift; my $p = $self->{pdf};
    my ($image) = @_;
    return pdflib_pl::PDF_get_value($p, 'imagewidth', $image);
}

sub image_height {
    my $self = shift; my $p = $self->{pdf};
    my ($image) = @_;
    return pdflib_pl::PDF_get_value($p, 'imageheight', $image);
}

while (my ($k, $v) = each %dispatch) {
    no strict 'refs';
    my $method = "pdflib_pl::PDF_$v";
    *$k = sub {
        my $self = shift;
        my $rv = &$method($self->{pdf}, @_);

        if ($v ne 'show_boxed' && defined $rv) {
            $rv = '0 but true' if $rv eq '0';
            $rv = undef if $rv eq '-1';
        }

        return $rv;
    };
}

1;

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004, 2005 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
