package Excel::Sheet;
use strict;
use warnings;
use Array;
use Excel::Cell;
use base qw(Object);

sub new {
    my ( $pkg, @config ) = @_;
    my $sheet = {
        name      => 'no name',
        cells     => Array->new( Array->new ),
        row_count => 0,
        col_count => 0,
        @config,
    };
    return bless $sheet, $pkg;
}

sub row_count { return shift->{row_count}; }

sub col_count { return shift->{col_count}; }

sub name {
    my ( $self, $new_val ) = @_;
    if ( defined $new_val ) {
        $self->{name} = $new_val;
        return $self;
    }
    else {
        return $self->{name};
    }
}

sub get {
    my ( $self, $row, $col ) = @_;
    if ( $col =~ /^[A-Za-z]+$/ ) {
        $col = _letter_to_num($col);
    }
    return $self->{cells}->[ $row - 1 ][ $col - 1 ];
}

sub _letter_to_num {
    my $str     = shift;
    my $letters = Array->new( split //, uc($str) );
    my $res     = 0;
    for ( my $i = ( $letters->size ) - 1 ; $i >= 0 ; $i-- ) {
        $res +=
          ( ( ord( $letters->[$i] ) - ord('A') + 1 ) *
              ( 26**( $letters->size - $i - 1 ) ) );
    }
    return $res;
}

1;
