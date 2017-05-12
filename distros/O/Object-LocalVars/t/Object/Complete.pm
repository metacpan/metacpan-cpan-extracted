package t::Object::Complete;
use strict;
use warnings;
use Object::LocalVars;

give_methods our $self;

our $name : Pub;
our $color : Pub;
our $_count : Class;

sub BUILD : Method {
    my %init = @_;
    ++$_count;
    $name = $init{"name"};
}

sub DEMOLISH : Method {
    --$_count;
}

sub get_count : Method { return $_count };

sub desc : Method {
    return "I'm $name and my color is $color";
};

sub report_caller : Method {
    return ( caller );
}

sub report_package : Method {
    return __PACKAGE__
}

sub report_color {
    return $color;
}

1;
