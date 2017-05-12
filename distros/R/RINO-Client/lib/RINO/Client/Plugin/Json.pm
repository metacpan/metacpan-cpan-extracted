package RINO::Client::Plugin::Json;

use strict;
require JSON;

sub write_out {
    my $class = shift;
    my $ref = shift;
    my @array = @{$ref};
    @array = splice(@array,1,$#array);

    ## fix for AdditionalData Glob
    foreach my $a (@array){
        foreach my $k (keys %{$a}){
            my $x = $a->{$k};
            next unless($x);
            my $h = eval { JSON::from_json($x) };
            next if($@);
            $a->{$k} = $h;
        }
    }

    return JSON::to_json(\@array);
}

1;
