package Sah::Schema::unix::local_uid;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-16'; # DATE
our $DIST = 'Sah-Schemas-Unix'; # DIST
our $VERSION = '0.013'; # VERSION

our $schema = ["unix::uid" => {
    summary => 'User identifier (UID) that has to exist (has associated username) on the system',
    description => <<'_',

Existing means having a user name associated with this UID, i.e. `getpwuid`
returns a record.

Support coercion from an existing user name.

_
    'prefilters' => ['Unix::convert_unix_user_to_uid', 'Unix::check_uid_exists'],
}, {}];

1;
# ABSTRACT: User identifier (UID) that has to exist (has associated username) on the system

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::unix::local_uid - User identifier (UID) that has to exist (has associated username) on the system

=head1 VERSION

This document describes version 0.013 of Sah::Schema::unix::local_uid (from Perl distribution Sah-Schemas-Unix), released on 2020-10-16.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("unix::local_uid*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("unix::local_uid*");
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
             schema => ['unix::local_uid*'],
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

Existing means having a user name associated with this UID, i.e. C<getpwuid>
returns a record.

Support coercion from an existing user name.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Unix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
