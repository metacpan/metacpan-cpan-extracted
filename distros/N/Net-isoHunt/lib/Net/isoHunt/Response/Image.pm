package Net::isoHunt::Response::Image;
BEGIN {
  $Net::isoHunt::Response::Image::VERSION = '0.102770';
}

# ABSTRACT: Provides accessors to image fields

use Moose;

has [
    qw{
        title
        url
        link
      }
    ] => (
    is  => 'ro',
    isa => 'Str',
);

has [
    qw{
        width
        height
      }
    ] => (
    is  => 'ro',
    isa => 'Int',
);

__PACKAGE__->meta()->make_immutable();

no Moose;

1;



=pod

=head1 NAME

Net::isoHunt::Response::Image - Provides accessors to image fields

=head1 VERSION

version 0.102770

=head1 ATTRIBUTES

=head2 C<title>

=head2 C<url>

=head2 C<link>

=head2 C<width>

=head2 C<height>

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

