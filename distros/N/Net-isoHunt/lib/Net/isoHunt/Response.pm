package Net::isoHunt::Response;
BEGIN {
  $Net::isoHunt::Response::VERSION = '0.102770';
}

# ABSTRACT: Provides accessors to various response fields

use Moose;

has [
    qw{
        title
        link
        description
        language
        category
        last_build_date
        pubDate
      }
    ] => (
    is  => 'ro',
    isa => 'Str',
);

has [
    qw{
        max_results
        ttl
        total_results
        censored
      }
    ] => (
    is  => 'ro',
    isa => 'Int',
);

has 'image' => (
    is  => 'ro',
    isa => 'Net::isoHunt::Response::Image',
);

has 'items' => (
    is  => 'ro',
    isa => 'ArrayRef[Net::isoHunt::Response::Item]',
);

__PACKAGE__->meta()->make_immutable();

no Moose;

1;



=pod

=head1 NAME

Net::isoHunt::Response - Provides accessors to various response fields

=head1 VERSION

version 0.102770

=head1 ATTRIBUTES

=head2 C<title>

=head2 C<link>

=head2 C<description>

=head2 C<language>

=head2 C<category>

=head2 C<max_results>

=head2 C<ttl>

=head2 C<image>

Returns a L<Net::isoHunt::Response::Image> object.

=head2 C<last_build_date>

=head2 C<pub_date>

=head2 C<total_results>

=head2 C<censored>

=head2 C<items>

Returns an array reference to L<Net::isoHunt::Response::Item> objects.

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

