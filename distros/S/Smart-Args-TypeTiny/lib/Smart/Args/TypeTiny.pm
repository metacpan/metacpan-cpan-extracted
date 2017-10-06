package Smart::Args::TypeTiny;
use strict;
use warnings;
our $VERSION = "0.02";
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
            ?    $DB::args[0]  # must be hash
            : +{ @DB::args };  # must be key-value list

    # args my $var => RULE
    #         ~~~~    ~~~~
    #         undef   defined

    for (my $i = 0; $i < @_; $i++) {
        (my $name = var_name(1, \$_[$i]))
            or Carp::croak('Usage: args my $var => RULE, ...');
        $name =~ s/^\$//;

        # with rule (my $foo => RULE, ...)
        if (defined $_[$i+1]) {
            $_[$i] = check_rule($_[$i+1], $args->{$name}, exists $args->{$name}, $name);
            delete $args->{$name};
            $i++;
        }
        # without rule (my $foo, my $bar, ...)
        else {
            unless (exists $args->{$name}) {
                Carp::confess("Required parameter '$name' not passed");
            }
            $_[$i] = delete $args->{$name};
        }
    }

    for my $name (sort keys %$args) {
        Carp::confess("Unexpected parameter '$name' passed");
    }
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

    # args my $var => RULE
    #         ~~~~    ~~~~
    #         undef   defined

    for (my $i = 0; $i < @_; $i++) {
        (my $name = var_name(1, \$_[$i]))
            or Carp::croak('Usage: args_pos my $var => RULE, ...');
        $name =~ s/^\$//;

        # with rule (my $foo => RULE, ...)
        if (defined $_[$i+1]) {
            $_[$i] = check_rule($_[$i+1], $args->[0], @$args > 0, $name);
            shift @$args;
            $i++;
        }
        # without rule (my $foo, my $bar, ...)
        else {
            unless (@$args > 0) {
                Carp::confess("Required parameter '$name' not passed");
            }
            $_[$i] = shift @$args;
        }
    }

    if (@$args) {
        Carp::confess('Too many parameters passed');
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Smart::Args::TypeTiny - We are smart, smart for you

=head1 SYNOPSIS

    use Smart::Args::TypeTiny;
    use Types::Standard -all;

    sub func2 {
        args my $p => Int,
             my $q => {isa => Int, optional => 1},
             ;
    }
    func2(p => 3, q => 4); # p => 3, q => 4
    func2(p => 3);         # p => 3, q => undef

    sub func3 {
        args my $p => {isa => Int, default => 3};
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

=head1 IMCOMPATIBLE CHANGES WITH Smart::Args

=head2 ISA TAKES Type::Tiny TYPE OBJECT OR INSTANCE CLASS NAME

This code is expected C<$p> as InstanceOf['Int'], you should specify L<Type::Tiny>'s type constraint.

    use Types::Standard -all;

    sub foo {
        args my $p => 'Int', # :( InstanceOf['Int']
             my $q => Int,   # :) Int
             my $r => 'Foo', # :) InstanceOf['Foo']
    }

=head2 DEFAULT PARAMETER CAN TAKE CODEREF AS LAZY VALUE

    sub foo {
        args my $p => {isa => 'Foo', default => create_foo},         # :( create_foo is called every time even if $p is passed
             my $q => {isa => 'Foo', default => sub { create_foo }}, # :) create_foo is called only when $p is not passed
             ;
    }

=head1 TIPS

=head2 SKIP TYPE CHECK

For optimization calling subroutine in runtime type check, you can overwrite C<check_rule> like following code:

    {
        no warnings 'redefine';
        sub Smart::Args::TypeTiny::check_rule {
            my ($rule, $value, $exists, $name) = @_;
            return $value;
        }
    }

=head1 SEE ALSO

L<Smart::Args>, L<Params::Validate>, L<Params::ValidationCompiler>

L<Type::Tiny>, L<Types::Standard>

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut
