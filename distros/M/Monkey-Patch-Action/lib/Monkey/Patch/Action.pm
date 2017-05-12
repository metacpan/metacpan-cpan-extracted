package Monkey::Patch::Action;

use 5.010;
use warnings;
use strict;

our $VERSION = '0.04'; # VERSION

use Monkey::Patch::Action::Handle;

use Exporter qw(import);
our @EXPORT_OK = qw(patch_package);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub patch_package {
    my ($package, $subname, $action, $code, @extra) = @_;

    die "Please specify action" unless $action;
    if ($action eq 'delete') {
        die "code not needed for 'delete' action" if $code;
    } else {
        die "Please specify code" unless $code;
    }

    my $name = "$package\::$subname";
    my $type;
    if ($action eq 'add') {
        die "Adding $name: must not already exist" if defined(&$name);
        $type = 'sub';
    } elsif ($action eq 'replace') {
        die "Replacing $name: must already exist" unless defined(&$name);
        $type = 'sub';
    } elsif ($action eq 'add_or_replace') {
        $type = 'sub';
    } elsif ($action eq 'wrap') {
        die "Wrapping $name: must already exist" unless defined(&$name);
        $type = 'wrap';
    } elsif ($action eq 'delete') {
        $type = 'delete';
    } else {
        die "Unknown action '$action', please use either ".
            "wrap/add/replace/add_or_replace/delete";
    }

    my @caller = caller(0);

    Monkey::Patch::Action::Handle->new(
        package => $package,
        subname => $subname,
        extra   => \@extra,
        patcher => \@caller,
        code    => $code,

        -type   => $type,
    );
}

1;
# ABSTRACT: Wrap/add/replace/delete subs from other package (with restore)


__END__
=pod

=head1 NAME

Monkey::Patch::Action - Wrap/add/replace/delete subs from other package (with restore)

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Monkey::Patch::Action qw(patch_package);

 package Foo;
 sub sub1  { say "Foo's sub1" }
 sub sub2  { say "Foo's sub2, args=", join(",", @_) }
 sub meth1 { my $self = shift; say "Foo's meth1" }

 package Bar;
 our @ISA = qw(Foo);

 package main;
 my $h; # handle object
 my $foo = Foo->new;
 my $bar = Bar->new;

 # replacing a subroutine
 $h = patch_package('Foo', 'sub1', 'replace', sub { "qux" });
 Foo::sub1(); # says "qux"
 undef $h;
 Foo::sub1(); # says "Foo's sub1"

 # adding a subroutine
 $h = patch_package('Foo', 'sub3', 'add', sub { "qux" });
 Foo::sub3(); # says "qux"
 undef $h;
 Foo::sub3(); # dies

 # deleting a subroutine
 $h = patch_package('Foo', 'sub2', 'delete');
 Foo::sub2(); # dies
 undef $h;
 Foo::sub2(); # says "Foo's sub2, args="

 # wrapping a subroutine
 $h = patch_package('Foo', 'sub2', 'wrap',
     sub {
         my $ctx = shift;
         say "wrapping $ctx->{package}::$ctx->{subname}";
         $ctx->{orig}->(@_);
     }
 );
 Foo::sub2(1,2,3); # says "wrapping Foo::sub2" then "Foo's sub2, args=1,2,3"
 undef $h;
 Foo::sub2(1,2,3); # says "Foo's sub2, args=1,2,3"

 # stacking patches (note: can actually be unapplied in random order)
 my ($h2, $h3);
 $h  = patch_package('Foo', 'sub1', 'replace', sub { "qux" });
 Foo::sub1(); # says "qux"
 $h2 = patch_package('Foo', 'sub1', 'delete');
 Foo::sub1(); # dies
 $h3 = patch_package('Foo', 'sub1', 'replace', sub { "quux" });
 Foo::sub1(); # says "quux"
 undef $h3;
 Foo::sub1(); # dies
 undef $h2;
 Foo::sub1(); # says "qux"
 undef $h;
 Foo::sub1(); # says "Foo's sub1"

=head1 DESCRIPTION

Monkey-patching is the act of modifying a package at runtime: adding a
subroutine/method, replacing/deleting/wrapping another, etc. Perl makes it easy
to do that, for example:

 # add a subroutine
 *{"Target::sub1"} = sub { ... };

 # another way, can be done from any file
 package Target;
 sub sub2 { ... }

 # delete a subroutine
 undef *{"Target::sub3"};

This module makes things even easier by helping you apply a stack of patches and
unapply them later in flexible order.

=head1 FUNCTIONS

=head2 patch_package($package, $subname, $action, $code, @extra) => HANDLE

Patch C<$package>'s subroutine named C<$subname>. C<$action> is either:

=over 4

=item * C<wrap>

C<$subname> must already exist. C<code> is required.

Your code receives a context hash as its first argument, followed by any
arguments the subroutine would have normally gotten. Context hash contains:
C<orig> (the original subroutine that is being wrapped), C<subname>, C<package>,
C<extra>.

=item * C<add>

C<subname> must not already exist. C<code> is required.

=item * C<replace>

C<subname> must already exist. C<code> is required.

=item * C<add_or_replace>

C<code> is required.

=item * C<delete>

C<code> is not needed.

=back

Die on error.

Function returns a handle object. As soon as you lose the value of the handle
(by calling in void context, assigning over the variable, undeffing the
variable, letting it go out of scope, etc), the patch is unapplied.

Patches can be unapplied in random order, but unapplying a patch where the next
patch is a wrapper can lead to an error. Example: first patch (P1) adds a
subroutine and second patch (P2) wraps it. If P1 is unapplied before P2, the
subroutine is now no longer there, and P2 no longer works. Unapplying P1 after
P2 works, of course.

=head1 FAQ

=head2 Differences with Monkey::Patch?

This module is based on the wonderful L<Monkey::Patch> by Paul Driver. The
differences are:

=over 4

=item *

This module adds the ability to add/replace/delete subroutines instead of just
wrapping them.

=item *

Interface to patch_package() is slightly different (see previous item for the
cause).

=item *

Using this module, the wrapper receives a context hash instead of just the
original subroutine.

=item *

Monkey::Patch adds convenience for patching classes and objects. To keep things
simple, no such convenience is currently provided by this module.
C<patch_package()> *can* patch classes and objects as well (see the next FAQ
entry).

=back

=head2 How to patch classes and objects?

Patching a class is basically the same as patching any other package, since Perl
implements a class with a package. One thing to note is that to call a parent's
method inside your wrapper code, instead of:

 $self->SUPER::methname(...)

you need to do something like:

 use SUPER;
 SUPER::find_parent(ref($self), 'methname')->methname(...)

Patching an object is also basically patching a class/package, because Perl does
not have per-object method like Ruby. But if you just want to provide a modified
behavior for a certain object only, you can do something like:

 patch_package($package, $methname, 'wrap',
 sub {
     my $ctx = shift;
     my $self = shift;

     my $obj = $ctx->{extra}[0];
     no warnings 'numeric';
     if ($obj == $self) {
         # do stuff
     }
     $ctx->{orig}->(@_);
 }, $obj);

=head1 SEE ALSO

L<Monkey::Patch>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

