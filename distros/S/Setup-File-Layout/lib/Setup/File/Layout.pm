package Setup::File::Layout;

our $DATE = '2015-09-11'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any::IfLOG '$log';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       setup_files_using_layout
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Setup files using a layout',
};

$SPEC{setup_files_using_layout} = {
    v => 1.1,
    summary => 'Setup files using layout',
    description => <<'_',

For more details on the format of the layout, see `File::Create::Layout`.

_
    args => {
        layout => {
            summary => 'Layout',
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        prefix => {
            summary => 'Starting path to create the layout in',
            schema => 'str*',
            req    => 1,
            pos    => 1,
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub setup_files_using_layout {
    require Cwd;
    require File::Create::Layout;
    require Perinci::Tx::Util;
    require Setup::File;
    require Setup::File::Symlink;

    my %args = @_;

    my $prefix = $args{prefix} or return [400, "Please specify prefix"];
    my $parse_res = File::Create::Layout::parse_layout(layout => $args{layout});
    return $parse_res unless $parse_res->[0] == 200;

    my @actions;

    my @dirs;
    for my $e (@{ $parse_res->[2] }) {

        $dirs[$e->{level}] = $e->{name} if $e->{is_dir};
        splice @dirs, $e->{level}+1;

        my $p = $prefix . join("", map {"/$_"} @dirs);

        if ($e->{is_dir}) {
            push @actions, ["Setup::File::setup_dir" => {
                should_exist => 1,
                path  => $p,
                # allow_symlink => 1, # XXX customizable
                mode  => $e->{perm},
                owner => $e->{user},
                group => $e->{group},
            }];
        } elsif ($e->{is_symlink}) {
            push @actions, ["Setup::File::Symlink::setup_symlink" => {
                symlink => Cwd::abs_path($p) . "/$e->{name}",
                target  => $e->{symlink_target},
                #mode    => $e->{perm},
                #owner   => $e->{user},
                #group   => $e->{group},
            }];
        } else {
            push @actions, ["Setup::File::setup_file" => {
                should_exist => 1,
                path  => "$p/$e->{name}",
                mode  => $e->{perm},
                owner => $e->{user},
                group => $e->{group},
                (content => $e->{content}) x !!(defined $e->{content}),
            }];
        }
    }

    #use DD; dd \@actions;
    Perinci::Tx::Util::use_other_actions(actions => \@actions);
}

1;
# ABSTRACT: Setup files using layout

__END__

=pod

=encoding UTF-8

=head1 NAME

Setup::File::Layout - Setup files using layout

=head1 VERSION

This document describes version 0.01 of Setup::File::Layout (from Perl distribution Setup-File-Layout), released on 2015-09-11.

=head1 SYNOPSIS

=head1 SEE ALSO

L<Setup>

L<File::Create::Layout>

=head1 FUNCTIONS


=head2 setup_files_using_layout(%args) -> [status, msg, result, meta]

Setup files using layout.

For more details on the format of the layout, see C<File::Create::Layout>.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<layout>* => I<str>

Layout.

=item * B<prefix>* => I<str>

Starting path to create the layout in.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Setup-File-Layout>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Setup-File-Layout>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Setup-File-Layout>

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
