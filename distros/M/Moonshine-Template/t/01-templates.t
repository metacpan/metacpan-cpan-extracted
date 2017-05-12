use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Moonshine::Template');
}

package Test::One;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' }

sub build_html {
    my ($self) = shift;

    my $base_element =
      $self->add_base_element( { tag => "div", class => "content" } );
    $base_element->add_child(
        { tag => "p", class => "testing", data => [ "one", "two", "three" ] } );
    return $base_element;
}

package Test::Two;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' }

sub base_element {
    return {
        tag   => 'div',
        class => 'content'
    };
}

sub build_html {
    my ( $self, $base ) = @_;

    my $ul = $base->add_child( { tag => 'ul' } );
    for (qw/one two three/) {
        $ul->add_child( { tag => 'li', class => $_, data => [$_] } );
    }
    return $base;
}

package Test::Three;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' }

sub base_element {
    return {
        tag   => 'div',
        class => 'content',
    };
}

sub build_html {
    my ( $self, $base ) = @_;

    my $test1 = Test::One->new();
    $base->children($test1);
    $test1->{base_element}->children( Test::Two->new() );
    return $base;
}

package Test::Build::Exception;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' }

sub base_element {
    return {
        tag   => 'div',
        class => 'content',
    };
}

package Test::NoDefaultBase;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' }

sub build_html {
    my ( $self, $base ) = @_;

    my $test1 = Test::One->new();
    $base->children($test1);
    $test1->{base_element}->children( Test::Two->new() );
    return $base;
}

package main;

subtest "build_and_render" => sub {
    build_and_render(
        {
            class => 'Test::One',
            expected =>
              '<div class="content"><p class="testing">one two three</p></div>',
        }
    );
    build_and_render(
        {
            class => 'Test::Two',
            expected =>
'<div class="content"><ul><li class="one">one</li><li class="two">two</li><li class="three">three</li></ul></div>',
        }
    );
    build_and_render(
        {
            class => 'Test::Three',
            expected =>
'<div class="content"><div class="content"><p class="testing">one two three</p><div class="content"><ul><li class="one">one</li><li class="two">two</li><li class="three">three</li></ul></div></div></div>'
        }
    );
    build_and_render(
        {
            class => 'Test::NoDefaultBase',
            args  => {
                base_element => {
                    tag   => 'div',
                    class => 'content',
                },
            },
            expected =>
'<div class="content"><div class="content"><p class="testing">one two three</p><div class="content"><ul><li class="one">one</li><li class="two">two</li><li class="three">three</li></ul></div></div></div>'
        }
    );
};

subtest 'add_child_test' => sub {
    add_child_test(
        {
            first_class  => 'Test::One',
            second_class => 'Test::Two',
            placement    => 'after',
            expected_render =>
'<div class="content"><p class="testing">one two three</p></div><div class="content"><ul><li class="one">one</li><li class="two">two</li><li class="three">three</li></ul></div>',
        }
    );
    add_child_test(
        {
            first_class  => 'Test::One',
            second_class => 'Test::Two',
            placement    => 'before',
            expected_render =>
'<div class="content"><ul><li class="one">one</li><li class="two">two</li><li class="three">three</li></ul></div><div class="content"><p class="testing">one two three</p></div>',
        }
    );
};

subtest 'die' => sub {
    build_and_die(
        {
            class     => 'Test::Build::Exception',
            exception => qr/build_html is not defined/,
        }
    );
};

sub build_and_render {
    my $args = shift;

    ok( my $class = $args->{class}->new( $args->{args} // {} ) );
    is( $class->render, $args->{expected},
        "render some html - $args->{expected}" );
}

sub build_and_die {
    my $args = shift;

    eval { $args->{class}->new; };
    like( $@, $args->{exception}, "dead - $args->{exception}" );
}

sub add_child_test {
    my $args = shift;

    my $first     = $args->{first_class}->new;
    my $second    = $args->{second_class}->new;
    my $placement = $args->{placement};

    $first->{base_element}->add_child( $second->{base_element}, $placement );
    is(
        $first->render,
        $args->{expected_render},
        "render - $args->{expected_render}"
    );
}

done_testing();

1;

