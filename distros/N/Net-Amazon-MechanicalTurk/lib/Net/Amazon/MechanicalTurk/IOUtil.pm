package Net::Amazon::MechanicalTurk::IOUtil;
use strict;
use warnings;
use IO::File;
use Carp;

our $VERSION = '1.00';

sub readContents {
    my ($class, $io) = @_;
    my $text = '';
    if (UNIVERSAL::isa($io, "GLOB")) {
        while (my $line = <$io>) {
            $text .= $line;
        }
    }
    else {
        my $in = IO::File->new($io, "r");
        if (!$in) {
            Carp::croak("Couldn't open $io - $!");
        }
        while (my $line = <$in>) {
            $text .= $line;
        }
        $in->close;
    }
    return $text;
}

sub writeContents {
    my ($class, $io, $content) = @_;
    my $text = '';
    if (UNIVERSAL::isa($io, "GLOB")) {
        print $io $content;
    }
    else {
        my $out = IO::File->new($io, "w");
        if (!$out) {
            Carp::croak("Couldn't open $io - $!");
        }
        print $out $content;
        $out->close;
    }
}

return 1;
