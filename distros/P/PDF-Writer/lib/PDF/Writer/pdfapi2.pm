package PDF::Writer::pdfapi2;

use strict;
use warnings;

our $VERSION = '0.01';

use charnames ':full';
use PDF::API2 0.40;

=head1 NAME

PDF::Writer::pdfapi2 - PDF::API2 backend

=head1 SYNOPSIS

(internal use only)

=head1 DESCRIPTION

No user-serviceable parts inside.

=cut

my %dispatch = (
    pdf => [qw( stringify info )],
    txt => [qw( font )],
    gfx => [qw( move line linewidth stroke fill circle )],
    ''  => [qw( parameter save_state restore_state end_page )],
);

sub new {
    my $class = shift;
    return bless({ pdf => PDF::API2->new }, $class);
}

sub open {
    my ($self, $f) = @_;
    $self->{filename} = $f;
    return !$f || (!-e $f or (!-d $f and -w $f));
}

sub save {
    my $self = shift; my $p = $self->{pdf};
    $p->saveas($self->{filename});
}

sub open_image {
    my $self = shift; my $p = $self->{pdf};
    my ($type, $file, $foo, $bar) = @_;

    require "PDF/API2/Resource/XObject/Image/\U$type\E.pm";
    return "PDF::API2::Resource::XObject::Image::\U$type\E"->new($p->{pdf}, $file);
}

sub image_width {
    my $self = shift; my $p = $self->{pdf};
    my ($image) = @_;
    return $image->width;
}

sub image_height {
    my $self = shift; my $p = $self->{pdf};
    my ($image) = @_;
    return $image->height;
}

sub place_image {
    my $self = shift; my $p = $self->{pdf};
    my ($image, $x, $y, $scale) = @_;
    #$y -= $image->height;
    $self->{gfx}->image($image, $x, $y, $scale);
}

sub close_image {
}

sub find_font {
    my $self = shift; my $p = $self->{pdf};
    my ($face, $pdf_encoding, $is_embed) = @_;
    my $mode = (
        ($face =~ /\.(?:pf[ab]|ps)$/i)
            ? 'ps' :
        ($face =~ /\.(?:ttf|otf|ttc)$/i)
            ? 'tt' :
        ($face =~ /(traditional|simplified|korean|japanese2?)/)
            ? 'cjk'
        : 'core'
    ) . 'font';

    # XXX - handle $pdf_encoding and $is_embed?
    return $p->can($mode)->($p, $face);
}

sub begin_page {
    my $self = shift; my $p = $self->{pdf};
    my ($width, $height) = @_;

    my $page = $p->page;
    $page->mediabox($width, $height);

    $self->{gfx} = $page->gfx;
    $self->{txt} = $page->text;
    $self->{page} = $page;

    return $page;
}

sub color {
    my $self = shift; my $p = $self->{pdf};
    my ($mode, $palette, @colors) = @_;

    die 'Palette other than "rgb" is not supported' unless $palette eq 'rgb';

    $self->{gfx}->fillcolor(@colors) unless $mode eq 'stroke';
    $self->{gfx}->strokecolor(@colors) unless $mode eq 'fill';
    $self->{txt}->fillcolor(@colors) unless $mode eq 'stroke';
    $self->{txt}->strokecolor(@colors) unless $mode eq 'fill';
}

my @SuperScript = (
    "\N{SUPERSCRIPT ZERO}", "\N{SUPERSCRIPT ONE}", "\N{SUPERSCRIPT TWO}",
    "\N{SUPERSCRIPT THREE}", "\N{SUPERSCRIPT FOUR}", "\N{SUPERSCRIPT FIVE}",
    "\N{SUPERSCRIPT SIX}", "\N{SUPERSCRIPT SEVEN}", "\N{SUPERSCRIPT EIGHT}",
    "\N{SUPERSCRIPT NINE}",
);
my @SubScript = (
    "\N{SUBSCRIPT ZERO}", "\N{SUBSCRIPT ONE}", "\N{SUBSCRIPT TWO}",
    "\N{SUBSCRIPT THREE}", "\N{SUBSCRIPT FOUR}", "\N{SUBSCRIPT FIVE}",
    "\N{SUBSCRIPT SIX}", "\N{SUBSCRIPT SEVEN}", "\N{SUBSCRIPT EIGHT}",
    "\N{SUBSCRIPT NINE}",
);

