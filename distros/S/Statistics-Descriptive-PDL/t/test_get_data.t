use strict;
use warnings;

use Test::More;

use rlib;
use lib 't/lib';
use Utils qw/compare_hash_by_ranges/;

use Statistics::Descriptive::PDL;
use Statistics::Descriptive::PDL::SampleWeighted;

my $unwtd_class = 'Statistics::Descriptive::PDL';
my $swtd_class   = 'Statistics::Descriptive::PDL::SampleWeighted';

use Devel::Symdump;
my $obj = Devel::Symdump->rnew(__PACKAGE__); 
my @subs = grep {$_ =~ 'main::test_'} $obj->functions();

exit main( @ARGV );


sub main {
    my @args  = @_;

    if (@args) {
        for my $name (@args) {
            die "No test method test_$name\n"
                if not my $func = (__PACKAGE__->can( 'test_' . $name ) || __PACKAGE__->can( $name ));
            $func->();
        }
        done_testing;
        return 0;
    }

    foreach my $sub (sort @subs) {
        no strict 'refs';
        $sub->();
    }
    
    done_testing;
    return 0;
}



sub test_unweighted {
    my @data = (1..10);
    my $stats = $unwtd_class->new;
    $stats->add_data (@data);
    is $stats->count, 10, 'got expected count';
    my $returned_data = $stats->get_data;
    is_deeply $returned_data, \@data, 'got expected data back from get_data';
    
    my $returned_hash = $stats->get_data_as_hash;
    my %exp;
    @exp{@data} = (1) x @data;
    is_deeply $returned_hash, \%exp, 'got expected data back from get_data_as_hash';
}

sub test_unweighted_to_hash_with_dups {
    my @data = (3, 25, 28, 5, 12, 9, 5, 21, 29, 3, 49, 10, 23, 15);
    my $stats = $unwtd_class->new;
    $stats->add_data (@data);
    is $stats->count, 14, 'got expected count';
    my %exp;
    @exp{@data} = (1) x @data;
    $exp{3}++;
    $exp{5}++;
    my $returned_hash = $stats->get_data_as_hash;
    is_deeply $returned_hash, \%exp, 'got expected data back from get_data_as_hash';

}


sub test_sample_weighted {
    my @values = (1..10);
    my @wts    = (2) x @values;
    my %input_data;
    @input_data{@values} = @wts;

    my $stats = $swtd_class->new;
    $stats->add_data (\%input_data);
    is $stats->count, 20, 'got expected count';
    my $median = $stats->median;  #  trigger a sort

    my $returned_data = $stats->get_data;
    is_deeply [\@values, \@wts], $returned_data, 'get_data on weighted stats object';

    my $returned_hash = $stats->get_data_as_hash;
    is_deeply $returned_hash, \%input_data, 'get_data_as_hash on weighted object';
}
