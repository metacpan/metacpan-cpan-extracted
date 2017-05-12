package Net::RabbitMQ::Management::API::Result;
{
  $Net::RabbitMQ::Management::API::Result::VERSION = '0.01';
}

# ABSTRACT: RabbitMQ Management API result object

use Moo;

use JSON::Any;


has 'response' => (
    handles => {
        code        => 'code',
        raw_content => 'content',
        request     => 'request',
        success     => 'is_success',
    },
    is       => 'ro',
    isa      => sub { die 'must be a HTTP::Response, but is ' . ref $_[0] unless ref $_[0] eq 'HTTP::Response' },
    required => 1,
);


has 'content' => (
    builder => '_build_content',
    clearer => 'clear_content',
    is      => 'ro',
    lazy    => 1,
);

has '_json' => (
    builder => '_build__json',
    is      => 'ro',
    isa     => sub { die 'must be a JSON::Any, but is ' . ref $_[0] unless ref $_[0] eq 'JSON::Any' },
    lazy    => 1,
);


sub _build__json {
    my ($self) = @_;
    return JSON::Any->new;
}

sub _build_content {
    my ($self) = @_;
    if ( $self->raw_content ) {
        return $self->_json->decode( $self->raw_content );
    }
    return {};
}

1;

__END__
=pod

=head1 NAME

Net::RabbitMQ::Management::API::Result - RabbitMQ Management API result object

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 response

The L<HTTP::Response> object.

=head2 content

The decoded JSON response. May be an arrayref or hashref, depending
on the API call. For some calls there is no content at all.

=head1 AUTHOR

Ioana Budai <hurith@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ioana Budai.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

