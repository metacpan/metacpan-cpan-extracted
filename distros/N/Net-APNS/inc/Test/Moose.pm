#line 1
package Test::Moose;
BEGIN {
  $Test::Moose::AUTHORITY = 'cpan:STEVAN';
}
BEGIN {
  $Test::Moose::VERSION = '2.0205';
}

use strict;
use warnings;

use Sub::Exporter;
use Test::Builder;

use List::MoreUtils 'all';
use Moose::Util 'does_role', 'find_meta';

my @exports = qw[
    meta_ok
    does_ok
    has_attribute_ok
    with_immutable
];

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { default => \@exports }
});

## the test builder instance ...

my $Test = Test::Builder->new;

## exported functions

sub meta_ok ($;$) {
    my ($class_or_obj, $message) = @_;

    $message ||= "The object has a meta";

    if (find_meta($class_or_obj)) {
        return $Test->ok(1, $message)
    }
    else {
        return $Test->ok(0, $message);
    }
}

sub does_ok ($$;$) {
    my ($class_or_obj, $does, $message) = @_;

    $message ||= "The object does $does";

    if (does_role($class_or_obj, $does)) {
        return $Test->ok(1, $message)
    }
    else {
        return $Test->ok(0, $message);
    }
}

sub has_attribute_ok ($$;$) {
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

sub with_immutable (&@) {
    my $block = shift;
    my $before = $Test->current_test;
    $block->();
    Class::MOP::class_of($_)->make_immutable for @_;
    $block->();
    my $num_tests = $Test->current_test - $before;
    return all { $_ } ($Test->summary)[-$num_tests..-1];
}

1;

# ABSTRACT: Test functions for Moose specific features



#line 187


__END__


