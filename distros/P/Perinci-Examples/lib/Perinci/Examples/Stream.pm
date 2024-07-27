package Perinci::Examples::Stream;

use 5.010;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'Perinci-Examples'; # DIST
our $VERSION = '0.825'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Examples for streaming input/output',
    description => <<'_',

This package contains functions that demonstrate streaming input/output.

_
};

my %arg_num = (
    num => {
        summary => 'Limit number of entries to produce',
        description => <<'_',

The default is to produce an infinite number.

_
        schema => ['int*', min=>0],
        cmdline_aliases => {n=>{}},
        pos => 0,
    },
);

$SPEC{produce_ints} = {
    v => 1.1,
    summary => 'This function produces a stream of integers, starting from 1',
    tags => ['category:streaming-result'],
    args => {
        %arg_num,
    },
    result => {
        stream => 1,
        schema => ['array*', of=>'int*'],
    },
};
sub produce_ints {
    my %args = @_;
    my $i = 1;
    my $num = $args{num};
    [200, "OK", sub {
         return undef if defined($num) && $i > $num; ## no critic: Subroutines::ProhibitExplicitReturnUndef
         $i++;
     }];
}

$SPEC{count_ints} = {
    v => 1.1,
    summary => 'This function accepts a stream of integers and return the number of integers input',
    tags => ['category:streaming-input'],
    args => {
        input => {
            summary => 'Numbers',
            schema => ['array*', of=>'int*'],
            stream => 1,
            cmdline_src => 'stdin_or_files',
        },
    },
};
sub count_ints {
    my %args = @_;
    my $input = $args{input};
    my $n = 0;
    $n++ while defined $input->();
    [200, "OK", $n];
}

$SPEC{count_lines} = {
    v => 1.1,
    summary => 'Count number of lines in the input',
    tags => ['category:streaming-input'],
    args => {
        input => {
            summary => 'Lines',
            schema => ['array*', of=>'str*'],
            stream => 1,
            cmdline_src => 'stdin_or_files',
        },
    },
};
sub count_lines {
    my %args = @_;
    my $input = $args{input};
    my $n = 0;
    $n++ while defined $input->();
    [200, "OK", "Input is $n line(s)"];
}

$SPEC{produce_words} = {
    v => 1.1,
    summary => 'This function produces a stream of random words',
    tags => ['category:streaming-result'],
    args => {
        %arg_num,
    },
    result => {
        stream => 1,
        schema => ['array*', of=>['str*', match=>'\A\w+\z']],
    },
};
sub produce_words {
    my %args = @_;
    my $i = 1;
    my $num = $args{num};
    [200, "OK", sub {
         return undef if defined($num) && $i > $num; ## no critic: Subroutines::ProhibitExplicitReturnUndef
         $i++;
         join('', map { ['a'..'z']->[26*rand()] } 1..(int(6*rand)+5));
     }];
}

$SPEC{produce_words_err} = {
    v => 1.1,
    summary => 'Like `produce_words()`, but 1 in every 10 words will be a non-word (which fails the result schema)',
    tags => ['categoryr:streaming-result'],
    args => {
        %arg_num,
    },
    result => {
        stream => 1,
        schema => ['array*', of => ['str*', match=>'\A\w+\z']],
    },
};
sub produce_words_err {
    my %args = @_;
    my $i = 1;
    my $num = $args{num};
    [200, "OK", sub {
         return undef if defined($num) && $i > $num; ## no critic: Subroutines::ProhibitExplicitReturnUndef
         if ($i++ % 10 == 0) {
             "contain space";
         } else {
             join('', map { ['a'..'z']->[26*rand()] } 1..(int(6*rand)+5));
         }
     }];
}

$SPEC{count_words} = {
    v => 1.1,
    summary => 'This function receives a stream of words and return the number of words',
    tags => ['category:streaming-input'],
    description => <<'_',

Input validation will check that each record from the stream is a word.

_
    args => {
        input => {
            schema => ['array*', of=>['str*', match=>'\A\w+\z']],
            stream => 1,
            cmdline_src => 'stdin_or_files',
        },
    },
};
sub count_words {
    my %args = @_;

    my $input = $args{input};
    my $num = 0;
    while (defined($input->())) {
        $num++;
    }
    [200, "OK", $num];
}

$SPEC{produce_hashes} = {
    v => 1.1,
    summary => 'This function produces a stream of hashes',
    args => {
        %arg_num,
    },
    result => {
        stream => 1,
        schema => ['array*', of=>'hash*'],
    },
};
sub produce_hashes {
    my %args = @_;
    my $num = $args{num};

    my $i = 1;
    [200, "OK", sub {
         return undef if defined($num) && $i > $num; ## no critic: Subroutines::ProhibitExplicitReturnUndef
         {num=>$i++};
     }];
}

$SPEC{square_nums} = {
    v => 1.1,
    summary => 'This function squares its stream input',
    tags => ['category:streaming-input', 'category:streaming-result'],
    args => {
        input => {
            req => 1,
            stream => 1,
            schema => ['array*', of=>'float*'],
            cmdline_src => 'stdin_or_files',
        },
    },
    result => {
        stream => 1,
        schema => ['array*', of=>'float*'],
    },
};
sub square_nums {
    my %args = @_;
    my $input = $args{input};

    [200, "OK", sub {
         my $n = $input->();
         return undef unless defined $n; ## no critic: Subroutines::ProhibitExplicitReturnUndef
         $n*$n;
     }];
}

