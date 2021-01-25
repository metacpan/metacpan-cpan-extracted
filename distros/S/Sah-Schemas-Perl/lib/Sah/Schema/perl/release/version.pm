package Sah::Schema::perl::release::version;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-20'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.035'; # VERSION

my %all_versions;

# from build version of Module::CoreList
our @build_releases;
@build_releases = ("5.011000","5.028001","5.029004","5.009003","5.01","5.02901","5.021006","5.025009","5.019011","5.00405","5.026002","5.015","5.014002","5.025010","5.027007","5.025008","5.013007","5.021005","5.019008","5.019010","5.028000","5.011001","5.029","5.025011","5.019009","5.015004","5.017003","5.012002","5.023003","5","5.025005","5.015001","5.002","5.016003","5.021011","5.024003","5.019006","5.028","5.011004","5.029000","5.015000","5.020002","5.025006","5.021009","5.011","5.008003","5.030000","5.029001","5.021008","5.022003","5.00503","5.021010","5.027002","5.004","5.019005","5.013002","5.007003","5.027004","5.025003","5.013004","5.01301","5.028002","5.017011","5.02701","5.008006","5.012000","5.026001","5.014001","5.029007","5.011002","5.017010","5.015007","5.017008","5.023008","5.005","5.027","5.013","5.012001","5.008005","5.026000","5.017009","5.014000","5.023009","5.025012","5.019003","5.020000","5.026","5.012004","5.015002","5.009005","5.014","5.018003","5.001","5.017006","5.023006","5.027000","5.013000","5.021003","5.00504","5.020001","5.012","5.008008","5.014004","5.027001","5.013001","5.017005","5.008009","5.029002","5.023005","5.025000","5.015006","5.018004","5.021","5.019001","5.012003","5.006","5.017002","5.029005","5.023002","5.015005","5.009002","5.025001","5.008007","5.026003","5.02101","5.029006","5.014003","5.018","5.021004","5.019000","5.020003","5.011005","5.006001","5.029010","5.029008","5.018000","5.021001","5.019","5.008002","5.029009","5.02501","5.025004","5.027003","5.022002","5.013003","5.021000","5.018001","5.019004","5.01901","5.015009","5.000","5.02","5.006000","5.025","5.016002","5.024002","5.015008","5.017007","5.023007","5.008","5.011003","5.009000","5.022","5.010001","5.024004","5.017001","5.023001","5.027005","5.019002","5.013005","5.022004","5.025002","5.021007","5.010000","5.016","5.024","5.008004","5.009001","5.027006","5.013006","5.017000","5.023000","5.025007","5.027008","5.027010","5.021002","5.013008","5.013010","5.006002","5.017","5.023","5.016000","5.027009","5.022001","5.013009","5.024000","5.03","5.012005","5.008001","5.009004","5.029003","5.015003","5.017004","5.023004","5.00307","5.018002","5.027011","5.01701","5.013011","5.008000","5.009","5.016001","5.022000","5.019007","5.024001");

$all_versions{"$_"} = 1 for @build_releases;

# from installed version of Module::CoreList
require Module::CoreList;
$all_versions{"$_"} = 1 for keys %Module::CoreList::released;

# in addition to the numified (which, unfortunately, collapses 5.010000 to
# 5.10), also provides the x.y.z representations
my @all_versions;
for (sort keys %all_versions) {
    my $major = sprintf "%.0f", $_;
    my $minor = sprintf "%.0f", ($_ - $major) * 1000;
    my $rev   = sprintf "%.0f", ($_ - $major - $minor/1000) * 1e6;
    my $xyz   = sprintf "%d.%d.%d", $major, $minor, $rev;
    #print "$_ -> $xyz\n";
    $all_versions{$xyz} = 1;
}

our $schema = [str => {
    summary => 'One of known released versions of perl (e.g. 5.010 or 5.10.0)',
    description => <<'_',

Use this schema if you want to accept one of the known released versions of
perl.

The list of releases of perl is retrieved from the installed core module
<pm:Module::CoreList> during runtime as well as the one used during build. One
of both those Module::CoreList instances might not be the latest, so this list
might not be up-to-date. To ensure that the list is complete, you will need to
keep your copy of Module::CoreList up-to-date.

The list of version numbers include numified version (which, unfortunately,
collapses trailing zeros, e.g. 5.010000 into 5.010) as well as the x.y.z version
(e.g. 5.10.0).

_
    in => [sort keys %all_versions],
}, {}];

1;
# ABSTRACT: One of known released versions of perl (e.g. 5.010 or 5.10.0)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::release::version - One of known released versions of perl (e.g. 5.010 or 5.10.0)

=head1 VERSION

This document describes version 0.035 of Sah::Schema::perl::release::version (from Perl distribution Sah-Schemas-Perl), released on 2021-01-20.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::release::version*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::release::version*");
     $validator->(\@args);
     ...
 }

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> to create a CLI:

 # in lib/MyApp.pm
 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['perl::release::version*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }
 1;

 # in myapp.pl
 package main;
 use Perinci::CmdLine::Any;
 Perinci::CmdLine::Any->new(url=>'MyApp::myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...

=head1 DESCRIPTION

Use this schema if you want to accept one of the known released versions of
perl.

The list of releases of perl is retrieved from the installed core module
L<Module::CoreList> during runtime as well as the one used during build. One
of both those Module::CoreList instances might not be the latest, so this list
might not be up-to-date. To ensure that the list is complete, you will need to
keep your copy of Module::CoreList up-to-date.

The list of version numbers include numified version (which, unfortunately,
collapses trailing zeros, e.g. 5.010000 into 5.010) as well as the x.y.z version
(e.g. 5.10.0).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Sah-Schemas-Perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

C<perl::release::*> is namespace for schemas related to perl releases.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
