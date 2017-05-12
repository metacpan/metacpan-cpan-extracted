use strict;
use warnings;

use Test::More;
use Data::Dumper;

use lib 'lib';

BEGIN {
    eval { require Lingua::Ispell };
    if ($@){
        eval { 
            require Text::Aspell;
            my $o = Text::Aspell->new;
            $o->check('house');
            die $o->errstr if $o->errstr;
        };
    }
    if ($@){
        plan skip_all => 'requires Lingua::Ispell or Text::Aspell' ; 
    }
}

BEGIN {
    use Pod::Spelling;
}

foreach my $pm (qw(
    Lingua::Ispell
    Text::Aspell
)){
    my ($mod) = $pm =~ /(\w+)$/;
    my $class = 'Pod::Spelling::'.$mod;
    eval "require $class";
    
    SKIP: {
        skip 'Cannot require '.$class, 7 if $@;

        my $o = eval { $class->new };
        
        SKIP: {
            skip "Did not find $class", 6 if not ref $o;
        
            ok((-e 't/for.pod'), 'Got file');
            my @r = $o->check_file( 't/for.pod' );
            
            is(  @r, 0, 'Expected 0 errors with '.$class )
                or diag 'Unknown words: ', join ', ', @r;
        }
    }
}

done_testing;

