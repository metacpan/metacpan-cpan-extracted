package Perinci::Sub::Gen::FromClass;

our $DATE = '2015-09-04'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

use Monkey::Patch::Action qw(patch_package);
use Perinci::Sub::Gen;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(gen_func_from_class);

our %SPEC;

$SPEC{gen_func_from_class} = {
    v => 1.1,
    summary => 'Generate function (and its Rinci metadata) from a class',
    description => <<'_',

`gen_func_from_class` will create a function and Rinci metadata from a
{Mo,Moo,Moose,Mouse} class. Given a class like this:

    # MyClass
    use Moo;
    has attr1 => (is => 'ro', required=>1);
    has attr2 => (is => 'rw');
    sub meth1 { ... }
    sub meth2 { ... }
    1;

will create a function that does something like this (it will basically
instantiate a class, set its attributes, and call a method):

    MyClass->new(attr1=>..., attr2=>...)->meth1;

along with Rinci metadata like this:

    {
        v => 1.1,
        args => {
            attr1 => { req=>1, schema=>'any' },
            attr2 => { schema=>'any' },
        },
    }

Currently only Mo- and Moo-based class is supported. Support for other Mo*
family members will be added.

_
    args => {
        %Perinci::Sub::Gen::common_args,
        class => {
            summary => 'Class name, will be loaded with require()',
            req => 1,
        },
        method => {
            summary => 'Method of class to call',
            req => 1,
            # XXX guess if not specified?
        },
        method_args => {
            schema => 'array*',
        },
    },
    result => {
        summary => 'A hash containing generated function, metadata',
        schema => 'hash*',
    },
};
sub gen_func_from_class {
    my %args = @_;

    my $class  = $args{class} or return [400, "Please specify 'class'"];
    $class =~ /\A\w+(::\w+)*\z/ or
        return [400, "Invalid value for 'class', please use Foo::Bar ".
                    "syntax only"];
    my $method = $args{method} or return [400, "Please specify 'method'"];

    my %mo_attrs;
    {
        my $handle_mo;
        # doesn't work if Mo is inlined
        if (eval "require Mo; 1") {
            require Mo::default;
            require Mo::required;
            my $M = "Mo::";
            # copied and modified from Mo 0.38
            $handle_mo = patch_package(
                'Mo', 'import', 'replace',
                sub {
    no strict; ###
    import warnings;
    $^H |= 1538;
    my ( $P, %e, %o ) = caller . '::';
    shift;
    eval "no Mo::$_", &{ $M . $_ . '::e' }( $P, \%e, \%o, \@_ ) for @_;
    return if $e{M};
    %e = ( 'extends',
        sub { eval "no $_[0]()"; @{ $P . ISA } = $_[0] },
        'has',
        sub {
            my $n = shift;
            my $p = $P; $p =~ s/::$//; $mo_attrs{$p}{$n} = {@_}; ###
            my $m = sub { $#_ ? $_[0]{$n} = $_[1] : $_[0]{$n} };
            @_ = ( 'default', @_ ) if !( $#_ % 2 );
            $m = $o{$_}->( $m, $n, @_ ) for sort keys %o;
            *{ $P . $n } = $m;
        },
        %e,
    );
    *{ $P . $_ } = $e{$_} for keys %e;
    @{ $P . ISA } = $M . Object;
                },
            );
        }
        # to support Mouse and Moose we'll need to let user enable it, because
        # of the startup overhead
        my $classp = $class;
        $classp =~ s!::!/!g; $classp .= ".pm";
        require $classp;
    }

    my $install = $args{install} // 1;

    my $fqname = $args{name} // 'noname';
    return [400, "Please specify 'name'"] unless $fqname || !$install;
    my @caller = caller();
    my ($package, $uqname);
    if ($fqname =~ /(.+)::(.+)/) {
        $package = $1;
        $uqname  = $2;
    } else {
        $package = $args{package} // $caller[0];
        $uqname  = $fqname;
        $fqname  = "$package\::$uqname";
    }

    my %func_args;
    {
        my $doit;
        $doit = sub {
            no strict 'refs';
            my $pkg = shift;
            my $ass = $mo_attrs{$pkg} //
                $Moo::MAKERS{$pkg}{constructor}{attribute_specs};
            if ($ass) {
                for my $k (keys %$ass) {
                    my $v = $ass->{$k};
                    my $as = {
                        req => $v->{required} ? 1:0,
                    };
                    if (exists $v->{default}) {
                        if (ref($v->{default}) eq 'CODE') {
                            # XXX we're required to send $self to coderef, so we
                            # don't do it yet.

                            #$as->{default} = $v->{default}->($obj);
                        } else {
                            $as->{default} = $v->{default};
                        }
                    }
                    $func_args{$k} = $as;
                }
            }
            $doit->($_) for @{"$pkg\::ISA"};
        };
        $doit->($class);
    }

    my $meta = {
        v => 1.1,
        (summary => $args{summary}) x !!$args{summary},
        (description => $args{description}) x !!$args{description},
        args => \%func_args,
        result_naked => 1,
    };

    my $func = sub {
        no strict 'refs';
        my %func_args = @_;
        my $obj = $class->new(%func_args);
        my @meth_args;
        if ($args{method_args}) {
            @meth_args = @{ $args{method_args} };
        }
        $obj->$method(@meth_args);
    };

    if ($install) {
        no strict 'refs';
        no warnings;
        #$log->tracef("Installing function as %s ...", $fqname);
        *{ $fqname } = $func;
        ${$package . "::SPEC"}{$uqname} = $meta;
    }

    return [200, "OK", {meta=>$meta, func=>$func}];
}

1;
# ABSTRACT: Generate function (and its Rinci metadata) from a class

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Gen::FromClass - Generate function (and its Rinci metadata) from a class

=head1 VERSION

This document describes version 0.04 of Perinci::Sub::Gen::FromClass (from Perl distribution Perinci-Sub-Gen-FromClass), released on 2015-09-04.

=head1 SYNOPSIS

Given a Mo/Moo/Mouse/Moose class:

    # MyClass
    use Moo;
    has attr1 => (is => 'ro', required=>1);
    has attr2 => (is => 'rw');
    sub do_this { ... }
    sub do_that { ... }
    1;

you can generate a function for it:

    use Perinci::Sub::Gen::FromClass qw(gen_func_from_class);
    gen_func_from_class(
        name   => 'do_this',

        class  => 'MyClass',
        type   => 'Moo',
        method => 'do_this',
        method_args => [3, 4, 5], # optional
    );

then if you call this function:

    do_this(attr1=>1, attr2=>2);

it will do something like (instantiate class and call a method):

    MyClass->new(attr1=>1, attr2=>2)->do_this(3, 4, 5);

=head1 DESCRIPTION

Sometimes some module annoyingly only provides OO interface like:

 my $obj = Foo->new(arg1=>1, arg2=>2);
 $obj->some_action;

when it could very well just be:

 some_action(arg1=>1, arg2=>2);

This module helps you create that function from a class.

=head1 FUNCTIONS


=head2 gen_func_from_class(%args) -> [status, msg, result, meta]

Generate function (and its Rinci metadata) from a class.

C<gen_func_from_class> will create a function and Rinci metadata from a
{Mo,Moo,Moose,Mouse} class. Given a class like this:

 # MyClass
 use Moo;
 has attr1 => (is => 'ro', required=>1);
 has attr2 => (is => 'rw');
 sub meth1 { ... }
 sub meth2 { ... }
 1;

will create a function that does something like this (it will basically
instantiate a class, set its attributes, and call a method):

 MyClass->new(attr1=>..., attr2=>...)->meth1;

along with Rinci metadata like this:

 {
     v => 1.1,
     args => {
         attr1 => { req=>1, schema=>'any' },
         attr2 => { schema=>'any' },
     },
 }

Currently only Mo- and Moo-based class is supported. Support for other Mo*
family members will be added.

Arguments ('*' denotes required arguments):

=over 4

=item * B<class>* => I<any>

Class name, will be loaded with require().

=item * B<description> => I<str>

Generated function's description.

=item * B<install> => I<bool> (default: 1)

Whether to install generated function (and metadata).

By default, generated function will be installed to the specified (or caller's)
package, as well as its generated metadata into %SPEC. Set this argument to
false to skip installing.

=item * B<method>* => I<any>

Method of class to call.

=item * B<method_args> => I<array>

=item * B<name> => I<str>

Generated function's name, e.g. `myfunc`.

=item * B<package> => I<str>

Generated function's package, e.g. `My::Package`.

This is needed mostly for installing the function. You usually don't need to
supply this if you set C<install> to false.

If not specified, caller's package will be used by default.

=item * B<summary> => I<str>

Generated function's summary.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value: A hash containing generated function, metadata (hash)

=head1 SEE ALSO

L<Rinci>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Gen-FromClass>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Gen-FromClass>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Gen-FromClass>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
