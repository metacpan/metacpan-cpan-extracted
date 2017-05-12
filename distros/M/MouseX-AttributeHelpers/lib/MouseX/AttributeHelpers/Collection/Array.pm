package MouseX::AttributeHelpers::Collection::Array;
use Mouse;
use MouseX::AttributeHelpers::Collection::List;

extends 'MouseX::AttributeHelpers::Base';

has '+method_constructors' => (
    default => sub {
        my $attr = MouseX::AttributeHelpers::Collection::List->meta->get_attribute('method_constructors');
        return +{
            %{ $attr->default->() }, # apply MouseX::AttributeHelpers::Collection::List
            push => sub {
                my ($attr, $name) = @_;
                return sub { push @{ shift->$name() } => @_ };
            },
            pop => sub {
                my ($attr, $name) = @_;
                return sub { pop @{ $_[0]->$name() } };
            },
            unshift => sub {
                my ($attr, $name) = @_;
                return sub { unshift @{ shift->$name() } => @_ };
            },
            shift => sub {
                my ($attr, $name) = @_;
                return sub { shift @{ $_[0]->$name() } };
            },
            get => sub {
                my ($attr, $name) = @_;
                return sub { $_[0]->$name()->[$_[1]] };
            },
            set => sub {
                my ($attr, $name) = @_;
                return sub { $_[0]->$name()->[$_[1]] = $_[2] };
            },
            clear => sub {
                my ($attr, $name) = @_;
                return sub { @{ $_[0]->$name() } = () };
            },
            delete => sub {
                my ($attr, $name) = @_;
                return sub { splice @{ $_[0]->$name() }, $_[1], 1 };
            },
            insert => sub {
                my ($attr, $name) = @_;
                return sub { splice @{ $_[0]->$name() }, $_[1], 0, $_[2] };
            },
            splice => sub {
                my ($attr, $name) = @_;
                return sub {
                    my ($self, $offset, $length, @args) = @_;
                    splice @{ $self->$name() }, $offset, $length, @args;
                };
            },
        };
    },
);

sub helper_type { 'ArrayRef' }

no Mouse;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
__END__

=head1 NAME

MouseX::AttributeHelpers::Collection::Array

=head1 SYNOPSIS

    package MyClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'options' => (
        metaclass => 'Collection::Array',
        is        => 'rw',
        isa       => 'ArrayRef',
        default   => sub { [] },
        provides  => {
            count => 'num_options',
            empty => 'has_options',
            push  => 'add_options',
            pop   => 'remove_last_option',
        },
    );

=head1 DESCRIPTION

This module provides an Array attribute which provides
a number of array operations.

=head1 PROVIDERS

This module also consumes the B<List> method providers.
See also L<MouseX::AttributeHelpers::Collection::List>.

=head2 push

=head2 pop

=head2 unshift

=head2 shift

=head2 get

=head2 set

=head2 clear

=head2 delete

=head2 insert

=head2 splice

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
L<MouseX::AttributeHelpers::Collection::List>

=cut
