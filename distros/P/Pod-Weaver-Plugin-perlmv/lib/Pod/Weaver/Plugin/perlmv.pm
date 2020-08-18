package Pod::Weaver::Plugin::perlmv;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-04'; # DATE
our $DIST = 'Pod-Weaver-Plugin-perlmv'; # DIST
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

    my $scriptlet = ${"$package\::SCRIPTLET"};

    (my $scriptlet_name = $package) =~ s/\AApp::perlmv::scriptlet:://;
    $scriptlet_name =~ s!::!/!g;
    $scriptlet_name =~ s!_!-!g;

    if (defined $scriptlet->{description}) {
        $self->add_text_to_section(
            $document, $self->_md2pod($scriptlet->{description}), 'DESCRIPTION',
        );
    }

    if (defined $scriptlet->{args} && keys(%{ $scriptlet->{args} })) {
        my @pod;
        push @pod, "Arguments can be passed using the C<-a> (C<--arg>) L<perlmv> option, e.g. C<< -a name=val >>.\n\n";
        for my $argname (sort keys %{ $scriptlet->{args} }) {
            my $argspec = $scriptlet->{args}{$argname};
            push @pod, "=head2 $argname\n\n";
            push @pod, "Required. " if $argspec->{req};
            if (defined $argspec->{summary}) {
                require String::PodQuote;
                push @pod, String::PodQuote::pod_quote($argspec->{summary}), ". ";
            }
            push @pod, "\n\n";
            if (defined $argspec->{description}) {
                push @pod, $self->_md2pod($argspec->{description});
            }
        }
        $self->add_text_to_section(
            $document, join("", @pod), 'SCRIPTLET ARGUMENTS',
            {after_section => 'DESCRIPTION'},
        );
    }

    # XXX don't add if current See Also already mentions it
    my @pod = (
        "L<perlmv> (from L<App::perlmv>)\n\n",
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

    return unless $filename =~ m!^lib/(.+)\.pm$!;
    my $package = $1;
    $package =~ s!/!::!g;
    return unless $package =~ /\AApp::perlmv::scriptlet::/;
    $self->_process_module($document, $input, $package);
}

1;
# ABSTRACT: Plugin to use when building App::perlmv and App::perlmv::scriptlet::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::perlmv - Plugin to use when building App::perlmv and App::perlmv::scriptlet::* distribution

=head1 VERSION

This document describes version 0.002 of Pod::Weaver::Plugin::perlmv (from Perl distribution Pod-Weaver-Plugin-perlmv), released on 2020-08-04.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-perlmv]

=head1 DESCRIPTION

This plugin is to be used when building L<App::perlmv> and
C<App::perlmv::scriptlet::*> distribution. Currently it does the following for
each F<lib/App/perlmv/scriptlet/*> pm file:

=over

=item * Fill Description section from scriptlet's description

=item * Mention some scripts/modules in the See Also section, including perlmv and App::perlmv

=back

=for Pod::Coverage .*

=head1 CONFIGURATION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-perlmv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-perlmv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-perlmv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::perlmv>

L<Dist::Zilla::Plugin::perlmv>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
