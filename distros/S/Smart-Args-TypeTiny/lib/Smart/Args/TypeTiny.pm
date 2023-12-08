package Smart::Args::TypeTiny;
use strict;
use warnings;
our $VERSION = "0.14";
use Carp ();
use PadWalker qw/var_name/;

use Exporter 'import';
our @EXPORT = qw/args args_pos/;

$Carp::CarpInternal{+__PACKAGE__}++;

use Smart::Args::TypeTiny::Check qw/check_rule/;

my %is_invocant = map { ($_ => 1) } qw($self $class);

sub args {
    {
        package DB;
        # call of caller in DB package sets @DB::args,
        # which requires list context, but we don't need return values
        () = CORE::caller(1);
    }

    if (@_) {
        my $name = var_name(1, \$_[0]) || '';
        if ($is_invocant{$name}) { # seems instance/class method call
            $name =~ s/^\$//;
            $_[0] = shift @DB::args;
            if (defined $_[1]) { # has rule?
                $_[0] = check_rule($_[1], $_[0], 1, $name);
                shift;
            }
            shift;
        }
    }

    my $args = (@DB::args == 1 && ref $DB::args[0] eq 'HASH')
            ? +{ %{$DB::args[0]} } # must be hash
            : +{ @DB::args };      # must be key-value list
    my $kv = {};

    # args my $var => RULE
    #         ~~~~    ~~~~
    #         undef   defined

    for (my $i = 0; $i < @_; $i++) {
        (my $name = var_name(1, \$_[$i]))
            or Carp::croak('Usage: args my $var => RULE, ...');
        $name =~ s/^\$//;

        # with rule (my $foo => RULE, ...)
        if (defined $_[$i+1]) {
            $_[$i] = $kv->{$name} = check_rule($_[$i+1], $args->{$name}, exists $args->{$name}, $name);
            delete $args->{$name};
            $i++;
        }
        # without rule (my $foo, my $bar, ...)
        else {
            unless (exists $args->{$name}) {
                Carp::confess("Required parameter '$name' not passed");
            }
            $_[$i] = $kv->{$name} = delete $args->{$name};
        }
    }

    for my $name (sort keys %$args) {
        Carp::confess("Unexpected parameter '$name' passed");
    }

    return $kv;
}

sub args_pos {
    {
        package DB;
        # call of caller in DB package sets @DB::args,
        # which requires list context, but we don't need return values
        () = CORE::caller(1);
    }

    if (@_) {
        my $name = var_name(1, \$_[0]) || '';
        if ($is_invocant{$name}) { # seems instance/class method call
            $name =~ s/^\$//;
            $_[0] = shift @DB::args;
            if (defined $_[1]) { # has rule?
                $_[0] = check_rule($_[1], $_[0], 1, $name);
                shift;
            }
            shift;
        }
    }

    my $args = [@DB::args];
    my $kv = {};

    # args my $var => RULE
    #         ~~~~    ~~~~
    #         undef   defined

    for (my $i = 0; $i < @_; $i++) {
        (my $name = var_name(1, \$_[$i]))
            or Carp::croak('Usage: args_pos my $var => RULE, ...');
        $name =~ s/^\$//;

        # with rule (my $foo => RULE, ...)
        if (defined $_[$i+1]) {
            $_[$i] = $kv->{$name} = check_rule($_[$i+1], $args->[0], @$args > 0, $name);
            shift @$args;
            $i++;
        }
        # without rule (my $foo, my $bar, ...)
        else {
            unless (@$args > 0) {
                Carp::confess("Required parameter '$name' not passed");
            }
            $_[$i] = $kv->{$name} = shift @$args;
        }
    }

    if (@$args) {
        Carp::confess('Too many parameters passed');
    }

    return $kv;
}

1;
__END__

=encoding utf-8

=head1 NAME

Smart::Args::TypeTiny - We are smart, smart for you

