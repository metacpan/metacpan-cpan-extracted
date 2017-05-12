package Parse::Hosts;

our $DATE = '2016-10-17'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(parse_hosts);

our %SPEC;

$SPEC{parse_hosts} = {
    v => 1.1,
    summary => 'Parse /etc/hosts',
    args => {
        content => {
            summary => 'Content of /etc/hosts file',
            description => <<'_',

Optional. Will attempt to read `/etc/hosts` from filesystem if not specified.

_
            schema => 'str*',
        },
    },
    examples => [
    ],
};
sub parse_hosts {
    my %args = @_;

    my $content = $args{content};
    unless (defined $content) {
        open my($fh), "<", "/etc/hosts"
            or return [500, "Can't read /etc/hosts: $!"];
        local $/;
        $content = <$fh>;
    }

    my @res;
    for my $line (split /^/, $content) {
        next unless $line =~ /\S/;
        chomp $line;
        next if $line =~ /^\s*#/;
        my ($ip, @hosts) = split /\s+/, $line;
        push @res, {
            ip => $ip,
            hosts => \@hosts,
        };
    }
    [200, "OK", \@res];
}

1;
# ABSTRACT: Parse /etc/hosts

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Hosts - Parse /etc/hosts

=head1 VERSION

This document describes version 0.002 of Parse::Hosts (from Perl distribution Parse-Hosts), released on 2016-10-17.

=head1 SYNOPSIS

 use Parse::Hosts qw(parse_hosts);
 my $res = parse_hosts();

=head1 FUNCTIONS


=head2 parse_hosts(%args) -> [status, msg, result, meta]

Parse /etc/hosts.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<content> => I<str>

Content of /etc/hosts file.

Optional. Will attempt to read C</etc/hosts> from filesystem if not specified.

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

Please visit the project's homepage at L<https://metacpan.org/release/Parse-Hosts>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-Hosts>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Hosts>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<parse-hosts> from L<App::ParseHosts>, CLI script.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
