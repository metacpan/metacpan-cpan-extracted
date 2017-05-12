package Pcore::HTTP::Message;

use Pcore -class;
use Pcore::HTTP::Message::Headers;

has headers => ( is => 'lazy', isa => InstanceOf ['Pcore::HTTP::Message::Headers'], init_arg => undef );
has body => ( is => 'ro', isa => Ref, writer => 'set_body', predicate => 1, init_arg => undef );
has path => ( is => 'ro', isa => Str, writer => 'set_path', predicate => 1, init_arg => undef );

has content_length => ( is => 'rwp', isa => PositiveOrZeroInt, default => 0, init_arg => undef );

has buf_size => ( is => 'ro', isa => PositiveOrZeroInt, default => 0 );    # write body to fh if body length > this value, 0 - always store in memory, 1 - always store to file

sub BUILD ( $self, $args ) {
    $self->headers->add( $args->{headers} ) if $args->{headers};

    $self->set_body( $args->{body} ) if $args->{body};

    return;
}

sub _build_headers ($self) {
    return Pcore::HTTP::Message::Headers->new;
}

# TODO
# body chunked if body is FH or FilePath, and size > $self->buf_size;
# body is multipart if has content parts with different content-types;
# universal response coderef;
sub body_to_http ($self) {
    return $self->body;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::HTTP::Message

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
