package Panotools::Script::Line::Variable;

use strict;
use warnings;
use Panotools::Script::Line;

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

=head1 NAME

Panotools::Script::Line::Variable - Panotools optimisation variables

=head1 SYNOPSIS

One or more parameters for optimisation form a 'v' line

=head1 DESCRIPTION

Please note: the 'v'-line must come after the the 'i'-lines.
Optimization variables are listed together with the image number
starting at 0. There can be several v-lines.

  y0           Optimize yaw in image 0
  p1           Optimize pitch in image 1
  r2           Optimize roll in image 2
  v0           Optimize field of view in image 0
  a2           Optimize lens correction parameter 'a' in image 2
  b1
  c1
  d1
  e1
  g1
  t1
  X1           Optimize x-coordinate of image 1, only for PTStereo
  Y2           Optimize y-coordinate of image 2, only for PTStereo
  Z6           Optimize z-coordinate of image 6, only for PTStereo
  TrX3         Optimise x-coordinate of image 3, mosaic/translation mode
  TrY2         Optimise y-coordinate of image 2, mosaic/translation mode
  TrZ1         Optimise z-coordinate of image 1, mosaic/translation mode
  Tpp1         Optimise pitch of picture plane of image 1, mosaic/translation mode
  Tpy1         Optimise yaw of picture plane of image 1, mosaic/translation mode

Additionally, photometric optimisation uses the same system. although this is a
secondary process and not simultaneous with geometric optimisation:

  Eev0         Optimise Exposure (Eev) for image 0
  Er1          Optimise red multiplier for image 1
  Eb1          Optimise blue multiplier for image 1

  Ra0          Optimise EMoR camera response for image 0
  Rb0            note usually all EMoR parameters are optimised at the same time
  Rc0
  Rd0
  Re0

  Va0          Optimise Vignetting 'Va' parameter for image 0, note usually only Vb, Vc, Vd are optimised
  Vb0          Optimise Vignetting 'Vb' parameter for image 0
  Vc0          Optimise Vignetting 'Vc' parameter for image 0
  Vd0          Optimise Vignetting 'Vd' parameter for image 0
  Vx1          Optimise Vignetting centre x-position for image 1
  Vy1          Optimise Vignetting centre y-position for image 1

If a image has a parameter linked to another image only need to optimize the master.

=cut

sub _valid { return '^([abcdegprtvyXYZ]|Te[0123]|Tp[py]|Tr[XYZ]|Ti[XYZS]|Eev|Er|Eb|Ra|Rb|Rc|Rd|Re|Va|Vb|Vc|Vd|Vx|Vy)(.*)' }

sub Identifier
{
    my $self = shift;
    return "v";
}

sub Parse
{
    my $self = shift;
    my $string = shift || return 0;
    my $valid = $self->_valid;
    my @res = $string =~ / ([a-zA-Z]+[0-9]+)/g;
    for my $token (grep { defined $_ } @res)
    {
        my ($param, $image) = $token =~ /([a-zA-Z]+)([0-9]+)/;
        next unless defined $image;
        $self->{$image}->{$param} = 1;
    }
    $self->_sanitise;
    return 1;
}

sub Assemble
{
    my $self = shift;
    $self->_sanitise;
    my $string = '';
    for my $image (sort {$a <=> $b} (keys %{$self}))
    {
        my @tokens;
        for my $param (sort keys %{$self->{$image}})
        {
            next unless $self->{$image}->{$param};
            push @tokens, $param . $image;
        }
        $string .= (join ' ', ($self->Identifier, @tokens)) ."\n";
    }
    $string .= $self->Identifier ."\n";
    return $string;
}

sub _sanitise
{
    my $self = shift;
    for my $image (keys %{$self})
    {
        delete $self->{$image} unless $image =~ /[0-9]+/;
    }
}

sub Report
{
    my $self = shift;
    my $index = shift;
    my @report;

    my $i = $self->{$index};

    push @report, 'Roll' if $self->{$index}->{r};
    push @report, 'Pitch' if $self->{$index}->{p};
    push @report, 'Yaw' if $self->{$index}->{y};
    push @report, 'Field of View' if $self->{$index}->{v};
    push @report, 'a' if $self->{$index}->{a};
    push @report, 'b' if $self->{$index}->{b};
    push @report, 'c' if $self->{$index}->{c};
    push @report, 'd' if $self->{$index}->{d};
    push @report, 'e' if $self->{$index}->{e};
    push @report, 'g' if $self->{$index}->{g};
    push @report, 't' if $self->{$index}->{t};

    push @report, 'Exposure' if $i->{Eev};
    push @report, 'Colour balance' if $i->{Er} or $i->{Eb};
    push @report, 'Response curve' if $i->{Ra} or $i->{Rb} or $i->{Rc} or $i->{Rd} or $i->{Re};
    push @report, 'Vignetting' if $i->{Va} or $i->{Vb} or $i->{Vc} or $i->{Vd};
    push @report, 'Vignetting centre' if $i->{Vx} or $i->{Vy};

    @report = ('NONE') if scalar @report == 0;
    [[('Optimise parameters', (join ',', @report))]];
}

1;
