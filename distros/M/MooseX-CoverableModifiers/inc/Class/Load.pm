#line 1
package Class::Load;
{
  $Class::Load::VERSION = '0.13';
}
use strict;
use warnings;
use base 'Exporter';
use Data::OptList 'mkopt';
use Module::Runtime 0.011 qw(
    check_module_name
    module_notional_filename
    require_module
    use_module
);
use Package::Stash;
use Try::Tiny;

our $IMPLEMENTATION;

BEGIN {
    $IMPLEMENTATION = $ENV{CLASS_LOAD_IMPLEMENTATION}
        if exists $ENV{CLASS_LOAD_IMPLEMENTATION};

    my $err;
    if ($IMPLEMENTATION) {
        try {
            require_module("Class::Load::$IMPLEMENTATION");
        }
        catch {
            require Carp;
            Carp::croak("Could not load Class::Load::$IMPLEMENTATION: $_");
        };
    }
    else {
        for my $impl ('XS', 'PP') {
            try {
                require_module("Class::Load::$impl");
                $IMPLEMENTATION = $impl;
            }
            catch {
                $err .= $_;
            };

            last if $IMPLEMENTATION;
        }
    }

    if (!$IMPLEMENTATION) {
        require Carp;
        Carp::croak("Could not find a suitable Class::Load implementation: $err");
    }

    my $impl = "Class::Load::$IMPLEMENTATION";
    my $stash = Package::Stash->new(__PACKAGE__);
    $stash->add_symbol('&is_class_loaded' => $impl->can('is_class_loaded'));

    sub _implementation {
        return $IMPLEMENTATION;
    }
}

our @EXPORT_OK = qw/load_class load_optional_class try_load_class is_class_loaded load_first_existing_class/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

our $ERROR;

sub load_class {
    my $class   = shift;
    my $options = shift;

    my ($res, $e) = try_load_class($class, $options);
    return 1 if $res;

    _croak($e);
}

sub load_first_existing_class {
    my $classes = Data::OptList::mkopt(\@_)
        or return;

    foreach my $class (@{$classes}) {
        check_module_name($class->[0]);
    }

    for my $class (@{$classes}) {
        my ($name, $options) = @{$class};

        # We need to be careful not to pass an undef $options to this sub,
        # since the XS version will blow up if that happens.
        return $name if is_class_loaded($name, ($options ? $options : ()));

        my ($res, $e) = try_load_class($name, $options);

        return $name if $res;

        my $file = module_notional_filename($name);

        next if $e =~ /^Can't locate \Q$file\E in \@INC/;
        next
            if $options
                && defined $options->{-version}
                && $e =~ _version_fail_re($name, $options->{-version});

        _croak("Couldn't load class ($name) because: $e");
    }

    my @list = map {
        $_->[0]
            . ( $_->[1] && defined $_->[1]{-version}
            ? " (version >= $_->[1]{-version})"
            : q{} )
    } @{$classes};

    my $err
        .= q{Can't locate }
        . _or_list(@list)
        . " in \@INC (\@INC contains: @INC).";
    _croak($err);
}

sub _version_fail_re {
    my $name = shift;
    my $vers = shift;

    return qr/\Q$name\E version \Q$vers\E required--this is only version/;
}

sub _or_list {
    return $_[0] if @_ == 1;

    return join ' or ', @_ if @_ ==2;

    my $last = pop;

    my $list = join ', ', @_;
    $list .= ', or ' . $last;

    return $list;
}

sub load_optional_class {
    my $class   = shift;
    my $options = shift;

    check_module_name($class);

    my ($res, $e) = try_load_class($class, $options);
    return 1 if $res;

    return 0
        if $options
            && defined $options->{-version}
            && $e =~ _version_fail_re($class, $options->{-version});

    # My testing says that if its in INC, the file definitely exists
    # on disk. In all versions of Perl. The value isn't reliable,
    # but it existing is.
    my $file = module_notional_filename($class);
    return 0 unless exists $INC{$file};

    _croak($ERROR);
}

sub try_load_class {
    my $class   = shift;
    my $options = shift;

    check_module_name($class);

    local $@;
    undef $ERROR;

    if (is_class_loaded($class)) {
        # We need to check this here rather than in is_class_loaded() because
        # we want to return the error message for a failed version check, but
        # is_class_loaded just returns true/false.
        return 1 unless $options && defined $options->{-version};
        return try {
            $class->VERSION($options->{-version});
            1;
        }
        catch {
            _error($_);
        };
    }

    my $file = module_notional_filename($class);
    # This says "our diagnostics of the package
    # say perl's INC status about the file being loaded are
    # wrong", so we delete it from %INC, so when we call require(),
    # perl will *actually* try reloading the file.
    #
    # If the file is already in %INC, it won't retry,
    # And on 5.8, it won't fail either!
    #
    # The extra benefit of this trick, is it helps even on
    # 5.10, as instead of dying with "Compilation failed",
    # it will die with the actual error, and thats a win-win.
    delete $INC{$file};
    return try {
        local $SIG{__DIE__} = 'DEFAULT';
        if ($options && defined $options->{-version}) {
            use_module($class, $options->{-version});
        }
        else {
            require_module($class);
        }
        1;
    }
    catch {
        _error($_);
    };
}

sub _error {
    $ERROR = shift;
    return 0 unless wantarray;
    return 0, $ERROR;
}

sub _croak {
    require Carp;
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    Carp::croak(shift);
}

1;

# ABSTRACT: a working (require "Class::Name") and more



#line 381


__END__


