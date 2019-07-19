package Sah::Schema::perl::modargs;

our $DATE = '2019-07-05'; # DATE
our $VERSION = '0.020'; # VERSION

our $schema = [str => {
    summary => 'Perl module name with optional arguments',
    description => <<'_',

Perl module name with optional arguments which will be used as import arguments,
just like the `-MMODULE=ARGS` shortcut that `perl` provides. Examples:

    Foo
    Foo::Bar
    Foo::Bar=arg1,arg2

See also: `perl::modname`.

_
    match => '\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*(?:=.*)?\z',

    #'x.perl.coerce_rules' => [
    #    'str_normalize_perl_modname',
    #],

    # XXX also provide completion for arguments
    'x.completion' => 'perl_modname',

}, {}];

1;
# ABSTRACT: Perl module name with optional arguments

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::modargs - Perl module name with optional arguments

=head1 VERSION

This document describes version 0.020 of Sah::Schema::perl::modargs (from Perl distribution Sah-Schemas-Perl), released on 2019-07-05.

=head1 DESCRIPTION

Perl module name with optional arguments which will be used as import arguments,
just like the C<-MMODULE=ARGS> shortcut that C<perl> provides. Examples:

 Foo
 Foo::Bar
 Foo::Bar=arg1,arg2

See also: C<perl::modname>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
