package Number::Object::Filter;

use strict;
use warnings;

use Carp::Clan qw/Number::Object/;
use Class::Inspector;
use String::CamelCase qw(camelize);
use UNIVERSAL::require;

sub init {}
sub filter {}

sub execute {
    my($class, $c, $value, @filters) = @_;

    for my $filter (@filters) {
        my $pkg = $class->resolve_filter($c, $filter);
	croak qq{not installed "$filter" filter} unless $pkg;
        unless (Class::Inspector->loaded($pkg)) {
            $pkg->require or die $@;
            $pkg->init($c);
        }
        $value = $pkg->filter($c, $value);
    }
    $value;
}

sub resolve_filter {
    my($class, $c, $filter) = @_;
    my $pkg = ref $c;
    $filter = camelize $filter;

    for my $f ("$pkg\::Filter::$filter", "Number::Object::Filter::$filter") {
        return $f if Class::Inspector->installed($f);
    }
    return;
}

1;
