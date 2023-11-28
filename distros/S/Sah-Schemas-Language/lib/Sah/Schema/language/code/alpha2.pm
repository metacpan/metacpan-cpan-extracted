package Sah::Schema::language::code::alpha2;

use strict;
use Locale::Codes::Language_Codes ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-07'; # DATE
our $DIST = 'Sah-Schemas-Language'; # DIST
our $VERSION = '0.005'; # VERSION

my $codes = [];
my $names = [];
{
    for my $alpha2 (keys(%{ $Locale::Codes::Data{'language'}{'code2id'}{'alpha-2'} })) {
        push @$codes, $alpha2;
        my $id = $Locale::Codes::Data{'language'}{'code2id'}{'alpha-2'}{$alpha2}[0];
        push @$names, $Locale::Codes::Data{'language'}{'id2names'}{$id}[0];
    }

    die "Can't extract country codes from Locale::Codes::Language_Codes"
        unless @$codes;
}

our $schema = [str => {
    summary => 'Language code (alpha-2)',
    description => <<'_',

Accept only current (not retired) codes. Only alpha-2 codes are accepted.

_
    match => '\A[a-z]{2}\z',
    in => $codes,
    'x.in.summaries' => $names,
    'x.perl.coerce_rules' => ['From_str::to_lower'],

    examples => [
        {value=>"", valid=>0},
        {value=>"ID", valid=>1, validated_value=>"id", summary=>"Indonesian (2 letter)"},
        {value=>"IND", valid=>0, summary=>"Indonesian (3 letter, rejected)"},
        {value=>"qq", valid=>0, summary=>"Unknown language code"},
    ],

}, {}];

1;
# ABSTRACT: Language code (alpha-2)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::language::code::alpha2 - Language code (alpha-2)

=head1 VERSION

