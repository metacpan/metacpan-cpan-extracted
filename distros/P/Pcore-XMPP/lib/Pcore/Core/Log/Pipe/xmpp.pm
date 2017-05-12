package Pcore::Core::Log::Pipe::xmpp;

use Pcore -class;

extends qw[Pcore::Core::Log::Pipe];

has to => ( is => 'ro', isa => Str, required => 1 );

has h => ( is => 'lazy', isa => InstanceOf ['Pcore::Handle::xmpp'], init_arg => undef );

around new => sub ( $orig, $self, $args ) {
    $args->{to} = $args->{uri}->query_params->{to};

    return $self->$orig($args);
};

sub _build_id ($self) {
    return 'xmpp://' . $self->uri->username . q[@] . $self->uri->host . q[?to=] . $self->to;
}

sub _build_h ($self) {
    return P->handle( $self->uri );
}

sub sendlog ( $self, $header, $data, $tag ) {
    $self->h->sendmsg( $self->to, $header . $data );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Log::Pipe::xmpp

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
