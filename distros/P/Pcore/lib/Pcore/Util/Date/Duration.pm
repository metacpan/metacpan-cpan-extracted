package Pcore::Util::Date::Duration;

use Pcore -class;

has seconds => ( required => 1 );    # Int

has minutes => ( is => 'lazy' );     # Int
has hours   => ( is => 'lazy' );     # Int
has days    => ( is => 'lazy' );     # Int

has ms   => ( is => 'lazy' );        # ArrayRef
has hm   => ( is => 'lazy' );        # ArrayRef
has hms  => ( is => 'lazy' );        # ArrayRef
has dhms => ( is => 'lazy' );        # ArrayRef
has dhm  => ( is => 'lazy' );        # ArrayRef

sub BUILDARGS ( $self, $args ) {
    my $seconds;

    if ( defined $args->{start} && defined $args->{end} ) {
        $seconds = $args->{start}->delta_seconds( $args->{end} );
    }
    else {
        $seconds = $args->{seconds} // 0;
        $seconds += $args->{minutes} * 60  if $args->{minutes};
        $seconds += $args->{hours} * 3_600 if $args->{hours};
        $seconds += $args->{days} * 86_400 if $args->{days};
    }

    return { seconds => $seconds };
}

sub _build_minutes ($self) { return int $self->{seconds} / 60 }

sub _build_hours ($self) { return int $self->{seconds} / 3_600 }

sub _build_days ($self) { return int $self->{seconds} / 86_400 }

sub _build_ms ($self) { return [ $self->minutes, $self->{seconds} - $self->minutes * 60 ] }

sub _build_hm ($self) { return [ $self->hours, $self->minutes - $self->hours * 60 ] }

sub _build_hms ($self) {
    return [ $self->hours, $self->minutes - $self->hours * 60, $self->{seconds} - $self->minutes * 60 ];
}

sub _build_dhms ($self) {
    return [ $self->days, $self->hours - $self->days * 24, $self->minutes - $self->hours * 60, $self->{seconds} - $self->minutes * 60 ];
}

sub _build_dhm ($self) {
    return [ $self->days, $self->hours - $self->days * 24, $self->minutes - $self->hours * 60 ];
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Date::Duration

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
