package Pcore::HTTP::Response;

use Pcore -class;
use Pcore::HTTP::Headers;
use HTTP::Message;    # TODO requires for decode body

with qw[Pcore::Util::Result::Status];

has url => ( is => 'ro', isa => Str | Object, writer => 'set_url' );
has buf_size => ( is => 'ro', isa => PositiveOrZeroInt, default => 0 );    # write body to fh if body length > this value, 0 - always store in memory, 1 - always store to file

has version => ( is => 'ro', isa => Num, writer => 'set_version', init_arg => undef );
has headers => ( is => 'ro', isa => InstanceOf ['Pcore::HTTP::Headers'], init_arg => undef );
has body => ( is => 'ro', isa => Ref, writer => 'set_body', predicate => 1, init_arg => undef );
has path => ( is => 'ro', isa => Str, writer => 'set_path', predicate => 1, init_arg => undef );

has content_length => ( is => 'rwp', isa => PositiveOrZeroInt, default => 0, init_arg => undef );

has redirect => ( is => 'lazy', isa => ArrayRef, default => sub { [] }, init_arg => undef );
has decoded_body => ( is => 'lazy', isa => Maybe [ScalarRef], init_arg => undef );

sub BUILD ( $self, $args ) {
    $self->{headers} = Pcore::HTTP::Headers->new;

    $self->{headers}->add( $args->{headers} ) if $args->{headers};

    $self->{body} = $args->{body} if $args->{body};

    return;
}

sub _build_decoded_body ($self) {
    return if !$self->has_body;

    return if ref $self->body ne 'SCALAR';

    return HTTP::Message->new( [ 'Content-Type' => $self->headers->{CONTENT_TYPE} ], $self->body->$* )->decoded_content( raise_error => 1, ref => 1 );
}

# TO_PSGI
sub to_psgi ($self) {
    if ( $self->has_body && ref $self->body eq 'CODE' ) {
        return $self->body;
    }
    else {
        return [ $self->status, $self->headers->to_psgi, $self->_body_to_psgi ];
    }
}

# TODO
sub _body_to_psgi ($self) {
    return [];
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::HTTP::Response

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
