package Object::Factory::Declarative;

use 5.006;
use strict;
use warnings;
use Carp;

our @ISA = qw();

our $VERSION = '0.07';

my @decl_keys = qw(constructor constructor_args method method_args package);

sub expand_scalar_arg
{
    my ($obj, $name, $arg) = @_;
    my @res = ($arg);
    if(@_>3)
    {
        my $opt = $_[3];
        eval { no warnings; @res = $obj->$arg($opt, $name); };
    }
    else
    {
        eval { no warnings; @res = $obj->$arg($name); };
    }
    wantarray?@res:pop @res;
}

sub expand_array_arg
{
    my ($obj, $name, @args) = @_;
    my @res;
    push @res, expand_scalar_arg($obj, $name, $_) foreach @args;
    wantarray?@res:pop @res;
}

sub expand_hash_arg
{
    my ($obj, $name, @args) = @_;
    return expand_array_arg($obj, $name, @args) if @args&1;
    my @res;
    my %args = @args;
    push @res, $_, expand_scalar_arg($obj, $name, $args{$_}, $_)
        foreach keys %args;
    wantarray?@res:pop @res;
}

sub expand_credentials
{
    my ($argf) = @_;
    return sub {} unless defined $argf;
    return (\&expand_scalar_arg, $argf) unless ref $argf;
    my @res = ($argf);
    eval { no warnings; @res = @$argf; };
    return (\&expand_array_arg, @res) unless $@;
    eval { no warnings; @res = %$argf; };
    return (\&expand_hash_arg, @res) unless $@;
    return (\&expand_scalar_arg, @res);
}

sub generate_method
{
    my ($class, $name, $cons, $c_args, $init, $i_args) = @_;
    my $package = ref $class || $class;
    my $fullname = $package . '::' . $name;
    my ($cons_expand_func, @c_args) = expand_credentials($c_args);
    my ($init_expand_func, @i_args) = expand_credentials($i_args);
    no strict 'refs';
    # We have several similar cases...
    # Case 1a & 1b - no init method
    unless($init)
    {
        # 1a - with constructor args
        if(@c_args)
        {
            *$fullname = sub
            {
                my ($obj) = @_;
                $obj->$cons(&{$cons_expand_func}($obj, $name, @c_args));
            } ;
        }
        # 2a - without constructor args
        else
        {
            *$fullname = sub
            {
                my ($obj) = @_;
                $obj->$cons;
            } ;
        }
        return;
    }
    # Case 2a & 2b - init method, no init args
    unless(@i_args)
    {
        # 2a - with constructor args
        if(@c_args)
        {
            *$fullname = sub
            {
                my ($obj, @args) = @_;
                my $rv = $obj->$cons(&{$cons_expand_func}($obj,
                                    $name, @c_args));
                $rv->$init;
                # expand_hash_arg will convert to expand_array_arg...
                $rv->$init(expand_hash_arg($obj, $name, @args)) if @args;
                $rv;
            } ;
        }
        # 2b - without constructor args
        else
        {
            *$fullname = sub
            {
                my ($obj, @args) = @_;
                my $rv = $obj->$cons;
                $rv->$init;
                # expand_hash_arg will convert to expand_array_arg...
                $rv->$init(expand_hash_arg($rv, $name, @args)) if @args;
                $rv;
            } ;
        }
        return;
    }
    # Case 3a & 3b - init with args
    # 3a - with constructor args
    if(@c_args)
    {
        *$fullname = sub
        {
            my ($obj, @args) = @_;
            my $rv = $obj->$cons(&{$cons_expand_func}($obj,
                $name, @c_args));
            $rv->$init(&{$init_expand_func}($obj, $name, @i_args));
            $rv->$init(&{$init_expand_func}($obj, $name, @args)) if @args;
            $rv;
        } ;
    }
    # 3b - without constructor args
    else
    {
        *$fullname = sub
        {
            my ($obj, @args) = @_;
            my $rv = $obj->$cons;
            $rv->$init(&{$init_expand_func}($obj, $name, @i_args));
            $rv->$init(&{$init_expand_func}($obj, $name, @args)) if @args;
            $rv;
        } ;
    }
}

