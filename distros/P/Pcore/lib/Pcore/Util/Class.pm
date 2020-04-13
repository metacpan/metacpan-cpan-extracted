package Pcore::Util::Class;

use Pcore;
use Sub::Util qw[];    ## no critic qw[Modules::ProhibitEvilModules]
use Package::Stash::XS qw[];
use Pcore::Util::Scalar qw[is_ref];

sub load ( $module, @ ) {
    my %args = (
        ns  => undef,
        isa => undef,
        splice @_, 1,
    );

    my $package = module_to_package($module);

    $package = resolve_class_name( $package, $args{ns} );

    die q[Invalid package name] if $package =~ /[^[:alnum:]_:]/sm;

    $module = package_to_module($package);

    require $module;

    die qq[Error loading module "$module". Module must be instance of "$args{isa}"] if $args{isa} && !$package->isa( $args{isa} );

    return $package;
}

sub find ( $module, @ ) {
    my %args = (
        ns => undef,
        splice @_, 1,
    );

    my $package = module_to_package($module);

    $package = resolve_class_name( $package, $args{ns} );

    $module = package_to_module($package);

    my $found;

    # find class in @INC
    for my $inc ( grep { !is_ref $_ } @INC ) {
        if ( -f "$inc/$module" ) {
            $found = "$inc/$module";

            last;
        }
    }

    return $found;
}

sub unload ( $package, $delete_inc = 1 ) {
    ( my $module, $package ) = get_module_package($package);

    my $stash = Package::Stash::XS->new($package);

    for my $sym ( $stash->list_all_symbols ) {
        next if substr( $sym, -1, 1 ) eq ':';

        $stash->remove_glob($sym);
    }

    delete $INC{$module} if $delete_inc;

    return;
}

sub resolve_class_name ( $package, $ns = undef ) {
    if ( substr( $package, 0, 1 ) eq '+' ) {
        return $package;
    }
    else {
        return $ns ? "${ns}::$package" : $package;
    }
}

# MODULE <-> PACKAGE CONVERSION
sub module_to_package ($module) {
    ( $module, my $package ) = get_module_package($module);

    return $package;
}

sub package_to_module ($package) {
    ( my $module, $package ) = get_module_package($package);

    return $module;
}

sub get_module_package ($module) {
    my $package;

    # $module is module
    if ( substr( $module, -3 ) eq '.pm' ) {
        $package = $module =~ s[/][::]smgr;

        substr $package, -3, 3, $EMPTY;
    }

    # $module is package
    else {
        $package = $module;

        $module =~ s[::][/]smg;

        $module .= '.pm';
    }

    return $module, $package;
}

# SUB
sub set_sub_prototype {
    return &Sub::Util::set_prototype;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

sub get_sub_prototype {
    return &Sub::Util::prototype;        ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

# allow to specify name as '::<name>', caller namespace will be used as full sub name
sub set_subname {
    return &Sub::Util::set_subname;      ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

sub get_sub_name {
    my ( $package, $name ) = &Sub::Util::subname =~ /^(.+)::(.+)$/sm;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    return $name;
}

sub get_sub_fullname {
    my $full_name = &Sub::Util::subname;                                 ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    if (wantarray) {
        my ( $package, $name ) = $full_name =~ /^(.+)::(.+)$/sm;

        return $name, $package;
    }
    else {
        return $full_name;
    }
}

1;
__END__
=pod

=encoding utf8

=cut
