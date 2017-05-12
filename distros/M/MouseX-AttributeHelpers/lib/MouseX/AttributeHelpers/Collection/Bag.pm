package MouseX::AttributeHelpers::Collection::Bag;
use Mouse;
use Mouse::Util::TypeConstraints;
use MouseX::AttributeHelpers::Collection::ImmutableHash;

extends 'MouseX::AttributeHelpers::Base';

has '+method_constructors' => (
    default => sub {
        my $attr = MouseX::AttributeHelpers::Collection::ImmutableHash->meta->get_attribute('method_constructors');
        return +{
            %{ $attr->default->() }, # apply MouseX::AttributeHelpers::Collection::ImmutableHash

            add => sub {
                my ($attr, $name) = @_;
                return sub { $_[0]->$name()->{$_[1]}++ };
            },
            delete => sub {
                my ($attr, $name) = @_;
                return sub { delete $_[0]->$name()->{$_[1]} };
            },
            reset => sub {
                my ($attr, $name) = @_;
                return sub { $_[0]->$name()->{$_[1]} = 0 };
            },
        };
    },
);

subtype 'Bag', as 'HashRef[Int]';

sub helper_type    { 'Bag' }
sub helper_default { sub { +{} } }

no Mouse;
no Mouse::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
__END__

=head1 NAME

MouseX::AttributeHelpers::Collection::Bag

=head1 SYNOPSIS

    package MyClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'word_histogram' => (
        metaclass => 'Collection::Bag',
        is        => 'rw',
        isa       => 'Bag', # exported
        default   => sub { +{} },
        provides  => {
            add    => 'add_word',
            get    => 'get_count_for',            
            empty  => 'has_any_words',
            count  => 'num_words',
            delete => 'delete_word',
        },
    );

=head1 DESCRIPTION

This module provides an Hash attribute which provides
a number of hash-like operations.

=head1 PROVIDERS

This module also consumes the B<ImmutableHash> method providers.
See also L<MouseX::AttributeHelpers::Collection::ImmutableHash>.

=head2 add

=head2 delete

=head2 reset

=head1 METHODS

=head2 method_constructors

=head2 helper_type

=head2 helper_default

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
