package Net::HTTP::API::Parser::JSON;
BEGIN {
  $Net::HTTP::API::Parser::JSON::VERSION = '0.14';
}

# ABSTRACT: Parse JSON

use JSON;
use Moose;
extends 'Net::HTTP::API::Parser';

has _json_parser => (
    is      => 'rw',
    isa     => 'JSON',
    lazy    => 1,
    default => sub { JSON->new->allow_nonref },
);

sub encode {
    my ($self, $content) = @_;
    $self->_json_parser->encode($content);
}

sub decode {
    my ($self, $content) = @_;
    $self->_json_parser->decode($content);
}

1;


__END__
=pod

=head1 NAME

Net::HTTP::API::Parser::JSON - Parse JSON

=head1 VERSION

version 0.14

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

