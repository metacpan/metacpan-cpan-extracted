use Modern::Perl;
package Net::OpenXchange::X::Thaw;
BEGIN {
  $Net::OpenXchange::X::Thaw::VERSION = '0.001';
}

use Moose;

# ABSTRACT: Exception class for Object thawing errors

use Data::Dump qw(dump);
extends 'Throwable::Error';

has class => (
    is       => 'ro',
    required => 1,
    isa      => 'ClassName',
);

has data => (
    is       => 'ro',
    required => 1,
    isa      => 'HashRef',
);

has 'message' => (
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
);

has 'error' => (
    is       => 'ro',
    required => 1,
);

sub _build_message {
    my ($self) = @_;
    return sprintf 'Could not thaw class %s from data: %s, because of: %s ',
        $self->class, dump($self->data), $self->error;

}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;


__END__
=pod

=head1 NAME

Net::OpenXchange::X::Thaw - Exception class for Object thawing errors

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    Net::OpenXchange::X::Thaw->throw(
        class => $class,
        data => \%data,
        error => $_,
    );

Net::OpenXchange::X::Thaw is an exception class which is thrown when an object
could not be created from a list of values fetched from OpenXchange.

=head1 ATTRIBUTES

=head2 class

Name of the class of which an instance should have been created (e.g.
Net::OpenXchange::Object::User)

=head2 data

Hash reference of data that was passed to the class's constructor

=head2 error

Error that prevented the creation of the class's instance

=head2 message

Will be constructed automatically and describe the exception using the above
attributes

=head1 SEE ALSO

L<http://oxpedia.org/wiki/index.php?title=HTTP_API#Error_handling|http://oxpedia.org/wiki/index.php?title=HTTP_API#Error_handling>

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

