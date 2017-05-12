package MouseX::AttributeHelpers::Counter;
use Mouse;

extends 'MouseX::AttributeHelpers::Base';

has '+method_constructors' => (
    default => sub {
        return +{
            reset => sub {
                my ($attr, $name) = @_;
                return sub {
                    $_[0]->{$name} = do {
                        if ($attr->has_default) {
                            my $default = $attr->default;
                            ref $default eq 'CODE' ? $default->($_[0]) : $default;
                        }
                        elsif ($attr->has_builder) {
                            my $builder = $attr->builder;
                            $_[0]->$builder;
                        }
                    };
                };
            },
            set => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} = $_[1] };
            },
            inc => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} += defined $_[1] ? $_[1] : 1 };
            },
            dec => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} -= defined $_[1] ? $_[1] : 1 };
            },
        };
    },
);

sub helper_type    { 'Num' }
sub helper_default { 0 }

no Mouse;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
__END__

=head1 NAME

MouseX::AttributeHelpers::Counter

=head1 SYNOPSIS

    package MyHomePage;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'counter' => (
        metaclass => 'Counter',
        is        => 'rw',
        isa       => 'Num',
        default   => 0,
        provides  => {
            inc   => 'inc_counter',
            dec   => 'dec_counter',
            reset => 'reset_counter',
        },
    );

    package main;
    my $page = MyHomePage->new;

    $page->inc_counter; # same as $page->counter($page->counter + 1);
    $page->dec_counter; # same as $page->counter($page->counter - 1);

=head1 DESCRIPTION

This module provides a simple counter attribute,
which can be incremented and decremented.

=head1 PROVIDERS

=head2 reset

=head2 set

=head2 inc

=head2 dec

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

L<MouseX::AttributeHelpers>, L<MouseX::AttributeHelpers::Base>

=cut
