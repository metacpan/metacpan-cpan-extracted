use strict;
use warnings;
package Search::GIN::Callbacks;
# ABSTRACT: Provide callbacks

our $VERSION = '0.11';

use Moose::Role;
use namespace::autoclean;

with qw(Search::GIN::Core);

foreach my $cb (
    qw(objects_to_ids extract_values extract_query compare_values
        consistent ids_to_objects) ) {
    has "${cb}_callback" => (
        isa => "CodeRef",
        is  => "rw",
        required => 1,
    );

    eval "sub $cb { \$self->${cb}_callback->(@_) }";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::GIN::Callbacks - Provide callbacks

=head1 VERSION

version 0.11

=head1 DESCRIPTION

This role provides a few callbacks for L<Search::GIN>.

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman), Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
