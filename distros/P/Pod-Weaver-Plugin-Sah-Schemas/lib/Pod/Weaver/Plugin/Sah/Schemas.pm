package Pod::Weaver::Plugin::Sah::Schemas;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-22'; # DATE
our $DIST = 'Pod-Weaver-Plugin-Sah-Schemas'; # DIST
our $VERSION = '0.067'; # VERSION

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
                        "Sah::Schema::", {recurse=>1, list_modules=>1});
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
                push @pod, "The following schemas are included in this distribution:\n\n";

                push @pod, "=over\n\n";
                for my $name (sort keys %schemas) {
                    my $sch = $schemas{$name};
                    push @pod, "=item * L<$name|Sah::Schema::$name>\n\n";
                    if (defined $sch->[1]{summary}) {
                        require String::PodQuote;
                        push @pod, String::PodQuote::pod_quote($sch->[1]{summary}), ".\n\n";
                    }
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
                    "L<Sah> - schema specification\n\n",
                    "L<Data::Sah> - Perl implementation of Sah\n\n",
                );
                $self->add_text_to_section(
                    $document, join('', @pod), 'SEE ALSO',
                    {after_section => ['DESCRIPTION']},
                );
            }

            $self->log(["Generated POD for '%s'", $filename]);

        } elsif ($package =~ /^Sah::Schema::(.+)/) {
            my $sch_name = $1;

            {
                local @INC = ("lib", @INC);
                require $package_pm;
            }
            my $sch = ${"$package\::schema"};

            # add POD section: Synopsis
            {
                my @pod;

                # example on how to use
                {
                    push @pod, <<"_";
To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my \$validator = gen_validator("$sch_name*");
 say \$validator->(\$data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my \@args = \@_;
     state \$validator = gen_validator("$sch_name*");
     \$validator->(\\\@args);
     ...
 }

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> to create a CLI:

 # in lib/MyApp.pm
 package
   MyApp;
 our \%SPEC;
 \$SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['$sch_name*'],
         },
         ...
     },
 };
 sub myfunc {
     my \%args = \@_;
     ...
 }
 1;

 # in myapp.pl
 package
   main;
 use Perinci::CmdLine::Any;
 Perinci::CmdLine::Any->new(url=>'/MyApp/myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...

_
                }

                # sample data
                {
                    require Data::Dmp;
                    my $egs = $sch->[1]{examples};
                    last unless $egs && @$egs;
                    push @pod, "Sample data:\n\n";
                    for my $eg (@$egs) {
                        # normalize non-defhash example
                        $eg = {value=>$eg, valid=>1} if ref $eg ne 'HASH';

                        # XXX if dump is too long, use Data::Dump instead
                        my $value = exists $eg->{value} ? $eg->{value} :
                            $eg->{data};
                        push @pod, " ", Data::Dmp::dmp($value);
                        if ($eg->{valid}) {
                            push @pod, "  # valid";
                            my $has_validated_value;
                            my $validated_value;
                            if (exists $eg->{validated_value}) {
                                $has_validated_value++; $validated_value = $eg->{validated_value};
                            } elsif (exists $eg->{res}) {
                                $has_validated_value++; $validated_value = $eg->{res};
                            }
                            if ($has_validated_value) {
                                push @pod, ", becomes ", Data::Dmp::dmp($validated_value);
                            }
                        } else {
                            push @pod, "  # INVALID";
                            push @pod, " ($eg->{summary})"
                                if defined $eg->{summary};
                        }
                        push @pod, "\n\n";
                    } # for eg
                } # examples

                $self->add_text_to_section(
                    $document, join("", @pod), 'SYNOPSIS',
                    {ignore => 1},
                );
            }

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

This document describes version 0.067 of Pod::Weaver::Plugin::Sah::Schemas (from Perl distribution Pod-Weaver-Plugin-Sah-Schemas), released on 2021-07-22.

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

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <sharyanto@cpan.org>

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

This software is copyright (c) 2021, 2020, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
