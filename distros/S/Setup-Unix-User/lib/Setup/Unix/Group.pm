package Setup::Unix::Group;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.14'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(setup_unix_group);

use PerlX::Maybe;
use Unix::Passwd::File;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Setup Unix group (existence)',
};

my %common_args = (
    etc_dir => {
        summary => 'Location of passwd files',
        schema  => ['str*' => {default=>'/etc'}],
    },
    group => {
        schema  => 'str*',
        summary => 'Group name',
    },
);

$SPEC{delgroup} = {
    v => 1.1,
    summary => 'Delete group',
    description => <<'_',

Fixed state: group does not exist.

Fixable state: group exists.

_
    args => {
        %common_args,
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub delgroup {
    my %args = @_;

    my $tx_action = $args{-tx_action} // '';
    my $dry_run   = $args{-tx_action} // '';
    my $group     = $args{group} or return [400, "Please specify group"];
    $group =~ $Unix::Passwd::File::re_group
        or return [400, "Invalid group"];
    my %ca        = (etc_dir => $args{etc_dir}, group=>$group);
    my $res;

    if ($tx_action eq 'check_state') {
        my $res = Unix::Passwd::File::get_group(%ca);
        return $res unless $res->[0] == 200 || $res->[0] == 404;

        return [304, "Group $group already doesn't exist"] if $res->[0] == 404;
        log_info("(DRY) Deleting Unix group $group ...") if $dry_run;
        return [200, "Group $group needs to be deleted", undef, {undo_actions=>[
            [addgroup => {%ca, gid => $res->[2]{gid}}],
        ]}];
    } elsif ($tx_action eq 'fix_state') {
        # we don't want to have to get_group() when fixing state, to reduce
        # number of read passes to the passwd files
        log_info("Deleting Unix group $group ...");
        return Unix::Passwd::File::delete_group(%ca);
    }
    [400, "Invalid -tx_action"];
}

$SPEC{addgroup} = {
    v => 1.1,
    summary => 'Add group',
    args => {
        %common_args,
        gid => {
            summary => 'Add with specified GID',
            description => <<'_',

If not specified, will search an unused GID from `min_new_gid` to `max_new_gid`.

If specified, will accept non-unique GID (that which has been used by other
group).

_
            schema => 'int',
        },
        min_gid => {
            summary => 'Specify range for new GID',
            description => <<'_',

If a free GID between `min_gid` and `max_gid` is not available, an error is
returned.

Passed to Unix::Passwd::File's `min_new_gid`.

_
            schema => [int => {between=>[0, 65535], default=>1000}],
        },
        max_gid => {
            summary => 'Specify range for new GID',
            description => <<'_',

If a free GID between `min_gid` and `max_gid` is not available, an error is
returned.

Passed to Unix::Passwd::File's `max_new_gid`.

_
            schema => [int => {between=>[0, 65535], default=>65534}],
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub addgroup {
    my %args = @_;

    my $tx_action = $args{-tx_action} // '';
    my $dry_run   = $args{-dry_run};
    my $group     = $args{group} or return [400, "Please specify group"];
    $group =~ $Unix::Passwd::File::re_group
        or return [400, "Invalid group"];
    my $gid       = $args{gid};
    my $min_gid   = $args{min_gid} //  1000;
    my $max_gid   = $args{max_gid} // 65534;
    my %ca0       = (etc_dir => $args{etc_dir});
    my %ca        = (%ca0, group=>$group);
    my $res;

    if ($tx_action eq 'check_state') {
        $res = Unix::Passwd::File::get_group(%ca);
        return $res unless $res->[0] == 200 || $res->[0] == 404;

        if ($res->[0] == 200) {
            if (!defined($gid) || $gid == $res->[2]{gid}) {
                return [304, "Group $group already exists"];
            } else {
                return [412, "Group $group already exists but with different ".
                            "GID ($res->[2]{gid}, wanted $gid)"];
            }
        } else {
            log_info("(DRY) Adding Unix group $group ...") if $dry_run;
            return [200, "Group $group needs to be added", undef,
                    {undo_actions=>[
                        [delgroup => {%ca}],
            ]}];
        }
    } elsif ($tx_action eq 'fix_state') {
        # we don't want to have to get_group() when fixing state, to reduce
        # number of read passes to the passwd files
        log_info("Adding Unix group $group ...");
        $res = Unix::Passwd::File::add_group(
            %ca,
            maybe gid     => $gid,
            min_gid => $min_gid,
            max_gid => $max_gid);
        if ($res->[0] == 200) {
            $args{-stash}{result}{gid} = $res->[2]{gid};
            return [200, "Created"];
        } else {
            return $res;
        }
    }
    [400, "Invalid -tx_action"];
}

$SPEC{setup_unix_group} = {
    v           => 1.1,
    summary     => "Setup Unix group (existence)",
    description => <<'_',

On do, will create Unix group if not already exists. The created GID will be
returned in the result (`{gid => GID}`). If `should_already_exist` is set to
true, won't create but only require that group already exists. If `should_exist`
is set to false, will delete existing group instead of creating it.

On undo, will delete Unix group previously created.

On redo, will recreate the Unix group with the same GID.

_
    args => {
        should_exist => {
            summary => 'Whether group should exist',
            schema  => [bool => {default=>1}],
        },
        should_already_exist => {
            summary => 'Whether group should already exist',
            schema  => 'bool',
        },
        %{ $SPEC{addgroup}{args} },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
for (qw/setup_unix_group/) {
    $SPEC{$_}{args}{min_new_gid} = delete $SPEC{$_}{args}{min_gid};
    $SPEC{$_}{args}{max_new_gid} = delete $SPEC{$_}{args}{max_gid};
    $SPEC{$_}{args}{new_gid}     = delete $SPEC{$_}{args}{gid};
}
sub setup_unix_group {
    my %args = @_;

    # TMP, schema
    my $dry_run       = $args{-dry_run};
    my $group         = $args{group} or return [400, "Please specify group"];
    $group =~ $Unix::Passwd::File::re_group
        or return [400, "Invalid group"];
    my $should_exist  = $args{should_exist} // 1;
    my $should_aexist = $args{should_already_exist};
    my %ca            = (etc_dir=>$args{etc_dir}, group=>$group);

    my $exists = Unix::Passwd::File::group_exists(%ca);
    my (@do, @undo);

    #$log->tracef("group=%s, exists=%s, should_exist=%s, ", $group, $exists, $should_exist);
    if ($exists) {
        if (!$should_exist) {
            log_info("(DRY) Deleting group $group ...");
            push    @do  , [delgroup=>{%ca}];
            unshift @undo, [addgroup=>{
                %ca,
                maybe gid     => $args{new_gid},
                maybe min_gid => $args{min_new_gid},
                maybe max_gid => $args{max_new_gid},
            }];
        }
    } else {
        if ($should_aexist) {
            return [412, "Group $group should already exist"];
        } elsif ($should_exist) {
            log_info("(DRY) Adding group $group ...");
            push    @do  , [addgroup=>{
                %ca,
                maybe gid     => $args{new_gid},
                maybe min_gid => $args{min_new_gid},
                maybe max_gid => $args{max_new_gid},
            }];
            unshift @do  , [delgroup=>{%ca}];
        }
    }

    if (@do) {
        return [200, "", undef, {do_actions=>\@do, undo_actions=>\@undo}];
    } else {
        return [304, "Already fixed"];
    }
}

1;
# ABSTRACT: Setup Unix group (existence)

__END__

=pod

=encoding UTF-8

=head1 NAME

Setup::Unix::Group - Setup Unix group (existence)

=head1 VERSION

This document describes version 0.14 of Setup::Unix::Group (from Perl distribution Setup-Unix-User), released on 2017-07-10.

=head1 FUNCTIONS


=head2 addgroup

Usage:

 addgroup(%args) -> [status, msg, result, meta]

Add group.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Location of passwd files.

=item * B<gid> => I<int>

Add with specified GID.

If not specified, will search an unused GID from C<min_new_gid> to C<max_new_gid>.

If specified, will accept non-unique GID (that which has been used by other
group).

=item * B<group> => I<str>

Group name.

=item * B<max_gid> => I<int> (default: 65534)

Specify range for new GID.

If a free GID between C<min_gid> and C<max_gid> is not available, an error is
returned.

Passed to Unix::Passwd::File's C<max_new_gid>.

=item * B<min_gid> => I<int> (default: 1000)

Specify range for new GID.

If a free GID between C<min_gid> and C<max_gid> is not available, an error is
returned.

Passed to Unix::Passwd::File's C<min_new_gid>.

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 delgroup

Usage:

 delgroup(%args) -> [status, msg, result, meta]

Delete group.

Fixed state: group does not exist.

Fixable state: group exists.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Location of passwd files.

=item * B<group> => I<str>

Group name.

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 setup_unix_group

Usage:

 setup_unix_group(%args) -> [status, msg, result, meta]

Setup Unix group (existence).

On do, will create Unix group if not already exists. The created GID will be
returned in the result (C<< {gid =E<gt> GID} >>). If C<should_already_exist> is set to
true, won't create but only require that group already exists. If C<should_exist>
is set to false, will delete existing group instead of creating it.

On undo, will delete Unix group previously created.

On redo, will recreate the Unix group with the same GID.

This function is not exported by default, but exportable.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Location of passwd files.

=item * B<group> => I<str>

Group name.

=item * B<max_new_gid> => I<int> (default: 65534)

Specify range for new GID.

If a free GID between C<min_gid> and C<max_gid> is not available, an error is
returned.

Passed to Unix::Passwd::File's C<max_new_gid>.

=item * B<min_new_gid> => I<int> (default: 1000)

Specify range for new GID.

If a free GID between C<min_gid> and C<max_gid> is not available, an error is
returned.

Passed to Unix::Passwd::File's C<min_new_gid>.

=item * B<new_gid> => I<int>

Add with specified GID.

If not specified, will search an unused GID from C<min_new_gid> to C<max_new_gid>.

If specified, will accept non-unique GID (that which has been used by other
group).

=item * B<should_already_exist> => I<bool>

Whether group should already exist.

=item * B<should_exist> => I<bool> (default: 1)

Whether group should exist.

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Setup-Unix-User>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Setup-Unix-User>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Setup-Unix-User>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Setup>

L<Setup::Unix::User>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
