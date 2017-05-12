package Net::HTTP::API::Parser::YAML;
BEGIN {
  $Net::HTTP::API::Parser::YAML::VERSION = '0.14';
}

# ABSTRACT: Parse YAML

use YAML::Syck;
use Moose;
extends 'Net::HTTP::API::Parser';

sub encode {
    my ($self, $content) = @_;
    return Dump($content);
}

sub decode {
    my ($self, $content) = @_;
    return Load($content);
}

1;


__END__
=pod

=head1 NAME

Net::HTTP::API::Parser::YAML - Parse YAML

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

