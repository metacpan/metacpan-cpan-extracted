package Sub::Multi::Tiny;

use 5.006;
use strict;
use warnings;

require Attribute::Handlers;    # Listed here so automated tools see it

use Import::Into;
use Scalar::Util qw(looks_like_number);
use Sub::Multi::Tiny::SigParse;
use Sub::Multi::Tiny::Util ':all';
use subs ();
use vars ();

our $VERSION = '0.000013';

use constant { true => !!1, false => !!0 };

# Documentation {{{1

=encoding utf-8

=head1 NAME

Sub::Multi::Tiny - Multisubs/multimethods (multiple dispatch) yet another way!

=head1 SYNOPSIS

    {
        package main::my_multi;     # We're making main::my_multi()
        use Sub::Multi::Tiny qw($foo $bar);     # All possible params

        sub first :M($foo, $bar) {  # sub's name will be ignored,
            return $foo ** $bar;    # but can't match the one we're making
        }

        sub second :M($foo) {
            return $foo + 42;
        }

    }

    # Back in package main, my_multi() is created just before the run phase.
    say my_multi(2, 5);     # -> 32
    say my_multi(1295);     # -> 1337

The default dispatcher dispatches solely by arity, and only one
candidate can have each arity.  For more flexible dispatching, see
L<Sub::Multi::Tiny::Dispatcher::TypeParams>.

=head1 DESCRIPTION

Sub::Multi::Tiny is a library for making multisubs, aka multimethods,
aka multiple-dispatch subroutines.  Each multisub is defined in a
single package.  Within that package, the individual implementations ("impls")
are C<sub>s tagged with the C<:M> attribute.  The names of the impls are
preserved but not used specifically by Sub::Multi::Tiny.

Within a multisub package, the name of the sub being defined is available
for recursion.  For example (using C<where>, supported by
L<Sub::Multi::Tiny::Dispatcher::TypeParams>):

    {
        package main::fib;
        use Sub::Multi::Tiny qw(D:TypeParams $n);
        sub base  :M($n where { $_ <= 1 })  { 1 }
        sub other :M($n)                    { $n * fib($n-1) }
    }

This code creates function C<fib()> in package C<main>.  Within package
C<main::fib>, function C<fib()> is an alias for C<main::fib()>.  It's easier
to use than to explain!

=head1 FUNCTIONS

=cut

# }}}1

# Information about the multisubs so we can create the dispatchers at
# INIT time.
my %_multisubs;

# Sanity check: any :M will die after the INIT block below runs.
my $_dispatchers_created;

# Accessor
sub _dispatchers_created { !!$_dispatchers_created; }

# INIT: Fill in the dispatchers for any multisubs we've created.
# Note: attributes are applied at CHECK time, before this.
# We use INIT so that compilation failures will prevent this code from running.

INIT {
    _hlog { __PACKAGE__, "in INIT block" };
    $_dispatchers_created = 1;
    while(my ($multisub_fullname, $hr) = each(%_multisubs)) {
        my $dispatcher = _make_dispatcher($hr)
            or die "Could not create dispatcher for $multisub_fullname\()";

        eval { no strict 'refs'; *{$multisub_fullname} = $dispatcher };
        die "Could not assign dispatcher for $multisub_fullname\:\n$@" if $@;
        do {
            no strict 'refs';
            no warnings 'redefine';
            my $target_name = "$hr->{defined_in}\::$hr->{subname}";
            *{$target_name} = $dispatcher;
        };
    } #foreach multisub
} #CHECK

=head2 import

Sets up the package that uses it to define a multisub.  The parameters
are all the parameter variables that the multisubs will use.  C<import>
creates these as package variables so that they can be used unqualified
in the multisub implementations.

A parameter C<D:Dispatcher> can also be given to specify the dispatcher to
use --- see L</CUSTOM DISPATCH>.

Also sets L<Sub::Multi::Tiny::Util/$VERBOSE> if the environment variable
C<SUB_MULTI_TINY_VERBOSE> has a truthy value.  If the C<SUB_MULTI_TINY_VERBOSE>
value is numeric, C<$VERBOSE> is set to that value; otherwise, C<$VERBOSE> is
set to 1.

