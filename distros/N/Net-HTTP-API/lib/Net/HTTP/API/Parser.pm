package Net::HTTP::API::Parser;
BEGIN {
  $Net::HTTP::API::Parser::VERSION = '0.14';
}

# ABSTRACT: base class for all Net::HTTP::API::Parser

use Moose;

sub encode {die "must be implemented"}
sub decode {die "must be implemented"}

1;


__END__
=pod

=head1 NAME

Net::HTTP::API::Parser - base class for all Net::HTTP::API::Parser

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

