use strict;
use JSON;
use GD;

my %wht;
for my $ix (0..9) {
    my $myImage = newFromPng GD::Image("gray-$ix.png",0);
    my @weights;

    # 10x10 image
    for my $column (0..9) {
    	for my $row (0..9) {
            my $index = $myImage->getPixel($row,$column);
    		my $weight = 255 - $index;
    		push @weights,$weight;
        }
    }
	$wht{$ix} = [@weights];
}

my $json = to_json(\%wht);

open my $fd,">","weights.json" or die $!;
print $fd $json;
close $fd;
