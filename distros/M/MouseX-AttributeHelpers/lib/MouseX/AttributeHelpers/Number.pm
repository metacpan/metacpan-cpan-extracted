package MouseX::AttributeHelpers::Number;
use Mouse;

extends 'MouseX::AttributeHelpers::Base';

has '+method_constructors' => (
    default => sub {
        return +{
            set => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} = $_[1] };
            },
            add => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} += $_[1] };
            },
            sub => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} -= $_[1] };
            },
            mul => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} *= $_[1] };
            },
            div => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} /= $_[1] };
            },
            mod => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} %= $_[1] };
            },
            abs => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} = abs $_[0]->{$name} };
            },
        };
    },
);

sub helper_type { 'Num' }

no Mouse;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
__END__

=head1 NAME

MouseX::AttributeHelpers::Number

=head1 SYNOPSIS

    package Real;
    use Mouse;
    use MouseX::AttributeHelpers;
  
    has 'integer' => (
        metaclass => 'Number',
        is        => 'rw',
        isa       => 'Int',
        default   => 5,
        provides  => {
            set => 'set',
            add => 'add',
            sub => 'sub',
            mul => 'mul',
            div => 'div',
            mod => 'mod',
            abs => 'abs',
        },
    );

    package main;
    my $real = Real->new;

    $real->add(5); # same as $real->integer($real->integer + 5);
    $real->sub(2); # same as $real->integer($real->integer - 2);

=head1 DESCRIPTION

This provides a simple numeric attribute,
which supports most of the basic math operations.

=head1 PROVIDERS

=head2 set

=head2 add

=head2 sub

=head2 mul

=head2 div

=head2 mod

=head2 abs

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
