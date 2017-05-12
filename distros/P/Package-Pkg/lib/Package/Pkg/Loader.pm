package Package::Pkg::Loader;

use strict;
use warnings;

use Mouse;

use Package::Pkg;

has namespacelist => qw/ is ro required 1 isa ArrayRef /;
has alias => qw/ is ro lazy_build 1 isa HashRef /;
sub _build_alias { {} }

sub load {
    my $self = shift;
    my $moniker = @_ > 1 ? Package::Pkg->name( @_ ) : $_[0];
    
    my $package = $self->softload( $moniker );
    unless ( $package ) {
        my @namespacelist = @{ $self->namespacelist };
        confess "Unable to load package ($moniker) under any namespace (@namespacelist)";
    }

    return $package;
}

sub softload {
    my $self = shift;
    my $moniker = @_ > 1 ? Package::Pkg->name( @_ ) : $_[0];

    my @namespacelist = @{ $self->namespacelist };
    for my $namespace (@namespacelist) {
        if ( my $package = Package::Pkg->softload( $namespace, $moniker ) ) {
            return $package;
        }
    }

    return;
}


1;
