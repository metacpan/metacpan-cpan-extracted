#!/usr/bin/perl

package MooseX::Compile;
use base qw(MooseX::Compile::Base);

use strict;
use warnings;

use constant DEBUG => MooseX::Compile::Base::DEBUG();
use constant default_compiler_class => "MooseX::Compile::Compiler";

use Devel::INC::Sorted qw(inc_add_floating);

BEGIN {
    inc_add_floating(sub {
        my ( $self, $file ) = @_;

        if ( DEBUG ) {
            foreach my $pkg qw(
                Moose
                Moose::Meta::Class

                Class::MOP
                Class::MOP::Class

                metaclass

                Moose::Util::TypeConstraints
                Moose::Meta::TypeConstraint
                Moose::Meta::TypeCoercion
            ) {
                ( my $pkg_file = "$pkg.pm" ) =~ s{::}{/}g;
                require Carp and Carp::carp("loading $pkg") if $file eq $pkg_file;
            }
        }

        if ( $ENV{MX_COMPILE_CLEAN} ) {
            foreach my $dir ( grep { not ref } @INC ) {
                my $full = "$dir/$file";

                my $pmc = "${full}c";
                ( my $mopc = $full ) =~ s/\.pm$/.mopc/;

                if ( -e $pmc && -e $mopc ) {
                    warn "removing compiled class for file '$file'\n" if DEBUG;
                    unlink $pmc or die "Can't remove pmc file (unlink($pmc)): $!";
                    unlink $mopc or die "Can't remove cached metaclass (unlink($mopc)): $!";
                }
            }
        }

        return;
    });
}

sub import {
    my ($self, @args) = @_;

    my ( $class, $file ) = caller();

    if ( $MooseX::Compile::Bootstrap::known_pmc_files{$file} ) {
        return $self->import_from_pmc( $class, $file, @args );
    } else {
        warn "class '$class' requires compilation\n" if DEBUG;

        require Check::UnitCheck;
        Check::UnitCheck::unitcheckify(sub {
            warn "compilation unit of class '$class' calling UNITCHECK\n" if DEBUG;
            $self->unit_check( $class, $file, @args );
        });

        require Moose;
        shift; unshift @_, "Moose";
        goto \&Moose::import;
    }
}

sub import_from_pmc {

}

sub unit_check {
    my ( $self, $class, $file, @args ) = @_;

    $self->compile_from_import(
        class => $class,
        file  => $file,
        @args,
    );
}

sub compile_from_import {
    my ( $self, %args ) = @_;

    if ( $ENV{MX_COMPILE_IMPLICIT_ANCESTORS} ) {
        warn "implicitly compiling all ancestors of class '$args{class}'\n" if DEBUG;
        $self->compile_ancestors( %args );
    }

    $self->compile_class( %args );
}

sub compile_ancestors {
    my ( $self, %args ) = @_;

    my $class = $args{class};
    my $files = $args{files} || {};

    foreach my $superclass ( reverse $class->meta->linearized_isa ) {
        next if $superclass eq $class;
        warn "compiling '$class' superclass '$superclass'\n" if DEBUG;
        $self->compile_class( %args, class => $superclass, file => $files->{$superclass} );
    }
}

sub compile_class {
    my ( $self, %args ) = @_;

    my $compiler = $self->create_compiler( %args );

    $compiler->compile_class( %args );
}

sub compiler_class {
    my ( $self, %args ) = @_;

    $args{compiler_class} || $self->default_compiler_class;
}

sub create_compiler {
    my ( $self, @args ) = @_;

    my $compiler_class = $self->compiler_class(@args);

    $self->load_classes($compiler_class);

    $compiler_class->new( @args );
}

__PACKAGE__;

__END__

=pod

=encoding utf8

=head1 NAME

MooseX::Compile - L<Moose> ♥ L<.pmc>

=head1 SYNOPSIS

In C<MyClass.pm>:

    package MyClass;
    use Moose;

    # your moose class here

On the command line:

    $ mkcompile compile --make-immutable MyClass

