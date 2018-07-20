package # hide from PAUSE
Term::Form::Linux;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.321';

use Term::Choose::Constants qw( :screen );

use parent 'Term::Choose::Linux';


my $Term_ReadKey; # declare but don't assign a value!
BEGIN {
    if ( eval { require Term::ReadKey; 1 } ) {
        $Term_ReadKey = 1;
    }
}

my $Stty = '';


sub new {
    return bless {}, $_[0];
}

sub __set_mode {
    my ( $self, $hide_cursor ) = @_;
    if ( $Term_ReadKey ) {
        Term::ReadKey::ReadMode( 'cbreak' );
    }
    else {
        $Stty = `stty --save`;
        chomp $Stty;
        system( "stty -echo cbreak" ) == 0 or die $?;
    }
    print HIDE_CURSOR if $hide_cursor;
};

sub __reset_mode {
    my ( $self, $hide_cursor ) = @_;
    print SHOW_CURSOR if $hide_cursor;
    if ( $Term_ReadKey ) {
        Term::ReadKey::ReadMode( 'restore' );
    }
    else {
        if ( $Stty ) {
            system( "stty $Stty" ) == 0 or die $?;
        }
        else {
            system( "stty sane" ) == 0 or die $?;
        }
    }
}

sub __down  { return if ! $_[1]; print "\e[${_[1]}B"; }

sub __mark_current { print UNDERLINE; } # "\e[1m\e[4m";

sub __clear_lines_to_end_of_screen { print "\r", CLEAR_TO_END_OF_SCREEN; }

sub __clear_line { print "\r", CLEAR_TO_END_OF_LINE; }


1;

__END__
