package Pod::Weaver::Plugin::Acme::CPANModules;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-24'; # DATE
our $DIST = 'Pod-Weaver-Plugin-Acme-CPANModules'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use Pod::From::Acme::CPANModules qw(gen_pod_from_acme_cpanmodules);

sub _process_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    {
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;
    }

    my $list = ${"$package\::LIST"};
    my $has_benchmark = 0;
  L1:
    for my $entry (@{ $list->{entries} }) {
        if (grep {/^bench_/} keys %$entry) {
            $has_benchmark = 1;
            last L1;
        }
    }

    (my $ac_name = $package) =~ s/\AAcme::CPANModules:://;

    my $res = gen_pod_from_acme_cpanmodules(
        module => $package,
        _raw=>1,
    );

    for my $section (sort keys %{$res->{pod}}) {
        $self->add_text_to_section(
            $document, $res->{pod}{$section}, $section,
            {
                (after_section => ['DESCRIPTION']) x ($section ne 'DESCRIPTION')
            },
        );
    }

    # XXX don't add if current See Also already mentions it
    my @pod = (
        "L<Acme::CPANModules> - about the Acme::CPANModules namespace\n\n",
        "L<cpanmodules> - CLI tool to let you browse/view the lists\n\n",
    );
    $self->add_text_to_section(
        $document, join('', @pod), 'SEE ALSO',
        {after_section => ['DESCRIPTION']
     },
    );

    # add FAQ section
    {
        my @pod;
        push @pod,
q(=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries ).$ac_name.q( | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=).$ac_name.q( -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

);
        if ($has_benchmark) {
            push @pod,
q(This module contains benchmark instructions. You can run a benchmark
for some/all the modules listed in this Acme::CPANModules module using
L<bencher>:

    % bencher --cpanmodules-module ).$ac_name.q(

);
        }

        push @pod,
q(This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

);
        $self->add_text_to_section(
            $document, join("", @pod), 'FAQ',
            {
                after_section => ['COMPLETION', 'DESCRIPTION'],
                before_section => ['CONFIGURATION FILE', 'CONFIGURATION FILES'],
                ignore => 1,
            });
    }

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    return unless $filename =~ m!^lib/(.+)\.pm$!;
    my $package = $1;
    $package =~ s!/!::!g;
    return unless $package =~ /\AAcme::CPANModules::/;
    $self->_process_module($document, $input, $package);
}

1;
# ABSTRACT: Plugin to use when building Acme::CPANModules::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Acme::CPANModules - Plugin to use when building Acme::CPANModules::* distribution

=head1 VERSION

This document describes version 0.003 of Pod::Weaver::Plugin::Acme::CPANModules (from Perl distribution Pod-Weaver-Plugin-Acme-CPANModules), released on 2019-12-24.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Acme::CPANModules]

=head1 DESCRIPTION

This plugin is used when building Acme::CPANModules::* distributions. It
currently does the following:

=over

=item * Create "INCLUDED MODULES" POD section from the list

=item * Mention some modules in See Also section

e.g. L<Acme::CPANModules> (the convention/standard), L<cpanmodules> (the CLI
tool), etc.

=back

=for Pod::Coverage weave_section

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Acme-CPANModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Acme-CPANModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Acme-CPANModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules>

L<Dist::Zilla::Plugin::Acme::CPANModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
