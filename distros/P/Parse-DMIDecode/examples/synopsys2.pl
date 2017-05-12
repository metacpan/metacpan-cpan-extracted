#!/usr/bin/perl -w

use strict;

use Parse::DMIDecode qw();
my $decoder = new Parse::DMIDecode;
$decoder->probe;

for my $handle ($decoder->get_handles) {
    printf("Handle %s of type %s is %s bytes long (minus strings).\n".
           "  > Contians the following keyword data entries:\n",
            $handle->handle,
            $handle->dmitype,
            $handle->bytes
        );

    for my $keyword ($handle->keywords) {
        my $value = $handle->keyword($keyword);
        printf("Keyword \"%s\" => \"%s\"\n",
                $keyword,
                (ref($value) eq 'ARRAY' ?
                    join(', ',@{$value}) : ($value||''))
            );
    }
}

