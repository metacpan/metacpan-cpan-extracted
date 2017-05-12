package Sash::Buffer;

use base qw( Tie::Scalar ); # Glorified Abstract Class is all this is

use Carp;
use warnings;

sub TIESCALAR {
    my $class = shift;

    my $filename = $class->filename;
    my $fh;
    
    if ( open $fh, '<', $filename or open $fh, '>', $filename ) {
        close $fh;
        return bless \$filename, $class;
    }
    
    croak "Can't tie $filename: $!\n";
    
    return;
}

sub FETCH {
    my $self = shift;
    
    croak "Not a class method!\n" unless ref $self;
    return unless open my $fh, ${$self};
    
    read( $fh, my $value, -s $fh );
    
    return "$value\n";
}

sub STORE {
    my $self = shift;
    my $value = shift;
    
    croak "Not a class method!\n" unless ref $self;
    
    open my $fh, ">", ${$self} or croak "Can't clobber myself: $! !\n";
    
    syswrite( $fh, $value ) == length $value or croak "Can't write to myself: $!\n";
    
    close $fh or croak "Can't close myself: $!\n";
    
    return $value;
}

sub filename {
    my $self = shift;

    return $ENV{HOME} . '/.sash_buffer';
}

sub add {
    my $self = shift;
    my $value = shift;
    
    croak "Not a class method!\n" unless ref $self;
    
    open my $fh, ">>", ${$self} or croak "Can't add to myself: $! !\n";
    
    syswrite( $fh, $value ) == length $value or croak "Can't write to myself: $!\n";
    
    close $fh or croak "Can't close myself: $!\n";
    
    return $value;
}

1;
