package Sub::Prepend;
use 5.006001;

$VERSION = 0.01;

use Exporter;
@ISA = Exporter::;
@EXPORT_OK = qw/ prepend /;
$EXPORT_TAGS{ALL} = \@EXPORT_OK;

use strict;
use Carp;
use Scalar::Util 1.11 'set_prototype';
use Symbol qw/ qualify_to_ref qualify /;

use vars qw/ $CALLER /;

*CALLER = \1;

sub prepend {
    my ($name, $code) = @_;

    my $glob = qualify_to_ref($name => scalar caller);

    defined &$glob
        or croak(sprintf __PACKAGE__ . ": Subroutine &%s not defined", qualify($name => scalar caller));

    my $orig = \&$glob;

    my $prepender = set_prototype(
        sub {
            &$code; # Don't use parenthesis!
            goto &$orig;
        },
        prototype $orig
    );

    {
        no warnings 'redefine';
        *$glob = $prepender;
    }

    return;
}

1;

__END__

=head1 NAME

Sub::Prepend - Prepend code to named subroutines.


=head1 SYNOPSIS

    use Sub::Prepend 'prepend';

    sub foo ($) {
        print "Foo executed with \@_ = (@_).\n";
    }

    BEGIN {
        prepend foo => sub {
            # This is called before foo executes.
            print "Foo was called with \@_ = (@_).\n";
            push @_, 'and more';
        }
    }

    my @bar = qw/ foo bar baz /;
    foo(@bar); # The prototype is preserved!

    __END__
    Foo was called with @_ = (3).
    Foo executed with @_ = (3 and more).


=head1 DESCRIPTION

C<Sub::Prepend> simply conveniently prepends code to named subroutines without any risk of the wrapping itself breaks any existing code. Prepending means that C<foo> and C<bar> below are equivalent (barring C<caller> in the prepended block):

    prepend foo => sub {
        ... # prepended
    };
    sub foo {
        ... # original
    }

    sub bar {
        {
            ... # prepended
        }
        ... # original
    }

This is an initial release, and some things may change for the next version. If you feel something is missing or poorly designed, now is the time to voice your opinion.

A key feature of this modules is what it B<doesn't> do. See below.


=head2 Differences with other modules

The goal for a general subroutine wrapper must be to in itself be transparent to the target subroutine. This is currently not possible for wrappers that append code. Thus the act of the wrapping itself, regardless of the added code, may break existing code.

Below is a list of features that C<Sub::Prepend> has, but it also illustrates the problems with the other modules available as CPAN (see L</"SEE ALSO">).

=over

=item Fully transparent regarding C<caller>.

When the other module try to append code they also must call the subroutine themselves, adding a call frame visible to C<caller>. This will break subroutines that rely on C<caller>. Some modules try to hack around this by overloading C<caller> but that solution will fail for subroutines compiled before the wrapper module was loaded. It can also introduce subtle bugs when other modules try to overload C<caller> and/or use the C<DB> interface.

C<Sub::Prepend> avoids this by using C<goto &foo> which completely hides the intermediate call frame.

=item Fully transparent regarding return contexts (such as void, scalar, list, lvalue, dereference, count, etc).

Subroutines that utilize L<Want|Want> to add magic for special contexts, such as optimizing for the number of return values in

    my ($x, $y) = foo();

a la C<split>, will usually break if wrapped with the other modules. This is because the return value must be saved away to be returned later, and the call done by the wrapper puts the subroutine call in another context. Simple void/scalar/list context is usually handled correctly.

C<Sub::Prepend> avoids this in the same way as the issue above: through C<goto &foo>.

=item Preserves prototypes.

In order for code like

    sub foo ($) { ... }

    my @bar;
    foo(@bar);

to continue to work as intended for code compiled after the wrapping, the wrapper must set the proper prototype.

=back


=head1 EXPORTED FUNCTIONS

Nothing is exported by default. The C<:ALL> tag exports everything that can be exported.

=over

=item prepend($subname => sub { ... })

Makes any call to the subroutine named by C<$subname> first go through the subroutine referenced by the second argument. If the subroutine name isn't fully qualified the current package is assumed (except for symbols that belong to main, such as C<ENV> and C<_>). The C<qualify> function in the standard module L<Symbol|Symbol> can be used if you want the name to default to another package:

    use Symbol 'qualify';

    prepend(
        qualify($name => 'Other::Package') => sub {
            ...
        }
    );

B<Note>: The two subroutines I<share> C<@_>:

    sub foo { print "@_" }

    prepend(foo => sub { unshift @_, 'x' });

    foo(1, 2, 3);

    __END__
    x 1 2 3

No attempt is made to fiddle with the calling context for the prepended code. Instead, you can use C<caller($Sub::Prepend::CALLER)> as a drop-in replacement for C<caller()>.

=back


=head1 DIAGNOSTICS

=over

=item Subroutine &%s not defined

(F) You tried to prepend code to a subroutine that wasn't yet defined.

=back


=head1 EXAMPLES

=head2 Create hybrid singleton classes

Some classes are designed so that class methods act on a shared object, like a singleton class. Let's say C<foo> and C<bar> are attributes, then such a class could look like

    package Foo;
    use strict;
    use Sub::Prepend 'prepend';

    sub new { bless {} => shift }

    {
        my $singleton;
        sub singleton { $singleton ||= shift()->new }
    }

    for (qw/ bar baz /) {
        prepend($_ => sub {
            unshift @_, shift()->singleton
                if not ref $_[0];
        });
    }

    sub bar { $_[0]->{bar} = $_[1] if @_ > 1; return $_[0]->{bar} }
    sub baz { $_[0]->{baz} = $_[1] if @_ > 1; return $_[0]->{baz} }

Here I used C<Sub::Prepend> to add the singleton logic to the attributes. Now C<< Foo->bar >> and C<< Foo->baz >> act like instance methods working on the default object. This is not necessarily a good idea.


=head1 AUTHOR

Johan Lodin <lodin@cpan.org>


=head1 COPYRIGHT

Copyright 2007-2008 Johan Lodin. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<Hook::WrapSub>

L<Hook::PrePostCall>

L<Hook::LexWrap>


=cut
