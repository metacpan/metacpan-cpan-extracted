package Role::Declare;
use strict;
use warnings;
our $VERSION = 0.05;

use Attribute::Handlers;
use Carp qw[ croak ];
use Data::Alias;
use Function::Parameters;
use Import::Into;
use Role::Tiny;
use Scalar::Util qw[ refaddr ];
use Types::Standard ':all';

use namespace::clean;

use constant {    # Attribute::Handlers argument positions
    PACKAGE   => 0,
    SYMBOL    => 1,
    REFERENT  => 2,
    ATTRIBUTE => 3,
    DATA      => 4,
};

my %return_hooks;

sub _install_hook {
    my ( $type, $target, $hook ) = @_;
    alias my $hook_slot = $return_hooks{ refaddr($target) }{$type};
    croak "A $type hook for $target already exists" if defined $hook_slot;
    $hook_slot = $hook;
    return;
}

sub _install_scalar_hook { return _install_hook('scalar', @_) }
sub _install_list_hook   { return _install_hook('list',   @_) }


sub Return : ATTR(CODE,BEGIN) {
    my ($referent, $data) = @_[ REFERENT, DATA ];

    croak 'Only a single constraint is supported' if @$data != 1;
    my $constraint = $data->[0];
    
    _install_scalar_hook($referent, sub {
        my $orig = shift;
        return $constraint->assert_return(scalar &$orig);
    });

    return;
}

sub ReturnMaybe : ATTR(CODE,BEGIN) {
    $_[DATA][0] = Maybe[ $_[DATA][0] ];
    goto &Return;
}

sub _make_list_check {
    my ($constraint, %args) = @_;
    my $allow_empty = $args{allow_empty};
    croak 'List constraint not defined' if not $constraint;

    return sub {
        my $orig   = shift;
        my $retval = [&$orig];
        return if not @$retval and $allow_empty;
        return @{ $constraint->assert_return($retval) };
    };
}

sub ReturnList : ATTR(CODE,BEGIN) {
    my ($referent, $data) = @_[ REFERENT, DATA ];
    my $type = ArrayRef($data);
    _install_list_hook($referent, _make_list_check($type, allow_empty => 0));
    return;
}

sub ReturnMaybeList : ATTR(CODE,BEGIN) {
    my ($referent, $data) = @_[ REFERENT, DATA ];
    my $type = ArrayRef($data);
    _install_list_hook($referent, _make_list_check($type, allow_empty => 1));
    return;
}

sub ReturnTuple : ATTR(CODE,BEGIN) {
    my ($referent, $data) = @_[ REFERENT, DATA ];

    my $type = Tuple($data);
    _install_list_hook($referent, _make_list_check($type, allow_empty => 0));
    return;
}

sub ReturnCycleTuple : ATTR(CODE,BEGIN) {
    my ($referent, $data) = @_[ REFERENT, DATA ];

    my $type = CycleTuple($data);
    _install_list_hook($referent, _make_list_check($type, allow_empty => 0));
    return;
}

sub ReturnHash : ATTR(CODE,BEGIN) {
    my $data = $_[DATA];
    croak 'Only a single constraint is supported' if @$data != 1;
    unshift @$data, Str;
    goto &ReturnCycleTuple;
}

sub _make_self_check {
    my %args = @_;
    my $allow_undef = $args{undef_ok};
    return sub {
        my $orig           = shift;
        my $orig_self_addr = refaddr($_[0]);
        my $self           = &$orig;
        return $self if not defined $self and $allow_undef;
        return $self if ref $self and refaddr($self) eq $orig_self_addr;
        croak "$self was not the original invocant";
    };
}

sub ReturnSelf : ATTR(CODE,BEGIN) {
    my $referent = $_[REFERENT];
    _install_scalar_hook($referent, _make_self_check(undef_ok => 0));
    return;
}

sub ReturnMaybeSelf : ATTR(CODE,BEGIN) {
    my $referent = $_[REFERENT];
    _install_scalar_hook($referent, _make_self_check(undef_ok => 1));
    return;
}

sub ReturnObject : ATTR(CODE,BEGIN) {
    $_[DATA][0] = Object;
    goto &Return;
}

sub ReturnMaybeObject : ATTR(CODE,BEGIN) {
    $_[DATA][0] = Maybe[Object];
    goto &Return;
}

sub ReturnInstanceOf : ATTR(CODE,BEGIN) {
    $_[DATA][0] = InstanceOf[$_[DATA][0]];
    goto &Return;
}

sub ReturnMaybeInstanceOf : ATTR(CODE,BEGIN) {
    $_[DATA][0] = Maybe[InstanceOf[$_[DATA][0]]];
    goto &Return;
}

sub _build_validator {
    my ($hooks) = @_;
    my $val_scalar = $hooks->{scalar};
    my $val_list   = $hooks->{list};
    return sub {
        goto &$val_list   if wantarray         and $val_list;
        goto &$val_scalar if defined wantarray and $val_scalar;

        # void context or no validators
        my $orig = shift;
        goto &$orig;
    };
}

sub import {
    my ($class, $mode) = @_;
    my $package = scalar caller;
    return if $class ne __PACKAGE__;    # don't let this import spread around

    my $lax;
    if (defined $mode) {
        if ($mode eq '-lax') {
            $lax = 1;
        }
        else {
            croak "Unsupported mode: $mode";
        }
    }

    # make the caller a role first, so we can install modifiers
    Role::Tiny->import::into($package);
    my $before = $package->can('before');
    my $around = $package->can('around');

    my $installer = sub {
        my ($name, $coderef) = @_;
        $before->($name, $coderef);

        my $hooks = delete $return_hooks{ refaddr($coderef) };
        if (defined $hooks) {
            my $return_validator = _build_validator($hooks);
            $around->($name, $return_validator);
        }

        return;
    };

    my %common_args = (
        name        => 'required',
        install_sub => $installer,
    );
    $common_args{check_argument_count} = 0 if $lax;
    Function::Parameters->import(
        {
            class_method => {
                %common_args,
                shift => [ [ '$class', ClassName ] ],
            },
        },
        {
            instance_method => {
                %common_args,
                shift => [ [ '$self', Object ] ],
            },
        },
        {
            method => {
                %common_args,
                shift => [ '$self' ],
            },
        },
    );

    # allow importing package to use our attributes
    parent->import::into($package, $class);

    return;
}

1;
