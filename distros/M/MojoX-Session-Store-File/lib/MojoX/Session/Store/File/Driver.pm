package MojoX::Session::Store::File::Driver;

use Carp qw(croak);

sub new {
    my $class = shift;

    bless {@_}, $class;
}

sub freeze {
    croak "freeze() method not implemented";
}

sub thaw {
    croak "thaw() method not implemented";
}

1;

__END__

=encoding utf8

=head1 NAME

MojoX::Session::Store::File::Driver - base class for various serialization drivers

=head1 SUBCLASSING

Any driver must implement these methods:

=head2 freeze($file, $ref)

    C<$ref> should be automatically converted to reference unless it already is.

    Must return some true value on sucess and false value otherwise.

=head2 thaw($file)

    Must return some ref value on success or undef otherwise.

=head1 CONTRIBUTE

L<http://github.com/ksurent/MojoX--Session--Store--File>

=head1 AUTHOR

Алексей Суриков E<lt>ksuri@cpan.orgE<gt>

=head1 LICENSE

This program is free software, you can redistribute it under the same terms as Perl itself.
