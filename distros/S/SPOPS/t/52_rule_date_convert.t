# -*-perl-*-

# $Id: 52_rule_date_convert.t,v 1.3 2004/02/26 02:02:29 lachoy Exp $

use strict;
use lib qw( t/ );
use Test::More tests => 22;

do "t/config.pl";

my $DATE_FORMAT = '%Y-%m-%d %H:%M:%S';

require_ok( 'SPOPS::Initialize' );


my $original_time = '2002-02-02 02:22:12';

my %config = (
      test => {
         class               => 'TimePieceTest',
         isa                 => [ 'SPOPS::Loopback' ],
         rules_from          => [ 'SPOPS::Tool::DateConvert' ],
         field               => [ qw( myid date_field ) ],
         id_field            => 'myid',
         convert_date_class  => 'Time::Piece',
         convert_date_format => $DATE_FORMAT,
         convert_date_field  => [ 'date_field' ],
      },
);

# Time::Piece

SKIP: {
    eval "require Time::Piece";
    if ( $@ ) {
        skip "Time::Piece not installed", 7;
    }

    # Create our test class using the loopback

    my $init_list_tp = eval { SPOPS::Initialize->process({ config => \%config }) };
    ok( ! $@, "Initialize process run $@" );
    is( $init_list_tp->[0], 'TimePieceTest',
        'Time::Piece object class initialized' );

    # Time::Piece

    my $original_obj_tp = Time::Piece->strptime( $original_time, $DATE_FORMAT );
    my $item_tp = TimePieceTest->new({ myid       => 88,
                                       date_field => $original_obj_tp });
    eval { $item_tp->save };
    ok( ! $@, 'Object with Time::Piece field saved' );
    isa_ok( $item_tp->{date_field}, 'Time::Piece',
            'Object field resaved as Time::Piece' );
    is( TimePieceTest->peek( 88, 'date_field' ), $original_time,
        'Time::Piece field value saved' );

    my $new_item_tp = TimePieceTest->fetch( 88 );
    isa_ok( $new_item_tp->{date_field}, 'Time::Piece',
            'Object field fetched as Time::Piece' );
    is( $original_obj_tp, $new_item_tp->{date_field},
        'Object field fetched matches value of original' );

}

# Class::Date

SKIP: {
    eval "require Class::Date";
    if ( $@ ) {
        skip "Class::Date not installed", 7;
    }

    $config{test}->{class} = 'ClassDateTest';
    $config{test}->{convert_date_class} = 'Class::Date';
    my $init_list_cd = eval { SPOPS::Initialize->process({ config => \%config }) };
    ok( ! $@, "Initialize process run $@" );
    is( $init_list_cd->[0], 'ClassDateTest',
        'Class::Date object class initialized' );

    my $original_obj_cd = Class::Date->new( $original_time );
    my $item_cd = ClassDateTest->new({ myid => 44,
                                       date_field => $original_obj_cd });
    eval { $item_cd->save };
    ok( ! $@, 'Object with Class::Date field saved' );
    isa_ok( $item_cd->{date_field}, 'Class::Date',
            'Object field resaved as Class::Date' );
    is( ClassDateTest->peek( 44, 'date_field' ), $original_time,
        'Class::Date field value saved' );

    my $new_item_cd = ClassDateTest->fetch( 44 );
    isa_ok( $new_item_cd->{date_field}, 'Class::Date',
            'Object field fetched as Class::Date' );
    is( $original_obj_cd, $new_item_cd->{date_field},
        'Object field fetched matches value of original' );
}


# DateTime
SKIP: {
    eval "require DateTime";
    if ( $@ ) {
        skip "DateTime not installed", 7;
    }
    eval "require DateTime::Format::Strptime";
    if ( $@ ) {
        skip "DateTime::Format::Strptime not installed", 7;
    }
    else {
        DateTime::Format::Strptime->import( 'strptime' );
    }

    $config{test}->{class} = 'DateTimeTest';
    $config{test}->{convert_date_class} = 'DateTime';
    my $init_list_dt = eval {
        SPOPS::Initialize->process({ config => \%config })
    };
    ok( ! $@, "Initialize process run $@" );
    is( $init_list_dt->[0], 'DateTimeTest',
        'DateTime object class initialized' );

    my $original_obj_dt = strptime( $DATE_FORMAT, $original_time );
    my $item_dt = DateTimeTest->new({ myid => 22,
                                      date_field => $original_obj_dt });
    eval { $item_dt->save };
    ok( ! $@, 'Object with DateTime field saved' );
    isa_ok( $item_dt->{date_field}, 'DateTime',
            'Object field resaved as DateTime' );
    is( DateTimeTest->peek( 22, 'date_field' ), $original_time,
        'DateTime field value saved' );

    my $new_item_dt = DateTimeTest->fetch( 22 );
    isa_ok( $new_item_dt->{date_field}, 'DateTime',
            'Object field fetched as DateTime' );
    is( $original_obj_dt, $new_item_dt->{date_field},
        'Object field fetched matches value of original' );
}
