package Struct::Path::JsonPointer;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use Carp 'croak';
use Scalar::Util 'looks_like_number';

our @EXPORT_OK = qw(
    path2str
    str2path
);

=head1 NAME

Struct::Path::JsonPointer - JsonPointer (L<rfc6901|https://tools.ietf.org/html/rfc6901>)
syntax frontend for L<Struct::Path|Struct::Path>

=begin html

<a href="https://travis-ci.org/mr-mixas/Struct-Path-JsonPointer.pm"><img src="https://travis-ci.org/mr-mixas/Struct-Path-JsonPointer.pm.svg?branch=master" alt="Travis CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Struct-Path-JsonPointer.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Struct-Path-JsonPointer.pm/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/Struct-Path-JsonPointer"><img src="https://badge.fury.io/pl/Struct-Path-JsonPointer.svg" alt="CPAN version"></a>

=end html

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Struct::Path qw(path);
    use Struct::Path::JsonPointer qw(str2path);

    my $data = {
        "foo"   => ["bar", "baz"],
        ""      => 0,
        "a/b"   => 1,
        "c%d"   => 2,
        "e^f"   => 3,
        "g|h"   => 4,
        "i\\j"  => 5,
        "k\"l"  => 6,
        " "     => 7,
        "m~n"   => 8
    };

    my ($found) = path($data, str2path('/foo/0'), deref => 1);
    print $found; # 'bar'

=head1 EXPORT

Nothing is exported by default.

=head1 SUBROUTINES

=head2 path2str

Convert L<Struct::Path|Struct::Path> path to JsonPointer.

    $pointer = path2str($path);

=cut

sub path2str {
    croak "Arrayref expected for path" unless (ref $_[0] eq 'ARRAY');

    my $str = '';
    my $i = 0;

    for my $step (@{$_[0]}) {
        if (ref $step eq 'ARRAY') {
            croak "Only one array index allowed, step #$i"
                if (@{$step} != 1);

            unless (
                looks_like_number($step->[0])
                and int($step->[0]) == $step->[0]
            ) {
                croak "Incorrect array index, step #$i";
            }

            $str .= "/$step->[0]";
        } elsif (ref $step eq 'HASH') {
            croak "Only keys allowed for hashes, step #$i"
                unless (keys %{$step} == 1 and exists $step->{K});

            croak "Incorrect hash keys format, step #$i"
                unless (ref $step->{K} eq 'ARRAY');

            croak "Only one hash key allowed, step #$i"
                unless (@{$step->{K}} == 1);

            my $key = $step->{K}->[0];
            $key =~ s|~|~0|g;
            $key =~ s|/|~1|g;

            $str .= "/$key";
        } else {
            croak "Unsupported thing in the path, step #$i";
        }

        $i++;
    }

    return $str;
}

=head2 str2path

Convert JsonPointer to L<Struct::Path|Struct::Path> path.

    $path = str2path($pointer);

=cut

# some steps (numbers, dash) should be evaluated using structure
sub _hook {
    my ($step, $last) = @_;

    return sub {
        if (ref $_ eq 'ARRAY') {
            if ($step eq '-') {
                $step = @{$_}; # Hyphen as array index should append new item
            } else {
                croak "Incorrect array index, step #" . @{$_[0]}
                    unless ($step eq abs(int($step)));

                croak "Index is out of range, step #" . @{$_[0]}
                    if ($step > ($_{opts}->{expand} ? @{$_} : $#{$_}));
            }

            splice @{$_}, $step, 0, undef if ($last and $_{opts}->{insert});

            push @{$_[0]}, [$step]; # update path
            push @{$_[1]}, \$_->[$step]; # update refs stack

            splice @{$_}, $step, 1 if ($last and $_{opts}->{delete});

        } elsif (ref $_ eq 'HASH') {
            croak "'$step' key doesn't exist, step #" . @{$_[0]}
                unless (exists $_->{$step} or $_{opts}->{expand});

            push @{$_[0]}, {K => [$step]}; # update path
            push @{$_[1]}, \$_->{$step}; # update refs stack
        } else {
            croak "Structure doesn't match, step #" . @{$_[0]};
        }

        return 1;
    }
};

sub str2path {
    croak "Undefined JSON Pointer passed" unless (defined $_[0]);

    my @steps = split('/', $_[0], -1);

    croak "JSON Pointer should start with a slash or be empty"
        if (shift @steps and substr($_[0], 0, 1) ne '/');

    my @path;

    for (@steps) {
        if (looks_like_number($_) or $_ eq '-') {
            push @path, _hook($_, @path == $#steps);
        } else { # hash
            s|~1|/|g;
            s|~0|~|g;

            push @path, {K => [$_]};
        }
    }

    return \@path;
}

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-struct-path-jsonpointer at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path-JsonPointer>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Path::JsonPointer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Path-JsonPointer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Struct-Path-JsonPointer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Struct-Path-JsonPointer>

=item * Search CPAN

L<http://search.cpan.org/dist/Struct-Path-JsonPointer/>

=back

=head1 SEE ALSO

L<JSON::Pointer>, L<rfc6901|https://tools.ietf.org/html/rfc6901>

L<Struct::Path>, L<Struct::Path::PerlStyle>, L<Struct::Diff>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path::JsonPointer
