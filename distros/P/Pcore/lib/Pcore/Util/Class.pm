package Pcore::Util::Class;

use Pcore;
use Sub::Util qw[];    ## no critic qw[Modules::ProhibitEvilModules]

sub load ( $class, @ ) {
    my %args = (
        ns   => undef,
        isa  => undef,    # InstanceOf
        does => undef,    # ConsumerOf
        splice @_, 1,
    );

    my $module;

    if ( substr( $class, -3 ) eq '.pm' ) {
        $module = $class;

        $class =~ s[/][::]smg;

        substr $class, -3, 3, q[];
    }
    else {
        $class = resolve_class_name( $class, $args{ns} );

        $module = ( $class =~ s[::][/]smgr ) . '.pm';
    }

    require $module;

    die qq[Error loading class "$class". Class must be instance of "$args{isa}"] if $args{isa} && !$class->isa( $args{isa} );

    die qq[Error loading class "$class". Class must be consumer of "$args{does}"] if $args{does} && !$class->does( $args{does} );

    return $class;
}

sub find ( $class, @ ) {
    my %args = (
        ns => undef,
        splice @_, 1,
    );

    my $class_filename;

    if ( $class =~ /[.]pm\z/sm ) {
        $class_filename = $class;
    }
    else {
        $class = resolve_class_name( $class, $args{ns} );

        $class_filename = ( $class =~ s[::][/]smgr ) . q[.pm];
    }

    my $found;

    # find class in @INC
    for my $inc ( grep { !ref } @INC ) {
        if ( -f "$inc/$class_filename" ) {
            $found = "$inc/$class_filename";

            last;
        }
    }

    return $found;
}

sub resolve_class_name ( $class, $ns = undef ) {
    if ( substr( $class, 0, 1 ) eq '+' ) {
        return $class;
    }
    else {
        return $ns ? "${ns}::$class" : $class;
    }
}

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
