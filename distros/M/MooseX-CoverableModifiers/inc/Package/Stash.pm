#line 1
package Package::Stash;
{
  $Package::Stash::VERSION = '0.33';
}
use strict;
use warnings;
# ABSTRACT: routines for manipulating stashes

our $IMPLEMENTATION;

BEGIN {
    $IMPLEMENTATION = $ENV{PACKAGE_STASH_IMPLEMENTATION}
        if exists $ENV{PACKAGE_STASH_IMPLEMENTATION};

    my $err;
    if ($IMPLEMENTATION) {
        if (!eval "require Package::Stash::$IMPLEMENTATION; 1") {
            require Carp;
            Carp::croak("Could not load Package::Stash::$IMPLEMENTATION: $@");
        }
    }
    else {
        for my $impl ('XS', 'PP') {
            if (eval "require Package::Stash::$impl; 1;") {
                $IMPLEMENTATION = $impl;
                last;
            }
            else {
                $err .= $@;
            }
        }
    }

    if (!$IMPLEMENTATION) {
        require Carp;
        Carp::croak("Could not find a suitable Package::Stash implementation: $err");
    }

    my $impl = "Package::Stash::$IMPLEMENTATION";
    my $from = $impl->new($impl);
    my $to = $impl->new(__PACKAGE__);
    my $methods = $from->get_all_symbols('CODE');
    for my $meth (keys %$methods) {
        $to->add_symbol("&$meth" => $methods->{$meth});
    }
}

use Package::DeprecationManager -deprecations => {
    'Package::Stash::add_package_symbol'        => 0.14,
    'Package::Stash::remove_package_glob'       => 0.14,
    'Package::Stash::has_package_symbol'        => 0.14,
    'Package::Stash::get_package_symbol'        => 0.14,
    'Package::Stash::get_or_add_package_symbol' => 0.14,
    'Package::Stash::remove_package_symbol'     => 0.14,
    'Package::Stash::list_all_package_symbols'  => 0.14,
};

sub add_package_symbol {
    #deprecated('add_package_symbol is deprecated, please use add_symbol');
    shift->add_symbol(@_);
}

sub remove_package_glob {
    #deprecated('remove_package_glob is deprecated, please use remove_glob');
    shift->remove_glob(@_);
}

sub has_package_symbol {
    #deprecated('has_package_symbol is deprecated, please use has_symbol');
    shift->has_symbol(@_);
}

sub get_package_symbol {
    #deprecated('get_package_symbol is deprecated, please use get_symbol');
    shift->get_symbol(@_);
}

sub get_or_add_package_symbol {
    #deprecated('get_or_add_package_symbol is deprecated, please use get_or_add_symbol');
    shift->get_or_add_symbol(@_);
}

sub remove_package_symbol {
    #deprecated('remove_package_symbol is deprecated, please use remove_symbol');
    shift->remove_symbol(@_);
}

sub list_all_package_symbols {
    #deprecated('list_all_package_symbols is deprecated, please use list_all_symbols');
    shift->list_all_symbols(@_);
}


1;

__END__
#line 294

