package Module::Abstract::Cwalitee;

our $DATE = '2019-07-26'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Cwalitee::Common;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       calc_module_abstract_cwalitee
                       list_module_abstract_cwalitee_indicators
               );

our %SPEC;

$SPEC{list_module_abstract_cwalitee_indicators} = {
    v => 1.1,
    args => {
        Cwalitee::Common::args_list('Module::Abstract::'),
    },
    examples => [
        {
            summary => 'List all installed indicators from all modules',
            args => {},
            test => 0,
        },
        {
            summary => 'List only certain names, show details',
            args => {include=>[qw/not_too_short not_too_long not_template/], detail=>1},
            test => 0,
        },
    ],
};
sub list_module_abstract_cwalitee_indicators {
    my %args = @_;

    Cwalitee::Common::list_cwalitee_indicators(
        prefix => 'Module::Abstract::',
        %args,
    );
}

$SPEC{calc_module_abstract_cwalitee} = {
    v => 1.1,
    args => {
        Cwalitee::Common::args_calc('Module::Abstract::'),
        abstract => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    examples => [
        {
            summary => 'Example of a good Abstract',
            args => {abstract => 'Calculate the frobnitz of thromblemeisters'},
            test => 0,
        },
        {
            summary => 'Example of a not-so-good Abstract',
            args => {abstract => 'PERL MODULE TO DO SOMETHING'},
            test => 0,
        },
    ],
};
sub calc_module_abstract_cwalitee {
    my %fargs = @_;

    Cwalitee::Common::calc_cwalitee(
        prefix => 'Module::Abstract::',
        %fargs,
        code_init_r => sub {
            return {
                # module => ...
                abstract => $fargs{abstract},
            },
        },
    );
}

1;
# ABSTRACT: Calculate the cwalitee of your module Abstract

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Abstract::Cwalitee - Calculate the cwalitee of your module Abstract

=head1 VERSION

This document describes version 0.005 of Module::Abstract::Cwalitee (from Perl distribution Module-Abstract-Cwalitee), released on 2019-07-26.

=head1 SYNOPSIS

 use Module::Abstract::Cwalitee qw(
     calc_module_abstract_cwalitee
     list_module_abstract_cwalitee_indicators
 );

 my $res = calc_module_abstract_cwalitee(
     abstract => 'Calculate the cwalitee of your module Abstract',
 );

=head1 DESCRIPTION

B<What is module abstract cwalitee?> A metric to attempt to gauge the quality of
your module's Abstract. Since actual quality is hard to measure, this metric is
called a "cwalitee" instead. The cwalitee concept follows "kwalitee" [1] which
is specifically to measure the quality of CPAN distribution. I pick a different
spelling to avoid confusion with kwalitee. And unlike kwalitee, the unqualified
term "cwalitee" does not refer to a specific, particular subject. There can be
"module abstract cwalitee" (which is handled by this module), "CPAN Changes
cwalitee", and so on.

=head1 FUNCTIONS


=head2 calc_module_abstract_cwalitee

Usage:

 calc_module_abstract_cwalitee(%args) -> [status, msg, payload, meta]

Examples:

=over

=item * Example of a good Abstract:

 calc_module_abstract_cwalitee(abstract => "Calculate the frobnitz of thromblemeisters");

Result:

 [
   {
     indicator => "not_empty",
     num => 1,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "language_english",
     num => 2,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "no_shouting",
     num => 3,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_end_with_dot",
     num => 4,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_module_name",
     num => 5,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_multiline",
     num => 6,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_redundant",
     num => 7,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_start_with_lowercase_letter",
     num => 8,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_template",
     num => 9,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_too_long",
     num => 10,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_too_short",
     num => 11,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "Score",
     result => "100.00",
     result_summary => "11 out of 11",
   },
 ]

=item * Example of a not-so-good Abstract:

 calc_module_abstract_cwalitee(abstract => "PERL MODULE TO DO SOMETHING");

Result:

 [
   {
     indicator => "not_empty",
     num => 1,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "language_english",
     num => 2,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "no_shouting",
     num => 3,
     result => 0,
     result_summary => "All-caps",
     severity => 3,
   },
   {
     indicator => "not_end_with_dot",
     num => 4,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_module_name",
     num => 5,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_multiline",
     num => 6,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_redundant",
     num => 7,
     result => 0,
     result_summary => "Saying 'PERL MODULE TO' is redundant, omit it",
     severity => 3,
   },
   {
     indicator => "not_start_with_lowercase_letter",
     num => 8,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_template",
     num => 9,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_too_long",
     num => 10,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   {
     indicator => "not_too_short",
     num => 11,
     result => 1,
     result_summary => "",
     severity => 3,
   },
   { indicator => "Score", result => 81.82, result_summary => "9 out of 11" },
 ]

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<exclude_indicator> => I<array[str]>

Do not use these indicators.

=item * B<exclude_indicator_module> => I<array[perl::modname]>

Do not use indicators from these modules.

=item * B<exclude_indicator_status> => I<array[str]>

Do not use indicators having these statuses.

=item * B<include_indicator> => I<array[str]>

Only use these indicators.

=item * B<include_indicator_module> => I<array[perl::modname]>

Only use indicators from these modules.

=item * B<include_indicator_status> => I<array[str]> (default: ["stable"])

Only use indicators having these statuses.

=item * B<min_indicator_severity> => I<uint> (default: 1)

Minimum indicator severity.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_module_abstract_cwalitee_indicators

Usage:

 list_module_abstract_cwalitee_indicators(%args) -> [status, msg, payload, meta]

Examples:

=over

=item * List all installed indicators from all modules:

 list_module_abstract_cwalitee_indicators();

Result:

 [
   "language_english",
   "no_shouting",
   "not_empty",
   "not_end_with_dot",
   "not_module_name",
   "not_multiline",
   "not_redundant",
   "not_start_with_lowercase_letter",
   "not_template",
   "not_too_long",
   "not_too_short",
 ]

=item * List only certain names, show details:

 list_module_abstract_cwalitee_indicators(
   detail  => 1,
   include => ["not_too_short", "not_too_long", "not_template"]
 );

Result:

 [
   {
     module   => "Module::Abstract::Cwalitee::Core",
     name     => "not_template",
     priority => 50,
     severity => 3,
     status   => "stable",
     summary  => undef,
   },
   {
     module   => "Module::Abstract::Cwalitee::Core",
     name     => "not_too_long",
     priority => 50,
     severity => 3,
     status   => "stable",
     summary  => undef,
   },
   {
     module   => "Module::Abstract::Cwalitee::Core",
     name     => "not_too_short",
     priority => 50,
     severity => 3,
     status   => "stable",
     summary  => undef,
   },
 ]

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<exclude> => I<array[str]>

Exclude by name.

=item * B<exclude_module> => I<array[perl::modname]>

Exclude by module.

=item * B<exclude_status> => I<array[str]>

Exclude by status.

=item * B<include> => I<array[str]>

Include by name.

=item * B<include_module> => I<array[perl::modname]>

Include by module.

=item * B<include_status> => I<array[str]> (default: ["stable"])

Include by status.

=item * B<max_severity> => I<int> (default: 5)

Maximum severity.

=item * B<min_severity> => I<int> (default: 1)

Minimum severity.

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

=head1 SEE ALSO

[1] L<https://cpants.cpanauthors.org/>

L<App::ModuleAbstractCwaliteeUtils> for the CLI's.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
