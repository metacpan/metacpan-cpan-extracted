# -*-perl-*-

# $Id: 07_utility.t,v 3.4 2004/02/26 02:02:29 lachoy Exp $

use strict;
use lib qw( t/ );
use Test::More tests => 17;

do "t/config.pl";

require_ok( 'SPOPS::Utility' );

# determine_limit()

{
    my $limit_start = '5';
    my ( $offset_start, $max_start ) = SPOPS::Utility->determine_limit( $limit_start );
    is( $offset_start, 0, 'Limit start offset' );
    is( $max_start, 5, 'Limit start max' );
    my $limit_range = '15,25';
    my ( $offset_range, $max_range ) = SPOPS::Utility->determine_limit( $limit_range );
    is( $offset_range, 15, 'Limit range offset' );
    is( $max_range, 40, 'Limit range max' );
}

# generate_random_code()

{
    my $random_1 = SPOPS::Utility->generate_random_code(15);
    is( length $random_1, 15, 'Random simple length' );
    ok( $random_1 =~ /^[A-Z]+$/, 'Random simple all caps' );
    my $random_2 = SPOPS::Utility->generate_random_code( 10, 'mixed' );
    is( length $random_2, 10, 'Random mixed length' );
    ok( $random_2 =~ /^[A-Za-z]+$/, 'Random mixed case' );
    my %uniq = ();
    for ( 1 .. 100 ) {
        $uniq{ SPOPS::Utility->generate_random_code(10) }++;
    }
    is( scalar keys %uniq, 100, 'Generate 100 unique random codes' );
}

# date stuff

{
    my $base_time = time;
    my ( $sec, $min, $hour, $mday, $mon, $year, @date_info ) = localtime( $base_time );
    $mon  = sprintf( '%02d', $mon+1 );
    $mday = sprintf( '%02d', $mday );
    $hour = sprintf( '%02d', $hour );
    $min  = sprintf( '%02d', $min );
    $sec  = sprintf( '%02d', $sec );
    $year += 1900;

SKIP: {
        skip( 'Weird timezone interaction', 1 );
        my $now = Class::Date->new({ time => $base_time })->strftime( '%Y-%m-%d %T' );
        is( $now, "$year-$mon-$mday $hour:$min:$sec", 'Default format for now()' );
    }
    my $today = SPOPS::Utility->today();
    is( $today, "$year-$mon-$mday", 'Format for today()' );
    ok( SPOPS::Utility->now_between_dates({ begin => '2000-01-01',
                                            end   => '2010-01-01' }),
        'Today is between date 1 and date 2' );
    ok( ! SPOPS::Utility->now_between_dates({ begin => '2010-01-01',
                                              end   => '2011-01-01' }),
        'Today is not between date 1 and date 2' );
    my $date = Class::Date->new( $base_time );
}

# List process. The 'is_deeply' comparisons are a little cumbersome
# because we can't depend on the order of the items coming back.

{
    my @existing = qw( a b c d );
    my @new      = qw( b d e );
    my $process_results = SPOPS::Utility->list_process( \@existing, \@new );
    my %add = map { $_ => 1 } @{ $process_results->{add} };
    is_deeply( \%add, { 'e' => 1 }, 'List process add items' );
    my %keep = map { $_ => 1 } @{ $process_results->{keep} };
    is_deeply( \%keep, { 'b' => 1, 'd' => 1 }, 'List process keep items' );
    my %remove = map { $_ => 1 } @{ $process_results->{remove} };
    is_deeply( \%remove, { 'a' => 1, 'c' => 1 }, 'List process remove items' );
}
