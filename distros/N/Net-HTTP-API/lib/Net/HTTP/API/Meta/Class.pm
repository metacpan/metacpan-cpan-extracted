package Net::HTTP::API::Meta::Class;
BEGIN {
  $Net::HTTP::API::Meta::Class::VERSION = '0.14';
}

# ABSTRACT: metaclass for all API client

use Moose::Role;

with qw/
    Net::HTTP::API::Meta::Method::APIMethod
    Net::HTTP::API::Meta::Method::APIDeclare
    /;

1;


__END__
=pod

=head1 NAME

Net::HTTP::API::Meta::Class - metaclass for all API client

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

