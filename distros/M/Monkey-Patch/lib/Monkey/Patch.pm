package Monkey::Patch;
BEGIN {
  $Monkey::Patch::VERSION = '0.03';
}

use warnings;
use strict;

use Monkey::Patch::Handle;
use Monkey::Patch::Handle::Class;
use Monkey::Patch::Handle::Object;

use Exporter qw(import);
our @EXPORT_OK = qw(patch_package patch_class patch_object);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub patch_package {
    Monkey::Patch::Handle->new(
        package => shift,
        subname => shift,
        code    => shift,
    )->install;
}

sub patch_class {
    Monkey::Patch::Handle::Class->new(
        package => shift,
        subname => shift,
        code    => shift,
    )->install;
}

sub patch_object {
    my $obj = shift;
    Monkey::Patch::Handle::Object->new(
        object  => $obj,
        package => ref $obj,
        subname => shift,
        code    => shift,
    )->install;
}

=head1 NAME

Monkey::Patch - Scoped monkeypatching (you can at least play nice)

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Monkey::Patch qw(:all);

    sub some_subroutine {
        my $pkg = patch_class 'Some::Class' => 'something' => sub {
            my $original = shift;
            say "Whee!";
            $original->(@_);
        };
        Some::Class->something(); # says Whee! and does whatever
        undef $pkg;
        Some::Class->something(); # no longer says Whee! 

        my $obj = Some::Class->new;
        my $obj2 = Some::Class->new;

        my $whoah = patch_object $obj, 'twiddle' => sub {
            my $original = shift;
            my $self     = shift;
            say "Whoah!";
            $self->$original(@_);
        };

        $obj->twiddle();  # says Whoah!
        $obj2->twiddle(); # doesn't
        $obj->twiddle()   # still does
        undef $whoah;
        $obj->twiddle();  # but not any more
    
=head1 SUBROUTINES

The following subroutines are available (either individually or via :all)

=head2 patch_package (package, subname, code)

Wraps C<package>'s subroutine named <subname> with your <code>.  Your code
recieves the original subroutine as its first argument, followed by any
arguments the subroutine would have normally gotten.  You can always call the
subroutine ref your received; if there was no subroutine by that name, the
coderef will simply do nothing.

=head2 patch_class (class, methodname, code)

Just like C<patch_package>, except that the @ISA chain is walked when you try
to call the original subroutine if there wasn't any subroutine by that name in
the package.

=head2 patch_object (object, methodname, code)

Just like C<patch_class>, except that your code will only get called on the
object you pass, not the entire class.

=head1 HANDLES

All the C<patch> functions return a handle object.  As soon as you lose the
value of the handle (by calling in void context, assigning over the variable,
undeffing the variable, letting it go out of scope, etc), the monkey patch is
unwrapped.  You can stack monkeypatches and let go of the handles in any
order; they obey a stack discipline, and the most recent valid monkeypatch
will always be called.  Calling the "original" argument to your wrapper
routine will always call the next-most-recent monkeypatched version (or, the
original subroutine, of course).

=head1 BUGS

This magic is only faintly black, but mucking around with the symbol table is
not for the faint of heart.  Help make this module better by reporting any
strange behavior that you see!