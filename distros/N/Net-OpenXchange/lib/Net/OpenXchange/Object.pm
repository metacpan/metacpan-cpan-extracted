use Modern::Perl;
package Net::OpenXchange::Object;
BEGIN {
  $Net::OpenXchange::Object::VERSION = '0.001';
}

use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Role for OpenXchange objects

use Net::OpenXchange::X::Thaw;
use Try::Tiny;

sub _get_ox_attributes {
    my ($class) = @_;
    return
      grep { $_->does('Net::OpenXchange::Attribute') }
      $class->meta->get_all_attributes;
}

sub get_ox_columns {
    my ($class) = @_;
    return map { $_->ox_id } $class->_get_ox_attributes;
}

sub thaw {
    my ($class, $values_ref) = @_;
    my @attrs = map { $_->name } $class->_get_ox_attributes;
    my %data;

    foreach (@attrs) {
        my $value = shift @{ $values_ref };
        $data{$_} = $value if defined $value;
    }

    my $obj = try {
        return $class->new(%data);
    }
    catch {
        Net::OpenXchange::X::Thaw->throw(
            class => $class,
            data  => \%data,
            error => $_,
        );
    };

    return $obj;
}

1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Object - Role for OpenXchange objects

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Object is a role to be consumed by classes representing
objects in OpenXchange, like contacts and appointments.

=head1 METHODS

=head2 get_ox_columns

    my @columns = $object->get_ox_columns();

Return a list of OpenXchange column IDs for all attributes of this object

=head2 thaw

    my $object = $class->thaw($values);

Maps the values given as an array reference into an object, using the same order
as returned by get_ox_columns

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

