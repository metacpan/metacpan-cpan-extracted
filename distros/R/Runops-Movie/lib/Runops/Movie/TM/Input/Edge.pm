package Runops::Movie::TM::Input::Edge;
use strict;
use warnings;
use parent 'Runops::Movie::TM::Input';

use constant Tie => 'Runops::Movie::TM::Input::Edge::Tie';
require Runops::Movie::TM::Input::Edge::Tie;

sub load {
    my ( $self, %path ) = @_;

    my $edge = 0;
    {
        open my($fh), $path{edge}
            or die "Can't open $path{edge}: $!";
        while ( my $line = <$fh> ) {
            my ($x,$y) = $line =~ /^edge\(([[:xdigit:]]+),([[:xdigit:]]+)\)\.$/;
            $x = hex "0x$x";
            $y = hex "0x$y";
            my ( $pyedge, $yedge ) = Judy::L::Get($edge,$x);
            if ( $pyedge ) {
                my $oyedge = $yedge;
                Judy::1::Set($yedge,$y);
                if ( $oyedge != $yedge ) {
                    Judy::Mem::Poke($pyedge,$yedge);
                }
            }
            else {
                my $yedge = 0;
                Judy::1::Set($yedge,$y);
                Judy::L::Set($edge,$x,$yedge);
            }
        }
    }

    my $size = 0;
    {
        open my($fh), $path{size}
            or die "Can't open $path{size}: $!";
        while (my $line = <$fh>) {
            my ($x,$s) = $line =~ /^size\(([[:xdigit:]]+),(\d+)\)\.$/;
            Judy::L::Set($size, hex "0x$x", $s);
        }
    }

    my %type;
    {
        open my($fh), $path{type}
            or die "Can't open $path{type}: $!";
        while (my $line = <$fh>) {
            my ($x,$t) = $line =~ /^type\(([[:xdigit:]]+),'?(.*?)'?\)\.$/;
            $type{pack 'i', hex "0x$x"} = $t;
        }
    }

    my %names;
    {
        open my($fh), $path{names}
            or die "Can't open $path{names}: $!";
        while (my $line = <$fh>) {
            my ($x,$n) = $line =~ /^name\(([[:xdigit:]]+),"(.*)"\)\.$/;
            $names{pack 'i', hex "0x$x"} = $n;
        }
    }

    my %hash;
    tie %hash, Runops::Movie::TM::Input::Edge::Tie,
        $size, $edge, \%type, \%names,
        0;
    $self->{DATA} = \ %hash;

    return 1;
}

1;
