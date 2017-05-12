package Pod::Weaver::Plugin::App::lcpan;

our $DATE = '2017-01-20'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

sub _process_cmdbundle_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $zilla = $input->{zilla};

    my $filename = $input->{filename};

    # add Description section
    {
        my @pod;

        push @pod, "This bundle provides the following lcpan subcommands:\n\n";
        push @pod, "=over\n\n";
        for my $file (@{ $input->{zilla}->files }) {
            my $name = $file->name;
            next unless $name =~ m!^lib/App/lcpan/Cmd/([^/]+)\.pm$!;
            my $subpkg = $1;
            (my $subcmd = $1) =~ s/_/-/g;
            push @pod, "=item * L<lcpan $subcmd|App::lcpan::Cmd::$subpkg>\n\n";
        }
        push @pod, "=back\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'DESCRIPTION',
            {
                after_section => ['SYNOPSIS'],
                top => 1,
            });
    }

    $self->log(["Generated POD for '%s'", $filename]);
}

sub _process_cmd_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    # Add Description section
    {
        my @pod;

        (my $subcmd = $filename) =~ s!.+/!!; $subcmd =~ s/\.pm$//; $subcmd =~ s/_/-/g;

        push @pod, "This module handles the L<lcpan> subcommand C<$subcmd>.\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'DESCRIPTION',
            {
                after_section => ['SYNOPSIS'],
                top => 1,
            });
    }

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(App/lcpan/CmdBundle/.+)\.pm$!) {
        {
            $package = $1;
            $package =~ s!/!::!g;
            $self->_process_cmdbundle_module($document, $input, $package);
        }
    }
    if ($filename =~ m!^lib/(App/lcpan/Cmd/.+)\.pm$!) {
        {
            $package = $1;
            $package =~ s!/!::!g;
            $self->_process_cmd_module($document, $input, $package);
        }
    }
}

1;
# ABSTRACT: Plugin to use when building App::lcpan::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::App::lcpan - Plugin to use when building App::lcpan::* distribution

=head1 VERSION

This document describes version 0.001 of Pod::Weaver::Plugin::App::lcpan (from Perl distribution Pod-Weaver-Plugin-App-lcpan), released on 2017-01-20.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-App::lcpan]

=head1 DESCRIPTION

This plugin is to be used when building C<App::lcpan::*> distribution. Currently
it does the following:

For each C<lib/App/lcpan/CmdBundle/*> module files:

=over

=item * Add general Description text

=back

For each C<lib/App/lcpan/Cmd/*> module files:

=over

=item * Add general Description text

=back

=for Pod::Coverage .*

=head1 CONFIGURATION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-App-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::lcpan>

L<Dist::Zilla::Plugin::App::lcpan>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
