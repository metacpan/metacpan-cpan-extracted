package REST::Cypher::Exception;
{
  $REST::Cypher::Exception::DIST = 'REST-Cypher';
}
# ABSTRACT base class for exception handling
$REST::Cypher::Exception::VERSION = '0.0.4';
use strict;
use warnings;

use Moo;
with 'Throwable';

use overload
    q{""}    => 'as_string',
    fallback => 1;

sub as_string {
    my ($self) = @_;
    return $self->message;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

REST::Cypher::Exception

=head1 VERSION

version 0.0.4

=head2 as_string

This method in L<REST::Cypher::Exception> allows easy stringification of
thrown exceptions.

It returns the current value of I<message>.

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
