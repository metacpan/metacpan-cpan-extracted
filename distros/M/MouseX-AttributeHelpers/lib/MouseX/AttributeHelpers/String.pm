package MouseX::AttributeHelpers::String;
use Mouse;

extends 'MouseX::AttributeHelpers::Base';

has '+method_constructors' => (
    default => sub {
        return +{
            append => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} .= $_[1] };
            },
            prepend => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} = $_[1] . $_[0]->{$name} };
            },
            replace => sub {
                my (undef, $name) = @_;
                return sub {
                    (ref $_[2] || '') eq 'CODE'
                        ? $_[0]->{$name} =~ s/$_[1]/$_[2]->()/e
                        : $_[0]->{$name} =~ s/$_[1]/$_[2]/;
                };
            },
            match => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} =~ $_[1] };
            },
            chop => sub {
                my (undef, $name) = @_;
                return sub { chop $_[0]->{$name} };
            },
            chomp => sub {
                my (undef, $name) = @_;
                return sub { chomp $_[0]->{$name} };
            },
            inc => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name}++ };
            },
            clear => sub {
                my (undef, $name) = @_;
                return sub { $_[0]->{$name} = '' };
            },
        };
    },
);

sub helper_type    { 'Str' }
sub helper_default { '' }

no Mouse;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
__END__

=head1 NAME

MouseX::AttributeHelpers::String

=head1 SYNOPSIS

    package MyHomePage;
    use Mouse;
    use MouseX::AttributeHelpers;
  
    has 'text' => (
        metaclass => 'String',
        is        => 'rw',
        isa       => 'Str',
        default   => '',
        provides  => {
            append => 'add_text',
            clear  => 'clear_text',
        },
    );

    package main;
    my $page = MyHomePage->new;

    $page->add_text("foo"); # same as $page->text($page->text . "foo");
    $page->clear_text;      # same as $page->text('');

=head1 DESCRIPTION

This module provides a simple string attribute,
to which mutating string operations can be applied more easily.

=head1 PROVIDERS

=head2 append

=head2 prepend

=head2 replace

=head2 match

=head2 chop

=head2 chomp

=head2 inc

=head2 clear

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
