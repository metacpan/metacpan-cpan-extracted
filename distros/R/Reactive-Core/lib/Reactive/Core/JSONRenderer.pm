package Reactive::Core::JSONRenderer;

use warnings;
use strict;

use Moo;

use Types::Standard qw( is_Bool is_Str is_Num is_HashRef is_ArrayRef InstanceOf );
use Reactive::Core::Types qw( is_Boolean is_DateTime is_DBIx is_SerializedDBIx to_SerializedDBIx is_DBIxProxy);

use DateTime::Format::ISO8601;
use JSON::MaybeXS;

has json => (is => 'lazy', isa => InstanceOf[qw/Cpanel::JSON::XS JSON::XS JSON::PP/]);
has canonical_json => (is => 'lazy', isa => InstanceOf[qw/Cpanel::JSON::XS JSON::XS JSON::PP/]);

=head2 render($self, HashRef $data)
    This method is not expected to be called directly via userland code
    but instead will be called by Reactive::Core::TemplateRenderer->inject_attribute

    returns json encoded $data after first handling some common types
=cut
sub render {
    my $self = shift;
    my $data = shift;

    my $processed = $self->process_data($data);

    return $self->json->encode($processed);
}

=head2 process_data($self, HashRef $data)
    This method is not expected to be called directly via userland code
    but instead will be called by ->render

    recursively iterates through $data performing some type conversions
    to allow json encoding to work more smoothly

    most notably
    DateTime objects will be encoded as full ISO8601 strings with timezone info
    DBIx::Class objects will be serialized in a way that minimizes the data while also allowing them to work nicely in components

    returns a HashRef with same keys as $data but with the converted values
=cut
sub process_data {
    my $self = shift;
    my $data = shift;

    if (is_Boolean($data) || is_Str($data) || is_Num($data) || is_SerializedDBIx($data)) {
        return $data;
    }

    if (is_DateTime($data)) {
        return DateTime::Format::ISO8601->format_datetime($data);
    }

    if (is_DBIx($data) || is_DBIxProxy($data)) {
        return to_SerializedDBIx($data);
    }

    if (is_ArrayRef($data)) {
        return [
            map { $self->process_data($_) } @{ $data }
        ];
    }

    if (is_HashRef($data)) {
        return {
            map { $_ => $self->process_data($data->{$_}) } keys %{ $data }
        };
    }

    return $data;
}

sub _build_json {
    my $self = shift;

    return JSON::MaybeXS->new(utf8 => 1, pretty => 1);
}

sub _build_canonical_json {
    my $self = shift;

    return JSON::MaybeXS->new(utf8 => 1, canonical => 1);
}

=head1 AUTHOR

Robert Moore, C<< <robert at r-moore.tech> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-reactive-core at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Reactive-Core>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Reactive::Core


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Reactive-Core>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Reactive-Core>

=item * Search CPAN

L<https://metacpan.org/release/Reactive-Core>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Robert Moore.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;
