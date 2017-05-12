package Scrapar::PArray;

use strict;
use warnings;
use DB_File;

sub new {
    my $class = CORE::shift;
    my $filename = CORE::shift || die "Please specify the filename for PArray";

    my $is_file_empty = ! -s $filename;
    unlink $filename if $is_file_empty;
    my $X = tie my @array, 'DB_File', $filename, O_CREAT | O_RDWR, 0644, $DB_RECNO;

    bless {
	x => $X,
	a => \@array, 
	is_file_empty => $is_file_empty,
    } => $class;
}

sub shift {
    my $self = CORE::shift;

    my $data = $self->{x}->shift;
    $self->{x}->sync();

    return $data;
}

sub unshift {
    my $self = CORE::shift;
    $self->{x}->unshift(@_);
    $self->{x}->sync();
}

sub push {
    my $self = CORE::shift;
    $self->{x}->push(@_);
    $self->{x}->sync();
}

sub pop {
    my $self = CORE::shift;

    my $data = $self->{x}->pop;
    $self->{x}->sync();

    return $data;
}

# randomly push or unshift data into arrays
sub put {
    my $self = CORE::shift;

    for my $e (@_) {
	if ((int rand time) % 2) {
	    $self->{x}->push($e);
	}
	else {
	    $self->{x}->unshift($e);
	}
    }
    $self->{x}->sync();
}

# randomly shift or pop data into arrays
sub get {
    my $self = CORE::shift;

    my $data = ((int rand time) % 2) ? $self->{x}->pop : $self->{x}->shift;
    $self->{x}->sync();

    return $data;
}

sub length {
    my $self = CORE::shift;
    return $self->{x}->length;
}

1;
