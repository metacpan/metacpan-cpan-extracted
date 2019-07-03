package Module::Abstract::Cwalitee::Core;

our $DATE = '2019-07-03'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

#use Module::Abstract::CwaliteeCommon;

our %SPEC;

$SPEC{indicator_not_empty} = {
    v => 1.1,
    args => {
    },
    #'x.indicator.error'    => '', #
    #'x.indicator.remedy'   => '', #
    #'x.indicator.severity' => '', # 1-5
    #'x.indicator.status'   => '', # experimental, stable*
    'x.indicator.priority' => 1,
};
sub indicator_not_empty {
    my %args = @_;
    my $r = $args{r};

    my $ab = $r->{abstract};
    defined($ab) && $ab =~ /\S/ ?
        [200, "OK", ''] : [200, "OK", 'Abstract is empty'];
}

$SPEC{indicator_not_too_short} = {
    v => 1.1,
    args => {
        min_len => {
            schema => 'uint*',
            default => 10,
        },
    },
};
sub indicator_not_too_short {
    my %args = @_;
    my $min_len = $args{min_len} // 10;
    my $r = $args{r};

    my $ab = $r->{abstract};
    defined $ab or return [412];

    length $ab >= $min_len ?
        [200, "OK", ''] : [200, "OK", "Abstract is too short (<$min_len characters)"];
}

$SPEC{indicator_not_too_long} = {
    v => 1.1,
    args => {
        max_len => {
            schema => 'uint*',
            default => 72,
        },
    },
};
sub indicator_not_too_long {
    my %args = @_;
    my $max_len = $args{max_len} // 72;
    my $r = $args{r};

    my $ab = $r->{abstract};
    defined $ab or return [412];

    length $ab <= $max_len ?
        [200, "OK", ''] : [200, "OK", "Abstract is too long (>$max_len characters)"];
}

$SPEC{indicator_not_multiline} = {
    v => 1.1,
    args => {
    },
};
sub indicator_not_multiline {
    my %args = @_;
    my $r = $args{r};

    my $ab = $r->{abstract};
    defined $ab or return [412];

    $ab !~ /\R/ ?
        [200, "OK", ''] : [200, "OK", 'Abstract is multiline'];
}

$SPEC{indicator_not_template} = {
    v => 1.1,
    args => {
    },
};
sub indicator_not_template {
    my %args = @_;
    my $r = $args{r};

    my $ab = $r->{abstract};
    defined $ab or return [412];

    if ($ab =~ /^(Perl extension for blah blah blah)/i) {
        [200, "OK", "Template from h2xs '$1'"];
    } elsif ($ab =~ /^(The great new )\w+(::\w+)*/i) {
        [200, "OK", "Template from module-starter '$1'"];
    } elsif ($ab =~ /^\b(blah blah)\b/i) {
        [200, "OK", "Looks like a template"];
    } else {
        [200, "OK", ""];
    }
}

$SPEC{indicator_not_start_with_lowercase_letter} = {
    v => 1.1,
    args => {
    },
};
sub indicator_not_start_with_lowercase_letter {
    my %args = @_;
    my $r = $args{r};

    my $ab = $r->{abstract};
    defined $ab or return [412];

    $ab !~ /^\s*[a-z]/ ?
        [200, "OK", ""] : [200, "OK", "Abstract starts with a lowercase letter"];
}

$SPEC{indicator_not_end_with_dot} = {
    v => 1.1,
    args => {
    },
};
sub indicator_not_end_with_dot {
    my %args = @_;
    my $r = $args{r};

    my $ab = $r->{abstract};
    defined $ab or return [412];

    $ab !~ /\.\s*\z/ ?
        [200, "OK", ''] : [200, "OK", "Abstract ends with dot"];
}

