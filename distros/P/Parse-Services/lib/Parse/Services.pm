package Parse::Services;

our $DATE = '2016-10-26'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(parse_services);

our %SPEC;

$SPEC{parse_services} = {
    v => 1.1,
    summary => 'Parse /etc/hosts',
    args => {
        content => {
            summary => 'Content of /etc/services file',
            description => <<'_',

Optional. Will attempt to read `/etc/services` from filesystem if not specified.

_
            schema => 'str*',
        },
    },
    examples => [
    ],
};
sub parse_services {
    my %args = @_;

    my $content = $args{content};
    unless (defined $content) {
        open my($fh), "<", "/etc/services"
            or return [500, "Can't read /etc/services: $!"];
        local $/;
        $content = <$fh>;
    }

    my @res;
    for my $line (split /^/, $content) {
        $line =~ s/#.*//;
        next unless $line =~ /\S/;
        chomp $line;
        my ($name, $port_proto, @aliases) = split /\s+/, $line;
        my ($port, $proto) = split m!/!, $port_proto;
        push @res, {
            name  => $name,
            port  => $port,
            proto => $proto,
            aliases => \@aliases,
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

Parse::Services - Parse /etc/hosts

=head1 VERSION

This document describes version 0.001 of Parse::Services (from Perl distribution Parse-Services), released on 2016-10-26.

=head1 SYNOPSIS

 use Parse::Services qw(parse_services);
 my $res = parse_services();

=head1 FUNCTIONS


=head2 parse_services(%args) -> [status, msg, result, meta]

Parse /etc/hosts.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<content> => I<str>

Content of /etc/services file.

Optional. Will attempt to read C</etc/services> from filesystem if not specified.

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

Please visit the project's homepage at L<https://metacpan.org/release/Parse-Services>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-Services>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Services>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<parse-services> from L<App::ParseServices>, CLI script.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
