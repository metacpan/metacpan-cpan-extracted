package Sub::Fp;
use strict;
use warnings;
use List::Util;
use Data::Dumper qw(Dumper);
use Exporter qw(import);
our @EXPORT_OK = qw(
    map         inc     freduce     flatten
    drop_right  drop    take_right  take
    assoc       fmap    dec         chain
    first       latest  subarray    partial
    __          find    filter      some
    none        uniq    bool        spread every
    len         to_keys to_vals     is_array
    is_hash
);

our $VERSION = '0.01';

use constant ARG_PLACE_HOLDER => {};

sub __ { ARG_PLACE_HOLDER };

# -----------------------------------------------------------------------------#

#TODO unit tests
sub is_array{
    my $coll = shift;

    return bool(ref $coll eq 'ARRAY');
}

#TODO unit tests
sub is_hash {
    my $coll = shift;

    return bool(ref $coll eq 'HASH');
}

#TODO unit tests FOR HASH AND ARRAY
sub to_keys {
    my $coll = shift;

    if (is_array($coll)) {
        return [keys @{ $coll }]
    }

    if (is_hash) {
        return [keys %{ $coll }];
    }
}

sub len {
    my $coll  = shift;

    if (ref $coll eq 'ARRAY') {
        return scalar spread($coll);
    }

    if (ref $coll eq 'HASH') {
        return to_keys($coll);
    }

    return length($coll);
}

#TODO unit tests;
sub is_empty {
    my $coll = shift;
    return bool(len($coll) == 0);
}

#TODO unit tests FOR HASH AND ARRAY AND OTHER!
sub to_vals {
    my $coll = shift;

    if (is_array($coll)) {
        return [values @{ $coll }]
    }

    if (is_hash($coll)) {
        return [values %{ $coll }];
    }
}

sub uniq {
    my $coll = shift;

    my @vals = do {
        my %seen;
        grep { !$seen{$_}++ } @$coll;
    };

    return [@vals];
}

sub find {
    my $fn   = shift;
    my $coll = shift // [];

    return List::Util::first {
        $fn->($_)
    } @$coll;
}

sub filter {
    my $fn   = shift;
    my $coll = shift // [];

    return [grep { $fn->($_) } @$coll];
}

sub some {
    my $fn   = shift;
    my $coll = shift // [];

    return find($fn, $coll) ? 1 : 0
}

sub every {
    my $fn   = shift;
    my $coll = shift // [];

    my $bool = List::Util::all {
        $fn->($_);
    } @$coll;

    return $bool ? 1 : 0;
}

sub none {
    my $fn   = shift;
    my $coll = shift // [];

    my $bool = List::Util::none {
        $fn->($_)
    } @$coll;

    return $bool ? 1 : 0;
}

sub inc {
    my $num = shift;
    return $num + 1;
}

sub dec {
    my $num = shift;
    return $num - 1;
}

sub first {
    my $coll = shift;
    return @$coll[0];
}

sub latest {
    my $coll = shift // [];
    my $len = scalar @$coll;

    return @$coll[$len - 1 ];
}

sub flatten {
    my $coll = shift;

    return [
        map {
            ref $_ ? @{$_} : $_;
        } @$coll
    ];
}

sub drop {
    my $coll = shift || [];
    my $count = shift // 1;
    my $len   = scalar @$coll;

    return [@$coll[$count .. $len - 1]];
}

sub drop_right {
    my $coll  = shift || [];
    my $count = shift // 1;
    my $len   = scalar @$coll;

    return [@$coll[0 .. ($len - ($count + 1))]];
}

sub take {
    my $coll  = shift || [];
    my $count = shift // 1;
    my $len   = scalar @$coll;

    if (!$len) {
        return [];
    }

    return [@$coll[0 .. $count - 1]];
}

sub take_right {
    my $coll  = shift || [];
    my $count = shift // 1;
    my $len   = scalar @$coll;

    if (!$len) {
        return [];
    }

    return [@$coll[($len - $count) .. ($len - 1)]];
}

sub assoc {
    my ($obj, $key, $item) = @_;

    if (!defined $key) {
        return $obj;
    }

    if (ref $obj eq 'ARRAY') {
        return [
            @{(take($obj, $key))},
            $item,
            @{(drop($obj, $key + 1))},
        ];
    }

    return {
        %{ $obj },
        $key => $item,
    };
}

sub fmap {
    my $func = shift;
    my $coll = shift;

    my $idx = 0;

    my @vals = map {
      $idx++;
      $func->($_, $idx - 1, $coll);
    } @$coll;

    return [@vals];
}

sub freduce {
    my $func           = shift;
    my ($accum, $coll) = spread(_get_freduce_args([@_]));

    my $idx = 0;

    return List::Util::reduce {
        my ($accum, $val) = ($a, $b);
        $idx++;
        $func->($accum, $val, $idx - 1, $coll);
    } ($accum, @$coll);
}

sub _get_freduce_args {
    my $args = shift;

    if (equal(len($args), 1)) {
        return chain(
            $args,
            \&flatten,
            sub {
                return [first($_[0]), drop($_[0])]
            }
        )
    }

    return [first($args), flatten(drop($args))];
}

sub partial {
    my $func    = shift;
    my $oldArgs = [@_];

    return sub {
        my $newArgs = [@_];
        my $no_placeholder_args = _fill_holders($oldArgs, $newArgs);
        return $func->(@$no_placeholder_args);
    }
}

#TODO DO this without mutation?
sub _fill_holders {
    my ($oldArgs, $newArgs) = @_;

    if (none(sub { equal($_[0], __) }, $oldArgs)) {
        return [@$oldArgs, @$newArgs];
    }

    return fmap(sub {
        my ($oldArg, $idx) = @_;
        return equal($oldArg, __) ? (shift @{ $newArgs }) : $oldArg;
    }, $oldArgs);
}

sub subarray {
    my $coll  = shift || [];
    my $start = shift;
    my $end   = shift // scalar @$coll;

    if (!$start) {
        return $coll;
    }

    if ($start == $end) {
        return [];
    }

    return [
       @$coll[$start .. ($end - 1)],
    ];
}

sub chain {
    no warnings 'once';
    my ($val, @funcs) = @_;

    return List::Util::reduce {
        my ($accum, $func) = ($a, $b);
        $func->($accum);
    } (ref($val) eq 'CODE' ? $val->() : $val), @funcs;
}

#TODO write le unit tests
sub equal {
    my ($arg1, $arg2) = @_;

    if (ref $arg1 ne ref $arg2) {
        return 0;
    }

    if(ref $arg1 eq 'String' &&
       ref $arg2 eq 'String') {
        return bool($arg1 eq $arg2);
    }

    return bool($arg1 == $arg2);
}

#TODO Unit Tests
sub bool {
    my ($val) = @_;

    return $val ? 1 : 0;
}

#TODO Unit tests, WORKS FOR STRINGS?
sub spread {
    my $coll = shift // [];

    if (ref $coll eq 'ARRAY') {
        return @{ $coll };
    }

    if (ref $coll eq 'HASH') {
        return %{ $coll }
    }

    return split('', $coll);
}

=head1 NAME

Sub::Fp - The great new Sub::Fp!

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Sub::Fp;

    my $foo = Sub::Fp->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function2

=cut

=head1 AUTHOR

Kristopher C. Paulsen, C<< <kristopherpaulsen+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-fp at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Fp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Fp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Fp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sub-Fp>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sub-Fp>

=item * Search CPAN

L<https://metacpan.org/release/Sub-Fp>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Kristopher C. Paulsen.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
