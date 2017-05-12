use strict;
use warnings;

use Test::More 'tests' => 6;

#$Object::InsideOut::DEBUG = 1;

package My::Class; {
    use Object::InsideOut;

    sub auto : Automethod
    {
        my $self = $_[0];
        my $class = ref($self) || $self;

        my $method = $_;

        my ($fld_name) = $method =~ /^[gs]et_(.*)$/;
        if (! $fld_name) {
            return;
        }
        Object::InsideOut->create_field($class, '@'.$fld_name,
                                        "'Name'=>'$fld_name',",
                                        "'Std' =>'$fld_name'");

        no strict 'refs';
        return *{$class.'::'.$method}{'CODE'};
    }

    sub make
    {
        my ($self, $name, $type) = @_;
        My::Class->create_field('@'.$name,
                                ":Field('Std' =>'$name',",
                                "       'Type' => '$type')",
                                ":Name($name)");
    }
}


package My::Sub; {
    use Object::InsideOut qw(My::Class);

    my @data :Field('set'=>'munge');
}


package main;

MAIN:
{
    my $obj = My::Sub->new();

    $obj->set_data(5);
    can_ok($obj, qw(get_data set_data));
    is($obj->get_data(), 5              => 'Method works');
    can_ok('My::Sub', qw(get_data set_data));
    $obj->munge('hello');
    is($obj->get_data(), 5              => 'Not munged');

    $obj->make('foo', 'numeric');
    can_ok($obj, qw(get_foo set_foo));
    $obj->set_foo(99);
    is($obj->get_foo(), 99              => 'Dynamic foo');

    #print(STDERR $obj->dump(1), "\n");
}

exit(0);

# EOF
