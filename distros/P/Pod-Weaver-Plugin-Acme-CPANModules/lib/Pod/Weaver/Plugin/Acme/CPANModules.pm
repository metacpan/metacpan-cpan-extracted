package Pod::Weaver::Plugin::Acme::CPANModules;

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

has entry_description_code => (is=>'rw');
has additional_props => (is=>'rw');

sub mvp_multivalue_args { qw(
                                additional_props
                        ) }

use Pod::From::Acme::CPANModules qw(gen_pod_from_acme_cpanmodules);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-17'; # DATE
our $DIST = 'Pod-Weaver-Plugin-Acme-CPANModules'; # DIST
our $VERSION = '0.013'; # VERSION

sub _process_module {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

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
        ($self->entry_description_code ? (entry_description_code => $self->entry_description_code) : ()),
        ($self->additional_props ? (additional_props => $self->additional_props) : ()),
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
q(=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n ).$ac_name.q(

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries ).$ac_name.q( | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=).$ac_name.q( -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::).$ac_name.q( -E'say $_->{module} for @{ $Acme::CPANModules::).$ac_name.q(::LIST->{entries} }' | cpanm -n

);
        if ($has_benchmark) {
            push @pod,
q(This Acme::CPANModules module contains benchmark instructions. You can run a
benchmark for some/all the modules listed in this Acme::CPANModules module using
the L<bencher> CLI (from L<Bencher> distribution):

    % bencher --cpanmodules-module ).$ac_name.q(

);
        }

        push @pod,
q(This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

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

sub _process_bundle_module {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    # collect modules list
    my %acs;
    {
        require Module::List;
        my $res;
        {
            local @INC = ("lib");
            $res = Module::List::list_modules(
                "Acme::CPANModules::", {recurse=>1, list_modules=>1});
        }
        for my $mod (keys %$res) {
            my $ac_name = $mod; $ac_name =~ s/^Acme::CPANModules:://;
            local @INC = ("lib", @INC);
            my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
            require $mod_pm;
            $acs{$ac_name} = ${"$mod\::LIST"};
        }
    }

    # add POD section: ACME::CPANMODULES MODULES
    {
        last unless keys %acs;
        require Markdown::To::POD;
        my @pod;
        push @pod, "The following Acme::CPANModules::* modules are included in this distribution:\n\n";

        push @pod, "=over\n\n";
        for my $name (sort keys %acs) {
            my $list = $acs{$name};
            push @pod, "=item * L<$name|Acme::CPANModules::$name>\n\n";
            if (defined $list->{summary}) {
                require String::PodQuote;
                push @pod, String::PodQuote::pod_quote($list->{summary}), ".\n\n";
            }
            if ($list->{description}) {
                my $pod = Markdown::To::POD::markdown_to_pod(
                    $list->{description});
                push @pod, $pod, "\n\n";
            }
        }
        push @pod, "=back\n\n";
        $self->add_text_to_section(
            $document, join("", @pod), 'ACME::CPANMODULES MODULES',
            {after_section => ['DESCRIPTION']},
        );
    }

    # add POD section: SEE ALSO
    {
        # XXX don't add if current See Also already mentions it
        my @pod = (
            "L<Acme::CPANModules> - the specification\n\n",
            "L<App::cpanmodules> - the main CLI\n\n",
            "L<App::CPANModulesUtils> - other CLIs\n\n",
        );
        $self->add_text_to_section(
            $document, join('', @pod), 'SEE ALSO',
            {after_section => ['DESCRIPTION']},
        );
    }

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    return unless $filename =~ m!^lib/(.+)\.pm$!;
    my $package = $1;
    $package =~ s!/!::!g;
    if ($package =~ /\AAcme::CPANModules::/) {
        $self->_process_module($document, $input, $package);
    } elsif ($package =~ /\AAcme::CPANModulesBundle::/) {
        $self->_process_bundle_module($document, $input, $package);
    }
}

1;
# ABSTRACT: Plugin to use when building Acme::CPANModules::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Acme::CPANModules - Plugin to use when building Acme::CPANModules::* distribution

=head1 VERSION

This document describes version 0.013 of Pod::Weaver::Plugin::Acme::CPANModules (from Perl distribution Pod-Weaver-Plugin-Acme-CPANModules), released on 2022-10-17.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Acme::CPANModules]
 ;entry_description_code = "Website URL: <" . $_->{website_url} . ">\n\n";

=head1 DESCRIPTION

This plugin is used when building Acme::CPANModules::* distributions. It
currently does the following:

For F<Acme/CPANModulesBundle/*.pm> files:

=over

=item * List Acme::CPANModules::* modules included in the distribution

=back

For F<Acme/CPANModules/*.pm> files:

=over

=item * Create "ACME::CPANMODULES ENTRIES" POD section from the list

=item * Create "ACME::CPANMODULES FEATURE COMPARISON MATRIX" POD section from the list

=item * Mention some modules in See Also section

e.g. L<Acme::CPANModules> (the convention/standard), L<cpanmodules> (the CLI
tool), etc.

=back

=for Pod::Coverage ^(weave_section|mvp_multivalue_args)$

=head1 CONFIGURATION

=head2 entry_description_code

Optional. Perl code to produce the description POD. If not specified, will use
default template for the description POD, i.e. entry's C<description> property,
plus C<rating>, C<alternative_modules> if available. See
L<Pod::From::Acme::CPANModules> for more details.

=head2 additional_props

Optional. Also passed to C<Pod::From::Acme::CPANModules>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Acme-CPANModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Acme-CPANModules>.

=head1 SEE ALSO

L<Acme::CPANModules>

L<Dist::Zilla::Plugin::Acme::CPANModules>

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Acme-CPANModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
