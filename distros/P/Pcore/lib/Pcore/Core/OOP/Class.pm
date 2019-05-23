package Pcore::Core::OOP::Class;

use Pcore;
use Pcore::Util::Scalar qw[is_ref is_plain_arrayref is_plain_hashref is_coderef];
use Class::XSAccessor qw[];
use Package::Stash::XS qw[];
use Sub::Util qw[];       ## no critic qw[Modules::ProhibitEvilModules]
use Data::Dumper qw[];    ## no critic qw[Modules::ProhibitEvilModules]
use mro qw[];

our %REG;

sub import ( $self, $caller = undef ) {
    $caller //= caller;

    # register caller module in %INC
    my $module = $caller =~ s[::][/]smgr . '.pm';
    if ( !exists $INC{$module} ) { $INC{$module} = "(embedded)" }    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    _defer_sub( $caller, new => sub { return _build_constructor($caller) } );

    *{"$caller\::does"}    = \&_does;
    *{"$caller\::extends"} = \&_extends;
    *{"$caller\::with"}    = \&_with;
    *{"$caller\::has"}     = \&_has;
    *{"$caller\::around"}  = \&_around;

    return;
}

sub load_class ($class) {
    my $name = $class =~ s[::][/]smgr . '.pm';

    require $name;

    return;
}

sub _does ( $self, $role ) {
    $self = ref $self if is_ref $self;

    return exists $REG{$self}{does}{$role};
}

sub _extends (@superclasses) {
    my $caller = caller;

    for my $base (@superclasses) {
        load_class($base);

        push @{"$caller\::ISA"}, $base;

        die qq[Class "$caller" multiple inheritance is disabled. Use roles or redesign your classes] if @{"$caller\::ISA"} > 1;

        # merge attributes
        while ( my ( $attr, $spec ) = each $REG{$base}{attr}->%* ) {
            add_attribute( $caller, $attr, $spec, 1, 1 );
        }
    }

    return;
}

sub _with (@roles) {
    my $caller = caller;

    for my $role (@roles) {

        # role is already applied
        die if $REG{$caller}{does}{$role};

        load_class($role);

        die qq[Class "$caller" is not a role] if !$REG{$role}{is_role};

        # merge does
        $REG{$caller}{does}->@{ $role, keys $REG{$role}{does}->%* } = ();

        # merge attributes
        while ( my ( $attr, $spec ) = each $REG{$role}{attr}->%* ) {
            add_attribute( $caller, $attr, $spec, 0, 1 );
        }
    }

    # merge methods
    export_methods( \@roles, $caller );

    #check requires,  install around
    for my $role (@roles) {
        if ( $REG{$role}{requires} ) {
            my @missed_methods = grep { !$caller->can($_) } $REG{$role}{requires}->@*;

            die qq[Class "$caller" required methods are missed: ] . join q[, ], map {qq["$_"]} @missed_methods if @missed_methods;
        }

        _install_around( $caller, $REG{$role}{around} ) if $REG{$role}{around};
    }

    return;
}

sub export_methods ( $roles, $to ) {
    my $is_role = $REG{$to}{is_role};

    $REG{$to}{method} //= {} if $is_role;

    for my $role ( $roles->@* ) {
        $REG{$role}{method} //= {};

        for my $subname ( Package::Stash::XS->new($role)->list_all_symbols('CODE') ) {
            my $fullname = Sub::Util::subname( *{"$role\::$subname"}{CODE} );

            next unless $fullname eq "$role\::$subname" || $fullname eq "$role\::__ANON__" || substr( $subname, 0, 1 ) eq '(' || exists $REG{$role}{method}->{$subname};

            next if defined *{"$to\::$subname"}{CODE};

            *{"$to\::$subname"} = *{"$role\::$subname"}{CODE};

            # export overload fallback value
            *{"$to\::()"} = *{"$role\::()"} if $subname eq '()';

            $REG{$to}{method}->{$subname} = undef if $is_role;
        }
    }

    return;
}

