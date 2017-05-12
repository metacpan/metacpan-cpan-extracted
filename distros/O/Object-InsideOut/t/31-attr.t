use strict;
use warnings;

use Test::More 'tests' => 5;

#MODIFY_CODE_ATTRIBUTES
#MODIFY_HASH_ATTRIBUTES
#MODIFY_ARRAY_ATTRIBUTES
#MODIFY_SCALAR_ATTRIBUTES

package Foo; {
    use Object::InsideOut;

    sub _add_defaults :MOD_SCALAR_ATTRS
    {
        my ($pkg, $scalar, @attrs) = @_;
        my @unused_attrs;   # List of any unhandled attributes

        while (my $attr = shift(@attrs)) {
            if ($attr =~ /^D\('?([^)']+)'?\)/i) {
                $$scalar = $1;
                Test::More::ok(1, "Foo: $attr");
            } else {
                push(@unused_attrs, $attr);
            }
        }

        return (@unused_attrs);
    }

    sub _make_fields :MOD_ARRAY_ATTRS
    {
        my ($pkg, $array, @attrs) = @_;
        my @unused_attrs;   # List of any unhandled attributes

        while (my $attr = shift(@attrs)) {
            if ($attr =~ /^F\('?([^)']+)'?\)/i) {
                push(@unused_attrs, "Field('all' => '$1')");
            } else {
                push(@unused_attrs, $attr);
            }
        }

        return (@unused_attrs);
    }

    my @foo :F(foo);    # :Field('all'=>'foo')
}

package Bork; {
    use Object::InsideOut;

    sub _check_attr :MOD_ARRAY_ATTRS
    {
        my ($pkg, $array, @attrs) = @_;
        my @unused_attrs;   # List of any unhandled attributes

        while (my $attr = shift(@attrs)) {
            if ($attr eq 'Test') {
                Test::More::ok(1, "Bork: $attr");
            } else {
                push(@unused_attrs, $attr);
            }
        }

        return (@unused_attrs);
    }
}

package Bar; {
    use Object::InsideOut qw(Foo Bork);

    my $iam :D(ima_foo);

    sub iam { return ($iam); }

    my @bar :F('bar') Test;

    sub _fetch_attrs :FETCH_CODE_ATTRS
    {
        my ($pkg, $ref) = @_;
        if ($ref == \&iam) {
            return ('Method');
        }
    }
}

package main;

MAIN:
{
    is(Bar::iam, 'ima_foo'      => 'Scalar default');

    my $obj = Bar->new();
    can_ok($obj => qw(foo bar));
    is((attributes::get(Bar->can('iam')))[0], 'Method', 'Fetch attr');
}

exit(0);

# EOF
