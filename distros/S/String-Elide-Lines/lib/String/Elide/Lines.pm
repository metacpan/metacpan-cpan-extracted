package String::Elide::Lines;

our $DATE = '2017-01-29'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(elide);

sub _elide_lines {
    my ($lines, $len, $marker, $truncate) = @_;

    $marker = ["$marker\n"] unless ref $marker eq 'ARRAY';

    if (@$lines <= $len) {
        return $lines;
    }

    my $len_marker = @$marker;
    if ($len <= $len_marker) {
        return [ @{$marker}[0..$len-1] ];
    }

    if ($truncate eq 'top') {
        return [ @$marker, @{$lines}[(@$lines - $len + $len_marker) .. $#$lines] ];
    } elsif ($truncate eq 'middle') {
        my @top_lines  = @{$lines}[0 .. ($len-$len_marker)/2-1];
        my @bottom_lines = @{$lines}[(@$lines - ($len-$len_marker-@top_lines)) .. $#$lines];
        return [ @top_lines, @$marker, @bottom_lines ];
    } elsif ($truncate eq 'ends') {
        if ($len <= 2*$len_marker) {
            my @marker2 = (@$marker, @$marker);
            return [@marker2[0..$len-1]];
        }
        my $offset = (@$lines-$len)/2 + $len_marker;
        return [ @$marker, @{$lines}[$offset .. $offset + ($len-2*$len_marker)-1], @$marker ];
    } else { # bottom
        return [ @{$lines}[0 .. $len-$len_marker-1], @$marker ];
    }
}

sub elide {
    my ($str, $len, $opts) = @_;

    $opts //= {};
    my $truncate  = $opts->{truncate} // 'bottom';
    my $marker = $opts->{marker} // '..';
    my $default_prio = $opts->{default_prio} // 1;

    # split into parts by priority
    my @parts;
    my @parts_attrs;
    while ($str =~ m#<elspan([^>]*)>(.*?)</elspan>|(.*?)(?=<elspan)|(.*)#gs) {
        if (defined $1) {
            next unless length $2;
            push @parts, $2;
            push @parts_attrs, $1;
        } elsif (defined $3) {
            next unless length $3;
            push @parts, $3;
            push @parts_attrs, undef;
        } elsif (defined $4) {
            next unless length $4;
            push @parts, $4;
            push @parts_attrs, undef;
        }
    }
    return "" unless @parts && $len > 0;
    for my $i (0..$#parts) {
        $parts[$i] = [split /^/, $parts[$i]];
        if (defined $parts_attrs[$i]) {
            my $attrs = {};
            $attrs->{truncate} = $1 // $2
                if $parts_attrs[$i] =~ /\btruncate=(?:"([^"]*)"|(\S+))/;
            $attrs->{marker} = $1 // $2
                if $parts_attrs[$i] =~ /\bmarker=(?:"([^"]*)"|(\S+))/;
            $attrs->{prio} = $1 // $2
                if $parts_attrs[$i] =~ /\bprio(?:rity)?=(?:"([^"]*)"|(\S+))/;
            $parts_attrs[$i] = $attrs;
        } else {
            $parts_attrs[$i] = {prio=>$default_prio};
        }
    }

    #use DD; dd \@parts; dd \@parts_attrs;

    # elide and truncate prio by prio until str is short enough
  PRIO:
    while (1) {
        # (re)calculate total len of all parts
        my $all_parts_len = 0;
        $all_parts_len += @$_ for @parts;

        # total len of all parts is short enough, we're done
        if ($all_parts_len <= $len) {
            return join("", map { join "", @$_ } @parts);
        }

        # we still need to elide some parts. first collect part indexes that
        # have the current largest priority.
        my $highest_prio;
        for (@parts_attrs) {
            $highest_prio = $_->{prio} if !defined($highest_prio) ||
                $highest_prio < $_->{prio};
        }
        my @high_indexes;
        my $high_parts_len = 0;
        for my $i (0..$#parts_attrs) {
            if ($parts_attrs[$i]{prio} == $highest_prio) {
                $high_parts_len += @{ $parts[$i] };
                push @high_indexes, $i;
            }
        }

        if ($all_parts_len - $high_parts_len >= $len) {
            # we need to fully eliminate all the highest parts part then search
            # for another set of parts
            for (reverse @high_indexes) {
                splice @parts, $_, 1;
                splice @parts_attrs, $_, 1;
                next PRIO;
            }
        }

        # elide all to-be-elided parts equally

        # after this position, must elide a total of this number of lines after
        # this position
        my @must_elide_total_len_after_this;
        my $tot_to_elide = $all_parts_len - $len;
        for my $i (0..$#high_indexes) {
            $must_elide_total_len_after_this[$i] =
                int( ($i+1)/@high_indexes * $tot_to_elide );
        }
        # calculate how many characters to truncate for each part
        my $tot_already_elided = 0;
        my $tot_still_to_elide = 0;
        for my $i (reverse 0..$#high_indexes) {
            my $idx = $high_indexes[$i];
            my $part_len = @{ $parts[$idx] };
            my $to_elide = $must_elide_total_len_after_this[$#high_indexes - $i] -
                $tot_already_elided;
            if ($to_elide <= 0) {
                # leave this part alone
            } elsif ($part_len <= $to_elide) {
                # we need to eliminate this part
                splice @parts, $idx, 1;
                splice @parts_attrs, $idx, 1;
                $tot_already_elided += $part_len;
                $tot_still_to_elide += ($to_elide - $part_len);
            } else {
                $parts[$idx] = _elide_lines(
                    $parts[$idx],
                    $part_len - $to_elide,
                    $parts_attrs[$idx]{marker} // $marker,
                    $parts_attrs[$idx]{truncate} // $truncate,
                );
                $tot_already_elided += $to_elide;
                $tot_still_to_elide = 0;
            }
        }

    } # while 1
}

1;
# ABSTRACT: Elide lines from a string, with options

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Elide::Lines - Elide lines from a string, with options

=head1 VERSION

This document describes version 0.003 of String::Elide::Lines (from Perl distribution String-Elide-Lines), released on 2017-01-29.

=head1 SYNOPSIS

 use String::Elide::Lines qw(elide);

=head1 DESCRIPTION

String::Elide::Lines is based on L<String::Elide::Parts> but works on a per-line
basis.

=head1 FUNCTIONS

=head2 elide($str, $len[, \%opts]) => str

Elide lines from a string if the string contains more than C<$len> lines.

String can be marked with C<< <elspan prio=N truncate=T marker=M>...</elspan> >>
so there can be multiple parts with different priorities and truncate direction.
The default priority is 1. You can mark less important lines with higher
priority to let it be elided first. The markup will be removed from the string
before eliding.

Known options:

=over

=item * marker => str (default: '..')

=item * truncate => 'top'|'middle'|'bottom'|'ends' (default: 'bottom')

=item * default_prio => int (default: 1)

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Elide-Lines>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Elide-Lines>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Elide-Lines>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<String::Elide::Parts> is the basis of this module but works on a per-character
basis. See that module's SEE ALSO for list of other string eliding modules.

L<Pod::Elide> uses this module.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
