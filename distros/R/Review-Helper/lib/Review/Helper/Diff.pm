package Review::Helper::Diff;
use v5.36;

our $VERSION = '0.001';

use Carp qw/croak/;
use List::Util qw/min/;

use Exporter 'import';
our @EXPORT_OK = qw/parse_diff count_lines attribute line_owners map_lines move_ranges section_hunks/;

sub parse_diff($text) {
    croak "parse_diff() needs diff text" unless defined $text;

    my @lines  = split /\n/, $text;
    my $binary = 0;
    my @hunks;

    my $i = 0;
    while ($i < @lines) {
        my $line = $lines[$i++];

        if ($line =~ m/^\@\@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? \@\@/) {
            my $hunk = {
                old_start => $1 + 0,
                old_count => ($2 // 1) + 0,
                new_start => $3 + 0,
                new_count => ($4 // 1) + 0,
                lines     => [],
            };
            $i = _read_hunk_lines($hunk, \@lines, $i);
            push @hunks => $hunk;
            next;
        }

        $binary = 1 if $line =~ m/^Binary files .* differ$/ || $line eq 'GIT binary patch';
    }

    return {binary => $binary, hunks => \@hunks};
}

sub count_lines($hunks) {
    my %count = (added => 0, removed => 0, changed => 0);

    for my $hunk (@$hunks) {
        my $lines = $hunk->{lines};
        for my $run (_change_runs($lines)) {
            my $minus = grep { $lines->[$_]->{type} eq '-' } @$run;
            _tally(\%count, $minus, @$run - $minus);
        }
    }

    return \%count;
}

sub attribute($hunks, $sections) {
    $_->@{qw/added removed changed touched/} = (0, 0, 0, 0) for @$sections;

    my $owners = line_owners($hunks, $sections);

    for my $h (0 .. $#$hunks) {
        my $lines = $hunks->[$h]->{lines};

        for my $run (_change_runs($lines)) {
            my %per;
            for my $i (@$run) {
                my $owner = $owners->[$h]->[$i] // next;
                $per{$owner}->[$lines->[$i]->{type} eq '-' ? 0 : 1]++;
            }

            for my $owner (keys %per) {
                my $section = $sections->[$owner];
                _tally($section, $per{$owner}->[0] // 0, $per{$owner}->[1] // 0);
                $section->{touched} = 1;
            }
        }
    }

    return;
}

sub line_owners($hunks, $sections) {
    my (%new_owner, %old_owner);

    for my $s (0 .. $#$sections) {
        my $section = $sections->[$s];
        $old_owner{$_} = $s for _range_lines($section->{old_ranges});
        next if $section->{deleted};
        $new_owner{$_} = $s for _range_lines($section->{ranges}), _range_lines($section->{doc_ranges});
    }

    my @owners;
    for my $hunk (@$hunks) {
        my @hunk_owners;
        my $lines = $hunk->{lines};
        my $near  = _nearest_new($lines);

        for my $i (0 .. $#$lines) {
            my $line = $lines->[$i];

            if ($line->{type} ne '-') {
                push @hunk_owners => $new_owner{$line->{new}};
                next;
            }

            my $owner = $old_owner{$line->{old}};
            $owner //= $new_owner{$near->[$i]} if defined $near->[$i];
            push @hunk_owners => $owner;
        }

        push @owners => \@hunk_owners;
    }

    return \@owners;
}

sub section_hunks($hunks, $new_lines, $sections, $index) {
    my $section = $sections->[$index];
    my $owners  = line_owners($hunks, $sections);

    my %part;
    unless ($section->{deleted}) {
        $part{$_} = 'code' for _range_lines($section->{ranges});
        $part{$_} = 'docs' for _range_lines($section->{doc_ranges});
    }

    # The whole file in order, one entry per line: [line, part, old, new]
    # where old and new are the positions on each side before the line, and
    # part is undef for a line the unit does not take and '-' for a removed
    # line it owns. Unchanged lines outside the hunks come from $new_lines.
    my @seq;
    my ($old, $new) = (1, 1);
    my $fill = sub ($to) {
        while ($new < $to) {
            my $part = $part{$new};
            push @seq => [$part ? {type => ' ', text => $new_lines->[$new - 1], old => $old, new => $new} : undef, $part, $old, $new];
            $old++;
            $new++;
        }
    };

    for my $h (0 .. $#$hunks) {
        my $hunk = $hunks->[$h];
        $fill->($hunk->{new_count} ? $hunk->{new_start} : $hunk->{new_start} + 1);
        ($old, $new) = map { $hunk->{"${_}_count"} ? $hunk->{"${_}_start"} : $hunk->{"${_}_start"} + 1 } qw/old new/;

        my $lines = $hunk->{lines};
        for my $i (0 .. $#$lines) {
            my $line = $lines->[$i];
            my $part = $line->{type} eq '-' ? (($owners->[$h]->[$i] // -1) == $index ? '-' : undef) : $part{$line->{new}};
            push @seq => [$line, $part, $old, $new];
            $old++ unless $line->{type} eq '+';
            $new++ unless $line->{type} eq '-';
        }
    }
    $fill->(@{$new_lines // []} + 1);

    _removed_parts(\@seq);

    my (@runs, $prev);
    for my $entry (@seq) {
        my $part = $entry->[1];
        push @runs        => []     if defined($part) && !($prev && $prev eq $part);
        push @{$runs[-1]} => $entry if defined $part;
        $prev = $part;
    }
    return [] unless grep { $_->[0]->{type} ne ' ' } map { @$_ } @runs;
    return [map { _run_hunk($_) } @runs];
}

sub map_lines($hunks, $start, $end = undef) {
    my @new = map { _map_line($hunks, $_) } $start .. $end // $start;
    for my $i (0 .. $#new) {
        return () unless defined($new[$i]) && $new[$i] == $new[0] + $i;
    }
    return ($new[0], defined($end) ? $new[-1] : undef);
}

sub move_ranges($hunks, $ranges) {
    my ($changed, @new) = (0);
    for my $range (@$ranges) {
        my $prev;
        for my $line ($range->[0] .. $range->[1]) {
            my $to = _map_line($hunks, $line);
            $changed = 1 unless defined($to) && (!defined($prev) || $to == $prev + 1);
            next unless defined $to;
            push @new => $to;
            $prev = $to;
        }
    }

    my @moved;
    for my $line (@new) {
        if (@moved && $moved[-1]->[1] + 1 == $line) { $moved[-1]->[1] = $line }
        else                                        { push @moved => [$line, $line] }
    }
    return (\@moved, $changed);
}

# The new number of an old line, or undef when the diff removes it.
sub _map_line($hunks, $line) {
    my $shift = 0;
    for my $hunk (@$hunks) {
        for my $l (@{$hunk->{lines}}) {
            next unless defined($l->{old}) && $l->{old} == $line;
            return $l->{type} eq ' ' ? $l->{new} + 0 : undef;
        }

        my $last = $hunk->{old_count} ? $hunk->{old_start} + $hunk->{old_count} - 1 : $hunk->{old_start};
        $shift += $hunk->{new_count} - $hunk->{old_count} if $last < $line;
    }

    return $line + $shift;
}

sub _read_hunk_lines($hunk, $lines, $i) {
    my ($old,      $new)      = ($hunk->{old_start}, $hunk->{new_start});
    my ($old_left, $new_left) = ($hunk->{old_count}, $hunk->{new_count});

    while ($i < @$lines && ($old_left > 0 || $new_left > 0)) {
        my $line = $lines->[$i++];
        my $type = substr($line, 0, 1);
        my $text = length($line) ? substr($line, 1) : '';

        next if $type eq '\\';    # "\ No newline at end of file"

        # A blank line inside a hunk is a context line whose leading space was stripped.
        $type = ' ' if $type eq '';

        if ($type eq ' ') {
            push @{$hunk->{lines}} => {type => ' ', text => $text, old => $old++, new => $new++};
            $old_left--;
            $new_left--;
        }
        elsif ($type eq '-') {
            push @{$hunk->{lines}} => {type => '-', text => $text, old => $old++, new => undef};
            $old_left--;
        }
        elsif ($type eq '+') {
            push @{$hunk->{lines}} => {type => '+', text => $text, old => undef, new => $new++};
            $new_left--;
        }
        else {
            croak "Malformed diff: unexpected line '$line' inside a hunk";
        }
    }

    $i++ while $i < @$lines && $lines->[$i] =~ m/^\\/;

    return $i;
}

# Maximal runs of non-context line indexes: in git's output each run is one
# group of '-' lines followed by '+' lines.
sub _change_runs($lines) {
    my (@runs, $run);

    for my $i (0 .. $#$lines) {
        if ($lines->[$i]->{type} eq ' ') {
            $run = undef;
            next;
        }

        push @runs => ($run = []) unless $run;
        push @$run => $i;
    }

    return @runs;
}

sub _tally($count, $minus, $plus) {
    my $changed = min($minus, $plus);
    $count->{changed} += $changed;
    $count->{removed} += $minus - $changed;
    $count->{added}   += $plus - $changed;
    return;
}

# Per line, the new-side line a '-' line belongs with: the next new-side
# line in the hunk, or for a removal at the very end of the file, the last
# one before it. One pass each way keeps long removals linear.
sub _nearest_new($lines) {
    my (@near, $seen);
    for my $i (reverse 0 .. $#$lines) {
        $near[$i] = $seen;
        $seen = $lines->[$i]->{new} // $seen;
    }

    $seen = undef;
    for my $i (0 .. $#$lines) {
        $near[$i] //= $seen;
        $seen = $lines->[$i]->{new} // $seen;
    }

    return \@near;
}

# A removed line the unit owns joins the part of the unit's line after it,
# else the one before it, else the code.
sub _removed_parts($seq) {
    for my $i (0 .. $#$seq) {
        next unless ($seq->[$i]->[1] // '') eq '-';
        my $part;
        for my $j ($i + 1 .. $#$seq) {
            my $p = $seq->[$j]->[1];
            last unless defined $p;
            next if $p eq '-';
            $part = $p;
            last;
        }
        for my $j (reverse 0 .. $i - 1) {
            last if defined($part);
            my $p = $seq->[$j]->[1];
            last       unless defined $p;
            $part = $p unless $p eq '-';
        }
        $seq->[$i]->[1] = $part // 'code';
    }
    return;
}

# One hunk over consecutive entries. A side with no lines names the line
# before the hunk, as git does.
sub _run_hunk($run) {
    my @lines = map { $_->[0] } @$run;
    my %hunk  = (part => $run->[0]->[1], lines => \@lines);
    for my $side (0, 1) {
        my $name  = $side ? 'new' : 'old';
        my $count = grep { $_->{type} ne ($side ? '-' : '+') } @lines;
        $hunk{"${name}_count"} = $count;
        $hunk{"${name}_start"} = $run->[0]->[$side + 2] - ($count ? 0 : 1);
    }
    return \%hunk;
}

sub _range_lines($ranges) {
    return map { $_->[0] .. $_->[1] } @{$ranges // []};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::Diff - Parse unified diffs, count changed lines, and attribute
them to sections.

=head1 DESCRIPTION

Pure functions over the text of a single-file unified diff as produced with
the fixed options Review::Helper always uses. Nothing here runs git.

A hunk line is a hashref C<< { type, text, old, new } >>: C<type> is C<' '>,
C<'-'> or C<'+'>; C<old> and C<new> are the line numbers on each side, C<undef>
on the side the line does not exist. Lines are 1-based.

Line counts follow one rule everywhere: each run of C<-> lines followed by
C<+> lines counts C<min(removed, added)> as changed and the rest as removed or
added.

=head1 SYNOPSIS

    use Review::Helper::Diff qw/parse_diff count_lines attribute/;

    my $diff   = parse_diff($text);
    my $counts = count_lines($diff->{hunks});    # { added, removed, changed }

    attribute($diff->{hunks}, \@sections);       # sets counts on each section

=head1 EXPORTS

Nothing is exported by default.

=over 4

=item $diff = parse_diff($text)

Returns C<< { binary => $bool, hunks => \@hunks } >>. Each hunk is
C<< { old_start, old_count, new_start, new_count, lines => \@lines } >>.
C<binary> is true when git reported a binary difference. An empty diff (a
pure rename or mode change) has no hunks. "No newline at end of file" markers
are dropped.

=item $counts = count_lines(\@hunks)

Returns C<< { added, removed, changed } >> for the whole diff.

=item attribute(\@hunks, \@sections)

Sets C<added>, C<removed>, C<changed> and C<touched> on every section hashref.
A section is touched when any C<-> or C<+> line is attributed to it; context
lines never touch a section. Owners are decided by C<line_owners()>. The
counting rule is applied within each run separately per owning section.

=item $owners = line_owners(\@hunks, \@sections)

Returns, for each hunk, an arrayref parallel to its lines holding the index
of the owning section in C<\@sections>, or C<undef> when no section owns the
line.

A context or C<+> line belongs to the section whose C<ranges> or
C<doc_ranges> hold its new line. A C<-> line belongs to the section whose
C<old_ranges> hold its old line; otherwise to the section holding the next
new-side line in the hunk, or, when the removal ends the file, the previous
one. Sections with C<deleted> set own only through C<old_ranges>.

=item $hunks = section_hunks(\@hunks, \@new_lines, \@sections, $index)

The diff of the section at C<$index> in C<\@sections>: every line of its
C<ranges> and C<doc_ranges>, unchanged ones as context (their text from
C<\@new_lines>, the file after the change, one string per line), with the
C<+> lines of C<\@hunks> and the C<-> lines C<line_owners> gives the
section, in file order. Each unbroken run of one part is
a hunk with a C<part> of C<code> or C<docs> and its own line numbers; lines
between runs do not appear. A removed line takes the part of the section's
next line in its run, else the previous one, else C<code>. A deleted section
shows its removed lines. Returns no hunks when the section has no added or
removed line.

=item ($ranges, $changed) = move_ranges(\@hunks, \@ranges)

Where the old lines of a range list are on the new side of the diff: the
lines the diff keeps, as a range list in new numbering. C<$changed> is true
when the diff removes any of them or adds lines inside one of the ranges.

=item ($start, $end) = map_lines(\@hunks, $start, $end)

Where old lines C<$start>..C<$end> are on the new side of the diff. Returns
the empty list when the diff removes any of them or adds lines between them.
C<$end> may be undef for a single line, and stays undef.

=back

=head1 SOURCE

The source code repository for Review-Helper can be found at
L<https://github.com/exodist/Review-Helper>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
