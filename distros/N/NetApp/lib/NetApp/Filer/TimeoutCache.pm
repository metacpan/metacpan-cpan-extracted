
package NetApp::Filer::TimeoutCache;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use English;
use Carp;
use Params::Validate qw( :all );

sub TIEHASH {

    my $class		= shift;
    my (%args) 		= validate( @_, {
        lifetime	=> { type	=> SCALAR,
                             regex	=> qr{^\d+$} },
    });

    if ( $args{lifetime} <= 0 ) {
        croak("Invalid argument: lifetime must be a positive integer\n");
    }

    my %self 		= (
        lifetime	=> $args{lifetime},
        cache		=> {},
    );

    return bless \%self => $class;

}

sub STORE {

    my $self		= shift;
    my ($key, $value) 	= @_;

    $self->{cache}->{$key} = {
        expiration      => $self->{lifetime} + time,
        value           => $value,
    };

    return $value;

}

sub FETCH {
    my $self		= shift;
    my $key		= shift;
    return $self->{cache}->{$key}->{value};
}

sub DELETE {
    my $self		= shift;
    my $key		= shift;
    my $value		= $self->{cache}->{$key}->{value};
    delete $self->{cache}->{$key};
    return $value;
}

sub CLEAR {
    return shift->{cache} = {};
}

sub EXISTS {

    my $self		= shift;
    my $key		= shift;

    if ( not exists $self->{cache}->{$key} ) {
        return 0;
    }

    my $data		= $self->{cache}->{$key};

    if ( $data->{expiration} > time ) {
        return 1;
    } else {
        return 0;
    }

}

1;
