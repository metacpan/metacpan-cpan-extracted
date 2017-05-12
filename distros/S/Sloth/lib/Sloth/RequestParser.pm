package Sloth::RequestParser;
BEGIN {
  $Sloth::RequestParser::VERSION = '0.05';
}
# ABSTRACT: An object that can parse requests into hash references
use Moose::Role;


requires 'parse';

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Sloth::RequestParser - An object that can parse requests into hash references

=head1 METHODS

=head2 parse

    $self->parse($request : L<Sloth::Request>)

B<Required>. Classes which consume this role must implement this method.

Parses a request into a hash reference.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Oliver Charles <sloth.cpan@ocharles.org.uk>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

