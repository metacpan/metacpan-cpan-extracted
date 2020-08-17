package Data::Sah::Filter::perl::Path::expand_tilde;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-08'; # DATE
our $DIST = 'Sah-Schemas-Path'; # DIST
our $VERSION = '0.014'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 1,
        target_type => 'str',
        summary => "Expand tilde ('~' and '~USER' to user's home directory)",
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; \$tmp =~ s!\\A~([^/]*)!my \@pw = length(\$1) ? getpwnam(\$1) : getpwuid(\$>); \@pw ? \$pw[7]: \"~\$1\"!e; \$tmp }",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Path::expand_tilde

=head1 VERSION

This document describes version 0.014 of Data::Sah::Filter::perl::Path::expand_tilde (from Perl distribution Sah-Schemas-Path), released on 2020-08-08.

=head1 DESCRIPTION

This filter rule does tilde expansion (e.g. "~/foo" or "~budi/foo" to
"/home/budi/foo") normally performed by Unix shells like bash. Since these
tilde-containing paths might seep unexpanded beyond shells, this filter rule can
be quite convenient.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Path>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
