package Net::StackExchange::Role::Response;
BEGIN {
  $Net::StackExchange::Role::Response::VERSION = '0.102740';
}

# ABSTRACT: Common response methods

use Moose::Role;

has [
    qw{
        total
        page
        pagesize
      }
    ] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

no Moose::Role;

1;



=pod

=head1 NAME

Net::StackExchange::Role::Response - Common response methods

=head1 VERSION

version 0.102740

=head1 ATTRIBUTES

=head2 C<total>

Returns total number of items in this sequence.

=head2 C<page>

Returns page of the total collection returned.

=head2 C<pagesize>

Returns size of each page returned from the collection.

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

