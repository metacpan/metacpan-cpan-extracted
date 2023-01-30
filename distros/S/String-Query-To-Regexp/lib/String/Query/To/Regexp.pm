package String::Query::To::Regexp;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(query2re);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-02'; # DATE
our $DIST = 'String-Query-To-Regexp'; # DIST
our $VERSION = '0.003'; # VERSION

sub query2re {
    my $opts = ref($_[0]) eq 'HASH' ? {%{shift()}} : {};
    my $bool   = delete $opts->{bool} // 'and';
    my $ci     = delete $opts->{ci};
    my $word   = delete $opts->{word};
    my $opt_re = delete $opts->{re};
    die "query2re(): Unknown option(s): ".
        join(", ", sort keys %$opts) if keys %$opts;

    return qr// unless @_;
    my @re_parts;
    for my $query0 (@_) {
        my ($neg, $query) = $query0 =~ /\A(-?)(.*)/;

        if ($opt_re) {
            if (ref $query0 eq 'Regexp') {
                $query = $query0;
            } else {
                require Regexp::From::String;
                $query = Regexp::From::String::str_maybe_to_re($query);
                $query = quotemeta($query) unless ref $query eq 'Regexp';
            }
        } else {
            $query = quotemeta $query;
        }

        if ($word) {
            push @re_parts, $neg ? "(?!.*\\b$query\\b)" : "(?=.*\\b$query\\b)";
        } else {
            push @re_parts, $neg ? "(?!.*$query)" : "(?=.*$query)";
        }
    }
    my $re = $bool eq 'or' ? "(?:".join("|", @re_parts).")" : join("", @re_parts);
    return $ci ? qr/\A$re.*\z/is : qr/\A$re.*\z/s;
}

1;
# ABSTRACT: Convert query to regular expression

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Query::To::Regexp - Convert query to regular expression

=head1 VERSION

This document describes version 0.003 of String::Query::To::Regexp (from Perl distribution String-Query-To-Regexp), released on 2022-11-02.

=head1 SYNOPSIS

 use String::Query::To::Regexp qw(query2re);

 my $re;

 $re = query2re("foo");                       # => qr/\A(?=.*foo).*\z/s   -> string must contain 'foo'
 $re = query2re({ci=>1}, "foo";               # => qr/\A(?=.*foo).*\z/is  -> string must contain 'foo', case-insensitively
 $re = query2re("foo", "bar");                # => qr/\A(?=.*foo)(?=.*bar).*\z/s   -> string must contain 'foo' and 'bar', order does not matter
 $re = query2re("foo", "-bar");               # => qr/\A(?=.*foo)(?!.*bar).*\z/s   -> string must contain 'foo' but must not contain 'bar'
 $re = query2re({bool=>"or"}, "foo", "bar");  # => qr/\A(?:(?=.*foo)|(?!.*bar)).*\z/s  -> string must contain 'foo' or 'bar'
 $re = query2re({word=>1}, "foo", "bar");     # => qr/\A(?=.*\bfoo\b)(?!.*\bbar\b).*\z/s  -> string must contain words 'foo' and 'bar'; 'food' or 'lumbar' won't match

 $re = query2re({re=>1}, "foo", "/bar+/", qr/baz/i);  # => qr/(?^s:\A(?=.*foo\+)(?=.*(?^i:bar+))(?=.*(?^u:baz+)).*\z)/  -> allow regexes in queries

=head1 DESCRIPTION

This module provides L</query2re> function to convert one or more string queries
to a regular expression. Features of the queries:

=over

=item * Negative searching using the I<-FOO> syntax

=back

=head1 FUNCTIONS

=head2 query2re

Usage:

 my $re = query2re([ \%opts , ] @query);

Create a regular expression object from query C<@query>.

Known options:

=over

=item * bool

Str. Default C<and>. Either C<and> or C<or>.

=item * word

Bool. Default false. If set to true, queries must be separate words.

=item * ci

Bool. Default false. If set to true, will do case-insensitive matching

=item * re

Bool. Default false. If set to true, will allow regexes in C<@query> as well as
converting string queries of the form C</foo/> to regex using
L<Regexp::From::String>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Query-To-Regexp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Query-To-Regexp>.

=head1 SEE ALSO

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Query-To-Regexp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
