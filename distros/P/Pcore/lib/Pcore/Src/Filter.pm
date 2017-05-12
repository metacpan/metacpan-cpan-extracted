package Pcore::Src::Filter;

use Pcore -role;

has file => ( is => 'ro', isa => InstanceOf ['Pcore::Src::File'], required => 1, weak_ref => 1 );
has buffer    => ( is => 'ro',   isa => ScalarRef, required => 1 );
has has_kolon => ( is => 'lazy', isa => Bool,      init_arg => undef );

sub src_cfg ($self) {
    return Pcore::Src::File->cfg;
}

sub dist_cfg ($self) {
    return $self->file->dist_cfg;
}

sub decompress {
    my $self = shift;

    return 0;
}

sub compress {
    my $self = shift;

    return 0;
}

sub obfuscate {
    my $self = shift;

    return 0;
}

sub _build_has_kolon {
    my $self = shift;

    return 1 if $self->buffer->$* =~ /<: /sm;

    return 1 if $self->buffer->$* =~ /^: /sm;

    return 0;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Src::Filter

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
