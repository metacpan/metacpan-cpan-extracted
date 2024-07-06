package Net::Z3950::FOLIO::lodashGet;

use strict;
use warnings;
use Data::Dumper; $Data::Dumper::INDENT = 2;


sub _compilePath {
    my($path) = @_;
    my @components;

    while ($path) {
	my @match = $path =~ /^([^.\[]*)(\.|\[\d+\]\.?)(.*)/;
	if (!@match) {
	    push @components, $path;
	    last;
	}

	my($head, $sep, $tail) = @match;
	push @components, $head if $head ne '';
	if ($sep ne '.') {
	    $sep =~ s/\]\.?//;
	    push @components, substr($sep, 1) + 0;
	}

	$path = $tail;
    }

    return @components;
}


sub lodashGet {
    my($data, $path) = @_;
    # warn "starting with ", Dumper($data);

    my @components = _compilePath($path);
    while (@components) {
	my $component = shift @components;
	if (ref $data eq 'HASH') {
	    $data = $data->{$component};
	} else {
	    # Assume it's an array
	    $data = $data->[$component];
	}
	# warn "moved down from '$component' to ", Dumper($data);
	return undef if !defined $data;
    }

    # warn "got ", (defined $data ? "'$data'" : 'UNDEF');

    return $data;
}


use Exporter qw(import);
our @EXPORT_OK = qw(_compilePath lodashGet);


1;
