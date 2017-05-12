package pdflib_pl;

use strict;

# This is a testing version of pdflib_pl, used to test PDF::Template.

BEGIN {
    use vars qw($VERSION $AUTOLOAD);

    $VERSION = '4.1';

    use IO::File;
}

my $DEBUG = 0;

my $fh;

sub PDF_new {
    $fh = undef;

    my $pdf = {
        BUFFER => [],
        FONTS  => [ undef ],
        CURRFONT => {},
    };

    print "PDF_new: $pdf\n" if $DEBUG;

    {
        local $" = "', '";
        push @{$pdf->{BUFFER}}, "PDF_new('@_')";
    }

    return $pdf;
}

sub PDF_open_file {
    my $pdf = shift;

    print "PDF_open_file: $pdf\n" if $DEBUG;

    {
        local $" = "', '";
        push @{$pdf->{BUFFER}}, "PDF_open_file('@_')";
    }

    my ($fname) = @_;

    if ($fname)
    {
        $fh = IO::File->new(">$fname")
            || return -1;
    }

    return 1;
}

sub PDF_close {
    my $pdf = shift;

    print "PDF_close: $pdf\n" if $DEBUG;

    {
        local $" = "', '";
        push @{$pdf->{BUFFER}}, "PDF_close('@_')";
    }

    if (UNIVERSAL::isa($fh, 'IO::File'))
    {
        local $" = $/;
        print $fh "@{$pdf->{BUFFER}}\n";
    }

    return 1;
}

sub PDF_get_buffer {
    my $pdf = shift;

    print "PDF_get_buffer: $pdf\n" if $DEBUG;

    {
        local $" = "', '";
        push @{$pdf->{BUFFER}}, "PDF_get_buffer('@_')";
    }

    my $w = wantarray;
    return unless defined $w;

    if (wantarray)
    {
        return @{$pdf->{BUFFER}};
    }
    else
    {
        local $" = $/;
        return "@{$pdf->{BUFFER}}\n";
    }
}

sub PDF_show_boxed {
    my $pdf = shift;

    print "PDF_show_boxed: $pdf\n" if $DEBUG;

    {
        local $" = "', '";
        push @{$pdf->{BUFFER}}, "PDF_show_boxed('@_')";
    }

    return 0;
}

sub PDF_findfont {
    my $pdf = shift;

    print "PDF_findfont: $pdf\n" if $DEBUG;

    {
        local $" = "', '";
        push @{$pdf->{BUFFER}}, "PDF_findfont('@_')";
    }

    push @{$pdf->{FONTS}}, join '|', @_;

    return $#{$pdf->{FONTS}};
}

sub PDF_setfont {
    my $pdf = shift;

    print "PDF_setfont: $pdf\n" if $DEBUG;

    {
        local $" = "', '";
        push @{$pdf->{BUFFER}}, "PDF_setfont('@_')";
    }

    $pdf->{CURRFONT} = {
        FACE => $_[0],
        SIZE => $_[1],
    };

    return 1;
}

sub PDF_get_value {
    my $pdf = shift;

    print "PDF_get_value: $pdf\n" if $DEBUG;

    {
        local $" = "', '";
        @_ = map { defined $_ ? $_ : '' } @_;
        push @{$pdf->{BUFFER}}, "PDF_get_value('@_')";
    }

    if ($_[0] eq 'fontsize')
    {
        return $pdf->{CURRFONT}{SIZE};
    }

    return 1;
}

my @func_names = qw(
    PDF_add_bookmark
    PDF_add_weblink
    PDF_begin_page
    PDF_circle
    PDF_close_image
    PDF_end_page
    PDF_fill
    PDF_fill_stroke
    PDF_lineto
    PDF_moveto
    PDF_open_image_file
    PDF_place_image
    PDF_rect
    PDF_restore
    PDF_save
    PDF_set_info
    PDF_set_parameter
    PDF_setcolor
    PDF_setlinewidth
    PDF_setrgbcolor
    PDF_setrgbcolor_fill
    PDF_setrgbcolor_stroke
    PDF_show_xy
    PDF_stroke
);

sub AUTOLOAD
{
    my $name = $AUTOLOAD;
    $name =~ s/.*::([^:]+)$/$1/;

    no strict 'refs';

    *$AUTOLOAD = sub {
        my $pdf = shift;

        print "$name: $pdf\n" if $DEBUG;

        local $" = "', '";
        push @{$pdf->{BUFFER}}, "${name}('@_')";
    };

    goto &$AUTOLOAD;
}

1;
__END__

