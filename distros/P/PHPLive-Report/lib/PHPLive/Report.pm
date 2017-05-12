package PHPLive::Report;

our $DATE = '2015-09-04'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(parse_phplive_transcript %reports %legends);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Generate reports for PHP Live!',
};

our %reports = (
    chat_report => 'Chat reports',
    chat_report_by_dept => 'Chat report by department',
    chat_report_by_op => 'Chat report by operator',
);

our %legends = (
    pct_rated => 'Percentage of chats that are rated by clients',
    pct_has_transfers => 'Percentage of chats that involve a transfer of operators',
    avg_chat_duration => 'Average chat duration, in minutes',
    avg_rating => 'Average chat rating from clients (counted over chats that are rated only)',
    num_chats => 'Number of chats',
    avg_msg_lines => 'Average number of message lines in a single chat. Note that non-message lines are excluded',
    avg_msg_words => 'Average number of words in a single chat. Note that the username prefix in message lines and non-message lines are excluded',
    avg_msg_chars => 'Average number of characters in a single chat. Like in "avg_msg_words", the username prefix in message lines and non-message lines are excluded',

    avg_simul_chats => 'Average number of simultaneous chats held by the operator at a time',
);


$SPEC{parse_phplive_transcript} = {
    v => 1.1,
    description => <<'_',

The `plain` column in `p_transcripts` table stores the actual chat transcript.
Entities characters like `<` and `>` are HTML-entities-escaped (becoming `&lt;`
and `&gt;`). Multiple lines are squished together into a single line. No
timestamp is recorded for each message.

_
    args => {
        transcript => {schema=>'str*', req=>1, pos=>0},
    },
    args_as => 'array',
    result_naked => 1,
};
sub parse_phplive_transcript {
    my ($transcript) = @_;

    my @lines = split /^/m, $transcript;
    my $num_transfers = 0;
    my $num_msg_lines = 0;
    my $num_msg_words = 0;
    my $num_msg_chars = 0;

    my %operators;
    for (@lines) {
        if (/^(.+) has joined the chat\.$/) {
            $operators{$1}++;
            next;
        }
        if (/(.+?): (.+)/) {
            $num_msg_lines++;
            chomp(my $msg = $2);
            $num_msg_words++ while $msg =~ /(\w+)/g;
            $num_msg_chars += length($msg);
            next;
        }
        if (/^Transferring chat to /) {
            $num_transfers++;
            next;
        }
    }

    return {
        num_transfers => $num_transfers,
        num_operators => scalar(keys %operators),
        num_msg_lines => $num_msg_lines,
        num_msg_words => $num_msg_words,
        num_msg_chars => $num_msg_chars,
    };
}

sub _recap_transcripts {
    my ($transcripts, $filter) = @_;

    my $n = 0;
    my $has_transfers = 0;
    my $total_msg_lines = 0;
    my $total_msg_words = 0;
    my $total_msg_chars = 0;
    for my $k (keys %$transcripts) {
        my $t = $transcripts->{$k};
        next unless $filter->($t);
        $n++;
        $has_transfers++ if $t->{num_transfers};
        $total_msg_lines += $t->{num_msg_lines};
        $total_msg_words += $t->{num_msg_words};
        $total_msg_chars += $t->{num_msg_chars};
    }
    return {
        #num_transcripts => $n,
        pct_has_transfers => $n == 0 ? 0 : sprintf("%.2f", $has_transfers/$n*100.0),
        avg_msg_lines => $n == 0 ? 0 : sprintf("%.f", $total_msg_lines/$n),
        avg_msg_words => $n == 0 ? 0 : sprintf("%.f", $total_msg_words/$n),
        avg_msg_chars => $n == 0 ? 0 : sprintf("%.f", $total_msg_chars/$n),
    };
}