Or to always compile:

    use MooseX::Compile; # instead of use Moose

=head1 HERE BE DRAGONS

This is alpha code.

If you decide to to use it please come by the C<#moose> IRC channel on
C<irc.perl.org> (maybe this link works: L<irc://irc.perl.org/#moose>).

Your help in testing this is highly valued, so please feel free to verbally
abuse C<nothingmuch> in C<#moose> until things are working properly.

=head1 DESCRIPTION

The example in the L</SYNOPSIS> will compile C<MyClass> into two files,
C<MyClass.pmc> and C<MyClass.mopc>. The C<.pmc> file caches all of the
generated code, and the C<.mopc> file is a L<Storable> file of the metaclass
instance.

When C<MyClass> is loaded the next time, Perl will see the C<.pmc> file and
load that instead. This file will load faster for several reasons:

=over 4

=item *

L<Moose> is no longer required to load C<MyClass>, all the methods L<Moose>
normally generates are already saved in the C<.pmc> file.

=item *

The metaclass does not need to be loaded, at least until you introspect.
C<meta> for compiled classes will lazy load the already computed metaclass
instance from the C<.mopc> file. When it is needed the instance will be
deserialized and it's class (probably L<Moose::Meta::Class>) will be loaded.

=back

If all your classes are compiled and you don't use introspection in your code,
you can then deploy your code without using moose.

=head1 MODUS OPERANDI

This is not a source filter.

Due to the fragility of source filtering in Perl, C<MooseX::Compile::Compiler>
will not alter the body of the class, but instead prefix it with a preamble
that sets up the right environment for it.

This involves temporarily overriding C<CORE::GLOBAL::require> to hide C<Moose>
from this module (but not others), and stubbing the sugar with no-ops (the
various declarations are thus effectively stripped without altering the source
code), amongst other things.

Then the source code of the original class is executed normally, and when the
file's lexical scope gets cleaned up then the final pieces of the class are put
in place and all the trickery is undone.

Until this point C<meta> is replaced with a mock object that will silently or
loudly ignore various method calls depending on their nature. For instance

    __PACKAGE__->meta->make_immutable();

is a silent no-op, because when the compiler compiled it the class was already
immutable, so the loaded version will be immutable too.

On the other hand

    __PACKAGE__->meta->superclasses(qw(Foo));

will complain because the value of C<@ISA> is already captured, and changing it
is meaningless.

=head1 INTERFACE FOR COMPILED MODULES

=item C<$__mx_is_compiled>

This variable is set at C<BEGIN> for modules in a C<.pmc>. This allows you to
write conditional code, like:

    use if not(our $__mx_is_compiled) metaclass => "Blah";

    __PACKAGE__->meta->add_attribute( ... ) unless our $__mx_is_compiled;

=item C<__mx_compile_post_hook>

If you add a subroutine named C<__mx_compile_post_hook> to your class it will
be called at the end of compilation, allowing you to to diddle the class after
loading.

=head1 LIMITATIONS

This developer release comes with some serious limitations.

It has so far only been tested with the C<Point> and C<Point3D> classes from
the recipe.

This means:

=over 4

=item *

No method modifiers are supported yet. We know how and it's going to take a while longer.

=item *

Only core, optimized Moose types are guaranteed to work (C<Int>, C<Str>, etc).
Other types may or may not deparse properly.

=item *

Roles are not yet supported.

=item *

Stuff is definitely going to break. This is just a first release of a fairly
complex project, so bear with us =)

=back

=head1 TODO

There is a fairly long F<TODO> file in the distribution.

=head1 SEE ALSO

L<MooseX::Compile::Compiler>, L<MooseX::Compile::Bootstrap>,
L<MooseX::Compile::CLI>.

=head1 VERSION CONTROL

L<http://code2.0beta.co.uk/moose/svn/MooseX-Compile/trunk>

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

    Copyright (c) 2008 Infinity Interactive, Yuval Kogman. All rights reserved
    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

=cut

