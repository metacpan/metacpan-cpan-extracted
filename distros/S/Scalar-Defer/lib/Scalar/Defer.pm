package Scalar::Defer;

use 5.006;
use strict;
use warnings;

BEGIN {
    our $VERSION   = '0.23';
    our @EXPORT    = qw( lazy defer force );
    our @EXPORT_OK = qw( is_deferred );
}

use Scalar::Util;
use Exporter::Lite;
use Class::InsideOut qw( register id );
use constant DEFER_PACKAGE => '0'; # This may change soon

BEGIN {
    my %_defer;

    sub defer (&) {
        my $cv  = shift;
        my $obj = register( bless(\(my $id) => __PACKAGE__) );
        $_defer{ $id = id $obj } = $cv;
        bless($obj => DEFER_PACKAGE);
    }

    sub lazy (&) {
        my $cv  = shift;
        my $obj = register( bless(\(my $id) => __PACKAGE__) );

        my ($value, $forced);
        $_defer{ $id = id $obj } = sub {
            $forced ? $value : scalar(++$forced, $value = &$cv)
        };

        bless $obj => DEFER_PACKAGE;
    }

    sub DEMOLISH {
        delete $_defer{ id $_[0] };
    }

    sub is_deferred ($) {
        no warnings 'uninitialized';
        ref $_[0] eq DEFER_PACKAGE;
    }

    use constant SUB_FORCE => sub ($) {
        no warnings 'uninitialized';
        &{
            $_defer{ id $_[0] } ||= $_defer{do {
                #
                # The memory address was dislocated.  Fortunately, its original
                # refaddr is saved directly inside the scalar referent slot.
                #
                # So we remove the overload by blessing into UNIVERSAL, get the
                # original refaddr back, and register it with ||= above to avoid
                # doing the same thing next time. (Afterwards we rebless it back.)
                # 
                # This of course assumes that nobody overloads ${} for UNIVERSAL
                # (which will naturally break all objects using scalar-ref layout);
                # if someone does, that someone is more crazy than we are and should
                # be able to handle the consequences.
                #
                my $self = $_[0];
                ref($self) eq DEFER_PACKAGE or return $self;

                bless($self => 'UNIVERSAL');
                my $id = $$self;
                bless($self => DEFER_PACKAGE);
                $id;
            }} or do {
                return 0 if caller eq 'Class::InsideOut';
                die sprintf("Cannot locate thunk for memory address: 0x%X", id $_[0]);
            };
        };
    };

    *force = SUB_FORCE();
}

BEGIN {
    package Scalar::Defer::Deferred;
    use overload (
        fallback => 1, map {
            $_ => Scalar::Defer::SUB_FORCE(),
        } qw( bool "" 0+ ${} @{} %{} &{} *{} )
    );

    sub AUTOLOAD {
        my $meth = our $AUTOLOAD;
        my $idx  = index($meth, '::');

        if ($idx >= 0) {
            $meth = substr($meth, $idx + 2);
        }

        unshift @_, Scalar::Defer::SUB_FORCE()->(shift(@_));
        goto &{$_[0]->can($meth)};
    };

    {
        foreach my $sym (grep {
             $_ ne 'DESTROY' and $_ ne 'DEMOLISH' and $_ ne 'BEGIN'
         and $_ ne 'END' and $_ ne 'AUTOLOAD' and $_ ne 'CLONE_SKIP'
        } keys %UNIVERSAL::) {
            my $code = q[
                sub $sym {
                    if ( defined Scalar::Util::blessed($_[0]) ) {
                        unshift @_, Scalar::Defer::SUB_FORCE()->(shift(@_));
                        goto &{$_[0]->can("$sym")};
                    }
                    else {
                        # Protect against future ALLCAPS methods
                        return if $_[0] eq Scalar::Defer::DEFER_PACKAGE;

                        return shift->SUPER::$sym(@_);
                    }
                }
            ];

            $code =~ s/\$sym/$sym/g;

            local $@;
            eval $code;
            warn $@ if $@;
        }

        *DESTROY  = \&Scalar::Defer::DESTROY;
        *DEMOLISH = \&Scalar::Defer::DEMOLISH;
    }
}

BEGIN {
    no strict 'refs';
    @{DEFER_PACKAGE().'::ISA'} = ('Scalar::Defer::Deferred');
}

1;

__END__

=head1 NAME

Scalar::Defer - Lazy evaluation in Perl

=head1 SYNOPSIS

    use Scalar::Defer; # exports 'defer', 'lazy' and 'force'

    my ($x, $y);
    my $dv = defer { ++$x };    # a deferred value (not memoized)
    my $lv = lazy { ++$y };     # a lazy value (memoized)

    print "$dv $dv $dv"; # 1 2 3
    print "$lv $lv $lv"; # 1 1 1

    my $forced = force $dv;     # force a normal value out of $dv

    print "$forced $forced $forced"; # 4 4 4

=head1 DESCRIPTION

This module exports two functions, C<defer> and C<lazy>, for constructing
values that are evaluated on demand.  It also exports a C<force> function
to force evaluation of a deferred value.

=head2 defer {...}

Takes a block or a code reference, and returns a deferred value.
Each time that value is demanded, the block is evaluated again to
yield a fresh result.

=head2 lazy {...}

Like C<defer>, except the value is computed at most once.  Subsequent
evaluation will simply use the cached result.

=head2 force $value

Force evaluation of a deferred value to return a normal value.
If C<$value> was already a normal value, then C<force> simply returns it.

=head2 is_deferred $value

Tells whether the argument is a deferred value or not. (Lazy values are
deferred too.)

The C<is_deferred> function is not exported by default; to import it, name
it explicitly in the import list.

=head1 NOTES

Deferred values are not considered objects (C<ref> on them returns C<0>),
although you can still call methods on them, in which case the invocant
is always the forced value.

Unlike the C<tie>-based L<Data::Lazy>, this module operates on I<values>,
not I<variables>.  Therefore, assigning another value into C<$dv> and C<$lv>
above will simply replace the value, instead of triggering a C<STORE> method
call.

Similarily, assigning C<$dv> or C<$dv> into another variable will not trigger
a C<FETCH> method, but simply propagates the deferred value over without
evaluationg.  This makes it much faster than a C<tie>-based implementation
-- even under the worst case scenario, where it's always immediately forced
after creation, this module is still twice as fast than L<Data::Lazy>.

=head1 CAVEATS

Bad things may happen if this module interacts with any other code which
fiddles with package C<0>.

Performance of creating new deferred or lazy values can be quite poor
under perl 5.8.9.  This is due a bugfix since 5.8.8, where re-blessing
an overloaded object caused bad interactions with other references to
the same value.  5.8.9's solution involves walking the arenas to find
all other references to the same object, which can cause C<bless> (and
thus L<Scalar::Defer/defer> to be up to three orders of magnitude
slower than usual.  perl 5.10.0 and higher do not suffer from this
problem.

=head1 SEE ALSO

L<Data::Thunk>, which implements C<lazy> values that can replace itself
upon forcing, leaving a minimal trace of the thunk, with some sneaky XS
magic in L<Data::Swap>.

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2006, 2007, 2008, 2009 by Audrey Tang <cpan@audreyt.org>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
