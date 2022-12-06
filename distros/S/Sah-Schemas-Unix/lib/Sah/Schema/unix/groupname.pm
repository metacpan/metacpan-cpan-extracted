package Sah::Schema::unix::groupname;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-08'; # DATE
our $DIST = 'Sah-Schemas-Unix'; # DIST
our $VERSION = '0.021'; # VERSION

our $schema = [str => {
    summary => 'Unix group name',
    description => <<'_',

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with GID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.

Note that this schema does not check whether the group name exists (has record
in the user database e.g. `/etc/group`). To do that, use the
`unix::groupname::exists` schema.

_
    prefilters => ['Unix::convert_gid_to_unix_group'],
    'x.completion' => ['unix_group_or_gid'],
    min_len => 1,
    max_len => 32,
    match => qr/(?=\A[A-Za-z0-9._][A-Za-z0-9._-]{0,31}\z)(?=.*[A-Za-z._-])/,

    examples => [
        {value=>'', valid=>0},
        {value=>'foo', valid=>1},
        {value=>'-andy', valid=>0},
        {value=>'1234', valid=>0},
        {value=>'andy2', valid=>1},
        {value=>'an dy', valid=>0},
        {value=>'an.dy', valid=>1},
        {value=>'a' x 33, valid=>0, summary=>'Too long'},
    ],

}];

1;
# ABSTRACT: Unix group name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::unix::groupname - Unix group name

=head1 VERSION

This document describes version 0.021 of Sah::Schema::unix::groupname (from Perl distribution Sah-Schemas-Unix), released on 2022-09-08.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "foo"  # valid

 "-andy"  # INVALID

 1234  # INVALID

 "andy2"  # valid

 "an dy"  # INVALID

 "an.dy"  # valid

 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"  # INVALID (Too long)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("unix::groupname*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("unix::groupname", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "andy2";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "an dy";
 my $errmsg = $validator->($data); # => "Must match regex pattern qr((?=\\A[A-Za-z0-9._][A-Za-z0-9._-]{0,31}\\z)(?=.*[A-Za-z._-]))"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("unix::groupname", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "andy2";
 my $res = $validator->($data); # => ["","andy2"]
 
 # a sample invalid data
 $data = "an dy";
 my $res = $validator->($data); # => ["Must match regex pattern qr((?=\\A[A-Za-z0-9._][A-Za-z0-9._-]{0,31}\\z)(?=.*[A-Za-z._-]))","an dy"]

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
     my @args = @_;
     state $validator = gen_validator("unix::groupname*");
     $validator->(\@args);
     ...
 }

=head2 Using with Perinci::CmdLine::Lite

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> (L<Perinci::CmdLine::Lite>) to create a CLI:

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
             schema => ['unix::groupname*'],
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

=head1 DESCRIPTION

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with GID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.

Note that this schema does not check whether the group name exists (has record
in the user database e.g. C</etc/group>). To do that, use the
C<unix::groupname::exists> schema.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Unix>.

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

This software is copyright (c) 2022, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
