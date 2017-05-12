package Net::HTTP::API::Parser::XML;
BEGIN {
  $Net::HTTP::API::Parser::XML::VERSION = '0.14';
}

# ABSTRACT: Parse XML result

use XML::Simple;
use Moose;
extends 'Net::HTTP::API::Parser';

has _xml_parser => (
    is      => 'rw',
    isa     => 'XML::Simple',
    lazy    => 1,
    default => sub { XML::SImple->new(ForceArray => 0) }
);

sub encode {
    my ($self, $content) = @_;
    return $self->_xml_parser->XMLin($content);
}

sub decode {
    my ($self, $content) = @_;
    return $self->_xml_parser->XMLout($content);
}

1;


__END__
=pod

=head1 NAME

Net::HTTP::API::Parser::XML - Parse XML result

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

