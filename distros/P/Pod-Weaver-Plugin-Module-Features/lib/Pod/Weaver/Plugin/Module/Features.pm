package Pod::Weaver::Plugin::Module::Features;

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

#has include_module => (is=>'rw');
#has exclude_module => (is=>'rw');

use Data::Dmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-11'; # DATE
our $DIST = 'Pod-Weaver-Plugin-Module-Features'; # DIST
our $VERSION = '0.003'; # VERSION

sub _md2pod {
    require Markdown::To::POD;

    my ($self, $md) = @_;
    my $pod = Markdown::To::POD::markdown_to_pod($md);
    # make sure we add a couple of blank lines in the end
    $pod =~ s/\s+\z//s;
    $pod . "\n\n\n";
}

sub _process_module {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

  LOAD_MODULE:
    {
        # XXX handle dynamically generated module (if there is such thing in the
        # future)
        local @INC = ("lib", @INC);
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;
    }

  RENDER_FEATURE_SET_SPEC:
    {
        last unless $package =~ /^Module::Features::/;

        require Data::Sah::Util::Type;

        my $feature_set_spec = \%{"$package\::FEATURES_DEF"};
        last unless keys %$feature_set_spec;

        # add Defined Features section
        {
            my @fnames = sort keys %{ $feature_set_spec->{features} };
            last unless @fnames;
            my @pod;
            push @pod, "Features defined by this module:\n\n";
            push @pod, "=over\n\n";
            for my $fname (@fnames) {
                my $fspec = $feature_set_spec->{features}{$fname};
                push @pod, "=item * $fname\n\n";
                my $req = $fspec->{req};
                push @pod, $req ? "Required. " : "Optional. ";
                my $type = Data::Sah::Util::Type::get_type($fspec->{schema} // 'bool');
                push @pod, "Type: $type. ";
                push @pod, "$fspec->{summary}. " if $fspec->{summary};
                if ($fspec->{description}) {
                    push @pod, $self->_md2pod($fspec->{description});
                } else {
                    push @pod, "\n\n";
                }
            }
            push @pod, "=back\n\n";

            push @pod, "For more details on module features, see L<Module::Features>.\n\n";

            $self->add_text_to_section(
                $document, join("", @pod), 'DEFINED FEATURES',
                {
                    after_section => ['VERSION', 'NAME'],
                    before_section => 'DESCRIPTION',
                    ignore => 1,
                });
        } # Defined Features section

        # add Description section
        {
            my @pod;
            push @pod, $self->_md2pod($feature_set_spec->{description}) if $feature_set_spec->{description};

            $self->add_text_to_section(
                $document, join("", @pod), 'DESCRIPTION',
                {
                    after_section => ['SYNOPSIS'],
                    ignore => 1,
                });
        } # Description section
    } # RENDER_FEATURE_SET_SPEC

  RENDER_FEATURES_DECL:
    {
        require Data::Dmp;
        require Data::Sah::Util::Type;
        require Module::FeaturesUtil::Get;
        require String::PodQuote;

        my $features_decl = Module::FeaturesUtil::Get::get_features_decl($package, 'load');
        my $source = delete $features_decl->{'x.source'};
        last unless $source && (keys %$features_decl);

        $source =~ s/^pm://;

        # add Declared Features section
        {
            my @fsetnames = sort keys %{ $features_decl->{features} };
            last unless @fsetnames;
            my @pod;
            push @pod, "Features declared by this module";
            push @pod, " (actually declared in L<$source>)" if $source ne $package;
            push @pod, " (actually declared for L<$1>)" if $package =~ /^(.+)::_ModuleFeatures$/;
            push @pod, ":\n\n";
            for my $fsetname (@fsetnames) {
                push @pod, "=head2 From feature set $fsetname\n\n";
                push @pod, "Features from feature set L<$fsetname|Module::Features::$fsetname> declared by this module:\n\n";

                my $feature_set_spec = Module::FeaturesUtil::Get::get_feature_set_spec($fsetname, 'load');
                my $set_features = $features_decl->{features}{$fsetname};
                my @fnames = sort keys %$set_features;
                push @pod, "=over\n\n";
                for my $fname (@fnames) {
                    my $fspec = $feature_set_spec->{features}{$fname};
                    push @pod, "=item * $fname\n\n";
                    if (defined $fspec->{summary}) {
                        require String::PodQuote;
                        push @pod, String::PodQuote::pod_quote($fspec->{summary}), ".\n\n";
                    }
                    if ($fspec->{description}) {
                        require Markdown::To::POD;
                        push @pod, _md2pod($fspec->{description});
                    }
                    my $type = Data::Sah::Util::Type::get_type($fspec->{schema} // 'bool');
                    my $fdefhash = Module::FeaturesUtil::Get::get_feature_defhash($package, $fsetname, $fname);
                    my $fval;
                    if (!defined($fdefhash->{value})) {
                        $fval = "N/A (not defined)";
                    } elsif ($type eq 'bool') {
                        $fval = $fdefhash->{value} ? "yes" : "no";
                    } else {
                        $fval = Data::Dmp::dmp($fdefhash->{value});
                    }
                    push @pod, "Value: ".String::PodQuote::pod_escape($fval).".\n\n";
                    if ($fdefhash->{summary}) { push @pod, $self->_md2pod($fdefhash->{summary} . ".") }
                    if ($fdefhash->{description}) { push @pod, $self->_md2pod($fdefhash->{description}) }
                } # for fname
                push @pod, "=back\n\n";
            } # for fsetname
            push @pod, "For more details on module features, see L<Module::Features>.\n\n";

            $self->add_text_to_section(
                $document, join("", @pod), 'DECLARED FEATURES',
                {
                    after_section => ['VERSION', 'NAME'],
                    before_section => 'DESCRIPTION',
                    ignore => 1,
                });
        } # Declared Features section
    } # RENDER_FEATURES_DECL

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!(?:lib/)?(.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;
        #if ($self->include_module && @{ $self->include_module }) {
        #    return unless grep {$_ eq $package} @{ $self->include_module };
        #}
        #if ($self->exclude_module && @{ $self->exclude_module }) {
        #    return if grep {$_ eq $package} @{ $self->exclude_module };
        #}
        $self->_process_module($document, $input, $package);
    }
}

1;
# ABSTRACT: Plugin to use when building distribution that has feature definer or featurer declarer modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Module::Features - Plugin to use when building distribution that has feature definer or featurer declarer modules

=head1 VERSION

This document describes version 0.003 of Pod::Weaver::Plugin::Module::Features (from Perl distribution Pod-Weaver-Plugin-Module-Features), released on 2023-11-11.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Module::Features]

=head1 DESCRIPTION

This plugin is to be used when building distribution that has feature definer or
featurer declarer modules. For more details on module features, see
L<Module::Features>. Currently it does the following:

For feature defined modules (C<Module::Features::*> modules):

=over

=item * Add a description in the feature definer's Description section

=item * Add a Defined Features section

=back

For feature defined modules:

=over

=item * Add a Declared Features section for a feature declarer module

=back

=for Pod::Coverage .*

=head1 CONFIGURATION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Module-Features>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Module-Features>.

=head1 SEE ALSO

L<Module::Features>

L<Dist::Zilla::Plugin::Module::Features>

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Module-Features>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
