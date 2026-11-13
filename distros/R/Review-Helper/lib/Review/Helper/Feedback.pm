package Review::Helper::Feedback;
use v5.36;

our $VERSION = '0.001';

use Carp qw/croak/;
use List::Util qw/uniq/;

use Object::HashBase qw{
    <db
};

use constant FORMAT         => 'review-feedback';
use constant FORMAT_VERSION => 1;
use constant PUBLISH_FORMAT => 'review-publish';

sub init($self) {
    croak "'db' is a required attribute" unless $self->{+DB};
}

sub export($self, %params) {
    my $dbh    = $self->{+DB}->dbh;
    my $where  = $params{open} ? q{WHERE status = 'open'} : '';
    my $latest = $self->{+DB}->latest_iteration;

    my $feedback = $dbh->selectall_arrayref("SELECT * FROM feedback $where ORDER BY id", {Slice => {}});
    my $requests = $dbh->selectall_arrayref("SELECT * FROM request $where ORDER BY id",  {Slice => {}});

    my $review = $self->{+DB}->review;
    return {
        format         => FORMAT,
        format_version => FORMAT_VERSION,
        review         => $review->{id},
        source         => $review->{source},
        iteration      => $latest ? $latest->{number} : undef,
        base           => $latest ? $latest->{base}   : undef,
        head           => $latest ? $latest->{head}   : undef,
        feedback       => [map { $self->feedback_entry($_) } @$feedback],
        requests       => [map { $self->request_entry($_) } @$requests],
    };
}

# The flag feedback is on, or was on before the agent retired it: its note
# id and sentence, both stored with the feedback, its path, and its lines in
# the feedback's iteration, so a comment can be placed where the flag is.
sub flag_of($self, $row) {
    return undef unless defined $row->{flag};
    my $lines = $self->{_flag_lines} //= {map { ("$_->[0]\0$_->[1]" => [$_->[2] + 0, $_->[3] + 0]) } @{$self->{+DB}->dbh->selectall_arrayref(<<~'EOT')}};
            SELECT c.iteration, f.note_id, f.line_start, f.line_end
              FROM flag f JOIN commit_entry c ON c.id = f.commit_id
             WHERE f.line_start IS NOT NULL
            EOT
    return {note => $row->{flag}, sentence => $row->{flag_sentence}, path => $row->{path}, lines => $lines->{"$row->{iteration}\0$row->{flag}"}};
}

sub feedback_entry($self, $row) {
    return {
        %{$self->anchor($row)},
        flag => $self->flag_of($row),
        map { ($_ => $row->{$_}) } qw/id iteration line side body status response resolved_in published reviewer/,
    };
}

sub request_entry($self, $row) {
    return {
        %{$self->anchor($row)},
        map { ($_ => $row->{$_}) } qw/id iteration kind note status case_for case_against reviewer/,
    };
}