=cut

sub import {
    my $multi_package = caller;     # The package that defines the multisub
    my $my_package = shift;         # The package we are

    for($ENV{SUB_MULTI_TINY_VERBOSE}) {
        last unless $_;
        $VERBOSE = looks_like_number($_) ? 0+ $_ : 1;
    }

    if(@_ && $_[0] eq ':nop') {
        _hlog { __PACKAGE__ . ':nop => Taking no action' } 0;    # Always
        return;
    }

    _hlog { "Target $multi_package package $my_package" };
    my ($target_package, $subname) = ($multi_package =~ m{^(.+?)::([^:]+)$});
        # $target_package is the package that will be able to call the multisub
    _croak "Can't parse package name ${multi_package} into <target>::<name>"
        unless $target_package && $subname;

    _croak "Can't redefine multi sub $multi_package\()"
        if exists $_multisubs{$multi_package};

    # Create the vars - they will be accessed as package variables.
    # TODO: parameters of the form D:<foo> import dispatcher <foo>.
    my @possible_params;
    my $dispatcher = 'Default';
    foreach (@_) {
        if(/^D:(.*)$/) {
            die '"D:" must be followed by a dispatcher class' unless $1;
            $dispatcher=$1;
        } elsif(/^.:/) {
            die '".:..." forms reserved - did you mean "D:DispatcherClass"?';
        } else {
            push @possible_params, $_;
        }
    }

    # Load the parameter variables as package variables
    _croak "Please list the sub parameters" unless @possible_params;
    vars->import::into($multi_package, @possible_params);

    # Load the dispatcher
    $dispatcher = __PACKAGE__ . "::Dispatcher::$dispatcher"
        unless index($dispatcher, '::') != -1;

    eval "require $dispatcher";
    die "Could not load dispatcher $dispatcher, requested by $multi_package: $@"
        if $@;

    _hlog { $multi_package, 'using dispatcher', $dispatcher };
    ${dispatcher}->import::into($multi_package);

    # Make a stub that we will redefine later
    _hlog { "Making $multi_package\()" } ;
    subs->import::into($target_package, $subname);
    # TODO add stub for callsame/nextwith/...

    # Save the patch
    $_multisubs{$multi_package} = {
        used_by => $target_package,
        defined_in => $multi_package,
        subname => $subname,
        possible_params => +{ map { ($_ => 1) } @possible_params },
        impls => [],    # Implementations - subs tagged :M
    };

    # Set up the :M attribute in $multi_package if it doesn't
    # exist yet.
    if(eval { no strict 'refs'; defined &{$multi_package . '::M'} }) {
        die "Cannot redefine M in $multi_package";
    } else {
        _hlog { "Making $multi_package attr M" } 2;
        eval(_make_M($multi_package));
        die $@ if $@;
    }

    # Set up $subname() in $multi_package, which will be aliased to the
    # dispatcher.
    if(eval { no strict 'refs'; defined &{"$multi_package\::$subname"} }) {
        die "Cannot redefine $subname in $multi_package";
    } else {
        _hlog { "Making $multi_package\::$subname stub" } 2;
        do { no strict 'refs'; *{"$multi_package\::$subname"} = sub {} };
    }
} #import()

# Parse the argument list to the attribute handler
sub _parse_arglist {
    my ($spec, $funcname) = @_;
    _croak "Need a parameter spec for $funcname" unless $spec;
    _hlog { "Parsing args for $funcname: $spec" } 2;

    return Sub::Multi::Tiny::SigParse::Parse($spec);
} #_parse_arglist

