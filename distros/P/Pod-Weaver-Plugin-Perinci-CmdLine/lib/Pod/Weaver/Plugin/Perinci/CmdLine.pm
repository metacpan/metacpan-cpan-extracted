package Pod::Weaver::Plugin::Perinci::CmdLine;

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-06'; # DATE
our $DIST = 'Pod-Weaver-Plugin-Perinci-CmdLine'; # DIST
our $VERSION = '0.001'; # VERSION

sub _md2pod {
    require Markdown::To::POD;

    my ($self, $md) = @_;
    my $pod = Markdown::To::POD::markdown_to_pod($md);
    # make sure we add a couple of blank lines in the end
    $pod =~ s/\s+\z//s;
    $pod . "\n\n\n";
}

sub _process_plugin_module {
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

    my $meta = $package->meta;

    (my $plugin_name = $package) =~ s/\APerinci::CmdLine::Plugin:://;

    # add Description section
    {
        my @pod;

        push @pod, $self->_md2pod($meta->{description})
            if $meta->{description};

        last unless @pod;

        $self->add_text_to_section(
            $document, join("", @pod), 'DESCRIPTION',
            {
                after_section => ['SYNOPSIS'],
                ignore => 1,
            });
    }

    $self->log(["Generated POD for '%s'", $filename]);
}

sub _process_pluginbundle_module {
    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    # collect plugins list
    my %plugins;
    {
        require Module::List;
        my $res;
        {
            local @INC = ("lib");
            $res = Module::List::list_modules(
                "Perinci::CmdLine::Plugin::", {recurse=>1, list_modules=>1});
        }
        for my $mod (keys %$res) {
            my $plugin_name = $mod; $plugin_name =~ s/^Perinci::CmdLine::Plugin:://;
            local @INC = ("lib", @INC);
            my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
            require $mod_pm;
            $plugins{$plugin_name} = $mod->meta;
        }
    }

    # add POD section: PERINCI::CMDLINE PLUGINS
    {
        last unless keys %plugins;
        require Markdown::To::POD;
        my @pod;
        push @pod, "The following Perinci::CmdLine::Plugin::* modules are included in this distribution:\n\n";

        push @pod, "=over\n\n";
        for my $plugin_name (sort keys %plugins) {
            my $meta = $plugins{$plugin_name};
            push @pod, "=item * L<$plugin_name|Perinci::CmdLine::Plugin::$plugin_name>\n\n";
            if (defined $meta->{summary}) {
                require String::PodQuote;
                push @pod, String::PodQuote::pod_quote($meta->{summary}), ".\n\n";
            }
            if ($meta->{description}) {
                my $pod = Markdown::To::POD::markdown_to_pod(
                    $meta->{description});
                push @pod, $pod, "\n\n";
            }
        }
        push @pod, "=back\n\n";
        $self->add_text_to_section(
            $document, join("", @pod), 'PERINCI::CMDLINE::PLUGIN MODULES',
            {after_section => ['DESCRIPTION']},
        );
    }

    # add POD section: SEE ALSO
    {
        # XXX don't add if current See Also already mentions it
        my @pod = (
            "L<Perinci::CmdLine>\n\n",
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
    if ($package =~ /\APerinci::CmdLine::Plugin::/) {
        $self->_process_plugin_module($document, $input, $package);
    } elsif ($package =~ /\APerinci::CmdLine::PluginBundle::/) {
        $self->_process_pluginbundle_module($document, $input, $package);
    }
}

1;
# ABSTRACT: Plugin to use when building Perinci::CmdLine::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Perinci::CmdLine - Plugin to use when building Perinci::CmdLine::* distribution

=head1 VERSION

This document describes version 0.001 of Pod::Weaver::Plugin::Perinci::CmdLine (from Perl distribution Pod-Weaver-Plugin-Perinci-CmdLine), released on 2021-10-06.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Perinci::CmdLine]

=head1 DESCRIPTION

This plugin is used when building C<Perinci::CmdLine::*> distributions. It
currently does the following:

For F<Perinci/CmdLine/Plugin/*.pm> files:

=over

=item * Fill Description POD section from the meta's description

=back

For F<Perinci/CmdLine/PluginBundle/*.pm> files:

=over

=item * Add "Perinci::CmdLine::Plugin Modules" POD section listing Perinci::CmdLine::Plugin::* modules included in the distribution

=item * Add See Also POD section mentioning Perinci::CmdLine and some other related modules

=back

=for Pod::Coverage weave_section

=head1 CONFIGURATION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Perinci-CmdLine>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Perinci-CmdLine>.

=head1 SEE ALSO

L<Perinci::CmdLine>

L<Dist::Zilla::Plugin::Perinci::CmdLine>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Perinci-CmdLine>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
