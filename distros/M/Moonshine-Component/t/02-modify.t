use Moonshine::Test qw/:all/;

use Moonshine::Component;
use Moonshine::Element;

my $instance = Moonshine::Component->new( {} );

package Test::First;

use Moonshine::Magic;
use Moonshine::Util qw/join_class prepend_str/;

extends 'Moonshine::Component';

has (
    modifier_spec => sub { 
        { 
            switch => 0,
            switch_base => 0,  
        }   
    }
);

lazy_components('span');

sub modify {
    my $self = shift;
    my ($base_args, $build_args, $modify_args) = @_;
    if (my $class = join_class($modify_args->{switch_base}, $modify_args->{switch})){
        $base_args->{class} = prepend_str($class, $base_args->{class});
    }
    return $base_args, $build_args, $modify_args;
}

sub glyphicon {
    my $self = shift;
    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => {
                switch      => 1,
                switch_base => { default => 'glyphicon glyphicon-' },
                aria_hidden => { default => 'true' },
            }
        }
    );
    return $self->span($base_args);
}

package main;

moon_test_one(
    instance  => $instance,
    func => 'build_elements',
    args      => [  
        {
            class => 'not an obj, nor am action. or a tag'
        },
    ],
    args_list => 1,
    expected  => qr/no instructions to build the element:/,
    catch     => 1,
);

my $args = { tag => 'div', class => 'one two three' };

moon_test_one(
    instance  => $instance,
    func => 'build_elements',
    args      => [  
        $args,
    ],
    args_list => 1,
    expected  => 'Moonshine::Element',
    test      => 'obj',
);

moon_test_one(
    instance  => $instance,
    func => 'build_elements',
    args      => [  
        {
            func => 'nope',
            class => 'not an obj, nor an action. or a tag'
        },
    ],
    args_list => 1,
    expected  => qr/no instructions to build the element/,
    catch     => 1,
);

my $test_instance = Test::First->new({});

moon_test_one(
    instance  => $test_instance,
    func => 'build_elements',
    args      => [  
        {
            action => 'glyphicon',
            switch => 'search',
        },
    ],
    args_list => 1,
    expected  => '<span class="glyphicon glyphicon-search" aria-hidden="true"></span>',
    test      => 'render',
);

my $test_element = Moonshine::Element->new({ tag => 'span', class => 'glyphicon glyphicon-search', aria_hidden => 'true' });

moon_test_one(
    instance  => $instance,
    func => 'build_elements',
    args      => [  
        $test_element
    ],
    args_list => 1,
    expected  => '<span class="glyphicon glyphicon-search" aria-hidden="true"></span>',
    test      => 'render',
);

sunrise();

1;