This document describes version 0.005 of Sah::Schema::language::code::alpha2 (from Perl distribution Sah-Schemas-Language), released on 2023-08-07.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "ID"  # valid (Indonesian (2 letter)), becomes "id"

 "IND"  # INVALID (Indonesian (3 letter, rejected))

 "qq"  # INVALID (Unknown language code)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("language::code::alpha2*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("language::code::alpha2", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "ID";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "IND";
 my $errmsg = $validator->($data); # => "Must be one of [\"km\",\"nn\",\"vo\",\"fa\",\"rm\",\"en\",\"aa\",\"oc\",\"mr\",\"ab\",\"tn\",\"lu\",\"oj\",\"cy\",\"sv\",\"lt\",\"sl\",\"tr\",\"lb\",\"la\",\"jv\",\"ps\",\"nr\",\"pi\",\"bm\",\"dv\",\"mn\",\"or\",\"af\",\"ny\",\"ff\",\"ht\",\"ie\",\"tk\",\"ty\",\"ha\",\"cr\",\"su\",\"av\",\"lv\",\"ja\",\"st\",\"id\",\"bh\",\"da\",\"be\",\"my\",\"vi\",\"sa\",\"mk\",\"gd\",\"hu\",\"qu\",\"pl\",\"nd\",\"sw\",\"mh\",\"fo\",\"si\",\"zh\",\"ss\",\"ee\",\"sg\",\"ne\",\"lo\",\"kk\",\"ky\",\"ik\",\"th\",\"te\",\"hi\",\"bn\",\"ch\",\"ce\",\"pt\",\"ho\",\"kr\",\"kj\",\"li\",\"pa\",\"gn\",\"lg\",\"as\",\"so\",\"fi\",\"rn\",\"om\",\"br\",\"ug\",\"kn\",\"ms\",\"ku\",\"ng\",\"iu\",\"mi\",\"se\",\"sh\",\"ru\",\"de\",\"ba\",\"tg\",\"gu\",\"ts\",\"sq\",\"co\",\"ti\",\"am\",\"ia\",\"he\",\"ka\",\"tw\",\"it\",\"os\",\"es\",\"ga\",\"sd\",\"mg\",\"eo\",\"no\",\"to\",\"wa\",\"cs\",\"sm\",\"gv\",\"gl\",\"ae\",\"kl\",\"kv\",\"nv\",\"el\",\"hz\",\"bo\",\"nl\",\"sr\",\"ay\",\"cu\",\"tl\",\"ak\",\"fy\",\"yo\",\"xh\",\"sc\",\"sn\",\"dz\",\"ko\",\"io\",\"ml\",\"hr\",\"ca\",\"ro\",\"uk\",\"bg\",\"ks\",\"ii\",\"ur\",\"ki\",\"rw\",\"is\",\"et\",\"zu\",\"hy\",\"wo\",\"nb\",\"ta\",\"kw\",\"tt\",\"az\",\"na\",\"an\",\"ve\",\"ln\",\"fr\",\"za\",\"ar\",\"yi\",\"sk\",\"cv\",\"eu\",\"mt\",\"kg\",\"bs\",\"fj\",\"bi\",\"ig\",\"uz\"]"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("language::code::alpha2", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "ID";
 my $res = $validator->($data); # => ["","id"]
 
 # a sample invalid data
 $data = "IND";
 my $res = $validator->($data); # => ["Must be one of [\"km\",\"nn\",\"vo\",\"fa\",\"rm\",\"en\",\"aa\",\"oc\",\"mr\",\"ab\",\"tn\",\"lu\",\"oj\",\"cy\",\"sv\",\"lt\",\"sl\",\"tr\",\"lb\",\"la\",\"jv\",\"ps\",\"nr\",\"pi\",\"bm\",\"dv\",\"mn\",\"or\",\"af\",\"ny\",\"ff\",\"ht\",\"ie\",\"tk\",\"ty\",\"ha\",\"cr\",\"su\",\"av\",\"lv\",\"ja\",\"st\",\"id\",\"bh\",\"da\",\"be\",\"my\",\"vi\",\"sa\",\"mk\",\"gd\",\"hu\",\"qu\",\"pl\",\"nd\",\"sw\",\"mh\",\"fo\",\"si\",\"zh\",\"ss\",\"ee\",\"sg\",\"ne\",\"lo\",\"kk\",\"ky\",\"ik\",\"th\",\"te\",\"hi\",\"bn\",\"ch\",\"ce\",\"pt\",\"ho\",\"kr\",\"kj\",\"li\",\"pa\",\"gn\",\"lg\",\"as\",\"so\",\"fi\",\"rn\",\"om\",\"br\",\"ug\",\"kn\",\"ms\",\"ku\",\"ng\",\"iu\",\"mi\",\"se\",\"sh\",\"ru\",\"de\",\"ba\",\"tg\",\"gu\",\"ts\",\"sq\",\"co\",\"ti\",\"am\",\"ia\",\"he\",\"ka\",\"tw\",\"it\",\"os\",\"es\",\"ga\",\"sd\",\"mg\",\"eo\",\"no\",\"to\",\"wa\",\"cs\",\"sm\",\"gv\",\"gl\",\"ae\",\"kl\",\"kv\",\"nv\",\"el\",\"hz\",\"bo\",\"nl\",\"sr\",\"ay\",\"cu\",\"tl\",\"ak\",\"fy\",\"yo\",\"xh\",\"sc\",\"sn\",\"dz\",\"ko\",\"io\",\"ml\",\"hr\",\"ca\",\"ro\",\"uk\",\"bg\",\"ks\",\"ii\",\"ur\",\"ki\",\"rw\",\"is\",\"et\",\"zu\",\"hy\",\"wo\",\"nb\",\"ta\",\"kw\",\"tt\",\"az\",\"na\",\"an\",\"ve\",\"ln\",\"fr\",\"za\",\"ar\",\"yi\",\"sk\",\"cv\",\"eu\",\"mt\",\"kg\",\"bs\",\"fj\",\"bi\",\"ig\",\"uz\"]","ind"]

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
     state $validator = gen_validator("language::code::alpha2*");
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
             schema => ['language::code::alpha2*'],
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

=head2 Using on the CLI with validate-with-sah

To validate some data on the CLI, you can use L<validate-with-sah> utility.
Specify the schema as the first argument (encoded in Perl syntax) and the data
to validate as the second argument (encoded in Perl syntax):

 % validate-with-sah '"language::code::alpha2*"' '"data..."'

C<validate-with-sah> has several options for, e.g. validating multiple data,
showing the generated validator code (Perl/JavaScript/etc), or loading
schema/data from file. See its manpage for more details.


=head2 Using with Type::Tiny

To create a type constraint and type library from a schema (requires
L<Type::Tiny> as well as L<Type::FromSah>):

 package My::Types {
     use Type::Library -base;
     use Type::FromSah qw( sah2type );

     __PACKAGE__->add_type(
         sah2type('language::code::alpha2*', name=>'LanguageCodeAlpha2')
     );
 }

 use My::Types qw(LanguageCodeAlpha2);
 LanguageCodeAlpha2->assert_valid($data);

=head1 DESCRIPTION

Accept only current (not retired) codes. Only alpha-2 codes are accepted.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Language>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Language>.

=head1 SEE ALSO

L<Sah::Schema::language::code::alpha3>

L<Sah::Schema::language::code>

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

This software is copyright (c) 2023, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Language>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
