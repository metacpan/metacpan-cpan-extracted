package Params::Lazy;

{ require 5.008 };
use strict;
use warnings FATAL => 'all';

use Carp;

# The call checker API is available on newer Perls;
# making the dependency on D::CC conditional lets me
# test this on an uninstalled blead.
use if $] < 5.014, "Devel::CallChecker";

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = "force";
our @EXPORT_OK = "force";

our $VERSION = '0.005';

my $hint_key = "Params::Lazy/no_caller_args";

require XSLoader;
XSLoader::load('Params::Lazy', $VERSION);

sub import {
    my $self   = shift;
    my $caller = caller();
    
    if ( @_ == 1 ) {
        if ($_[0] eq 'force') {
            return $self->export_to_level(1);
        }
        elsif ( $_[0] eq 'caller_args' ) {
            delete $^H{$hint_key};
            return;
        }
    }
    
    if ( @_ && @_ % 2 ) {
        croak("You passed in an uneven list of values, "
            . "but that doesn't make sense");
    }
    
    while (@_) {
        my ($name, $proto) = splice(@_, 0, 2);
        if (grep !defined, $name, $proto) {
           croak("Both the function name and the "
               . "pseudo-prototype must be defined");
        }

        my $coderef;
        if ( (ref($name) || "") eq 'CODE' ) {
            $coderef = $name;
        }
        else {
            if ($name !~ /::/) {
               $name = $caller . "::" . $name;
            }
 
            my $glob = do { no strict 'refs'; \*{$name} };
 
            # Predeclare the sub if it doesn't exist. This allows
            # people to write
            # use Params::Lazy foo => ...;
            # ...
            # sub foo { ... }
            # That is, to have the 'use' line on top as usual,
            # and later on the body of the function.
            if ( !*{$glob}{CODE} ) {
                *{$glob} = do { no strict 'refs'; \&{$name} };
            }
            
            $coderef = *{$glob}{CODE};
        }
        
        Params::Lazy::cv_set_call_checker_delay($coderef, $proto);
    }

    $self->export_to_level(1);
}

sub unimport {
    shift;
    $^H{$hint_key} = 1;
}

=encoding utf8

=head1 NAME

Params::Lazy - Transparent lazy arguments for subroutines.

=head1 VERSION

Version 0.005

=head1 SYNOPSIS

    use Params::Lazy delay => '^';
    sub delay {
        say "One";
        force $_[0];
        say "Three";
    }

    delay say "Two"; # Will output One, Two, Three

    use Params::Lazy fakemap => '^@';
    sub fakemap {
       my $delayed = shift;
       my @retvals;
       push @retvals, force $delayed for @_;
       return @retvals;
    }

    my @goodies = fakemap "<$_>", 1..10; # same as map "<$_>", 1..10;
    ...
    
    use Params::Lazy fakegrep => ':@';
    sub fakegrep (&@) {
        my $delayed = shift;
        my $coderef = ref($delayed) eq 'CODE';
        my @retvals;
        for (@_) {
            if ($coderef ? $delayed->() : force $delayed) {
                push @retvals, $_;
            }
        }
        return @retvals;
    }
    
    say fakegrep { $_ % 2 } 9, 16, 25, 36;
    say fakegrep   $_ % 2,  9, 16, 25, 36;

=head1 DESCRIPTION

The Params::Lazy module provides a way to transparently create lazy
arguments for a function, without the callers being aware that anything
unusual is happening under the hood.

You can enable lazy arguments using this module and specifying the
function name and a prototype-looking string as the functions to "export".

That pseudo-prototype allows all the characters normally present in a
prototype, plus two new options: A caret (C<^>), which means "make this
argument lazy", and a colon (C<:>), which will be explained later.

When a function with lazy magic is called, instead of receiving the
result of whatever expression the caller specified, the delayed argument
will instead show up as a simple scalar reference in C<@_>.
Only after you pass that reference to C<force()> will the delayed
expression be run.

By default, delayed arguments will see the C<@_> of the context
they were delayed in.  While this is generally the most desirable behavior,
it makes delayed arguments slightly slower, so you can switch to using
the current C<@_> by B<defining> the delaying function under
the scope of C<no Params::Lazy 'caller_args'>; that is, you must do this:

    {
        no Params::Lazy 'caller_args';
        use Params::Lazy foo => q(^^);
        ...
    }

For the sake of sanity, it's not recommended that you define a function
under no-caller-args, but then enable those again inside the function
and then use C<&force> (note the C<&>).

The colon (C<:>) is special cased to work with the C<&> prototype. 
The gist of it is that, if the expression is something that the
C<&> prototype would allow, it stays out of the way and gives you that.
Otherwise, it gives you a delayed argument you can use with C<force()>.

=head1 EXPORT

=head2 force $delayed

Runs the delayed code.

=head1 LIMITATIONS AND CAVEATS

=over

=item *

When using the C<:> prototype, these two cases are indistinguishable:

    myfunction { ... }
    myfunction sub { ... }

Which means that C<mymap sub { ... }, 1..10> will work
differently than the default map.

=item *

It's important to note that delayed arguments are C<*not*> closures,
so storing them for later use will likely lead to crashes, segfaults,
and a general feeling of malignancy to descend upon you, your family,
and your cat.  Passing them to other functions should work fine, but
returning them to the place where they were delayed is generally a
bad idea.

=item *

On Perl 5.8, throwing an exception within a delayed eval does not
generally work properly, and, if running with C<$ENV{PERL_DESTRUCT_LEVEL}>
set to anything but 0, causes Segfaults during global destruction.

=item *

There's a bug in Perls older than 5.14 that makes delaying a regular
expression likely to crash the program.

=item *

Threading support is experimental.  It should behave slightly better
on Perls 5.18 and newer.

=item *

As of version 0.005, the 'caller arguments' feature doesn't work
if you're passing a delayed argument to another delayed function:

    use Params::Lazy qw( delay_1 ^$ delay_2 ^$ );
    sub delay_1 { my $delayed = shift; delay_2 expr(), $delayed }
    sub delay_2 { my ($d1, $d2) = @_; force $d2 }

    sub {
        delay_1(
            warn("I should see the original \@_: <@_>"),
            "delay_2 should see this"
        );
    }->('delay_1 should see this');
    
This is because currently, the 'delayed argument' magic is attached
to the delaying function, rather than the delayed argument. 
This will be fixed in future releases.
    
=item *

Finally, while delayed arguments are intended to be faster & more 
lightweight than passing coderefs, are at best just as fast, and
generally anywhere between 5% and 100% B<slower> than passing a
coderef and dereferencing it, so beware!

=back

=head1 PREREQUISITES

Perl 5.14.0 or higher, although 5.18.0 is recommended to get the most
stable behavior.  The module will build and test fine as far back as 5.8.8,
but some operations are either unstable or plain dangerous; for example,
delaying a regular expression might cause the program to crash in 5.10,
and trying to C<goto LABEL> out of a delayed expression in 5.8 will cause
all sorts of unexpected behavior.

Devel::CallChecker 0.005 or higher, for perl versions earlier than 5.14.

Exporter 5.58 or higher.

=head1 AUTHOR, LICENSE AND COPYRIGHT

Copyright 2013 Brian Fraser, C<< <fraserbn at gmail.com> >>

This program is free software; you may redistribute it and/or modify it under the same terms as perl.

=head1 ACKNOWLEDGEMENTS

To Scala for the inspiration, to p5p in general for holding my hand as I
stumbled through the callchecker, and to Zefram for L<Devel::CallChecker>
and spotting a leak.

=cut

1; # End of Params::Lazy
