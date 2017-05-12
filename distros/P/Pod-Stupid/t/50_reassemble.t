#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use File::Slurp qw( read_file );
use Data::Dumper qw( Dumper );
use File::Basename qw( dirname );

my @corpus_files = glob dirname( $0 ) . "/corpus{,2}/*";

# one test for each file, plus the "use_ok"
plan tests => @corpus_files + 1;

use_ok 'Pod::Stupid';

# for each file, parse out the pod, then insert it back into the 
# stripped version and assert they're the same.
for my $file ( glob dirname( $0 ) . "/corpus{,2}/*" ) {

    my $original_text = read_file( $file );
    my $parsed_pieces = Pod::Stupid->parse_string( $original_text );
    my $stripped_text = Pod::Stupid->strip_string( $original_text, $parsed_pieces );


    # put the pod back in the stripped text, just to test...
    substr( $stripped_text, $_->{start_pos}, 0, $_->{orig_txt} )
        for grep { $_->{is_pod} } @$parsed_pieces;

    ok $stripped_text eq $original_text, $file;

}

#done_testing();