# The feedback to post to the pull or merge request: by default each open
# item not posted yet, or the items named by id.
sub publish($self, @ids) {
    my $rows;
    if (@ids) {
        $rows = [map { $self->{+DB}->feedback($_) // croak "No such feedback item: $_" } uniq @ids];
    }
    else {
        $rows = $self->{+DB}->dbh->selectall_arrayref(q{SELECT * FROM feedback WHERE status = 'open' AND published IS NULL ORDER BY id}, {Slice => {}});
    }

    my $review = $self->{+DB}->review;
    my $latest = $self->{+DB}->latest_iteration;
    return {
        format         => PUBLISH_FORMAT,
        format_version => FORMAT_VERSION,
        review         => $review->{id},
        source         => $review->{source},
        head           => $latest ? $latest->{head} : undef,
        items          => [map { $self->publish_item($_) } @$rows],
    };
}

# One item to post: the general comment's text, the item's location prefix
# then a blank line then its body, unless a line comment fits; then the body
# alone with its anchor, the general comment kept as the fallback.
sub publish_item($self, $row) {
    my ($prefix, $anchor) = $self->location($row);
    my $general = defined($prefix) ? "$prefix\n\n$row->{body}" : $row->{body};
    return {id => $row->{id}, text => $general, anchor => undef, fallback => undef} unless $anchor;
    return {id => $row->{id}, text => $row->{body}, anchor => $anchor, fallback => $general};
}

# The location prefix naming where the item was given (undef for the whole
# change), and the line comment anchor when one fits.
sub location($self, $row) {
    my ($target, $path, $topic) = @$row{qw/target path topic/};
    my $commit = substr($row->{revision} // '', 0, 7);

    if ($target eq 'line') {
        my $old = $row->{side} eq 'old' ? 'old side, ' : '';
        return ("`$path:$row->{line}` (${old}commit $commit)", $self->line_anchor($row, $row->{line}, $row->{side}));
    }

    if ($target eq 'flag') {
        my $lines = $path ? $self->flag_of($row)->{lines} : undef;
        if ($lines) {
            my $range = $lines->[0] == $lines->[1] ? $lines->[0] : "$lines->[0]-$lines->[1]";
            return ("`$path:$range` (commit $commit), on a flag", $self->line_anchor($row, $lines->[0], 'new'));
        }
        return ("`$path`, on a flag")                         if defined $path;
        return ("topic `$topic` (commit $commit), on a flag") if defined $topic;
        return ("commit $commit, on a flag");
    }

    return ("`$path`, section `$row->{section_name}`") if $target eq 'section';

    if ($target eq 'review') {
        return (undef)                                 unless defined $topic;
        return ('was on the files not in a topic yet') unless length $topic;
        return ("was on topic `$topic`");
    }

    my $prefix =
        $target eq 'file'
        ? "`$path`" . (defined($row->{section_name}) ? ", was on section `$row->{section_name}`" : '')
        : (defined($topic) ? "topic `$topic` (commit $commit)" : "commit $commit");
    $prefix .= ', was on a flag' if defined $row->{flag};
    return ($prefix);
}

# A line comment fits when the line counts in the same file as that side of
# the request's diff, as the review knows it (its latest iteration): on the
# new side no later commit of that iteration changes the file, on the old
# side no earlier one does. The commit must still be in that iteration; a
# squashed iteration's old side is its base.
sub line_anchor($self, $row, $line, $side) {
    my $db     = $self->{+DB};
    my $latest = $db->latest_iteration;
    my $anchor = {path => $row->{path}, line => $line, side => $side};

    my $iteration = $db->iteration($row->{iteration});
    return $iteration->{base} eq $latest->{base} ? $anchor : undef if $side eq 'old' && $iteration->{squashed};

    my ($position) = $db->dbh->selectrow_array('SELECT MIN(position) FROM commit_entry WHERE iteration = ? AND revision = ?', undef, $latest->{number}, $row->{revision});
    return undef unless defined $position;

    # Merged-in commits do not follow one another in position order: then
    # any other commit changing the file counts.
    my ($merges) = $db->dbh->selectrow_array('SELECT COUNT(*) FROM commit_entry WHERE iteration = ? AND merge_id IS NOT NULL', undef, $latest->{number});
    my $compare = $merges ? '!=' : $side eq 'new' ? '>' : '<';

    # A file the item's commit renamed is still its old path before it.
    my ($renamed) = $db->dbh->selectrow_array(<<~'EOT', undef, $latest->{number}, $row->{revision}, $row->{path});
        SELECT f.old_path FROM commit_entry c JOIN file_change f ON f.commit_id = c.id
         WHERE c.iteration = ? AND c.revision = ? AND f.path = ? AND f.old_path IS NOT NULL
        EOT
    my @paths = ($row->{path}, $renamed // ());
    my $in    = join ', ' => ('?') x @paths;

    my ($changed) = $db->dbh->selectrow_array(<<~"EOT", undef, $latest->{number}, $row->{revision}, $position, @paths, @paths);
        SELECT COUNT(*) FROM commit_entry c JOIN file_change f ON f.commit_id = c.id
         WHERE c.iteration = ? AND c.revision != ? AND c.position $compare ? AND (f.path IN ($in) OR f.old_path IN ($in))
        EOT
    return $changed ? undef : $anchor;
}

sub anchor($self, $row) {
    my $section = defined($row->{section_name}) ? {name => $row->{section_name}, package => $row->{section_package}} : undef;
    return {target => $row->{target}, commit => $row->{revision}, topic => $row->{topic}, path => $row->{path}, section => $section};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::Feedback - Export a review's feedback and requests.

=head1 DESCRIPTION

Builds the feedback export: every feedback item and request in the review,
from any iteration, oldest first. Each anchors to a C<target> (C<review>,
C<commit>, C<file>, C<section>, or C<line> or C<flag> for feedback), with C<commit>,
C<path> and C<section> (C<< { name, package } >>) set as far as the target
reaches. A C<commit> item in a squashed iteration split into topics names
its C<topic>; C<topic> is null otherwise, or kept as context on an item
that moved to the C<review> when its topic went. A C<file> item may also carry C<section>: the section it was on
before a re-split took that section away, kept as context. A feedback item's
C<flag> is C<< { note, sentence, path, lines } >> for a C<flag> target, or for feedback a
retired flag left on its file or commit (its sentence stored with the
feedback), and null otherwise. C<published> is null until the feedback is posted to the pull or
merge request under review. C<reviewer> names who wrote the item, null when
the file did not record it.

=head1 SYNOPSIS

    use Review::Helper::Feedback;

    my $export = Review::Helper::Feedback->new(db => $db)->export(open => 1);

=head1 ATTRIBUTES

=over 4

=item $db = $feedback->db()

The L<Review::Helper::DB> of the review. Required.

=back

=head1 PUBLIC METHODS

=over 4

=item $data = $feedback->export()

=item $data = $feedback->export(open => 1)

A hashref with C<format> (C<review-feedback>), C<format_version> (1),
C<review> (its id), C<source> (the pull or merge request URL, or undef),
C<iteration>, C<base> and C<head> (of the latest iteration), C<feedback> and
C<requests>. With
C<open>, only items whose status is C<open>.

=item $entry = $feedback->feedback_entry($row)

=item $entry = $feedback->request_entry($row)

One exported feedback item or request from its database row.

=item $flag = $feedback->flag_of($row)

The flag a feedback row is on, or was on before the agent retired it, as
C<< { note, sentence, path, lines } >>: its C<flag>, C<flag_sentence> and
C<path>, and the C<[start, end]> of the flag with that note id in the row's
iteration (null for a whole-file or whole-commit flag, or one no longer
there); undef for feedback on no flag.

=item $data = $feedback->publish()

=item $data = $feedback->publish(@ids)

What to post to the pull or merge request: a hashref with C<format>
(C<review-publish>), C<format_version> (1), C<review>, C<source>, C<head>
(of the latest iteration) and C<items>, one per feedback item that is open
and not yet published, or per item of C<@ids>, in that order, each once.
Croaks on an id with no item. Each item is C<< { id, text, anchor, fallback } >>, as
C<publish_item> builds it. The prefixes and the line-fit rule are those of
the review file format's publish list (see L<Review::Helper::Manual>).

=item $item = $feedback->publish_item($row)

One item to post. C<text> is the general comment: the location prefix, a
blank line, then C<body> exactly as stored, or C<body> alone for an item with
no prefix. When a line comment fits, C<text> is C<body> alone, C<anchor> is
C<< { path, line, side } >> and C<fallback> the general comment to post if
the forge refuses the line comment; otherwise both are undef.

=item ($prefix, $anchor) = $feedback->location($row)

The item's location prefix (undef for whole-change feedback with no topic)
and, for a C<line> item or a C<flag> item with lines, its anchor from
C<line_anchor>.

=item $anchor = $feedback->line_anchor($row, $line, $side)

C<< { path, line, side } >> for a line comment at C<$line> on C<$side> of the
row's commit and path, or undef when it does not fit: when the latest
iteration lacks the row's commit, or another of its commits changes the
path after it (C<new> side) or before it (C<old> side), or at all when the
iteration has merged-in commits. When the row's commit renamed the file, a
change to its old path counts too. On the C<old> side
of a squashed iteration's item, it fits when that iteration's base is the
latest one's.

=item $anchor = $feedback->anchor($row)

=item $anchor = Review::Helper::Feedback->anchor($row)

The C<target>, C<commit>, C<topic>, C<path> and C<section> of a feedback or
request row. It needs no object; L<Review::Helper::Sheet> calls it on the
class for its feedback and debate items.

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
