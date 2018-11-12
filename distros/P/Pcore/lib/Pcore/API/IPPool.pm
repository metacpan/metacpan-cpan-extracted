package Pcore::API::IPPool;

use Pcore -class;

has ip => ( required => 1 );

has _cache => ( init_arg => undef );

sub size ($self) {
    return scalar $self->{ip}->@*;
}

sub next_ip ( $self, $key ) {
    if ( !exists $self->{_cache}->{$key} ) {
        $self->{_cache}->{$key} = 0;

        return $self->{ip}->[0];
    }
    else {
        $self->{_cache}->{$key}++;

        $self->{_cache}->{$key} = 0 if $self->{_cache}->{$key} > $self->{ip}->$#*;

        return $self->{ip}->[ $self->{_cache}->{$key} ];
    }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::IPPool

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
