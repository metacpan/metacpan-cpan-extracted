#line 1
package Test::Mouse;

use Mouse::Exporter;
use Mouse::Util qw(does_role find_meta);

use Test::Builder;

Mouse::Exporter->setup_import_methods(
    as_is => [qw(
        meta_ok
        does_ok
        has_attribute_ok
        with_immutable
    )],
);

## the test builder instance ...

my $Test = Test::Builder->new;

## exported functions

sub meta_ok ($;$) { ## no critic
    my ($class_or_obj, $message) = @_;

    $message ||= "The object has a meta";

    if (find_meta($class_or_obj)) {
        return $Test->ok(1, $message)
    }
    else {
        return $Test->ok(0, $message);
    }
}

sub does_ok ($$;$) { ## no critic
    my ($class_or_obj, $does, $message) = @_;

    $message ||= "The object does $does";

    if (does_role($class_or_obj, $does)) {
        return $Test->ok(1, $message)
    }
    else {
        return $Test->ok(0, $message);
    }
}

sub has_attribute_ok ($$;$) { ## no critic
    my ($class_or_obj, $attr_name, $message) = @_;

    $message ||= "The object does has an attribute named $attr_name";

    my $meta = find_meta($class_or_obj);

    if ($meta->find_attribute_by_name($attr_name)) {
        return $Test->ok(1, $message)
    }
    else {
        return $Test->ok(0, $message);
    }
}

sub with_immutable (&@) { ## no critic
    my $block = shift;

    my $before = $Test->current_test;

    $block->();
    $_->meta->make_immutable for @_;
    $block->();
    return if not defined wantarray;

    my $num_tests = $Test->current_test - $before;
    return !grep{ !$_ } ($Test->summary)[-$num_tests .. -1];
}

1;
__END__

#line 132