sub import
{
    my ($package, @args) = @_;
    carp "Expected an even number of arguments" and return if @args&1;
    my $callpkg = caller;
    my %defaults =
    (
        package => $callpkg,
    ) ;
    while(@args)
    {
        my ($name, $ref) = splice @args, 0, 2;
        my %h;
        if('--defaults' eq $name)
        {
            %defaults = ( package => $callpkg );
            %h = %$ref;
            foreach my $k (grep { exists $h{$_}; } @decl_keys)
            {
                delete $defaults{$k};
                my $v = delete $h{$k};
                $defaults{$k} = $v if defined $v;
            }
            carp "Unexpected declaration key(s) ", join(',', keys %h) if %h;
            next;
        }
        if('--export-to' eq $name)
        {
            no strict 'refs';
            *$ref = \&generate_method;
            next;
        }
        %h = %$ref;
        my %p;
        $p{$_} = delete $h{$_} || $defaults{$_} foreach @decl_keys;
        carp "Unexpected declaration key(s) ", join(',', keys %h) if %h;
        carp "Can't have initialization args without an initialization method"
            if $p{method_args} and not $p{method};
        carp "Missing constructor" and next unless $p{constructor};
        generate_method($p{package}, $name, @p{qw(constructor constructor_args
            method method_args)});
    }
}

1;
__END__

=head1 NAME

Object::Factory::Declarative - Create object factory methods using declarative syntax

=head1 SYNOPSIS

  use Object::Factory::Declarative
  (
    '--defaults' =>
    {
        constructor => 'load_tmpl',
        method => 'param',
    },
    'main_template' =>
    {
        constructor_args => 'main.tmpl',
        method_args =>
        {
            title => 'Main template',
            content => 'generate_content',
        },
    },
    '--export-to' => __PACKAGE__ . '::new_template_factory',

  ) ;

  # ...
  my $tmpl = $self->main_template(content => $content2);
  print $tmpl->output;

=head1 DESCRIPTION

The B<Object::Factory::Declarative> module is a generalization of a
method-generating module for creating self-loading template objects.  It
creates methods in arbitrary packages (the package where
B<Object::Factory::Declarative> is used, by default) that act as object
factories.  These methods are referred to as I<declared methods> in the
rest of this documentation.

The objects are created using the provided constructor method, and then
optionally initialized with the provided initialization method.  If the
factory method is passed any arguments when it is called, the
initialization method will be called with those arguments as the last
step before the created object gets returned.

The module is used with a list of method name - parameter hash ref pairs.
The method name becomes the name of the declared method.  If the special
method name C<--defaults> is given, further methods can be declared
assuming the values set in the C<--defaults> section.  The special
method name C<--export-to> is used to declare an alias for the function
that creates factory methods.

The parameters to the C<use> statement are processed as a list, not a
hash.  This means you can have more than one C<--default> section, with
each one overriding the previous one.  You can also export more than
one alias for the factory creation function.

The valid keys (and their meanings) for the parameter hash refs are:

=over 4

=item constructor

This is the method used to initially construct the object.  It is an
error to try to declare a method without providing a constructor.

=item constructor_args

This can be a scalar, code ref, array ref, or hash ref, and it's used to
assemble the arguments to the constructor, after argument expansion.

=item method

This is the initialization method applied to the object after it is
constructed.  If no method is provided, no further initialization is
performed after the object is constructed.

=item method_args

This can be a scalar, code ref, array ref, or hash ref, and it's used to
assemble the arguments to the declared initialization method, after
argument expansion.

=item package

This is the name of the package where the method should be created.  It
defaults to the package where the C<use> statement was encountered.

=back

=head1 ARGUMENT EXPANSION

The arguments to the constructor or initialization methods are expanded
before they are passed to the method in question.  Arguments passed to
the declared method are also expanded before being passed to the
initialization method.