$SPEC{square_nums_from_file} = {
    v => 1.1,
    summary => 'This function squares its stream input',
    tags => ['category:streaming-input', 'category:streaming-result'],
    args => {
        input => {
            req => 1,
            pos => 0,
            stream => 1,
            schema => ['array*', of=>'float*'],
            cmdline_src => 'file',
        },
    },
    result => {
        stream => 1,
        schema => ['array*', of=>'float*'],
    },
};
sub square_nums_from_file {
    goto &square_input;
}

$SPEC{square_nums_from_stdin} = {
    v => 1.1,
    summary => 'This function squares its stream input',
    tags => ['category:streaming-input', 'category:streaming-result'],
    args => {
        input => {
            req => 1,
            pos => 0,
            stream => 1,
            schema => ['array*', of=>'float*'],
            cmdline_src => 'stdin',
        },
    },
    result => {
        stream => 1,
        schema => ['array*', of=>'float*'],
    },
};
sub square_nums_from_stdin {
    goto &square_input;
}

$SPEC{square_nums_from_stdin_or_file} = {
    v => 1.1,
    summary => 'This function squares its stream input',
    tags => ['category:streaming-input', 'category:streaming-result'],
    args => {
        input => {
            req => 1,
            pos => 0,
            stream => 1,
            schema => 'float*',
            cmdline_src => 'stdin_or_file',
        },
    },
    result => {
        stream => 1,
        schema => ['array*', of=>'float*'],
    },
};
sub square_nums_from_stdin_or_file {
    goto &square_input;
}

$SPEC{wc} = {
    v => 1.1,
    summary => 'Count the number of lines/words/characters of input, like the "wc" command',
    tags => ['category:streaming-input'],
    args => {
        input => {
            req => 1,
            stream => 1,
            schema => ['array*', of=>'str*'],
            cmdline_src => 'stdin_or_files',
            'cmdline.chomp' => 0,
        },
    },
    result => {
        schema => 'hash*',
    },
};
sub wc {
    my %args = @_;
    my $input = $args{input};

    my ($lines, $words, $chars) = (0,0,0);
    while (defined( my $line = $input->())) {
        $lines++;
        $words++ for $line =~ /(\S+)/g;
        $chars += length($line);
    }
    [200, "OK", {lines=>$lines, words=>$words, chars=>$chars}];
}

$SPEC{wc_keys} = {
    v => 1.1,
    summary => 'Count the number of keys of each hash',
    tags => ['category:streaming-input'],
    description => <<'_',

This is a simple demonstration of accepting a stream of hashes. In command-line
application this will translate to JSON stream.

_
    args => {
        input => {
            req => 1,
            stream => 1,
            schema => ['array*', of=>'hash*'],
            cmdline_src => 'stdin_or_files',
        },
    },
    result => {
        schema => 'hash*',
    },
};
sub wc_keys {
    my %args = @_;
    my $input = $args{input};

    my ($keys) = (0);
    while (defined(my $hash = $input->())) {
        $keys += keys %$hash;
    }
    [200, "OK", {keys=>$keys}];
}

1;
# ABSTRACT: Examples for streaming input/output

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Stream - Examples for streaming input/output

=head1 VERSION

This document describes version 0.825 of Perinci::Examples::Stream (from Perl distribution Perinci-Examples), released on 2024-07-17.

=head1 DESCRIPTION


This package contains functions that demonstrate streaming input/output.

=head1 FUNCTIONS


=head2 count_ints

Usage:

 count_ints(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function accepts a stream of integers and return the number of integers input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<array[int]>

Numbers.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 count_lines

Usage:

 count_lines(%args) -> [$status_code, $reason, $payload, \%result_meta]

Count number of lines in the input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<array[str]>

Lines.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 count_words

Usage:

 count_words(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function receives a stream of words and return the number of words.

Input validation will check that each record from the stream is a word.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<array[str]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 produce_hashes

Usage:

 produce_hashes(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function produces a stream of hashes.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num> => I<int>

Limit number of entries to produce.

The default is to produce an infinite number.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (array[hash])



=head2 produce_ints

Usage:

 produce_ints(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function produces a stream of integers, starting from 1.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num> => I<int>

Limit number of entries to produce.

The default is to produce an infinite number.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (array[int])



=head2 produce_words

Usage:

 produce_words(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function produces a stream of random words.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num> => I<int>

Limit number of entries to produce.

The default is to produce an infinite number.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (array[str])



=head2 produce_words_err

Usage:

 produce_words_err(%args) -> [$status_code, $reason, $payload, \%result_meta]

Like `produce_words()`, but 1 in every 10 words will be a non-word (which fails the result schema).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num> => I<int>

Limit number of entries to produce.

The default is to produce an infinite number.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (array[str])



=head2 square_nums

Usage:

 square_nums(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function squares its stream input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<array[float]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (array[float])



=head2 square_nums_from_file

Usage:

 square_nums_from_file(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function squares its stream input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<array[float]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (array[float])



=head2 square_nums_from_stdin

Usage:

 square_nums_from_stdin(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function squares its stream input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<array[float]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (array[float])



=head2 square_nums_from_stdin_or_file

Usage:

 square_nums_from_stdin_or_file(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function squares its stream input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<float>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (array[float])



=head2 wc

Usage:

 wc(%args) -> [$status_code, $reason, $payload, \%result_meta]

Count the number of linesE<sol>wordsE<sol>characters of input, like the "wc" command.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<array[str]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (hash)



=head2 wc_keys

Usage:

 wc_keys(%args) -> [$status_code, $reason, $payload, \%result_meta]

Count the number of keys of each hash.

This is a simple demonstration of accepting a stream of hashes. In command-line
application this will translate to JSON stream.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<array[hash]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2023, 2022, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
