package Rclone::Util;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-15'; # DATE
our $DIST = 'Rclone-Util'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       parse_rclone_config
               );

our %SPEC;

our %argspecs_common = (
    rclone_config_filenames => {
        schema => ['array*', of=>'filename*'],
        tags => ['category:configuration'],
    },
    rclone_config_dirs => {
        schema => ['array*', of=>'dirname*'],
        tags => ['category:configuration'],
    },
);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utility routines related to rclone',
};

$SPEC{parse_rclone_config} = {
    v => 1.1,
    summary => 'Read and parse rclone configuration file(s)',
    description => <<'_',

By default will search these paths for `rclone.conf`:

All found files will be read, parsed, and merged.

Returns the merged config hash.

_
    args => {
        %argspecs_common,
    },
};
sub parse_rclone_config {
    my %args = @_;

    my @dirs      = @{ $args{rclone_config_dirs} // ["$ENV{HOME}/.config/rclone", "/etc/rclone", "/etc"] }; # XXX on windows?
    my @filenames = @{ $args{rclone_config_filenames} // ["rclone.conf"] };

    my @paths;
    for my $dir (@dirs) {
        for my $filename (@filenames) {
            my $path = "$dir/$filename";
            next unless -f $path;
            push @paths, $path;
        }
    }
    unless (@paths) {
        return [412, "No config paths found/specified"];
    }

    require Config::IOD::Reader;
    my $reader = Config::IOD::Reader->new;
    my $merged_config_hash;
    for my $path (@paths) {
        my $config_hash;
        eval { $config_hash = $reader->read_file($path) };
        return [500, "Error in parsing config file $path: $@"] if $@;
        for my $section (keys %$config_hash) {
            my $hash = $config_hash->{$section};
            for my $param (keys %$hash) {
                $merged_config_hash->{$section}{$param} = $hash->{$param};
            }
        }
    }
    [200, "OK", $merged_config_hash];
}

$SPEC{list_rclone_remotes} = {
    v => 1.1,
    summary => 'List known rclone remotes from rclone configuration file',
    args => {
        %argspecs_common,
    },
};
sub list_rclone_remotes {
    my %args = @_;
    my $res = parse_rclone_config(%args);
    return $res unless $res->[0] == 200;
    my $config = $res->[2];
    [200, "OK", [sort keys %$config]];
}

1;
# ABSTRACT: Utility routines related to rclone

__END__

=pod

=encoding UTF-8

=head1 NAME

Rclone::Util - Utility routines related to rclone

=head1 VERSION

This document describes version 0.002 of Rclone::Util (from Perl distribution Rclone-Util), released on 2021-05-15.

=for Pod::Coverage .+

=head1 FUNCTIONS


=head2 list_rclone_remotes

Usage:

 list_rclone_remotes(%args) -> [status, msg, payload, meta]

List known rclone remotes from rclone configuration file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<rclone_config_dirs> => I<array[dirname]>

=item * B<rclone_config_filenames> => I<array[filename]>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_rclone_config

Usage:

 parse_rclone_config(%args) -> [status, msg, payload, meta]

Read and parse rclone configuration file(s).

By default will search these paths for C<rclone.conf>:

All found files will be read, parsed, and merged.

Returns the merged config hash.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<rclone_config_dirs> => I<array[dirname]>

=item * B<rclone_config_filenames> => I<array[filename]>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Rclone-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Rclone-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Rclone-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://rclone.org>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
