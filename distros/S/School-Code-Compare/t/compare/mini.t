use strict;
use v5.6.0;

use Test::More tests => 4;

use File::Slurp;
use School::Code::Compare;
use School::Code::Compare::Charset;

my $comparer = School::Code::Compare->new()                                    
                                    ->set_max_relative_difference(2)           
                                    ->set_min_char_total        (20)           
                                    ->set_max_relative_distance(0.8);

my @lines_oldstyle = read_file( 'xt/data/perl/hello_oo/hello_5.22', binmode => ':utf8' );
my @lines_newstyle = read_file( 'xt/data/perl/hello_oo/hello_5.28', binmode => ':utf8' );

my $clean_oldstyle  = School::Code::Compare::Charset->new()
                                                    ->set_language('hashy')
                                                    ->get_visibles(\@lines_oldstyle);
my $clean_newstyle  = School::Code::Compare::Charset->new()
                                                    ->set_language('hashy')
                                                    ->get_visibles(\@lines_newstyle);

my $comparison = $comparer->measure(join('',@{$clean_oldstyle}),
                                    join('',@{$clean_newstyle})
                                   );


is($comparison->{ratio}, 98, 'compare_similarity_perl');
is($comparison->{distance}, 4, 'compare_distance_perl');

#
# Repeat with different file
#

@lines_oldstyle = read_file( 'xt/data/java/factorial/Factorial.java', binmode => ':utf8' );
@lines_newstyle = read_file( 'xt/data/java/factorial/Faktorial.java', binmode => ':utf8' );

$clean_oldstyle  = School::Code::Compare::Charset->new()
                                                 ->set_language('slashy')
                                                 ->get_visibles(\@lines_oldstyle);
$clean_newstyle  = School::Code::Compare::Charset->new()
                                                 ->set_language('slashy')
                                                 ->get_visibles(\@lines_newstyle);

$comparison = $comparer->measure(join('',@{$clean_oldstyle}),
                                 join('',@{$clean_newstyle})
                                );

is($comparison->{ratio}, 96, 'compare_similarity_java');
is($comparison->{distance}, 11, 'compare_distance_java');
