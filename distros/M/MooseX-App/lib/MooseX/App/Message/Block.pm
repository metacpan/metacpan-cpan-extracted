# ============================================================================
package MooseX::App::Message::Block;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;

use MooseX::App::Utils;

use overload
    '""' => "stringify";

has 'header' => (
    is          => 'ro',
    isa         => 'MooseX::App::Types::MessageString',
    predicate   => 'has_header',
);

has 'type' => (
    is          => 'ro',
    isa         => 'Str',
    default     => sub {'default'},
);

has 'body' => (
    is          => 'ro',
    isa         => 'MooseX::App::Types::MessageString',
    predicate   => 'has_body',
);

sub stringify {
    my ($self) = @_;

    my $message = '';
    $message .= $self->header."\n"
        if $self->has_header;

    $message .= $self->body."\n\n"
        if $self->has_body;

    return $message;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Message::Block - Message block

=head1 DESCRIPTION

A simple message block with a header and body

=head1 METHODS

=head2 header

Read/set a header string

=head2 has_header

Check if a header is set

=head2 body

Read/set a body string

=head2 has_body

Check if a body is set

=head2 type

Read/set an arbitrary block type. Defaults to 'default'

=head2 stringify

Stringify a message block