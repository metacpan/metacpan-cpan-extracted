package Pod::Weaver::Plugin::Sah::Schemas;

our $DATE = '2016-05-08'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

sub weave_section {
    no strict 'refs';

    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;

        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";

        if ($package =~ /^Sah::Schemas::/) {

            {
                local @INC = ("lib", @INC);
                require $package_pm;
            }
            my %schemas;
            # collect schema
            {
                require Module::List;
                my $res;
                {
                    local @INC = ("lib");
                    $res = Module::List::list_modules(
                        "Sah::Schema::", {list_modules=>1});
                }
                for my $mod (keys %$res) {
                    my $schema_name = $mod; $schema_name =~ s/^Sah::Schema:://;
                    local @INC = ("lib", @INC);
                    my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
                    require $mod_pm;
                    $schemas{$schema_name} = ${"$mod\::schema"};
                }
            }

            # add POD section: SAH SCHEMAS
            {
                last unless keys %schemas;
                require Markdown::To::POD;
                my @pod;
                push @pod, "=over\n\n";
                for my $name (sort keys %schemas) {
                    my $sch = $schemas{$name};
                    push @pod, "=item * L<$name|Sah::Schema::$name>\n\n";
                    push @pod, "$sch->[1]{summary}.\n\n" if $sch->[1]{summary};
                    if ($sch->[1]{description}) {
                        my $pod = Markdown::To::POD::markdown_to_pod(
                            $sch->[1]{description});
                        push @pod, $pod, "\n\n";
                    }
                }
                push @pod, "=back\n\n";
                $self->add_text_to_section(
                    $document, join("", @pod), 'SAH SCHEMAS',
                    {after_section => ['DESCRIPTION']},
                );
            }

            # add POD section: SEE ALSO
            {
                # XXX don't add if current See Also already mentions it
                my @pod = (
                    "L<Sah> - specification\n\n",
                    "L<Data::Sah>\n\n",
                );
                $self->add_text_to_section(
                    $document, join('', @pod), 'SEE ALSO',
                    {after_section => ['DESCRIPTION']},
                );
            }

            $self->log(["Generated POD for '%s'", $filename]);

        } elsif ($package =~ /^Sah::Schema::/) {

            {
                local @INC = ("lib", @INC);
                require $package_pm;
            }
            my $sch = ${"$package\::schema"};

            # add POD section: DESCRIPTION
            {
                last unless $sch->[1]{description};
                require Markdown::To::POD;
                my @pod;
                push @pod, Markdown::To::POD::markdown_to_pod(
                    $sch->[1]{description}), "\n\n";
                $self->add_text_to_section(
                    $document, join("", @pod), 'DESCRIPTION',
                    {ignore => 1},
                );
            }

            $self->log(["Generated POD for '%s'", $filename]);

        } # Sah::Schema::*
    }
}

1;
# ABSTRACT: Plugin to use when building Sah::Schemas::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Sah::Schemas - Plugin to use when building Sah::Schemas::* distribution

=head1 VERSION

This document describes version 0.04 of Pod::Weaver::Plugin::Sah::Schemas (from Perl distribution Pod-Weaver-Plugin-Sah-Schemas), released on 2016-05-08.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Sah::Schemas]

=head1 DESCRIPTION

This plugin is used when building a Sah::Schemas::* distribution. It currently
does the following to F<lib/Sah/Schemas/*> .pm files:

=over

=item * Create "SAH SCHEMAS" POD section from list of Sah::Schema::* modules in the distribution

=item * Mention some modules in See Also section

e.g. L<Sah> and L<Data::Sah>.

=back

It does the following to L<lib/Sah/Schema/*> .pm files:

=over

=item * Add "DESCRIPTION" POD section schema's description

=back

=for Pod::Coverage weave_section

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Sah-Schemas>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Sah-Schemas>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Sah-Schemas>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> and L<Data::Sah>

L<Dist::Zilla::Plugin::Sah::Schemas>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
