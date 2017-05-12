package Mock::Quick::Util;
use strict;
use warnings;

use base 'Exporter';
use Scalar::Util qw/blessed/;
use Mock::Quick::Method;
use Carp qw/croak/;

our $CLEAR = 'clear';
our @EXPORT = qw/
    class_meth
    obj_meth
    alt_meth
    call
    param
    inject
    purge_util
    super
/;

sub inject {
    my ( $package, $name, $code ) = @_;
    no warnings 'redefine';
    no strict 'refs';
    *{"$package\::$name"} = $code;
}

sub call {
    my $self = shift;
    require Mock::Quick::Object::Control;
    my $control = Mock::Quick::Object::Control->new( $self );
    my $name = shift;

    my $class = blessed( $self );
    croak "Can't call method on an unblessed reference"
        unless $class;

    if ( $control->strict ) {
        croak "Can't locate object method \"$name\" in this instance"
            unless exists $self->{$name};
    }

    if ( @_ && ref $_[0] && "$_[0]" eq "" . \$CLEAR ) {
        delete $self->{ $name };
        delete $control->metrics->{$name};
        return;
    }

    $control->metrics->{$name}++;

    return $self->{ $name }->( $self, @_ )
        if exists(  $self->{ $name })
        && blessed( $self->{ $name })
        && blessed( $self->{ $name })->isa( 'Mock::Quick::Method' );

    return $self->{$name} = shift(@_)
        if blessed( $_[0] ) && blessed( $_[0] )->isa( 'Mock::Quick::Method' );

    param( $self, $name, @_ );
}

sub param {
    my $self = shift;
    my $name = shift;

    $self->{$name} = shift(@_) if @_;

    # Prevent autovivication
    return unless exists( $self->{ $name });
    return $self->{ $name };
}

sub class_meth {
    my ( $name, $block ) = @_;
    my $caller = caller;

    my $sub = sub {
        goto &$block unless blessed( $_[0] );
        unshift @_ => ( shift(@_), $name );
        goto &call;
    };

    inject( $caller, $name, $sub );
}

sub obj_meth {
    my ( $name, $block ) = @_;
    my $caller = caller;

    my $sub = sub {
        goto &$block if blessed( $_[0] );
        Carp::croak( "Can't locate object method \"$name\" via package \"$caller\"" );
    };

    inject( $caller, $name, $sub );
}

sub alt_meth {
    my ( $name, %alts ) = @_;
    my $caller = caller;

    croak "You must provide an action for both 'class' and 'obj'"
        unless $alts{class} && $alts{obj};

    my $sub = sub {
        goto &{ $alts{obj }} if blessed( $_[0] );
        goto &{ $alts{ class }};
    };

    inject( $caller, $name, $sub );
}

sub purge_util {
    my $caller = caller;
    for my $sub ( @EXPORT ) {
        no strict 'refs';
        my $ref = \%{"$caller\::"};
        delete $ref->{ $sub };
    }
}

1;

__END__

=head1 NAME

Mock::Quick::Util - Uitls for L<Mock::Quick>.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Mock-Quick is free software; Standard perl licence.

Mock-Quick is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.
