package Pod::Weaver::Plugin::ScriptX;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-16'; # DATE
our $DIST = 'Pod-Weaver-Plugin-ScriptX'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

sub _md2pod {
    require Markdown::To::POD;

    my ($self, $md) = @_;
    my $pod = Markdown::To::POD::markdown_to_pod($md);
    # make sure we add a couple of blank lines in the end
    $pod =~ s/\s+\z//s;
    $pod . "\n\n\n";
}

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

    my $meta = {}; eval { $meta = $package->meta };

    (my $plugin_name = $package) =~ s/\AScriptX:://;

    # add CONFIGURATION section
    {
        my @pod;
        last unless $meta->{conf};
        for my $conf_name (sort keys %{$meta->{conf}}) {
            my $conf_spec = $meta->{conf}{$conf_name};
            push @pod, "=head2 $conf_name\n\n";

            require Data::Sah::Normalize;
            my $nsch = Data::Sah::Normalize::normalize_schema($conf_spec->{schema});
            push @pod, ucfirst("$nsch->[0]. ");
            push @pod, ($conf_spec->{req} ? "Required. " : "Optional. ");

            if (defined $conf_spec->{summary}) {
                require String::PodQuote;
                push @pod, String::PodQuote::pod_quote($conf_spec->{summary}).".";
            }
            push @pod, "\n\n";

            if ($conf_spec->{description}) {
                require Markdown::To::POD;
                my $pod = Markdown::To::POD::markdown_to_pod(
                    $conf_spec->{description});
                push @pod, $pod, "\n\n";
            }
        }
        $self->add_text_to_section(
            $document, join("", @pod), 'CONFIGURATION',
            {
                after_section => ['DESCRIPTION'],
                ignore => 1,
            });
    } # CONFIGURATION

    # add DESCRIPTION section
    {
        my @pod;

        push @pod, $self->_md2pod($meta->{description})
            if $meta->{description};

        $self->add_text_to_section(
            $document, join("", @pod), 'DESCRIPTION',
            {
                after_section => ['SYNOPSIS'],
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
    return unless $package =~ /\AScriptX::/;
    $self->_process_module($document, $input, $package);
}

1;
# ABSTRACT: Plugin to use when building ScriptX::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::ScriptX - Plugin to use when building ScriptX::* distribution

=head1 VERSION

This document describes version 0.002 of Pod::Weaver::Plugin::ScriptX (from Perl distribution Pod-Weaver-Plugin-ScriptX), released on 2020-04-16.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-ScriptX]

=head1 DESCRIPTION

This plugin is used when building ScriptX::* distributions. It currently does
the following:

=over

=item * Create "CONFIGURATION" POD section from the meta's conf

=item * Add text to Description section from meta's description

=back

=for Pod::Coverage weave_section

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-ScriptX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-ScriptX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-ScriptX>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ScriptX>

L<Dist::Zilla::Plugin::ScriptX>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
