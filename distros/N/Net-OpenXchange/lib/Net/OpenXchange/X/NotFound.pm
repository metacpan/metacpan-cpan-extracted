use Modern::Perl;
package Net::OpenXchange::X::NotFound;
BEGIN {
  $Net::OpenXchange::X::NotFound::VERSION = '0.001';
}

use Moose;

# ABSTRACT: Exception class for missing objects

extends 'Throwable::Error';

has 'message' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;


__END__
=pod

=head1 NAME

Net::OpenXchange::X::NotFound - Exception class for missing objects

=head1 VERSION

version 0.001

=head1 SYNOPSIS

        Net::OpenXchange::X::NotFound->throw({
            message => "$type $name not found",
            type => $type,
            name => $name,
        });

Net::OpenXchange::X::NotFound is an exception class thrown when an object could not
be found.

=head1 ATTRIBUTES

=head2 message

Required, message describing the error

=head2 response

Required, type of object that could not be found (e.g. folder)

=head2 name

Name of object that could not be found (e.g. the name of a folder)

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

