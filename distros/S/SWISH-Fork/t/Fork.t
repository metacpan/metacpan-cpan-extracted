#!/usr/local/bin/perl -w
use strict;

# This will run swish-e with with a few test files.
# Doesn't test much at this point....

use SWISH;


    BEGIN { $| = 1; print "1..7\n"; }
    

    my ( $swish, $version ) = read_swish_version();

    print $swish && -e $swish ? "ok $swish\n" : "not ok $swish\n";




    my %settings = (
       # version      => $version,  # let Fork find the version
       output_separator => '|',
       prog         => $swish,
       indexes      => ['t/test.index'],
       results      => \&display_results,
    );

    $settings{properties} = 'property' if $version >= 1.3;


    #$SWISH::Fork::DEBUG++;

    my $error;


    my $sh = SWISH->connect('Fork', %settings );


    print ref $sh ? "ok connect\n" : "not ok connect: $SWISH::errstr\n";
    die unless ref $sh;

    
    $version = $sh->version || '';
    print $version ? "ok swish version $version \n" : "not ok swish version not loaded\n";


    print $sh ? "ok Connect\n" : "not ok Connect\n";


    my $prop_found;

    my $hits = $sh->query('find');


    print $hits && $hits == 3 ?  "ok Query\n" : "not ok Query hits = '" . ($hits||'?') ."' " . ($sh->errstr || 'unknown error') . "\n";


    if ( $sh->version && $sh->version >= 1.3 ) {

        print $prop_found  ? "ok properties\n" : "not ok properties\n";

    } else {
        print "ok properties not checked version\n";
    }


    # Test the headers, not the difference in 2.1-dev 20 and above
    
    if ( $sh->version && $sh->version >= 2.120 ) {

        print $sh->get_header( 'WordCharacters' ) && $sh->get_header('wordcharacters','t/test.index') &&
              $sh->get_header( 'WordCharacters' ) eq $sh->get_header( 'WordCharacters' , 't/test.index' )
            ?  "ok Header 'WordCharacters'\n" 
            : "not ok Header 'WordCharacters'\n";
    } else {
        print $sh->get_header( 'Total Words' )
            ?  "ok Header 'Total Words'\n" 
            : "not ok Header 'Total Words'\n";
    }

    

    sub display_results {
        my ($sh, $hit) = @_;

        # Display as a formatted string (in version <= 2.0 format)
        # print $hit->as_string, "\n";

        # Get the list of field names
        # Only returns defined fields

        my @fields = $hit->field_names;
        print "$_ : " . $hit->$_() . "\n" for sort @fields;
        print "\n";

        $prop_found++ if $hit->property;

     }    



sub read_swish_version {
    open FH, 't/swish.dat' or return ('','');
    my @dat = <FH>;
    chomp @dat;
    return @dat;
}

