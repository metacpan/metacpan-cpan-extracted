#!/usr/bin/perl

use strict;

my $file = "./.settings";

print get_val_by_name( name => $ARGV[0] );

sub get_val_by_name {
	#
	my %in = (
		name => '',
		@_,
	);
	#
	my %o;
	#
	if ( -f $file ) {
		if ( open( my $FILE, "<", "$file" ) ) {
			while ( my $line = <$FILE> ) {
				my ($left, $right) = split(/\=/, $line, 2);
				$o{"$left"} = $right;
			}
		} else {
			$o{error} .= qq{Could not open file $file};
		}
	} else {
		$o{error} = "Could not find file: $file\n";
		$o{error} .= "Creating $file\n";
		`touch $file`;
		if ( -f $file ) { $o{error} .= "$file was created, empty\n"; }
	}

	if ( $in{name} ne '') { return $o{$in{name}};  }
	else { return "$o{error}"; }
}



1;