package Tester;
use strict;
use warnings;

use Test::More;
use Test::Exception;

use MooseX::LocalAttribute 'local_attribute';

sub run_tests {
    my ($obj) = @_;

    subtest 'errors' => sub {
        throws_ok {
            local_attribute( $obj, 'string', my $foo )
        }
        qr/local_attribute must not be called in void context/,
          'errors when called in void context';
        throws_ok {
            my $guard = local_attribute( $obj, 'no_such_attr', my $foo )
        }
        qr/Attribute 'no_such_attr' does not exist/,
          'errors when objects does not have attribute';

    };

    subtest 'string attribute' => sub {
        is $obj->string, 'string', 'string attribute before we change it';

        my $temp  = 123;
        my $guard = local_attribute( $obj, 'string', $temp );
        isa_ok $guard, 'Scope::Guard';
        is $obj->string, 123, 'string attribute has been changed';
        is $temp, 123, '... and our variable is still there';

        undef $guard;
        is $obj->string, 'string', 'string attribute has changed back';
    };

    subtest 'hashref attribute' => sub {
        is $obj->hashref->{key}, 'value',
          'hashref attribute before we change it';

        my $temp  = { key => 123 };
        my $guard = local_attribute( $obj, 'hashref', $temp );
        isa_ok $guard, 'Scope::Guard';
        is $obj->hashref->{key}, 123, 'hashref attribute has been changed';

        # this method needs to exist on the tester, it will set the value
        $obj->change_hashref( key => 'foobar' );
        is $obj->hashref->{key}, 'foobar',
          'calling code that changes a value inside the hashref works';
        is $temp->{key}, 'foobar',
          '... and it also got changed in our variable';

        undef $guard;
        is $obj->hashref->{key}, 'value', 'hashref attribute has changed back';
    };
}

1;