$SPEC{gen_phplive_reports} = {
    v => 1.1,
    summary => 'Generate reports for PHP Live!',
    args => {
        dbh     => {schema=>'obj*', req=>1},
        year    => {schema=>'int*', req=>1},
        month   => {schema=>['int*', between=>[1,12]], req=>1},
    },
    result_naked=>1,
};
sub gen_phplive_reports {
    require DateTime;

    my %args = @_;

    my $res;

    my $dbh   = $args{dbh};
    my $year  = $args{year}+0;
    my $month = $args{month}+0;

    my $dt = DateTime->new(year=>$year, month=>$month, day=>1);
    my $ts_start_of_month = $dt->epoch;
    $dt->add(months => 1)->subtract(seconds => 1);
    my $ts_end_of_month = $dt->epoch;

    my $sql;
    my $sth;

    $log->debug("Parsing all transcripts ...");
    $sql = <<_;
SELECT
  ces,
  opID,
  deptID,
  plain transcript
FROM p_transcripts
WHERE created BETWEEN $ts_start_of_month AND $ts_end_of_month
_
    $sth = $dbh->prepare($sql);
    $sth->execute;
    my %transcripts; # key = ces (table PK)
    while (my $row = $sth->fetchrow_hashref) {
        my $res = parse_phplive_transcript($row->{transcript});
        # insert this so we can recapitulate on a per-department/per-operator
        # basis
        $res->{opID}   = $row->{opID};
        $res->{deptID} = $row->{deptID};
        $transcripts{$row->{ces}} = $res;
    }

    $log->debug("Preparing chat reports ...");
    my $sql_cr = <<_;
  COUNT(*) num_chats,
  ROUND(AVG(t.ended-t.created)/60, 1) avg_chat_duration,
  IF(COUNT(*)=0,0,ROUND(SUM(IF(t.rating>0,1,0))/COUNT(*)*100.0,2)) pct_rated,
  IF(SUM(IF(t.rating>0,1,0))=0,0,ROUND(SUM(t.rating)/SUM(IF(t.rating>0,1,0)),2)) avg_rating
_
    $sql = <<_;
SELECT
  $sql_cr
FROM p_transcripts t
WHERE created BETWEEN $ts_start_of_month AND $ts_end_of_month
_
    $sth = $dbh->prepare($sql);
    $sth->execute;
    {
        my @rows;
        while (my $row = $sth->fetchrow_hashref) {
            push @rows, $row;
            my $tres = _recap_transcripts(\%transcripts, sub{1});
            $row->{$_} = $tres->{$_} for keys %$tres;
        }
        $res->{chat_report} = \@rows;
    }

    $log->debug("Preparing per-department chat reports ...");
    $sql = <<_;
SELECT
  t.deptID deptID,
  (SELECT name FROM p_departments WHERE deptID=t.deptID) deptName,
  $sql_cr
FROM p_transcripts t
WHERE created BETWEEN $ts_start_of_month AND $ts_end_of_month
GROUP BY t.deptID
_
    $sth = $dbh->prepare($sql);
    $sth->execute;
    {
        my @rows;
        while (my $row = $sth->fetchrow_hashref) {
            push @rows, $row;
            my $tres = _recap_transcripts(
                \%transcripts, sub{shift->{deptID} == $row->{deptID}});
            $row->{$_} = $tres->{$_} for keys %$tres;
            # so they are the first/leftmost columns
            $row->{'00deptID'} = $row->{deptID};
            delete $row->{deptID};
            $row->{'00deptName'} = $row->{deptName};
            delete $row->{deptName};
        }
        $res->{chat_report_by_dept} = \@rows;
    }

    $log->debug("Preparing per-operator chat reports ...");
    $sql = <<_;
SELECT
  t.opID opID,
  (SELECT name FROM p_operators WHERE opID=t.opID) opName,
  $sql_cr
FROM p_transcripts t
WHERE created BETWEEN $ts_start_of_month AND $ts_end_of_month
GROUP BY t.opID
_
    $sth = $dbh->prepare($sql);
    $sth->execute;
    {
        my @rows;
        while (my $row = $sth->fetchrow_hashref) {
            push @rows, $row;
            my $tres = _recap_transcripts(
                \%transcripts, sub{shift->{opID} == $row->{opID}});
            $row->{$_} = $tres->{$_} for keys %$tres;
            # so they are the first/leftmost columns
            $row->{'00opID'} = $row->{opID};
            delete $row->{opID};
            $row->{'00opName'} = $row->{opName};
            delete $row->{opName};
        }
        $res->{chat_report_by_op} = \@rows;
    }

    $res;
}

1;
# ABSTRACT: Generate reports for PHP Live!

__END__

=pod

=encoding UTF-8

=head1 NAME

PHPLive::Report - Generate reports for PHP Live!

=head1 VERSION

This document describes version 0.06 of PHPLive::Report (from Perl distribution PHPLive-Report), released on 2015-09-04.

=head1 SYNOPSIS

Use the included L<gen-phplive-reports> to generate HTML report files.

=head1 DESCRIPTION

PHP Live! is a web-based live chat/live support application,
L<http://www.phplivesupport.com/>. As of this writing, version 4.4.7, the
reports it generates are quite limited. This module produces additional reports
for your PHP Live! installation.

=head1 FUNCTIONS


=head2 gen_phplive_reports(%args) -> any

Generate reports for PHP Live!.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dbh>* => I<obj>

=item * B<month>* => I<int>

=item * B<year>* => I<int>

=back

Return value:  (any)


=head2 parse_phplive_transcript($transcript) -> any

The C<plain> column in C<p_transcripts> table stores the actual chat transcript.
Entities characters like C<< E<lt> >> and C<< E<gt> >> are HTML-entities-escaped (becoming C<&lt;>
and C<&gt;>). Multiple lines are squished together into a single line. No
timestamp is recorded for each message.

Arguments ('*' denotes required arguments):

=over 4

=item * B<transcript>* => I<str>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PHPLive-Report>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PHPLive-Report>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PHPLive-Report>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