# Create the source for the M attribute handler for a given package
sub _make_M {
    my $multi_package = shift;
    my $P = __PACKAGE__;
    my $code = _line_mark_string
        "package $multi_package;\n";

    # TODO See if making M an :ATTR(..., BEGIN) permits us to remove the
    # requirement to list all the parameters in the `use S::M::T` line

    $code .= _line_mark_string <<'EOT';
use Attribute::Handlers;
use Sub::Multi::Tiny::Util qw(_hlog);
##use Data::Dumper;

sub M :ATTR(CODE,RAWDATA) {
    _hlog { require Data::Dumper;
            'In ', __PACKAGE__, "::M: \n",
            Data::Dumper->Dump([\@_], ['attr_args']) } 2;

    my ($package, $symbol, $referent, $attr, $data, $phase,
        $filename, $linenum) = @_;
    my $funcname = "$package\::" . *{$symbol}{NAME};

    _hlog {     # Code from Attribute::Handlers, license perl_5
        ref($referent),
        $funcname,
        "($referent)", "was just declared",
        "and ascribed the ${attr} attribute",
        "with data ($data)",
        "in phase $phase",
        "in file $filename at line $linenum"
    } 2;
EOT

    # Trap out-of-sequence calls.  Currently you can't create a new multisub
    # via eval at runtime.  TODO use UNITCHECK instead to permit doing so?
    $code .= _line_mark_string <<EOT;
    die 'Dispatchers already created - please file a bug report'
        if $P\::_dispatchers_created();

    my \$multi_def = \$_multisubs{'$multi_package'};
EOT

    # Parse and validate the args
    $code .= _line_mark_string <<EOT;
    my \$hrSig = $P\::_parse_arglist(\$data, \$funcname);
    $P\::_check_and_inflate_sig(\$hrSig, \$multi_def,
        \$funcname, \$package, \$filename, \$linenum);
EOT

    $code .= _line_mark_string <<'EOT';
EOT

    # Save the implementation's info for use when making the dispatcher.
    $code .= _line_mark_string <<'EOT';
    my $info = {
        code => $referent,
        args => $hrSig->{parms},    # TODO remove eventually
        sig => $hrSig,

        # For error messages
        filename => $filename,
        linenum => $linenum,
        candidate_name => $funcname
    };
    push @{$multi_def->{impls}}, $info;

} #M
EOT

    _hlog { "M code:\n$code\n" } 2;
    return $code;
} #_make_M

# Validate a signature and convert text to usable objects
sub _check_and_inflate_sig {
    my ($signature, $multi_def, $funcname, $package, $filename, $linenum) = @_;
    my ($saw_positional, $saw_named);

    my $args = $signature->{parms};
    my $temp;
    foreach (@$args) {

        # Is the argument valid in this package?
        my $name = $_->{name};
        unless($multi_def->{possible_params}->{$name}) {
            die "Argument $name is not listed on the 'use Sub::Multi::Tiny' line (used by $funcname at $filename\:$linenum";
        }

        # Is the argument out of order?
        die "Positional arguments must precede named arguments"
            if $saw_named && !$_->{named};

        # Inflate type constraint, if any
        if($_->{type}) {
            _hlog { In => $package, "evaluating type '$_->{type}'" };
            $temp = eval _line_mark_string <<EOT;
do {
    package $package;
    $_->{type}  # Anything meaningful in the calling package is OK
}
EOT
            die "In $package: Could not understand type '$_->{type}': $@" if $@;
            $_->{type} = $temp;
        }

        # Inflate where clause, if any, into a closure
        if($_->{where}) {
            _hlog { In => $package, "evaluating 'where' clause '$_->{where}'" };
            $temp = eval _line_mark_string <<EOT;
do {
    package $package;
    sub $_->{where}     # Anything meaningful in the calling package is OK
}
EOT
            die "In $package: Could not understand 'where' clause '$_->{where}': $@" if $@;
            $_->{where} = $temp;
        }

        # Remember data for later
        $saw_named ||= $_->{named};
        $saw_positional ||= !$_->{named};

    }
} # _check_and_inflate_sig

