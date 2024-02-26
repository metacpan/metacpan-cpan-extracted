package Pod::Weaver::Plugin::Sah::SchemaBundle;

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

has show_source => (is=>'rw', default=>sub {1});
has include_schema_module => (is=>'rw');
has exclude_schema_module => (is=>'rw');
has include_schemabundle_module => (is=>'rw');
has exclude_schemabundle_module => (is=>'rw');

sub mvp_multivalue_args { qw(
                                include_schema_module exclude_schema_module
                                include_schemabundle_module exclude_schemabundle_module
                        ) }

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-23'; # DATE
our $DIST = 'Pod-Weaver-Plugin-Sah-SchemaBundle'; # DIST
our $VERSION = '0.082'; # VERSION

sub weave_section {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;

        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";

        if ($package =~ /^Sah::SchemaBundle::/) {

            if ($self->include_schemabundle_module && @{ $self->include_schemabundle_module }) {
                do { $self->log_debug(["Skipping module %s (not in include_schemabundle_module)", $package]); return } unless grep {$_ eq $package || "Sah::SchemaBundle::$_" eq $package} @{ $self->include_schemabundle_module };
            }
            if ($self->exclude_schemabundle_module && @{ $self->exclude_schemabundle_module }) {
                do { $self->log_debug(["Skipping module %s (in exclude_schemabundle_module)", $package]);     return } if     grep {$_ eq $package || "Sah::SchemaBundle::$_" eq $package} @{ $self->exclude_schemabundle_module };
            }

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

            if ($self->include_schema_module && @{ $self->include_schema_module }) {
                do { $self->log_debug(["Skipping module %s (not in include_schmea_module)", $package]); return } unless grep {$_ eq $package || "Sah::Schema::$_" eq $package} @{ $self->include_schema_module };
            }
            if ($self->exclude_schema_module && @{ $self->exclude_schema_module }) {
                do { $self->log_debug(["Skipping module %s (in exclude_schmea_module)", $package]);     return } if     grep {$_ eq $package || "Sah::Schema::$_" eq $package} @{ $self->exclude_schema_module };
            }

            # add POD section: SAH SCHEMA DEFINITION
            {
                last unless $self->show_source;

                require Data::Clone;
                require Data::Dump::SortKeys;
                require Data::Sah::Util::Type;
                require Sort::Sub;
                require Sort::Sub::sah_schema_clause; # for scan_prereqs

                my @pod;
                my $sch = Data::Clone::clone($sch);
                delete $sch->[1]{summary};
                delete $sch->[1]{description};
                delete $sch->[1]{examples};

                {
                    my $sorter = Sort::Sub::get_sorter("sah_schema_clause");
                    local $Data::Dump::SortKeys::SORT_KEYS = sub {
                        my $hash = shift;
                        sort { $sorter->($a,$b) } keys %$hash;
                    };
                    my $dump = Data::Dump::SortKeys::dump($sch);
                    $dump =~ s/^/ /mg;
                    push @pod, $dump, "\n\n";
                }

                # link to base schema/type
                my $type = Data::Sah::Util::Type::get_type($sch);
                if (Data::Sah::Util::Type::is_type($type)) {
                    push @pod, "Base type: L<$type|Data::Sah::Type::$type>\n\n";
                } else {
                    push @pod, "Base schema: L<$type|Sah::Schema::$type>\n\n";
                }

                # link to prefilters modules
                my $prefilters = $sch->[1]{prefilters};
                if ($prefilters && @$prefilters) {
                    push @pod, "Used prefilters: ";
                    for my $i (0 .. $#{$prefilters}) {
                        my $fname = ref $prefilters->[$i] ? $prefilters->[$i][0] : $prefilters->[$i];
                        push @pod, ", " if $i; push @pod, "L<$fname|Data::Sah::Filter::perl::$fname>" }
                    push @pod, "\n\n";
                }

                # TODO: link to perl coercion rule modules
                # TODO: link to js coercion rule modules

                # link to completion modules
                my $xcompletions = $sch->[1]{'x.completion'};
                if ($xcompletions) {
                    $xcompletions = [$xcompletions] unless ref $xcompletions eq 'ARRAY';
                    push @pod, "Used completion: ";
                    for my $i (0 .. $#{$xcompletions}) {
                        my $cname = ref $xcompletions->[$i] eq 'ARRAY' ? $xcompletions->[$i][0] : $xcompletions->[$i];
                        push @pod, ", " if $i; push @pod, "L<$cname|Perinci::Sub::XCompletion::$cname>" }
                    push @pod, "\n\n";
                }

                $self->add_text_to_section(
                    $document, join("", @pod), 'SAH SCHEMA DEFINITION',
                    {ignore => 1},
                );
            } # add POD section: SAH SCHEMA DEFINITION

            # add POD section: Synopsis
            {
                my @pod;

                # sample data & validation results
                {
                    require Data::Dmp;
                    my $egs = $sch->[1]{examples};
                    last unless $egs && @$egs;
                    push @pod, "=head2 Sample data and validation results against this schema\n\n";
                    for my $eg (@$egs) {
                        # normalize non-defhash example
                        $eg = {value=>$eg, valid=>1} if ref $eg ne 'HASH';

                        # XXX if dump is too long, use Data::Dump instead
                        my $value = exists $eg->{value} ? $eg->{value} :
                            $eg->{data};
                        push @pod, " ", Data::Dmp::dmp($value);
                        if ($eg->{valid}) {
                            push @pod, "  # valid";
                            push @pod, " ($eg->{summary})"
                                if defined $eg->{summary};

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

                my $egs = $sch->[1]{examples} // [];
                my @valid_egs = grep { $_->{valid} } @$egs;
                my @invalid_egs = grep { !$_->{valid} } @$egs;
                my $random_valid_eg = $valid_egs[rand @valid_egs];
                my $random_invalid_eg = $invalid_egs[rand @invalid_egs];

                # example on how to use
                {
                    require Data::Sah;
                    push @pod, <<"_";
=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my \$validator = gen_validator("$sch_name*");
 say \$validator->(\$data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my \$validator = gen_validator("$sch_name", {return_type=>'str_errmsg'});
 my \$errmsg = \$validator->(\$data);
_

                    my $v = Data::Sah::gen_validator($sch, {return_type=>"str_errmsg"});
                    if ($random_valid_eg) {
                        push @pod, " \n";
                        push @pod, " # a sample valid data\n";
                        push @pod, " \$data = ".Data::Dmp::dmp($random_valid_eg->{value}).";\n";
                        push @pod, " my \$errmsg = \$validator->(\$data); # => ".Data::Dmp::dmp($v->($random_valid_eg->{value}))."\n";
                    }
                    if ($random_invalid_eg) {
                        push @pod, " \n";
                        push @pod, " # a sample invalid data\n";
                        push @pod, " \$data = ".Data::Dmp::dmp($random_invalid_eg->{value}).";\n";
                        push @pod, " my \$errmsg = \$validator->(\$data); # => ".Data::Dmp::dmp($v->($random_invalid_eg->{value}))."\n";
                    }

                    push @pod, <<"_";

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my \$validator = gen_validator("$sch_name", {return_type=>'str_errmsg+val'});
 my \$res = \$validator->(\$data); # [\$errmsg, \$validated_val]
_

                    $v = Data::Sah::gen_validator($sch, {return_type=>"str_errmsg+val"});
                    if ($random_valid_eg) {
                        push @pod, " \n";
                        push @pod, " # a sample valid data\n";
                        push @pod, " \$data = ".Data::Dmp::dmp($random_valid_eg->{value}).";\n";
                        push @pod, " my \$res = \$validator->(\$data); # => ".Data::Dmp::dmp($v->($random_valid_eg->{value}))."\n";
                    }
                    if ($random_invalid_eg) {
                        push @pod, " \n";
                        push @pod, " # a sample invalid data\n";
                        push @pod, " \$data = ".Data::Dmp::dmp($random_invalid_eg->{value}).";\n";
                        push @pod, " my \$res = \$validator->(\$data); # => ".Data::Dmp::dmp($v->($random_invalid_eg->{value}))."\n";
                    }

                    push @pod, <<"_";

Data::Sah can also create validator that returns a hash of detailed error
message. Data::Sah can even create validator that targets other language, like
JavaScript, from the same schema. Other things Data::Sah can do: show source
code for validator, generate a validator code with debug comments and/or log
statements, generate human text from schema. See its documentation for more
details.

=head2 Using with Params::Sah

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my \@args = \@_;
     state \$validator = gen_validator("$sch_name*");
     \$validator->(\\\@args);
     ...
 }

=head2 Using with Perinci::CmdLine::Lite

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> (L<Perinci::CmdLine::Lite>) to create a CLI:

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

=head2 Using on the CLI with validate-with-sah

To validate some data on the CLI, you can use L<validate-with-sah> utility.
Specify the schema as the first argument (encoded in Perl syntax) and the data
to validate as the second argument (encoded in Perl syntax):

 % validate-with-sah '"$sch_name*"' '"data..."'

C<validate-with-sah> has several options for, e.g. validating multiple data,
showing the generated validator code (Perl/JavaScript/etc), or loading
schema/data from file. See its manpage for more details.

_
                    (my $type_name = $sch_name) =~ s/(\A\w)|(::|_)(\w)/defined($3) ? uc($3) : uc($1)/eg;

                    push @pod, <<"_";

=head2 Using with Type::Tiny

To create a type constraint and type library from a schema (requires
L<Type::Tiny> as well as L<Type::FromSah>):

 package My::Types {
     use Type::Library -base;
     use Type::FromSah qw( sah2type );

     __PACKAGE__->add_type(
         sah2type('$sch_name*', name=>'$type_name')
     );
 }

 use My::Types qw($type_name);
 $type_name->assert_valid(\$data);

_
                }

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

            # add POD section: SEE ALSO
            {
                my $links = $sch->[1]{links};
                next unless $links && @$links;

                my @pod;

                require String::PodQuote;
                for my $link (@$links) {
                    my $url = $link->{url}; $url =~ s/^(prog|pm)://;
                    push @pod, "L<$url>", ($link->{summary} ? " - ".String::PodQuote::pod_quote($link->{summary}) : ""), "\n\n";
                }
                $self->add_text_to_section(
                    $document, join('', @pod), 'SEE ALSO',
                    {after_section => ['DESCRIPTION']},
                );
            }

        } # Sah::Schema::*
    }
}

1;
# ABSTRACT: Plugin to use when building Sah::SchemaBundle::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Sah::SchemaBundle - Plugin to use when building Sah::SchemaBundle::* distribution

=head1 VERSION

This document describes version 0.082 of Pod::Weaver::Plugin::Sah::SchemaBundle (from Perl distribution Pod-Weaver-Plugin-Sah-SchemaBundle), released on 2024-02-23.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Sah::SchemaBundle]

=head1 DESCRIPTION

This plugin is used when building a Sah::SchemaBundle::* distribution. It
currently does the following to F<lib/Sah/SchemaBundle/*> .pm files:

=over

=item * Create "SAH SCHEMAS" POD section from list of Sah::Schema::* modules in the distribution

=item * Mention some modules in See Also section

e.g. L<Sah> and L<Data::Sah>.

=back

It does the following to L<lib/Sah/Schema/*> .pm files:

=over

=item * Add "DESCRIPTION" POD section schema's description

=back

=for Pod::Coverage ^(weave_section|mvp_multivalue_args)$

=head1 CONFIGURATION

=head2 show_source

Bool. Default true. If set to true, will add a C<SAH SCHEMA DEFINITION> section
containing the source (dump) of the schema. Examples will be stripped.

=head2 include_schema_module

Filter only certain scenario modules that get processed. Can be specified
multiple times. The C<Sah::Schema::> prefix can be omitted.

=head2 exclude_schema_module

Exclude certain scenario modules from being processed. Can be specified multiple
times. The C<Sah::Schems::> prefix can be omitted.

=head2 include_schemabundle_module

Filter only certain scenario modules that get processed. Can be specified
multiple times. The C<Sah::SchemaBundle::> prefix can be omitted.

=head2 exclude_schemabundle_module

Exclude certain scenario modules from being processed. Can be specified multiple
times. The C<Sah::SchemaBundle::> prefix can be omitted.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Sah-SchemaBundle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Sah-SchemaBundle>.

=head1 SEE ALSO

L<Sah> and L<Data::Sah>

L<Dist::Zilla::Plugin::Sah::SchemaBundle>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2024, 2023, 2022, 2020, 2019, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Sah-SchemaBundle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
