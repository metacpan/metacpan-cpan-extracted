package String::Elide::Parts;

our $DATE = '2017-01-29'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(elide);

sub _elide_part {
    my ($str, $len, $marker, $truncate) = @_;

    my $len_marker = length($marker);
    if ($len <= $len_marker) {
        return substr($marker, 0, $len);
    }

    if ($truncate eq 'left') {
        return $marker . substr($str, length($str) - $len+$len_marker);
    } elsif ($truncate eq 'middle') {
        my $left  = substr($str, 0,
                           ($len-$len_marker)/2);
        my $right = substr($str,
                           length($str) - ($len-$len_marker-length($left)));
        return $left . $marker . $right;
    } elsif ($truncate eq 'ends') {
        if ($len <= 2*$len_marker) {
            return substr($marker . $marker, 0, $len);
        }
        return $marker . substr($str, (length($str)-$len)/2 + $len_marker,
                                $len-2*$len_marker) . $marker;
    } else { # right
        return substr($str, 0, $len-$len_marker) . $marker;
    }
}

sub elide {
    my ($str, $len, $opts) = @_;

    $opts //= {};
    my $truncate  = $opts->{truncate} // 'right';
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
    for my $i (0..@parts-1) {
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
        $all_parts_len += length($_) for @parts;

        # total len of all parts is short enough, we're done
        if ($all_parts_len <= $len) {
            return join("", @parts);
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
                $high_parts_len += length $parts[$i];
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

        # after this position, must elide a total of this number of characters
        # after this position
        my @must_elide_total_len_after_this;
        my $tot_to_elide = $all_parts_len - $len;
        for my $i (0..$#high_indexes) {
            $must_elide_total_len_after_this[$i] =
                int( ($i+1)/@high_indexes * $tot_to_elide );
        }
        #use DD; dd \@must_elide_total_len_after_this;

        # calculate how many characters to truncate for each part
        my $tot_already_elided = 0;
        my $tot_still_to_elide = 0;
        for my $i (reverse 0..$#high_indexes) {
            my $idx = $high_indexes[$i];
            my $part_len = length $parts[$idx];
            my $to_elide = $must_elide_total_len_after_this[$#high_indexes - $i] -
                $tot_already_elided;
            #say "D:[", ($i+1), "/", ~~@high_indexes, "] must_elide_total_len_after_this=", $must_elide_total_len_after_this[$#high_indexes-$i], " to_elide=$to_elide";
            if ($to_elide <= 0) {
                # leave this part alone
                #say "D:  leave alone <$parts[$idx]>";
            } elsif ($part_len <= $to_elide) {
                # we need to eliminate this part
                #say "D:  eliminate <$parts[$idx]>";
                splice @parts, $idx, 1;
                splice @parts_attrs, $idx, 1;
                $tot_already_elided += $part_len;
                $tot_still_to_elide += ($to_elide - $part_len);
                #say "D:  tot_already_elided=$tot_already_elided, tot_still_to_elide=$tot_still_to_elide";
            } else {
                #say "D:  elide <$parts[$idx]>";
                $parts[$idx] = _elide_part(
                    $parts[$idx],
                    $part_len - $to_elide,
                    $parts_attrs[$idx]{marker} // $marker,
                    $parts_attrs[$idx]{truncate} // $truncate,
                );
                #say "D:  elide result <$parts[$idx]>";
                $tot_already_elided += $to_elide;
                $tot_still_to_elide = 0;
                #say "D:  tot_already_elided=$tot_already_elided, tot_still_to_elide=$tot_still_to_elide";
            }
        }

    } # while 1
}

1;
# ABSTRACT: Elide a string with multiple parts of different priorities

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Elide::Parts - Elide a string with multiple parts of different priorities

=head1 VERSION

This document describes version 0.07 of String::Elide::Parts (from Perl distribution String-Elide-Parts), released on 2017-01-29.

=head1 SYNOPSIS

 use String::Elide::Parts qw(elide);

Eliding string with no parts:

 my $text = "this is your brain";
 #                                            0----5---10---15---20
 elide($text, 16);                       # -> "this is your ..."
 elide($text, 16, {truncate=>"left"});   # -> "...is your brain"
 elide($text, 16, {truncate=>"middle"}); # -> "this is... brain"
 elide($text, 16, {truncate=>"ends"});   # -> "... is your b..."

 elide($text, 16, {marker=>"--"});       # -> "this is your b--"

Eliding string with multiple parts marked with markup. We want to elide URL
first (prio=3), then the C<Downloading> text (prio=2), then the speed (prio=1,
default):

 $text = "<elspan prio=2>Downloading</elspan> <elspan prio=3 truncate=middle>http://www.example.com/somefile</elspan> 320.0k/5.5M";
 #                      0----5---10---15---20---25---30---35---40---45---50---55---60
 elide($text, 56); # -> "Downloading http://www.example.com/somefile 320.0k/5.5M"
 elide($text, 55); # -> "Downloading http://www.example.com/somefile 320.0k/5.5M"
 elide($text, 50); # -> "Downloading http://www.e..com/somefile 320.0k/5.5M"
 elide($text, 45); # -> "Downloading http://ww..m/somefile 320.0k/5.5M"
 elide($text, 40); # -> "Downloading http://..omefile 320.0k/5.5M"
 elide($text, 35); # -> "Downloading http..efile 320.0k/5.5M"
 elide($text, 30); # -> "Downloading ht..le 320.0k/5.5M"
 elide($text, 25); # -> "Downloading . 320.0k/5.5M"
 elide($text, 24); # -> "Downloading  320.0k/5.5M"
 elide($text, 23); # -> "Download..  320.0k/5.5M"
 elide($text, 20); # -> "Downl..  320.0k/5.5M"
 elide($text, 15); # -> "..  320.0k/5.5M"
 elide($text, 13); # -> "  320.0k/5.5M"
 elide($text, 10); # -> " 320.0k/.."
 elide($text,  5); # -> " 32.."
 #                      0----5---10---15---20---25---30---35---40---45---50---55---60

=head1 DESCRIPTION

String::Elide::Parts is similar to other string eliding modules, with one main
difference: it accepts string marked with parts of different priorities. The
goal is to retain more important information as much as possible when length is
reduced.

=head1 FUNCTIONS

=head2 elide($str, $len[, \%opts]) => str

Elide a string if length exceeds C<$len>.

String can be marked with C<< <elspan prio=N truncate=T marker=M>...</elspan> >>
so there can be multiple parts with different priorities and truncate direction.
The default priority is 1. You can mark less important strings with higher
priority to let it be elided first. The markup will be removed from the string
before eliding.

Known options:

=over

=item * marker => str (default: '..')

=item * truncate => 'left'|'middle'|'middle'|'ends' (default: 'right')

=item * default_prio => int (default: 1)

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Elide-Parts>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Elide-Parts>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Elide-Parts>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head2 Similar elide modules

L<Text::Elide> is simple, does not have many options, and elides at word
boundaries.

L<String::Truncate> has similar interface like String::Elide::Parts and has some
options.

L<String::Elide::Lines> is based on this module but works on a line-basis.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