sub _has ( $attr, @spec ) {
    my $caller = caller;

    add_attribute( $caller, $attr, \@spec, 0, 1 );

    return;
}

sub _around ( $name, $code ) {
    my $caller = caller;

    _install_around( $caller, { $name => [$code] } );

    return;
}

sub _install_around ( $to, $spec ) {
    for my $name ( keys $spec->%* ) {
        for my $code ( $spec->{$name}->@* ) {
            my $wrapped = $to->can($name);

            die qq[Class "$to" method modifier "around" requires method "$name"] if !$wrapped;

            no warnings qw[redefine];
            eval qq[package $to; sub $name { \$code->( \$wrapped, \@_ ) }];    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
        }
    }

    return;
}

sub add_attribute ( $caller, $attr, $spec, $is_base, $install_accessors ) {
    if ( is_plain_arrayref $spec) {
        if ( $spec->@* % 2 ) {
            $spec = { default => shift $spec->@*, $spec->@* };
        }
        else {
            $spec = { $spec->@* };
        }
    }

    # check default value
    die qq[Class "$caller" attribute "$attr" default value can be "Scalar" or "CodeRef"] if exists $spec->{default} && !( !is_ref $spec->{default} || is_coderef $spec->{default} );

    my $override;

    # redefine attribute
    if ( my $current_spec = $REG{$caller}{attr}{$attr} ) {
        $override = 1;

        if ( $spec->{is} and ( $spec->{is} // $EMPTY ) ne ( $current_spec->{is} // $EMPTY ) ) {
            die qq[Class "$caller" attribute "$attr" not allowed to redefine parent attribute "is" property];
        }

        # merge attribute spec
        if ($is_base) {

            # current spec overrides base spec (from base class)
            $spec = { $spec->%*, $current_spec->%* };
        }
        else {

            # new spec overrides current spec (self or from role)
            $spec = { $current_spec->%*, $spec->%* };
        }
    }

    $REG{$caller}{attr}{$attr} = $spec;

    # install accessors, do not create accessor, inherited from the base class
    if ( $install_accessors && $spec->{is} ) {

        # do not allow override method with accessor
        die qq[Class "$caller" attribute "$attr" attempt to override method with accessor] if !$override && defined &{"$caller\::$attr"};

        # "ro" accessor
        if ( $spec->{is} eq 'ro' ) {
            Class::XSAccessor->import(
                getters => [$attr],
                class   => $caller,
                replace => 1,
            );
        }

        # "rw" accessor
        elsif ( $spec->{is} eq 'rw' ) {
            Class::XSAccessor->import(
                accessors => [$attr],
                class     => $caller,
                replace   => 1,
            );
        }

        # "lazy" accessor
        elsif ( $spec->{is} eq 'lazy' ) {
            no warnings qw[redefine];

            # attr has default property
            if ( exists $spec->{default} ) {

                # default is a coderef
                if ( is_coderef $spec->{default} ) {
                    my $sub = $spec->{default};

                    eval <<"PERL";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
package $caller;

sub $attr {
    \$_[0]->{$attr} = &{\$sub}(\$_[0]) if !exists \$_[0]->{$attr};

    return \$_[0]->{$attr};
}
PERL
                }

                # default is a plain scalar
                else {
                    eval <<"PERL";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
package $caller;

sub $attr {
    \$_[0]->{$attr} = qq[$spec->{default}] if !exists \$_[0]->{$attr};

    return \$_[0]->{$attr};
}
PERL
                }
            }

            # use attr builder
            else {
                eval <<"PERL";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
package $caller;

sub $attr {
    \$_[0]->{$attr} = \$_[0]->_build_$attr if !exists \$_[0]->{$attr};

    return \$_[0]->{$attr};
}
PERL
            }
        }
        else {
            die qq[Invalid "is" type for attribute "$attr" in class "$caller"];
        }
    }

    return;
}

sub _defer_sub ( $caller, $name, $code ) {
    my $defer = [];

    eval <<"PERL";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
package $caller;

sub $name {
    if ( !defined \$defer->[1] ) {

        # undefer sub
        \$defer->[1] = \$code->();

        # install, if wasn't changed
        no warnings qw[redefine];

        *{'$caller\::$name'} = \$defer->[1] if *{'$caller\::$name'}{CODE} eq \$defer->[0];
    }

    goto &{\$defer->[1]};
};
PERL

    $defer->[0] = *{"$caller\::$name"}{CODE};

    return;
}

sub _build_constructor ( $self ) {

    # header
    my $new = <<"PERL";
package $self;

sub {
    my \$self = !Pcore::Util::Scalar::is_ref \$_[0] ? CORE::shift : Pcore::Util::Scalar::is_blessed_ref \$_[0] ? CORE::ref CORE::shift : die qq[Invalid invoker for "$self\::new" constructor];

PERL

    # buildargs
    if ( $self->can('BUILDARGS') ) {
        $new .= <<'PERL';
    my $args = $self->BUILDARGS(@_);

    if (!defined $args) {
        $args = {};
    }
    elsif (!Pcore::Util::Scalar::is_plain_hashref $args) {
        die qq["$self\::BUILDARGS" method didn't returned HashRef];
    }

PERL
    }
    else {
        $new .= <<'PERL';
    my $args = Pcore::Util::Scalar::is_plain_hashref $_[0] ? {$_[0]->%*} : @_ ? {@_} : {};
PERL
    }

    my @build = grep { defined *{"$_\::BUILD"} && *{"$_\::BUILD"}{CODE} } reverse mro::get_linear_isa($self)->@*;

    if (@build) {
        $new .= <<'PERL';
    my $args_orig = { $args->%* };
PERL
    }

    # attributes
    my $init_arg;
    my $required;
    my $default;
    my @attr_default_coderef;

    while ( my ( $attr, $spec ) = each $REG{$self}{attr}->%* ) {

        # attr init_arg
        if ( exists $spec->{init_arg} ) {
            if ( !defined $spec->{init_arg} ) {
                $init_arg .= <<"PERL";
    delete \$args->{$attr};

PERL
            }
            else {
                $init_arg .= <<"PERL";
    \$args->{$attr} = delete \$args->{$spec->{init_arg}};

PERL
            }
        }

        # attr required
        if ( $spec->{required} && !exists $spec->{default} ) {
            $required .= <<"PERL";
    die qq[Class "\$self" attribute "$attr" is required] if !exists \$args->{$attr};

PERL
        }

        # attr default
        if ( exists $spec->{default} && ( !$spec->{is} || $spec->{is} ne 'lazy' ) ) {
            if ( !is_ref $spec->{default} ) {
                local $Data::Dumper::Useqq = 1;
                local $Data::Dumper::Terse = 1;

                $default .= <<"PERL";
    \$args->{$attr} = @{[ Data::Dumper::Dumper $spec->{default} ]} if !exists \$args->{$attr};

PERL
            }
            else {
                push @attr_default_coderef, $spec->{default};

                $default .= <<"PERL";
    \$args->{$attr} = &{\$attr_default_coderef[$#attr_default_coderef]}(\$self) if !exists \$args->{$attr};

PERL
            }
        }
    }

    $new .= $init_arg if $init_arg;

    $new .= $required if $required;

    # bless
    $new .= <<'PERL';
    $self = bless $args, $self;

PERL

    $new .= $default if $default;

    # build
    for (@build) {
        $new .= <<"PERL";
    \$self->$_\::BUILD(\$args_orig);

PERL
    }

    # footer
    $new .= <<'PERL';
    return $self;
}
PERL

    no warnings qw[redefine];
    return eval $new;    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 18                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 153, 233, 246, 260,  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |      | 282, 426             |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 160                  | Subroutines::ProhibitExcessComplexity - Subroutine "add_attribute" with high complexity score (24)             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 160                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::OOP::Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
