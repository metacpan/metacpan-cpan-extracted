package MooseX::Net::API;
BEGIN {
  $MooseX::Net::API::VERSION = '0.12';
}

# ABSTRACT: Easily create client for net API (DEPRECATED)

warn "The MooseX::Net::API module is being deprecated in favour of Net::HTTP::API. Please don't use it.";

use base 'Net::HTTP::API';

1;


__END__
=pod

=head1 NAME

MooseX::Net::API - Easily create client for net API (DEPRECATED)

=head1 VERSION

version 0.12

=head1 SYNOPSIS

DEPRECATED

THIS MODULE IS BEING DEPRECATED IN FAVOUR OF L<Net::HTTP::API>.

=head1 AUTHOR

  franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