sub show_boxed {
    my $self = shift; my $p = $self->{pdf};
    my ($str, $x, $y, $w, $h, $j, $m) = @_;
    my $txt = $self->{txt};

    return 0 if $m eq 'blind';

    my $method = 'text';
    if ($j =~ /right/) {
        $x += $w;
        $method .= "_$j";
    }
    elsif ($j =~ /center/) {
        $x += $w / 2;
        $method .= "_$j";
    }

    $txt->translate($x, $y);

    my @tokens = split(/ /, $str);
    my @try;
    my $advance_width;
    while (@tokens) {
        push @try, shift(@tokens);
        $advance_width = $txt->advancewidth("@try");
        if ($advance_width >= $w) {
            # overflow only if absolutely neccessary
            pop @try if @try > 1;

            my $chunk = $self->_transform_text("@try");
            $self->_draw_underline($txt->advancewidth($chunk)) if $j =~ /underline/;

            # XXX - sup/sub handling here
            $txt->can($method)->($self->{txt}, $chunk);
            return length($str) - length($chunk);
        }
    }

    my $chunk = $self->_transform_text($str);
    $self->_draw_underline($txt->advancewidth($chunk)) if $j =~ /underline/;
    $txt->can($method)->($self->{txt}, $chunk);

    return 0;
}

sub _transform_text {
    my ($self, $text) = @_;
    my $found;
    foreach my $i (0..9) {
        # XXX - handle subscript.
        # also, redraw using ->transform, instead of substituting
        $found++ if $text =~ s/$SuperScript[$i]/<-<$i>->/g;
    }
    if ($found) {
        $text =~ s/>-><-<//g;
        $text =~ s/ ?<-</ [/g;
        $text =~ s/>->/]/g;
    }
    return $text;
}

sub _draw_underline {
    my $self = shift;
    my $width = shift or return;

    my ($txt, $gfx) = @{$self}{'txt', 'gfx'};

    my %state = $txt->textstate;
    my ($x1, $y1) = $txt->textpos;
    $txt->matrix_update($width, 0);
    my ($x2, $y2) = $txt->textpos;
    my $x3 = $x1 + (($y2 - $y1) / $width)
             * ($txt->{' font'}->underlineposition * $txt->{' fontsize'} / 1000);
    my $y3 = $y1 + (($x2 - $x1) / $width)
             * ($txt->{' font'}->underlineposition * $txt->{' fontsize' }/ 1000);
    my $x4 = $x3 + ($x2 - $x1);
    my $y4 = $y3 + ($y2 - $y1);
    $gfx->save;
    $gfx->linewidth(0.5);
    $gfx->strokecolor(0, 0, 0);
    $gfx->move($x3, $y3);
    $gfx->line($x4, $y4);
    $gfx->stroke;
    $gfx->restore;
    $txt->textstate(%state);
}

sub show_xy {
    my $self = shift; my $p = $self->{pdf};
    my ($str, $x, $y) = @_;

    $self->{txt}->translate($x, $y);
    $self->{txt}->text($str);
}

sub font_size {
    my $self = shift; my $p = $self->{pdf};
    return $self->{txt}{' fontsize'};
}

sub rect {
    my $self = shift; my $p = $self->{pdf};
    my $gfx = $self->{gfx};
    $gfx->linewidth(0.2);
    $gfx->rect(@_);
}

sub fill_stroke {
    my $self = shift; my $p = $self->{pdf};
    my $gfx = $self->{gfx};
    $gfx->fillstroke(@_);
}

sub close { %{$_[0]} = (); }

sub add_weblink {
    die "->add_weblink is not implemented yet for pdfapi2."
}

sub add_bookmark {
    die "->add_bookmark is not implemented yet for pdfapi2."
}

while (my ($k, $v) = each %dispatch) {
    foreach my $method (@$v) {
        no strict 'refs';
        if ($k) {
            *$method = sub {
                my $self = shift;
                $self->{$k}->can($method)->($self->{$k}, @_);
            };
        }
        else {
            *$method = sub {
                return 1;
            }
        }
    }
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
