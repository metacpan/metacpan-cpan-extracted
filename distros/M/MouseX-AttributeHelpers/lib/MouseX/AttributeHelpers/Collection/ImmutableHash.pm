package MouseX::AttributeHelpers::Collection::ImmutableHash;
use Mouse;

extends 'MouseX::AttributeHelpers::Base';

has '+method_constructors' => (
    default => sub {
        return +{
            exists => sub {
                my ($attr, $name) = @_;
                return sub { exists $_[0]->$name()->{$_[1]} ? 1 : 0 };
            },
            get => sub {
                my ($attr, $name) = @_;
                return sub {
                    if (@_ == 2) {
                        $_[0]->$name()->{$_[1]};
                    } else {
                        my $h = shift->$name();
                        @{ $h }{@_};
                    }
                }
            },
            keys => sub {
                my ($attr, $name) = @_;
                return sub { keys %{ $_[0]->$name() } };
            },
            values => sub {
                my ($attr, $name) = @_;
                return sub { values %{ $_[0]->$name() } };
            },
            kv => sub {
                my ($attr, $name) = @_;
                return sub {
                    my $h = $_[0]->$name();
                    map { [ $_, $h->{$_} ] } keys %$h;
                };
            },
            count => sub {
                my ($attr, $name) = @_;
                return sub { scalar keys %{ $_[0]->$name() } };
            },
            empty => sub {
                my ($attr, $name) = @_;
                return sub { scalar keys %{ $_[0]->$name() } ? 1 : 0 };
            },
        };
    },
);

sub helper_type { 'HashRef' }

no Mouse;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
__END__

=head1 NAME

MouseX::AttributeHelpers::Collection::ImmutableHash

=head1 SYNOPSIS

    package MyClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'options' => (
        metaclass => 'Collection::ImmutableHash',
        is        => 'rw',
        isa       => 'HashRef',
        default   => sub { +{} },
        provides  => {
            get   => 'get_option',
            empty => 'has_options',
            keys  => 'get_option_list',
        },
    );

=head1 DESCRIPTION

This module provides a immutable HashRef attribute
which provides a number of hash-line operations.

=head1 PROVIDERS

=head2 count

=head2 empty

=head2 exists

=head2 get

=head2 keys

=head2 values

=head2 kv

=head1 METHODS

=head2 method_constructors

=head2 helper_type

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<MouseX::AttributeHelpers>, L<MouseX::AttributeHelpers::Base>

=cut
