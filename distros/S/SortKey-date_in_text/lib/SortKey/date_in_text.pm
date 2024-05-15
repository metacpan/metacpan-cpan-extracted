package SortKey::date_in_text;

use 5.010001;
use strict;
use warnings;

use DateTime;

our $DATE_EXTRACT_MODULE = $ENV{PERL_DATE_EXTRACT_MODULE} // "Date::Extract";

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-15'; # DATE
our $DIST = 'SortKey-date_in_text'; # DIST
our $VERSION = '0.002'; # VERSION

sub meta {
    return {
        v => 1,
        args => {
        },
    };
}

my $re_is_num = qr/\A
                   [+-]?
                   (?:\d+|\d*(?:\.\d*)?)
                   (?:[Ee][+-]?\d+)?
                   \z/x;

sub gen_keygen {
    my ($is_reverse, $is_ci) = @_;

    my ($parser, $code_parse);
    unless (defined $parser) {
        my $module = $DATE_EXTRACT_MODULE;
        $module = "Date::Extract::$module" unless $module =~ /::/;
        if ($module eq 'Date::Extract') {
            require Date::Extract;
            $parser = Date::Extract->new();
            $code_parse = sub { $parser->extract($_[0]) };
        } elsif ($module eq 'Date::Extract::ID') {
            require Date::Extract::ID;
            $parser = Date::Extract::ID->new();
            $code_parse = sub { $parser->extract($_[0]) };
        } elsif ($module eq 'DateTime::Format::Alami::EN') {
            require DateTime::Format::Alami::EN;
            $parser = DateTime::Format::Alami::EN->new();
            $code_parse = sub { my $h; eval { $h = $parser->parse_datetime($_[0]) }; $h }; ## no critic: BuiltinFunctions::ProhibitStringyEval
        } elsif ($module eq 'DateTime::Format::Alami::ID') {
            require DateTime::Format::Alami::ID;
            $parser = DateTime::Format::Alami::ID->new();
            $code_parse = sub { my $h; eval { $h = $parser->parse_datetime($_[0]) }; $h }; ## no critic: BuiltinFunctions::ProhibitStringyEval
        } else {
            die "Invalid date extract module '$module'";
        }
        eval "use $module"; die if $@; ## no critic: BuiltinFunctions::ProhibitStringyEval
    }

    sub {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

        my $arg = @_ ? $_[0] : $_;
        my $dt = $code_parse->($arg);
        return '' unless $dt;
        "$dt";
    };
}

1;
# ABSTRACT: Date found in text as sort key

__END__

=pod

=encoding UTF-8

=head1 NAME

SortKey::date_in_text - Date found in text as sort key

=head1 VERSION

This document describes version 0.002 of SortKey::date_in_text (from Perl distribution SortKey-date_in_text), released on 2024-05-15.

=head1 DESCRIPTION

The generated keygen will extract date found in text (by default extracted using
L<Date::Extract>, but other modules can be used, see
L</PERL_DATE_EXTRACT_MODULE>) and return the date in ISO 8601 format. Will
return empty string if string is not found.

=for Pod::Coverage ^(gen_keygen|meta)$

=head1 ENVIRONMENT

=head2 DEBUG => bool

If set to true, will print stuffs to stderr.

=head2 PERL_DATE_EXTRACT_MODULE => str

Can be set to L<Date::Extract>, L<Date::Extract::ID>, or
L<DateTime::Format::Alami::EN>, L<DateTime::Format::Alami::ID>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SortKey-date_in_text>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SortKey-date_in_text>.

=head1 SEE ALSO

Old incarnation: L<Sort::Sub::by_date_in_text>.

L<Comparer> version: L<Comparer::by_date_in_text>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SortKey-date_in_text>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
