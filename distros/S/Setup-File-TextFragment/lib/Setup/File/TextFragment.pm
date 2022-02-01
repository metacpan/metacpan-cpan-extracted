package Setup::File::TextFragment;

our $DATE = '2021-08-02'; # DATE
our $VERSION = '0.070'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::Trash::Undoable;
use Text::Fragment;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(setup_text_fragment);

our %SPEC;

$SPEC{setup_text_fragment} = {
    v           => 1.1,
    summary     => 'Insert/delete text fragment in a file (with undo support)',
    description => <<'_',

On do, will insert fragment to file (or delete, if `should_exist` is set to
false). On undo, will restore old file.

Unfixable state: file does not exist or not a regular file (directory and
symlink included).

Fixed state: file exists, fragment already exists and with the same content (if
`should_exist` is true) or fragment already does not exist (if `should_exist` is
false).

Fixable state: file exists, fragment doesn't exist or payload is not the same
(if `should_exist` is true) or fragment still exists (if `should_exist` is
false).

_
    args        => {
        path => {
            summary => 'Path to file',
            schema => 'str*',
            req    => 1,
            pos    => 0,
        },
        id => {
            summary => 'Fragment ID',
            schema => 'str*',
            req    => 1,
            pos    => 1,
        },
        payload => {
            summary => 'Fragment content',
            schema => 'str*',
            req    => 1,
            pos    => 2,
        },
        attrs => {
            summary => 'Fragment attributes (only for inserting new fragment)'.
                ', passed to Text::Fragment',
            schema => 'hash',
        },
        top_style => {
            summary => 'Will be passed to Text::Fragment',
            schema => 'bool',
        },
        comment_style => {
            summary => 'Will be passed to Text::Fragment',
            schema => 'bool',
        },
        label => {
            summary => 'Will be passed to Text::Fragment',
            schema => 'str',
        },
        replace_pattern => {
            summary => 'Will be passed to Text::Fragment',
            schema => 'str',
        },
        good_pattern => {
            summary => 'Will be passed to Text::Fragment',
            schema => 'str',
        },
        should_exist => {
            summary => 'Whether fragment should exist',
            schema => [bool => {default=>1}],
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub setup_text_fragment {
    my %args = @_;

    # TMP, schema
    my $tx_action       = $args{-tx_action} // '';
    my $taid            = $args{-tx_action_id}
        or return [400, "Please specify -tx_action_id"];
    my $dry_run         = $args{-dry_run};
    my $path            = $args{path};
    defined($path) or return [400, "Please specify path"];
    my $id              = $args{id};
    defined($id) or return [400, "Please specify id"];
    my $payload         = $args{payload};
    defined($payload) or return [400, "Please specify payload"];
    my $attrs           = $args{attrs};
    my $comment_style   = $args{comment_style};
    my $top_style       = $args{top_style};
    my $label           = $args{label};
    my $replace_pattern = $args{replace_pattern};
    my $good_pattern    = $args{good_pattern};
    my $should_exist    = $args{should_exist} // 1;

    my $is_sym  = (-l $path);
    my @st      = stat($path);
    my $exists  = $is_sym || (-e _);
    my $is_file = (-f _);

    my @cmd;

    return [412, "$path does not exist"] unless $exists;
    return [412, "$path is not a regular file"] if $is_sym||!$is_file;

    open my($fh), "<", $path or return [500, "Can't open $path: $!"];
    my $text = do { local $/; scalar <$fh> };

    my $res;
    if ($should_exist) {
        $res = Text::Fragment::insert_fragment(
            text=>$text, id=>$id, payload=>$payload,
            comment_style=>$comment_style, label=>$label, attrs=>$attrs,
            good_pattern=>$good_pattern, replace_pattern=>$replace_pattern,
            top_style=>$top_style,
        );
    } else {
        $res = Text::Fragment::delete_fragment(
            text=>$text, id=>$id,
            comment_style=>$comment_style, label=>$label,
        );
    }

    return $res if $res->[0] == 304;
    return $res if $res->[0] != 200;

    if ($tx_action eq 'check_state') {
        if ($should_exist) {
            log_info("(DRY) Inserting fragment $id to $path ...")
                if $dry_run;
        } else {
            log_info("(DRY) Deleting fragment $id from $path ...")
                if $dry_run;
        }
        return [200, "Fragment $id needs to be inserted to $path", undef,
                {undo_actions=>[
                    ['File::Trash::Undoable::untrash', # restore old file
                     {path=>$path, suffix=>substr($taid,0,8)}],
                    ['File::Trash::Undoable::trash',   # trash new file
                     {path=>$path, suffix=>substr($taid,0,8)."n"}],
                ]}];
    } elsif ($tx_action eq 'fix_state') {
        if ($should_exist) {
            log_info("Inserting fragment $id to $path ...");
        } else {
            log_info("Deleting fragment $id from $path ...");
        }

        File::Trash::Undoable::trash(
            path=>$path, suffix=>substr($taid,0,8), -tx_action=>'fix_state');
        open my($fh), ">", $path or return [500, "Can't open: $!"];
        print $fh $res->[2]{text};
        close $fh or return [500, "Can't write: $!"];
        chmod $st[2] & 07777, $path; # XXX ignore error?
        unless ($>) { chown $st[4], $st[5], $path } # XXX ignore error?
        return [200, "OK"];
    }
    [400, "Invalid -tx_action"];
}

1;
# ABSTRACT: Insert/delete text fragment in a file (with undo support)

__END__

=pod

=encoding UTF-8

=head1 NAME

Setup::File::TextFragment - Insert/delete text fragment in a file (with undo support)

=head1 VERSION

This document describes version 0.070 of Setup::File::TextFragment (from Perl distribution Setup-File-TextFragment), released on 2021-08-02.

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <sharyanto@cpan.org>

=head1 FUNCTIONS


=head2 setup_text_fragment

Usage:

 setup_text_fragment(%args) -> [$status_code, $reason, $payload, \%result_meta]

InsertE<sol>delete text fragment in a file (with undo support).

On do, will insert fragment to file (or delete, if C<should_exist> is set to
false). On undo, will restore old file.

Unfixable state: file does not exist or not a regular file (directory and
symlink included).

Fixed state: file exists, fragment already exists and with the same content (if
C<should_exist> is true) or fragment already does not exist (if C<should_exist> is
false).

Fixable state: file exists, fragment doesn't exist or payload is not the same
(if C<should_exist> is true) or fragment still exists (if C<should_exist> is
false).

This function is not exported by default, but exportable.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<attrs> => I<hash>

Fragment attributes (only for inserting new fragment), passed to Text::Fragment.

=item * B<comment_style> => I<bool>

Will be passed to Text::Fragment.

=item * B<good_pattern> => I<str>

Will be passed to Text::Fragment.

=item * B<id>* => I<str>

Fragment ID.

=item * B<label> => I<str>

Will be passed to Text::Fragment.

=item * B<path>* => I<str>

Path to file.

=item * B<payload>* => I<str>

Fragment content.

=item * B<replace_pattern> => I<str>

Will be passed to Text::Fragment.

=item * B<should_exist> => I<bool> (default: 1)

Whether fragment should exist.

=item * B<top_style> => I<bool>

Will be passed to Text::Fragment.


=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_v> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Setup-File-TextFragment>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Setup-File-TextFragment>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Setup-File-TextFragment>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

A more general version of this: L<Setup::File::Edit>.

A variation that adds/removes line to file: L<Setup::File::Line>.

Backend for this module: L<Text::Fragment>

The Setup framework: L<Setup>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
