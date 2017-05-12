package Sloth::RequestParser::Form;
BEGIN {
  $Sloth::RequestParser::Form::VERSION = '0.05';
}
# ABSTRACT: A request parser for application/x-www-urlencoded data
use Moose;

with 'Sloth::RequestParser';


sub parse {
    my ($self, $request) = @_;
    return %{ $request->body_parameters };
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Sloth::RequestParser::Form - A request parser for application/x-www-urlencoded data

=head1 METHODS

=head2 parse

Parse a request by extracting a hash reference of body parameters.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Oliver Charles <sloth.cpan@ocharles.org.uk>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

