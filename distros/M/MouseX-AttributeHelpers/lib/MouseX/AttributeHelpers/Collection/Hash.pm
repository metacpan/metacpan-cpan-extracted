package MouseX::AttributeHelpers::Collection::Hash;
use Mouse;
use MouseX::AttributeHelpers::Collection::ImmutableHash;

extends 'MouseX::AttributeHelpers::Base';

has '+method_constructors' => (
    default => sub {
        my $attr = MouseX::AttributeHelpers::Collection::ImmutableHash->meta->get_attribute('method_constructors');
        return +{
            %{ $attr->default->() }, # apply MouseX::AttributeHelpers::Collection::ImmutableHash

            set => sub {
                my ($attr, $name) = @_;
                return sub {
                    if (@_ == 3) {
                        $_[0]->$name()->{$_[1]} = $_[2];
                    }
                    else {
                        my $self = shift;
                        my (@k, @v);
                        while (@_) {
                            push @k, shift;
                            push @v, shift;
                        }
                        @{ $self->$name() }{@k} = @v;
                    }
                };
            },
            clear => sub {
                my ($attr, $name) = @_;
                return sub { %{ $_[0]->$name() } = () };
            },
            delete => sub {
                my ($attr, $name) = @_;
                return sub { delete @{ shift->$name() }{@_} };
            },
        };
    },
);

sub helper_type { 'HashRef' }

no Mouse;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
__END__

=head1 NAME

MouseX::AttributeHelpers::Collection::Hash

=head1 SYNOPSIS

    package MyClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'options' => (
        metaclass => 'Collection::Hash',
        is        => 'rw',
        isa       => 'HashRef',
        default   => sub { +{} },
        provides  => {
            set    => 'set_option',
            get    => 'get_option',
            empty  => 'has_options',
            count  => 'num_options',
            delete => 'delete_option',
        },
    );

=head1 DESCRIPTION

This module provides an Hash attribute which provides
a number of hash-like operations.

=head1 PROVIDERS

This module also consumes the B<ImmutableHash> method providers.
See also L<MouseX::AttributeHelpers::Collection::ImmutableHash>.

=head2 set

=head2 clear

=head2 delete

=head1 METHODS

=head2 method_constructors

=head2 helper_type

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<MouseX::AttributeHelpers>,
L<MouseX::AttributeHelpers::Base>,
L<MouseX::AttributeHelpers::Collection::ImmutableHash>

=cut
