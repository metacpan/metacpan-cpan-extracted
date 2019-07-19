package Sah::Schema::perl::pm_filename;

our $DATE = '2019-07-05'; # DATE
our $VERSION = '0.020'; # VERSION

our $schema = [str => {
    summary => 'Filename (.pm file)',
    description => <<'_',

String containing filename of a Perl module. For convenience, when value is in
the form of:

    Foo
    Foo.pm
    Foo::Bar
    Foo/Bar
    Foo/Bar.pm

and a matching .pm file is found in `@INC`, then it will be coerced (converted)
into the path of that .pm file, e.g.:

    /home/ujang/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/Foo/Bar.pm

To prevent such coercion, you can use prefixing path, e.g.:

    ./Foo::Bar
    ../Foo/Bar
    /path/to/Foo/Bar

This schema comes with convenience completion too.

_
    'x.perl.coerce_rules' => [
        'str_convert_perl_pm_to_path',
    ],
    'x.completion' => sub {
        require Complete::File;
        require Complete::Module;
        require Complete::Util;

        my %args = @_;
        my $word = $args{word};

        my @answers;
        push @answers, Complete::File::complete_file(word => $word);
        if ($word =~ m!\A\w*((?:::|/)\w+)*\z!) {
            push @answers, Complete::Module::complete_module(
                word => $word, find_pod=>0);
        }

        Complete::Util::combine_answers(@answers);
    },

}, {}];

1;
# ABSTRACT: Filename (.pm file)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::pm_filename - Filename (.pm file)

=head1 VERSION

This document describes version 0.020 of Sah::Schema::perl::pm_filename (from Perl distribution Sah-Schemas-Perl), released on 2019-07-05.

=head1 DESCRIPTION

String containing filename of a Perl module. For convenience, when value is in
the form of:

 Foo
 Foo.pm
 Foo::Bar
 Foo/Bar
 Foo/Bar.pm

and a matching .pm file is found in C<@INC>, then it will be coerced (converted)
into the path of that .pm file, e.g.:

 /home/ujang/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/Foo/Bar.pm

To prevent such coercion, you can use prefixing path, e.g.:

 ./Foo::Bar
 ../Foo/Bar
 /path/to/Foo/Bar

This schema comes with convenience completion too.

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
