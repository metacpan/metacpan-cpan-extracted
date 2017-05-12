package Parse::Sums;

our $DATE = '2016-11-23'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(parse_sums);

our %SPEC;

sub _guess_algo {
    my $str = shift;
    my $len = length($str);
    if ($len == 8) {
        return ('crc32', 0);
    } elsif ($len == 32) {
        return ('md5', 0);
    } elsif ($len == 40) {
        return ('sha1', 0);
    } elsif ($len == 56) {
        return ('sha224', 1); # or sha512224
    } elsif ($len == 64) {
        return ('sha256', 1); # or sha512256
    } elsif ($len == 96) {
        return ('sha384', 0);
    } elsif ($len == 128) {
        return ('sha512', 0);
    } else {
        return '';
    }
}

$SPEC{parse_sums} = {
    v => 1.1,
    summary => 'Parse checksums file (e.g. MD5SUMS, SHA1SUMS)',
    args => {
        filename => {
            summary => 'Checksums filename',
            schema => 'filename*',
        },
        content => {
            summary => 'Content of checksums file',
            schema => 'str*',
            description => <<'_',

If specified, then `filename` contents will not be read.

_
        },
    },
    examples => [
    ],
};
sub parse_sums {
    my %args = @_;

    my $filename = $args{filename};
    my $content  = $args{content};
    unless (defined $content) {
        open my($fh), "<", $filename
            or return [500, "Can't read '$filename': $!"];
        local $/;
        $content = <$fh>;
    }

    my $algo;
    if (defined $filename) {
        if ($filename =~ /(crc32|md5|sha[_-]?(?:512224|512256|224|256|384|512|1))/i) {
            $algo = lc($1);
        }
    }

    my @res;
    my $num_invalid_lines = 0;
    my $linenum = 0;
    for my $line (split /^/, $content) {
        $linenum++;
        next unless $line =~ /\S/;
        my ($digest, $line_algo, $multiple, $file);
        if ($line =~ /\A([0-9A-Fa-f]+)\s+\*?(.+)$/) {
            $digest = $1;
            ($line_algo, $multiple) = _guess_algo($1);
            $file = $2;
        } elsif ($line =~ /\A(\w+) \((.+)\) = ([0-9A-Fa-f]+)$/) {
            $digest = $3;
            (undef, $multiple) = _guess_algo($3);
            $file = $2;
            $line_algo = lc($1); $line_algo =~ s/-//g;
        } else {
            $num_invalid_lines++;
            next;
        }
        if ($algo && !$multiple && $algo ne $line_algo) {
            $num_invalid_lines++;
            next;
        }
        $line_algo = $algo if $algo;
        if (!$line_algo) {
            $num_invalid_lines++;
            next;
        }
        push @res, {algorithm=>$line_algo, file=>$file, digest=>$digest, linenum=>$linenum};
    }
    [200, "OK", \@res, {
        ('func.warning' => ($num_invalid_lines > 1 ? "$num_invalid_lines lines are" : "1 line is")." improperly formatted") x !!$num_invalid_lines,
    }];
}

1;
# ABSTRACT: Parse checksums file (e.g. MD5SUMS, SHA1SUMS)

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Sums - Parse checksums file (e.g. MD5SUMS, SHA1SUMS)

=head1 VERSION

This document describes version 0.001 of Parse::Sums (from Perl distribution Parse-Sums), released on 2016-11-23.

=head1 SYNOPSIS

 use Parse::Sums qw(parse_sums);
 my $res = parse_sums(filename => 'MD5SUMS');

=head1 FUNCTIONS


=head2 parse_sums(%args) -> [status, msg, result, meta]

Parse checksums file (e.g. MD5SUMS, SHA1SUMS).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<content> => I<str>

Content of checksums file.

If specified, then C<filename> contents will not be read.

=item * B<filename> => I<filename>

Checksums filename.

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

Please visit the project's homepage at L<https://metacpan.org/release/Parse-Sums>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-Sums>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Sums>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<xsum> from L<App::xsum>.

L<shasum> which comes with the perl distribution.

Unix utilities: L<md5sum>, L<sha1sum>, L<sha256sum>, etc.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
