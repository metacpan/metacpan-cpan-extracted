package Sah::Schema::bencher::scenario;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-23'; # DATE
our $DIST = 'Sah-Schemas-Bencher'; # DIST
our $VERSION = '1.054.1'; # VERSION

our $schema = ['defhash', {
    summary => 'Bencher scenario structure',
    'merge.add.keys' => {
        defhash_v => ['int', {req=>1, is=>1}],
        v => ['int', {req=>1, is=>1}],

        test => ['bool', {req=>1, default=>1}],
        module_startup => ['bool', {req=>1, default=>0}],
        code_startup => ['bool', {req=>1, default=>0}],
        precision => ['float', {req=>1}],
        module_startup_precision => ['float', {req=>1}],
        # default_precision is deprecated
        result => ['any'],
        with_arg_size => ['bool', {req=>1, default=>0}],
        with_result_size => ['bool', {req=>1, default=>0}],
        with_process_size => ['bool', {req=>1, default=>0}],
        capture_stdout => ['bool', {req=>1, default=>0}],
        capture_stderr => ['bool', {req=>1, default=>0}],
        extra_modules => ['array', {req=>1, of=>['perl::modname', {req=>1}]}],
        env_hashes => ['array', {req=>1, of=>['bencher::env_hash', {req=>1}]}],
        runner => ['str', {req=>1, default=>'Benchmark::Dumb', examples=>[qw/Benchmark::Dumb Benchmark Benchmark::Dumb::SimpleTime/]}],
        on_failure => ['str', {req=>1, in=>['skip','die'], default=>'die'}],
        on_result_failure => ['str', {req=>1, in=>['skip','die','warn']}], # TODO: the default is the value of on_failure

        before_parse_scenario => ['code', {req=>1}],
        before_parse_participants => ['code', {req=>1}],
        before_parse_datasets => ['code', {req=>1}],
        after_parse_scenario => ['code', {req=>1}],
        before_gen_items => ['code', {req=>1}],
        before_bench => ['code', {req=>1}],
        before_test_item => ['code', {req=>1}],
        after_test_item => ['code', {req=>1}],
        after_bench => ['code', {req=>1}],
        before_return => ['code', {req=>1}],

        participants => ['array*', {of=>['bencher::participant', {req=>1}]}],
        datasets => ['array*', {of=>['bencher::dataset', {req=>1}]}],
    },
    'req_keys' => [qw/participants/],
    'keys.restrict' => 1,

    examples => [
        {value=>{summary=>'Compare startup overhead of Foo vs Bar', participants=>[{module=>'Foo'}, {module=>'Bar'}], module_startup=>1}, valid=>1},
    ],
}];

1;
# ABSTRACT: Bencher scenario structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::bencher::scenario - Bencher scenario structure

=head1 VERSION

This document describes version 1.054.1 of Sah::Schema::bencher::scenario (from Perl distribution Sah-Schemas-Bencher), released on 2021-07-23.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("bencher::scenario*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("bencher::scenario*");
     $validator->(\@args);
     ...
 }

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> to create a CLI:

 # in lib/MyApp.pm
 package
   MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['bencher::scenario*'],
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

Sample data:

 {module_startup=>1,participants=>[{module=>"Foo"},{module=>"Bar"}],summary=>"Compare startup overhead of Foo vs Bar"}  # valid

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Bencher>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Bencher>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Bencher>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