=head1 SYNOPSIS

    use Smart::Args::TypeTiny;

    sub func2 {
        args my $p => 'Int',
             my $q => {isa => 'Int', optional => 1},
             ;
    }
    func2(p => 3, q => 4); # p => 3, q => 4
    func2(p => 3);         # p => 3, q => undef

    sub func3 {
        args my $p => {isa => 'Int', default => 3};
    }
    func3(p => 4); # p => 4
    func3();       # p => 3

    package F;
    use Moo;
    use Smart::Args::TypeTiny;
    use Types::Standard -all;

    sub method {
        args my $self,
             my $p => Int,
             ;
    }
    sub class_method {
        args my $class => ClassName,
             my $p     => Int,
             ;
    }

    sub simple_method {
        args_pos my $self, my $p;
    }

    my $f = F->new();
    $f->method(p => 3);

    F->class_method(p => 3);

    F->simple_method(3);

=head1 DESCRIPTION

Smart::Args::TypeTiny provides L<Smart::Args>-like argument validator using L<Type::Tiny>.

=head2 IMCOMPATIBLE CHANGES WITH Smart::Args

=over 4

=item Unexpected parameters will be a fatal error

    sub foo {
        args my $x => 'Str';
    }

    sub bar {
        args_pos my $x => 'Str';
    }

    foo(x => 'a', y => 'b'); # fatal: Unexpected parameter 'y' passed
    bar('a', 'b');           # fatal: Too many parameters passed

=item Optional allows to pass undef to parameter

    sub foo {
        args my $p => {isa => 'Int', optional => 1};
    }

    foo();           # $p = undef
    foo(p => 1);     # $p = 1
    foo(p => undef); # $p = undef

=item Default parameter can take coderef as lazy value

    sub foo {
        args my $p => {isa => 'Foo', default => create_foo},         # calls every time even if $p is passed
             my $q => {isa => 'Foo', default => sub { create_foo }}, # calls only when $p is not passed
             ;
    }

=back

=head1 FUNCTIONS

=over 4

=item my $args = args my $var[, $rule], ...;

    sub foo {
        args my $int   => 'Int',
             my $foo   => 'Foo',
             my $bar   => {isa => 'Bar',  default  => sub { Bar->new }},
             my $baz   => {isa => 'Baz',  optional => 1},
             my $bool  => {isa => 'Bool', default  => 0},
             ;

        ...
    }

    foo(int => 1, foo => Foo->new, bool => 1);

Check parameters and fills them into lexical variables. All the parameters are mandatory by default.
The hashref of all parameters is returned.

C<$rule> can be any one of type name, L<Type::Tiny>'s type constraint object, or hashref have these parameters:

=over 4

=item isa C<Str|Object>

Type name or L<Type::Tiny>'s type constraint.

=over 4

=item Types::Standard

    args my $int => {isa => 'Int'};

=item Mouse::Util::TypeConstraints

Enable if Mouse.pm is loaded.

    use Mouse::Util::TypeConstraints;

    subtype 'PositiveInt',
        as 'Int',
        where { $_ > 0 },
        message { 'Must be greater than zero' };

    args my $positive_int => {isa => 'PositiveInt'};

=item class name

    {
        package Foo;
        ...
    }

    args my $foo => {isa => 'Foo'};

=back

=item does C<Str|Object>

Role name or L<Type::Tiny>'s type constraint object.

=item optional C<Bool>

The parameter doesn't need to be passed when L<optional> is true.

=item default C<Any|CodeRef>

Default value for the parameter.

=back

=item my $args = args_pos my $var[, $rule], ...;

    sub bar {
        args_pos my $x => 'Str',
                 my $p => 'Int',
                 ;

        ...
    }

    bar('abc', 123);

Same as C<args> except take arguments instead of parameters.

=back

=head1 TIPS

=head2 SKIP TYPE CHECK

For optimization calling subroutine in runtime type check, you can overwrite C<check_rule> like following code:

    {
        no warnings 'redefine';
        *Smart::Args::TypeTiny::check_rule = \&Smart::Args::TypeTiny::Check::no_check_rule;
    }

C<Smart::Args::TypeTiny::Check::no_check_rule> is a function without type checking and type coerce, but settings such as default and optional work the same as C<check_rule>.

=head1 SEE ALSO

L<Smart::Args>, L<Data::Validator>, L<Params::Validate>, L<Params::ValidationCompiler>

L<Type::Tiny>, L<Types::Standard>, L<Mouse::Util::TypeConstraints>

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut
