package SVG::VCD;

use strict;
use warnings;
use IO::File;
use SVG::VCD::Taxon;


our $VERSION = 0.4;


sub new {
    my $class = shift();
    my($filename) = @_;

    my $this = bless {
	filename => $filename,
	config => {},
	taxa => [],
    }, $class;

    $this->parse();
    return $this;
}


sub parse {
    my $this = shift();
    my $filename = $this->{filename};

    my $f = new IO::File("<$filename")
	or die "$0: can't open VCD-file '$filename': $!";

    my %fields = ();

    while (my $line = <$f>) {
	chomp $line;
	$line =~ s/^\s+//;
	$line =~ s/#.*//;
	$line =~ s/\s+$//;
	next if $line eq "";
	my($star, $key, $value) = ($line =~ /^(\*?)([a-z0-9_-]+):\s*(.*)/i);
	die "$0: $filename: bad line: '$line'" if !defined $key || $key eq "";
	$key = lc($key);
	if ($star) {
	    $this->{config}->{$key} = $value;
	    next;
	}
	if ($key eq "taxon" && keys %fields > 1) {
	    push @{ $this->{taxa} }, new SVG::VCD::Taxon(%fields);
	    %fields = ();
	}
	$fields{$key} = $value;
    }

    push @{ $this->{taxa} }, new SVG::VCD::Taxon(%fields);
    $f->close();
}


sub config {
    my $this = shift();
    my($key) = @_;

    return $this->{config}->{$key};
}


sub ntaxa {
    my $this = shift();

    return scalar @{ $this->{taxa} };
}


sub taxon {
    my $this = shift();
    my($i) = @_;

    return $this->{taxa}->[$i];
}


1;
