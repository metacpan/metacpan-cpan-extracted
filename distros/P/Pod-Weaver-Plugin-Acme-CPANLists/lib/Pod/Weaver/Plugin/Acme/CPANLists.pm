package Pod::Weaver::Plugin::Acme::CPANLists;

our $DATE = '2016-02-21'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use Pod::From::Acme::CPANLists qw(gen_pod_from_acme_cpanlists);

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

    my $res = gen_pod_from_acme_cpanlists(
        module => $package,
        _raw=>1,
    );

    $self->add_text_to_section(
        $document, $res->{author_lists}, 'AUTHOR LISTS',
        {after_section => ['DESCRIPTION']},
    ) if $res->{author_lists};

    $self->add_text_to_section(
        $document, $res->{module_lists}, 'MODULE LISTS',
        {after_section => ['AUTHOR LISTS', 'DESCRIPTION']},
    ) if $res->{module_lists};

    # XXX don't add if current See Also already mentions it
    my @pod = (
        "L<Acme::CPANLists> - about the Acme::CPANLists namespace\n\n",
        "L<acme-cpanlists> - CLI tool to let you browse/view the lists\n\n",
    );
    $self->add_text_to_section(
        $document, join('', @pod), 'SEE ALSO',
        {after_section => ['DESCRIPTION']
     },
    );

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;
        $self->_process_module($document, $input, $package);
    }
}

1;
# ABSTRACT: Plugin to use when building Acme::CPANLists::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Acme::CPANLists - Plugin to use when building Acme::CPANLists::* distribution

=head1 VERSION

This document describes version 0.06 of Pod::Weaver::Plugin::Acme::CPANLists (from Perl distribution Pod-Weaver-Plugin-Acme-CPANLists), released on 2016-02-21.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Acme::CPANLists]

=head1 DESCRIPTION

This plugin is used when building Acme::CPANLists::* distributions. It currently
does the following:

=over

=item * Create "AUTHOR LISTS" POD section from C<@Author_Lists>

=item * Create "MODULE LISTS" POD section from C<@Module_Lists>

=item * Mention some modules in See Also section

e.g. L<Acme::CPANLists> (the convention/standard), L<acme-cpanlists> (the CLI
tool), etc.

=back

=for Pod::Coverage weave_section

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Acme-CPANLists>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-PERLANCAR-CPANLists>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Acme-CPANLists>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists>

L<Dist::Zilla::Plugin::Acme::CPANLists>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