# Create a dispatcher
sub _make_dispatcher {
    my $hr = shift;
    die "No implementations given for $hr->{defined_in}"
        unless @{$hr->{impls}};

    my $custom_dispatcher = do {
        no strict 'refs';
        *{ $hr->{defined_in} . '::MakeDispatcher' }{CODE}
    };

    return $custom_dispatcher->($hr) if defined $custom_dispatcher;

    # Default dispatcher
    require Sub::Multi::Tiny::Dispatcher::Default;
    return Sub::Multi::Tiny::Dispatcher::Default::MakeDispatcher($hr);
} #_make_dispatcher

1;
# Rest of the documentation {{{1
__END__

=head1 CUSTOM DISPATCH

This module includes a default dispatcher (implemented in
L<Sub::Multi::Tiny::Dispatcher::Default>.  To use a different dispatcher,
define or import a sub C<MakeDispatcher()> into the package before
compilation ends.  That sub will be called to create the dispatcher.
For example:

    {
        package main::foo;
        use Sub::Multi::Tiny;
        sub MakeDispatcher { return sub { ... } }
    }

or

    {
        package main::foo;
        use Sub::Multi::Tiny;
        use APackageThatImportsMakeDispatcherIntoMainFoo;
    }

As a shortcut, you can specify a dispatcher on the C<use> line.  For example:

    use Sub::Multi::Tiny qw(D:Foo $var);

will use dispatcher C<Sub::Multi::Tiny::Dispatcher::Foo>.  Any name with a
double-colon will be used as a full package name.  E.g., C<D:Bar::Quux> will
use dispatcher C<Bar::Quux>.  If C<Foo> does not include a double-colon,
C<Sub::Multi::Tiny::Dispatcher::> will be prepended.

=head1 DEBUGGING

For extra debug output, set L<Sub::Multi::Tiny::Util/$VERBOSE> to a positive
integer.  This has to be set at compile time to have any effect.  For example,
before creating any multisubs, do:

    use Sub::Multi::Tiny::Util '*VERBOSE';
    BEGIN { $VERBOSE = 2; }

=head1 RATIONALE

=over

=item *

To be able to use multisubs in pre-5.14 Perls with only built-in
language facilities.  This will help me make my own modules backward
compatible with those Perls.

=item *

To learn how it's done! :)

=back

=head1 SEE ALSO

I looked at these but decided not to use them for the following reasons:

=over

=item L<Class::Multimethods>

I wanted a syntax that used normal C<sub> definitions as much as possible.
Also, I was a bit concerned by LPALMER's experience that it "does what you
don't want sometimes without saying a word"
(L<Class::Multimethods::Pure/Semantics>).

Other than that, I think this looks pretty decent (but haven't tried it).

=item L<Class::Multimethods::Pure>

Same desire for C<sub> syntax.  Additionally, the last update was in 2007,
and the maintainer hasn't uploaded anything since.  Other than that, I think
this also looks like a decent option (but haven't tried it).

=item L<Dios>

This is a full object system, which I do not need in my use case.

=item L<Logic>

This one is fairly clean, but uses a source filter.  I have not had much
experience with source filters, so am reluctant.

=item L<Kavorka::Manual::MultiSubs> (and L<Moops>)

Requires Perl 5.14+.

=item L<MooseX::MultiMethods>

I am not ready to move to full L<Moose>!

=item L<MooseX::Params>

As above.

=item L<Sub::Multi>

The original inspiration for this module, whence this module's name.
C<Sub::Multi> uses coderefs, and I wanted a syntax that used normal
C<sub> definitions as much as possible.

=item L<Sub::SmartMatch>

This one looks very interesting, but I haven't used smartmatch enough
to be fully comfortable with it.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Multi::Tiny

You can also look for information at:

=over

=item * GitHub: The project's main repository and issue tracker

L<https://github.com/cxw42/Sub-Multi-Tiny>

=item * MetaCPAN

L<Sub::Multi::Tiny>

=item * This distribution

See the tests in the C<t/> directory distributed with this software
for usage examples.

=back

=head1 BUGS

=over

=item * It's not as tiny as I thought it would be!

=item * This isn't Damian code ;) .

=back

=head1 AUTHOR

Chris White E<lt>cxw@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) 2019 Chris White E<lt>cxw@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# }}}1
# vi: set fdm=marker: #
