package Search::QS::Options::Limit;
$Search::QS::Options::Limit::VERSION = '0.04';
use Moose;
# ABSTRACT: The Limit option object


extends 'Search::QS::Options::Int';

has '+name'    => ( default => 'limit' );


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::QS::Options::Limit - The Limit option object

=head1 VERSION

version 0.04

=head1 DESCRIPTION

A subclass of L<Seach::QS::Options::Int> incapsulate limit value

=head1 SEE ALSO

L<Seach::QS::Options::Int>

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