$SPEC{indicator_not_redundant} = {
    v => 1.1,
    args => {
    },
    'x.indicator.severity' => 2,
};
sub indicator_not_redundant {
    my %args = @_;
    my $r = $args{r};

    my $ab = $r->{abstract};
    defined $ab or return [412];

    if ($ab =~ /^( (?: (?:a|the) \s+)?
                    (?: perl\s?[56]? \s+)?
                    (?:extension|module|library|interface|xs \s binding)
                    (?: \s+ (?:to|for))?
                )/xi) {
        return [200, "OK", "Saying '$1' is redundant, omit it"];
    } else {
        [200, "OK", ''];
    }
}

$SPEC{indicator_language_english} = {
    v => 1.1,
    args => {
    },
};
sub indicator_language_english {
    require Lingua::Identify;

    my %args = @_;
    my $r = $args{r};

    my $ab = $r->{abstract};
    defined $ab or return [412];

    my %langs = Lingua::Identify::langof($ab);
    return [412, "Lingua::Identify cannot detect language"] unless keys(%langs);

    my @langs = sort { $langs{$b}<=>$langs{$a} } keys %langs;
    my $confidence = Lingua::Identify::confidence(%langs);
    log_trace(
        "Lingua::Identify result: langof=%s, langs=%s, confidence=%s",
        \%langs, \@langs, $confidence);
    if ($langs[0] ne 'en') {
        [200, "OK", "Language not detected as English, ".
             sprintf("%d%% %s (confidence %.2f)",
                     $langs{$langs[0]}*100, $langs[0], $confidence)];
    } else {
        [200, "OK", ''];
    }
}

$SPEC{indicator_no_shouting} = {
    v => 1.1,
    args => {
    },
};
sub indicator_no_shouting {
    my %args = @_;
    my $r = $args{r};

    my $ab = $r->{abstract};
    defined $ab or return [412];

    if ($ab =~ /!{3,}/) {
        [200, "OK", "Too many exclamation points"];
    } else {
        my $spaces = 0; $spaces++ while $ab =~ s/\s+//;
        $ab =~ s/\W+//g;
        $ab =~ s/\d+//g;
        if ($ab =~ /^[[:upper:]]+$/ && $spaces >= 2) {
            return [200, "OK", "All-caps"];
        } else {
            return [200, "OK", ''];
        }
    }
}

$SPEC{indicator_not_module_name} = {
    v => 1.1,
    args => {
    },
};
sub indicator_not_module_name {
    my %args = @_;
    my $r = $args{r};

    my $ab = $r->{abstract};
    defined $ab or return [412];

    if ($ab =~ /^\w+(::\w+)+$/) {
        [200, "OK", "Should not just be a module name"];
    } else {
        [200, "OK", ''];
    }
}

1;
# ABSTRACT: A collection of core indicators for module abstract cwalitee

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Abstract::Cwalitee::Core - A collection of core indicators for module abstract cwalitee

=head1 VERSION

This document describes version 0.001 of Module::Abstract::Cwalitee::Core (from Perl distribution Module-Abstract-Cwalitee), released on 2019-07-03.

=head1 FUNCTIONS


=head2 indicator_language_english

Usage:

 indicator_language_english() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 indicator_no_shouting

Usage:

 indicator_no_shouting() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 indicator_not_empty

Usage:

 indicator_not_empty() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 indicator_not_end_with_dot

Usage:

 indicator_not_end_with_dot() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 indicator_not_module_name

Usage:

 indicator_not_module_name() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 indicator_not_multiline

Usage:

 indicator_not_multiline() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 indicator_not_redundant

Usage:

 indicator_not_redundant() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 indicator_not_start_with_lowercase_letter

Usage:

 indicator_not_start_with_lowercase_letter() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 indicator_not_template

Usage:

 indicator_not_template() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 indicator_not_too_long

Usage:

 indicator_not_too_long(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<max_len> => I<uint> (default: 72)

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 indicator_not_too_short

Usage:

 indicator_not_too_short(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<min_len> => I<uint> (default: 10)

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

Please visit the project's homepage at L<https://metacpan.org/release/Module-Abstract-Cwalitee>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Abstract-Cwalitee>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Abstract-Cwalitee>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