Arguments are expanded when the object is created, not when the declared
method is created.  Argument expansion takes place in the context of the
class or object where the declared method is called.  For the example in
the synopsis, this would be the value of C<$self> at the time the
main_template() method were called.

For constructor and initialization methods, argument expansion is
dependent on the type of the argument.  For scalar arguments, an attempt
is made to apply the argument as a method in the appropriate context,
with the name of the generated method as an argument.  For the example
in the synopsis, something like the following code fragment would be
attempted:

  my $meth = 'main.tmpl';
  my @res = $self->$meth("main_template");

If applying the scalar as a method fails (by which I mean it calls die()
in one of its various incarnations), it's used as-is.  If the method
call succeeds, the returned result is used.

For code ref arguments, the argument is applied as a method.  The
underlying code doesn't actually distinguish between a scalar and a code
ref, so if the code ref calls die(), it will be passed as-is to the
constructor.

For array ref arguments, an attempt is made to apply each element as a method,
with an argument of the declared method name.  When the method application
fails, the argument is used as-is.  When it succeeds, the argument is
replaced by whatever is returned from the method call.  For example, if you
have an argument list that looks like this:

  [ 'a string', 'method1', 'another string', 'method2' ]

and method1() returns nothing, and method2() returns the list C<qw(a b c)>,
the resulting arguments would be:

  ('a string', 'another string', 'a', 'b', 'c')

Note that this is quite different from a method that returns C<undef> - had
method1() returned C<undef>, the resulting arguments would be:

  ('a string', undef, 'another string', 'a', 'b', 'c')

For hash ref arguments, an attempt is made to apply each value in the hash
as a method, with the corresponding key and the declared method name as
arguments.  For the example in the synopsis, this would result in code
like the following be run:

  my @res;
  push @res, 'title';
  my $meth = 'Main template';
  eval { push @res, $obj->$meth('title', 'main_template'); };
  push @res, $meth if $@;
  $meth = 'generate_content',
  push @res, 'content';
  eval { push @res, $obj->$meth('content', 'main_template'); };
  push @res, $meth if $@;

Arguments to the declared method are expanded based on any implicit
argument to the initialization method.  If their is no argument declared
for the initialization method, arguments to the declared method are
handled like a hash (if there are an even number of them) or an array
(if there are an odd number).  If an argument is declared for the
initialization method, arguments to the declared method are expanded
in a manner similar to the those to the initialization method.  For
the example in the synopsis, arguments to main_template() would
be expanded as a hash.

=head1 PARENT CLASS METHODS

B<Object::Factory::Declarative> expects the calling class (or one of its
superclasses) to provide the constructor and initialization methods, as
well as any methods used in argument expansion.

=head1 FACTORY CREATION FUNCTION ALIASES

If you create an alias for the factory creation function, it can either
be called as a function (with an explicit package as the first argument)
or as a method.  For a method call, the syntax is:

  $self->new_factory($name, $cons, $cons_arg, $init, $init_arg);

The arguments correspond to the name of the declared method, the name of 
the constructor method, the argument to the constructor (as a scalar or
reference, and subject to argument expansion), the initialization
method, and the argument to the initialization method, (again, as a
scalar or reference, and subject to argument expansion).

You can also call it as a function by providing an explicit package name.

=head1 NOTES

Any array or hash ref declared as an argument is copied, but not deeply.

While there is no way to turn off argument expansion, you can guarantee
a specific result by using code references wherever
B<Object::Factory::Declarative> expects a method name.

Passing a list of parameters with an odd length to a declared method that
expects to expand its parameters as a hash will cause it to expand the
parameters as an array for that invocation.

=head1 MOTIVATION

As you can probably tell from the synopsis, B<Object::Factory::Declarative>
originated in a project that used B<CGI::Application> and a horde of
B<HTML::Template>-style template files.  Originally, they were managed with
a bunch of C<use constant> statements, but that was unwieldy.  A
special-purpose solution was created, and that was eventually expanded into
this module.

=head1 AUTHOR

Jim Schneider, E<lt>perl@jrcsdevelopment.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jim Schneider

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
