package Quiq::Gnuplot::Process;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::Gnuplot::Plot;
use Quiq::FileHandle;
use Quiq::Path;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gnuplot::Process - Gnuplot-Prozess

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Gnuplot-Prozess.
Ein Gnuplot-Prozess erzeugt Plots.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Gnuplot-Prozess

=head4 Synopsis

    $gnu = Quiq::Gnuplot::Process->new;

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $fh = Quiq::FileHandle->new('|-','gnuplot');
    $fh->autoFlush;

    my $self = $class->SUPER::new(
        debug => 0,
        fh => $fh,
    );
    $self->set(@_);
    
    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 render() - Rendere Plot

=head4 Synopsis

    $gnu->render($plt);
    $img = $gnu->render($plt); # funktioniert nicht

=head4 Description

Rendere den Plot und speichere ihn auf auf der angebenen Bilddatei
oder liefere die Bilddaten zurück. Werden die Bilddaten zurückgeliefert,
wird die Bilddatei automatisch gelöscht.

=cut

# -----------------------------------------------------------------------------

sub render {
    my ($self,$plt) = @_;

    my $fh = $self->fh;
    my $timeSeries = $plt->timeSeries;

    if (my $terminal = $plt->terminal) {
        my $cmd = "set terminal $terminal";
        my $width = $plt->width;
        my $height = $plt->height;
        if ($width && $height) {
            $cmd .= " size $width, $height";
        }
        # $cmd .= ' small'; # globaler font s. S. 2006
        $self->print("$cmd\n");
    }
    $self->print("set lmargin 12\n");
    # $self->print("set size 0.5\n");
    # $self->print("set origin 0.5,0.5\n");

    my $output = $plt->output;
    if ($output) {
        $self->print("set output '$output'\n");
    }

    if ($timeSeries) {
        $self->print("set xdata time\n");
        # $self->print("unset autoscale x\n");
        $self->print(qq|set timefmt "%Y-%m-%d %H:%M:%S"\n|);
        if (my $formatX = $plt->formatX || '%H:%M') {
            $self->print(qq|set format x "$formatX"\n|);
            # $self->print("set format x '%H:%M'\n");
            # $self->print("set format x '%Y-%m-%d %H:%M'\n");
        }
    }
    
    my $xMin = $plt->xMin;
    my $xMax = $plt->xMax;
    if (defined $xMin || defined $xMax) {
        my $cmd = 'set xrange [';
        if (defined $xMin) {
            $cmd .= "'$xMin'";
        }
        $cmd .= ':';
        if (defined $xMax) {
            $cmd .= "'$xMax'";
        }
        $cmd .= ']';
        $self->print("$cmd\n");
    }

    my $yMin = $plt->yMin;
    my $yMax = $plt->yMax;
    if (defined $yMin || defined $yMax) {
        my $cmd = 'set yrange [';
        if (defined $yMin) {
            $cmd .= $yMin;
        }
        $cmd .= ':';
        if (defined $yMax) {
            $cmd .= $yMax;
        }
        $cmd .= ']';
        $self->print("$cmd\n");
    }
    
    if (my $title = $plt->title) {
        my $cmd = qq|set title "$title"|;
        if (my $titleFont = $plt->titleFont) {
            $cmd .= qq| font "$titleFont"|;
        }
        $self->print("$cmd\n");
    }
    if (my $xlabel = $plt->xlabel) {
        $self->print(qq|set xlabel "$xlabel"\n|);
    }
    if (my $ylabel = $plt->ylabel) {
        $self->print(qq|set ylabel "$ylabel"\n|);
    }

    if (my $ytics = $plt->ytics) {
        $self->print("set ytics $ytics\n");
    }
    
    if ($plt->mxTics) {
        $self->print("set mxtics\n");
    }
    if ($plt->myTics) {
        $self->print("set mytics\n");
    }

    my $legendPos = $plt->legendPosition;
    $self->print("set key $legendPos reverse Left box linetype 0\n");
    $self->print("set grid xtics mxtics ytics mytics back\n");

    # Arrows
    
    my $arwA = $plt->arrows;
    if (@$arwA) {
        my $i = 1;
        for my $arw (@$arwA) {
            my $str = sprintf 'set arrow %d',$i++;
            my $fromA = $arw->from;
            if ($timeSeries) {
                $str .= sprintf " from '%s',%s",@$fromA;
            }
            else {
                $str .= sprintf " from %s,%s",@$fromA;
            }
            my $toA = $arw->to;
            if ($timeSeries) {
                $str .= sprintf " to '%s',%s",@$toA;
            }
            else {
                $str .= sprintf " to %s,%s",@$toA;
            }
            if (my $heads = $arw->heads) {
                $str .= " $heads";
            }
            if (my $lineType = $arw->lineType) {
                $str .= " linetype $lineType";
            }
            if (my $lineWidth = $arw->lineWidth) {
                $str .= " linewidth $lineWidth";
            }
            if (my $lineStyle = $arw->lineStyle) {
                $str .= " linestyle $lineStyle";
            }
            $str .= "\n";
            $self->print($str);
        }
    }

    # Labels

    my $labA = $plt->labels;
    if (@$labA) {
        my $i = 1;
        for my $lab (@$labA) {
            my $str = sprintf 'set label %d "%s"',$i++,$lab->text;
            my $atA = $lab->at;
            if ($timeSeries) {
                $str .= sprintf " at '%s',%s",@$atA;
            }
            else {
                $str .= sprintf " at %s,%s",@$atA;
            }
            if (my $font = $lab->font) {
                $str .= " font '$font'";
            }
            if (my $textColor = $lab->textColor) {
                $str .= " tc $textColor";
            }
            $str .= "\n";
            $self->print($str);
        }
    }

    # Graphen

    my $gphA = $plt->graphsWithData;
    if (@$gphA) {
        my $str;
        for my $gph (@$gphA) {
            if ($str) {
                $str .= ', ';
            }
            my $to = $timeSeries? 3: 2;
            $str .= "'-' using 1:$to";
            if (my $title = $gph->title) {
                $str .= " title '$title'";
            }
            else {
                $str .= ' notitle';
            }
            my $with = $gph->with || 'points';
            $str .= " with $with";
            my $style = $gph->style;
            if (defined $style) {
                $str .= " $style";
            }
        }
        $self->print("plot $str\n");
    
        for my $gph (@$gphA) {
            my $dataA = $gph->data;          
            for (my $i = 0; $i < @$dataA; $i += 2) {
                my $x = $dataA->[$i];
                if (!defined $x || $x eq '') {
                    $x = 'NaN';
                }
                my $y = $dataA->[$i+1];
                if (!defined $y || $y eq '') {
                    $y = 'NaN';
                }
                $self->print("$x $y\n");
            }
            $self->print("e\n");
        }
    }

    $self->print("reset\n");

    # Forcieren, dass Gnuplot die Datei schreibt
    $self->print("unset output\n");

    # Funktioniert nicht, da wir nicht wissen, wann Gnuplot die Datei
    # zuende geschrieben hat

    #if (defined wantarray) {
    #    # Wir liefern die Bilddaten zurück und löschen die Datei
    #
    #    my $img = Quiq::Path->read($output);
    #    Quiq::Path->delete($output);
    #    return $img;
    #}

    # Wir liefern nichts zurück, die Bilddatei bleibt stehen
    return;
}

# -----------------------------------------------------------------------------

=head3 print() - Übertrage Daten an den Gnuplot-Prozess

=head4 Synopsis

    $gnu->print(@data);

=cut

# -----------------------------------------------------------------------------

sub print {
    my $self = shift;
    # @_: @data

    my $fh = $self->fh;
    $fh->print(@_);

    if (my $debug = $self->debug) {
        warn @_;
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.148

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
