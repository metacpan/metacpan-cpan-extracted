package Perinci::Examples::Stream;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010;
use strict;
use warnings;

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
         return undef if defined($num) && $i > $num;
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
         return undef if defined($num) && $i > $num;
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
         return undef if defined($num) && $i > $num;
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
         return undef if defined($num) && $i > $num;
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
         return undef unless defined $n;
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

This document describes version 0.814 of Perinci::Examples::Stream (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 DESCRIPTION


This package contains functions that demonstrate streaming input/output.

=head1 FUNCTIONS


=head2 count_ints

Usage:

 count_ints(%args) -> [status, msg, payload, meta]

This function accepts a stream of integers and return the number of integers input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<array[int]>

Numbers.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 count_lines

Usage:

 count_lines(%args) -> [status, msg, payload, meta]

Count number of lines in the input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<array[str]>

Lines.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 count_words

Usage:

 count_words(%args) -> [status, msg, payload, meta]

This function receives a stream of words and return the number of words.

Input validation will check that each record from the stream is a word.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 produce_hashes

Usage:

 produce_hashes(%args) -> [status, msg, payload, meta]

This function produces a stream of hashes.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num> => I<int>

Limit number of entries to produce.

The default is to produce an infinite number.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (array[hash])



=head2 produce_ints

Usage:

 produce_ints(%args) -> [status, msg, payload, meta]

This function produces a stream of integers, starting from 1.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num> => I<int>

Limit number of entries to produce.

The default is to produce an infinite number.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (array[int])



=head2 produce_words

Usage:

 produce_words(%args) -> [status, msg, payload, meta]

This function produces a stream of random words.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num> => I<int>

Limit number of entries to produce.

The default is to produce an infinite number.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (array[str])



=head2 produce_words_err

Usage:

 produce_words_err(%args) -> [status, msg, payload, meta]

Like `produce_words()`, but 1 in every 10 words will be a non-word (which fails the result schema).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num> => I<int>

Limit number of entries to produce.

The default is to produce an infinite number.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (array[str])



=head2 square_nums

Usage:

 square_nums(%args) -> [status, msg, payload, meta]

This function squares its stream input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<array[float]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (array[float])



=head2 square_nums_from_file

Usage:

 square_nums_from_file(%args) -> [status, msg, payload, meta]

This function squares its stream input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<array[float]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (array[float])



=head2 square_nums_from_stdin

Usage:

 square_nums_from_stdin(%args) -> [status, msg, payload, meta]

This function squares its stream input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<array[float]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (array[float])



=head2 square_nums_from_stdin_or_file

Usage:

 square_nums_from_stdin_or_file(%args) -> [status, msg, payload, meta]

This function squares its stream input.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<float>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (array[float])



=head2 wc

Usage:

 wc(%args) -> [status, msg, payload, meta]

Count the number of lines/words/characters of input, like the "wc" command.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (hash)



=head2 wc_keys

Usage:

 wc_keys(%args) -> [status, msg, payload, meta]

Count the number of keys of each hash.

This is a simple demonstration of accepting a stream of hashes. In command-line
application this will translate to JSON stream.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<array[hash]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
