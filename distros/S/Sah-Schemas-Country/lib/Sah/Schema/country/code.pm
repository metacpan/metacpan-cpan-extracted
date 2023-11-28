package Sah::Schema::country::code;

use strict;
use Locale::Codes::Country_Codes ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-07'; # DATE
our $DIST = 'Sah-Schemas-Country'; # DIST
our $VERSION = '0.009'; # VERSION

my $codes = [];
my $names = [];
{
    for my $alpha2 (keys(%{ $Locale::Codes::Data{'country'}{'code2id'}{'alpha-2'} })) {
        push @$codes, $alpha2;
        my $id = $Locale::Codes::Data{'country'}{'code2id'}{'alpha-2'}{$alpha2}[0];
        push @$names, $Locale::Codes::Data{'country'}{'id2names'}{$id}[0];
    }
    for my $alpha3 (keys(%{ $Locale::Codes::Data{'country'}{'code2id'}{'alpha-3'} })) {
        push @$codes, $alpha3;
        my $id = $Locale::Codes::Data{'country'}{'code2id'}{'alpha-3'}{$alpha3}[0];
        push @$names, $Locale::Codes::Data{'country'}{'id2names'}{$id}[0];
    }

    die "Can't extract country codes from Locale::Codes::Country_Codes"
        unless @$codes;
}

our $schema = [str => {
    summary => 'Country code (alpha-2 or alpha-3)',
    description => <<'_',

Accept only current (not retired) codes. Alpha-2 or alpha-3 codes are accepted.

Code will be converted to lowercase.

_
    match => '\A[a-z]{2,3}\z',
    in => $codes,
    'x.in.summaries' => $names,
    'x.perl.coerce_rules' => ['From_str::to_lower'],
    examples => [
        {value=>'', valid=>0},
        {value=>'ID' , valid=>1, validated_value=>'id'},
        {value=>'IDN', valid=>1, validated_value=>'idn'},
        {value=>'xx', valid=>0},
        {value=>'xxx', valid=>0},
    ],
}];

1;
# ABSTRACT: Country code (alpha-2 or alpha-3)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::country::code - Country code (alpha-2 or alpha-3)

=head1 VERSION

This document describes version 0.009 of Sah::Schema::country::code (from Perl distribution Sah-Schemas-Country), released on 2023-08-07.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "ID"  # valid, becomes "id"

 "IDN"  # valid, becomes "idn"

 "xx"  # INVALID

 "xxx"  # INVALID

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("country::code*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("country::code", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "IDN";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "xx";
 my $errmsg = $validator->($data); # => "Must be one of [\"hu\",\"tv\",\"ca\",\"pk\",\"by\",\"tf\",\"pn\",\"tm\",\"bl\",\"ie\",\"pm\",\"tn\",\"lt\",\"pf\",\"tk\",\"cg\",\"ls\",\"ga\",\"mg\",\"mq\",\"ph\",\"jp\",\"fr\",\"dm\",\"yt\",\"ax\",\"as\",\"bb\",\"th\",\"sr\",\"kg\",\"dk\",\"us\",\"ma\",\"ee\",\"at\",\"gg\",\"io\",\"gq\",\"ec\",\"lv\",\"jo\",\"qa\",\"ps\",\"bi\",\"sa\",\"pt\",\"mr\",\"vn\",\"tt\",\"lk\",\"ro\",\"id\",\"gr\",\"kr\",\"sg\",\"am\",\"sj\",\"af\",\"um\",\"je\",\"nf\",\"bw\",\"fj\",\"re\",\"cr\",\"mx\",\"na\",\"gs\",\"aq\",\"gt\",\"il\",\"ag\",\"ug\",\"tr\",\"sh\",\"om\",\"ua\",\"mt\",\"pr\",\"rw\",\"ru\",\"be\",\"ng\",\"ms\",\"vg\",\"sn\",\"fm\",\"sk\",\"cx\",\"sm\",\"fk\",\"bo\",\"sv\",\"la\",\"va\",\"kn\",\"zw\",\"ch\",\"mv\",\"lr\",\"gn\",\"mf\",\"mm\",\"bd\",\"mn\",\"bz\",\"gf\",\"gm\",\"mk\",\"km\",\"tj\",\"ar\",\"pa\",\"ss\",\"cn\",\"tg\",\"ck\",\"kh\",\"gh\",\"st\",\"mh\",\"nr\",\"cv\",\"dj\",\"pg\",\"sx\",\"cm\",\"cf\",\"zm\",\"ci\",\"sl\",\"de\",\"rs\",\"sy\",\"ad\",\"uz\",\"az\",\"mu\",\"mw\",\"to\",\"gw\",\"gu\",\"lc\",\"vc\",\"kw\",\"nz\",\"np\",\"nc\",\"ki\",\"in\",\"gi\",\"do\",\"eh\",\"br\",\"sb\",\"pe\",\"im\",\"cu\",\"cw\",\"es\",\"hr\",\"jm\",\"dz\",\"cl\",\"cy\",\"ba\",\"et\",\"si\",\"ae\",\"bg\",\"bq\",\"fi\",\"ne\",\"ye\",\"tc\",\"gb\",\"ao\",\"it\",\"gl\",\"tz\",\"gy\",\"ve\",\"td\",\"bj\",\"ky\",\"is\",\"no\",\"ml\",\"my\",\"bh\",\"ni\",\"lu\",\"vu\",\"cz\",\"er\",\"cd\",\"se\",\"mc\",\"ht\",\"ai\",\"py\",\"au\",\"aw\",\"pl\",\"bn\",\"mz\",\"md\",\"mp\",\"fo\",\"cc\",\"bv\",\"so\",\"kp\",\"ws\",\"li\",\"vi\",\"kz\",\"nu\",\"bf\",\"bm\",\"tl\",\"gp\",\"gd\",\"ir\",\"nl\",\"lb\",\"hm\",\"tw\",\"mo\",\"uy\",\"pw\",\"al\",\"iq\",\"hn\",\"hk\",\"sd\",\"sz\",\"sc\",\"me\",\"wf\",\"bt\",\"bs\",\"ke\",\"za\",\"ge\",\"eg\",\"co\",\"ly\",\"phl\",\"esp\",\"tkm\",\"ago\",\"jor\",\"cyp\",\"cuw\",\"blm\",\"can\",\"aia\",\"hun\",\"atg\",\"vat\",\"esh\",\"glp\",\"mli\",\"mda\",\"ind\",\"eth\",\"png\",\"asm\",\"bfa\",\"guy\",\"deu\",\"ukr\",\"jpn\",\"prt\",\"cck\",\"lao\",\"tkl\",\"blr\",\"afg\",\"are\",\"gab\",\"swz\",\"vnm\",\"idn\",\"tcd\",\"bgd\",\"srb\",\"ala\",\"mwi\",\"rus\",\"bes\",\"tgo\",\"che\",\"zwe\",\"cok\",\"mne\",\"mar\",\"guf\",\"grl\",\"sjm\",\"mmr\",\"flk\",\"plw\",\"ben\",\"bmu\",\"gnq\",\"bol\",\"lca\",\"sgs\",\"zaf\",\"omn\",\"shn\",\"gtm\",\"nam\",\"lso\",\"iot\",\"svn\",\"gnb\",\"fro\",\"cmr\",\"bra\",\"grc\",\"bel\",\"niu\",\"gmb\",\"eri\",\"pyf\",\"arg\",\"abw\",\"nld\",\"hmd\",\"vgb\",\"dza\",\"hti\",\"hnd\",\"mac\",\"msr\",\"mtq\",\"tto\",\"tca\",\"chn\",\"mhl\",\"egy\",\"sxm\",\"pse\",\"qat\",\"fsm\",\"lby\",\"tza\",\"chl\",\"ita\",\"mrt\",\"moz\",\"mng\",\"cod\",\"pan\",\"khm\",\"smr\",\"arm\",\"cxr\",\"aut\",\"prk\",\"uga\",\"gum\",\"kgz\",\"ncl\",\"kaz\",\"bvt\",\"gbr\",\"lie\",\"nga\",\"ton\",\"ner\",\"mco\",\"ggy\",\"sgp\",\"bgr\",\"rwa\",\"brn\",\"isr\",\"civ\",\"ltu\",\"imn\",\"slv\",\"bih\",\"fji\",\"vut\",\"svk\",\"cri\",\"blz\",\"gin\",\"nzl\",\"wlf\",\"cze\",\"dom\",\"umi\",\"npl\",\"nor\",\"sur\",\"pol\",\"gib\",\"yem\",\"isl\",\"syr\",\"jey\",\"kna\",\"tjk\",\"fin\",\"reu\",\"bhs\",\"brb\",\"cym\",\"cub\",\"maf\",\"pcn\",\"grd\",\"atf\",\"hrv\",\"gha\",\"uzb\",\"rou\",\"nic\",\"aus\",\"zmb\",\"caf\",\"kir\",\"slb\",\"tls\",\"sau\",\"and\",\"per\",\"pak\",\"ecu\",\"geo\",\"ven\",\"tur\",\"bdi\",\"mdv\",\"sen\",\"mdg\",\"lbr\",\"mnp\",\"kor\",\"irl\",\"fra\",\"dma\",\"sle\",\"dnk\",\"irn\",\"jam\",\"wsm\",\"stp\",\"aze\",\"dji\",\"som\",\"pry\",\"mys\",\"cpv\",\"ata\",\"tha\",\"vct\",\"kwt\",\"mex\",\"alb\",\"usa\",\"ury\",\"nru\",\"sdn\",\"spm\",\"pri\",\"mus\",\"lva\",\"bhr\",\"swe\",\"lux\",\"tun\",\"twn\",\"col\",\"lka\",\"mlt\",\"lbn\",\"myt\",\"cog\",\"mkd\",\"com\",\"nfk\",\"est\",\"ssd\",\"ken\",\"tuv\",\"syc\",\"bwa\",\"hkg\",\"vir\",\"irq\",\"btn\"]"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("country::code", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "IDN";
 my $res = $validator->($data); # => ["","idn"]
 
 # a sample invalid data
 $data = "xx";
 my $res = $validator->($data); # => ["Must be one of [\"hu\",\"tv\",\"ca\",\"pk\",\"by\",\"tf\",\"pn\",\"tm\",\"bl\",\"ie\",\"pm\",\"tn\",\"lt\",\"pf\",\"tk\",\"cg\",\"ls\",\"ga\",\"mg\",\"mq\",\"ph\",\"jp\",\"fr\",\"dm\",\"yt\",\"ax\",\"as\",\"bb\",\"th\",\"sr\",\"kg\",\"dk\",\"us\",\"ma\",\"ee\",\"at\",\"gg\",\"io\",\"gq\",\"ec\",\"lv\",\"jo\",\"qa\",\"ps\",\"bi\",\"sa\",\"pt\",\"mr\",\"vn\",\"tt\",\"lk\",\"ro\",\"id\",\"gr\",\"kr\",\"sg\",\"am\",\"sj\",\"af\",\"um\",\"je\",\"nf\",\"bw\",\"fj\",\"re\",\"cr\",\"mx\",\"na\",\"gs\",\"aq\",\"gt\",\"il\",\"ag\",\"ug\",\"tr\",\"sh\",\"om\",\"ua\",\"mt\",\"pr\",\"rw\",\"ru\",\"be\",\"ng\",\"ms\",\"vg\",\"sn\",\"fm\",\"sk\",\"cx\",\"sm\",\"fk\",\"bo\",\"sv\",\"la\",\"va\",\"kn\",\"zw\",\"ch\",\"mv\",\"lr\",\"gn\",\"mf\",\"mm\",\"bd\",\"mn\",\"bz\",\"gf\",\"gm\",\"mk\",\"km\",\"tj\",\"ar\",\"pa\",\"ss\",\"cn\",\"tg\",\"ck\",\"kh\",\"gh\",\"st\",\"mh\",\"nr\",\"cv\",\"dj\",\"pg\",\"sx\",\"cm\",\"cf\",\"zm\",\"ci\",\"sl\",\"de\",\"rs\",\"sy\",\"ad\",\"uz\",\"az\",\"mu\",\"mw\",\"to\",\"gw\",\"gu\",\"lc\",\"vc\",\"kw\",\"nz\",\"np\",\"nc\",\"ki\",\"in\",\"gi\",\"do\",\"eh\",\"br\",\"sb\",\"pe\",\"im\",\"cu\",\"cw\",\"es\",\"hr\",\"jm\",\"dz\",\"cl\",\"cy\",\"ba\",\"et\",\"si\",\"ae\",\"bg\",\"bq\",\"fi\",\"ne\",\"ye\",\"tc\",\"gb\",\"ao\",\"it\",\"gl\",\"tz\",\"gy\",\"ve\",\"td\",\"bj\",\"ky\",\"is\",\"no\",\"ml\",\"my\",\"bh\",\"ni\",\"lu\",\"vu\",\"cz\",\"er\",\"cd\",\"se\",\"mc\",\"ht\",\"ai\",\"py\",\"au\",\"aw\",\"pl\",\"bn\",\"mz\",\"md\",\"mp\",\"fo\",\"cc\",\"bv\",\"so\",\"kp\",\"ws\",\"li\",\"vi\",\"kz\",\"nu\",\"bf\",\"bm\",\"tl\",\"gp\",\"gd\",\"ir\",\"nl\",\"lb\",\"hm\",\"tw\",\"mo\",\"uy\",\"pw\",\"al\",\"iq\",\"hn\",\"hk\",\"sd\",\"sz\",\"sc\",\"me\",\"wf\",\"bt\",\"bs\",\"ke\",\"za\",\"ge\",\"eg\",\"co\",\"ly\",\"phl\",\"esp\",\"tkm\",\"ago\",\"jor\",\"cyp\",\"cuw\",\"blm\",\"can\",\"aia\",\"hun\",\"atg\",\"vat\",\"esh\",\"glp\",\"mli\",\"mda\",\"ind\",\"eth\",\"png\",\"asm\",\"bfa\",\"guy\",\"deu\",\"ukr\",\"jpn\",\"prt\",\"cck\",\"lao\",\"tkl\",\"blr\",\"afg\",\"are\",\"gab\",\"swz\",\"vnm\",\"idn\",\"tcd\",\"bgd\",\"srb\",\"ala\",\"mwi\",\"rus\",\"bes\",\"tgo\",\"che\",\"zwe\",\"cok\",\"mne\",\"mar\",\"guf\",\"grl\",\"sjm\",\"mmr\",\"flk\",\"plw\",\"ben\",\"bmu\",\"gnq\",\"bol\",\"lca\",\"sgs\",\"zaf\",\"omn\",\"shn\",\"gtm\",\"nam\",\"lso\",\"iot\",\"svn\",\"gnb\",\"fro\",\"cmr\",\"bra\",\"grc\",\"bel\",\"niu\",\"gmb\",\"eri\",\"pyf\",\"arg\",\"abw\",\"nld\",\"hmd\",\"vgb\",\"dza\",\"hti\",\"hnd\",\"mac\",\"msr\",\"mtq\",\"tto\",\"tca\",\"chn\",\"mhl\",\"egy\",\"sxm\",\"pse\",\"qat\",\"fsm\",\"lby\",\"tza\",\"chl\",\"ita\",\"mrt\",\"moz\",\"mng\",\"cod\",\"pan\",\"khm\",\"smr\",\"arm\",\"cxr\",\"aut\",\"prk\",\"uga\",\"gum\",\"kgz\",\"ncl\",\"kaz\",\"bvt\",\"gbr\",\"lie\",\"nga\",\"ton\",\"ner\",\"mco\",\"ggy\",\"sgp\",\"bgr\",\"rwa\",\"brn\",\"isr\",\"civ\",\"ltu\",\"imn\",\"slv\",\"bih\",\"fji\",\"vut\",\"svk\",\"cri\",\"blz\",\"gin\",\"nzl\",\"wlf\",\"cze\",\"dom\",\"umi\",\"npl\",\"nor\",\"sur\",\"pol\",\"gib\",\"yem\",\"isl\",\"syr\",\"jey\",\"kna\",\"tjk\",\"fin\",\"reu\",\"bhs\",\"brb\",\"cym\",\"cub\",\"maf\",\"pcn\",\"grd\",\"atf\",\"hrv\",\"gha\",\"uzb\",\"rou\",\"nic\",\"aus\",\"zmb\",\"caf\",\"kir\",\"slb\",\"tls\",\"sau\",\"and\",\"per\",\"pak\",\"ecu\",\"geo\",\"ven\",\"tur\",\"bdi\",\"mdv\",\"sen\",\"mdg\",\"lbr\",\"mnp\",\"kor\",\"irl\",\"fra\",\"dma\",\"sle\",\"dnk\",\"irn\",\"jam\",\"wsm\",\"stp\",\"aze\",\"dji\",\"som\",\"pry\",\"mys\",\"cpv\",\"ata\",\"tha\",\"vct\",\"kwt\",\"mex\",\"alb\",\"usa\",\"ury\",\"nru\",\"sdn\",\"spm\",\"pri\",\"mus\",\"lva\",\"bhr\",\"swe\",\"lux\",\"tun\",\"twn\",\"col\",\"lka\",\"mlt\",\"lbn\",\"myt\",\"cog\",\"mkd\",\"com\",\"nfk\",\"est\",\"ssd\",\"ken\",\"tuv\",\"syc\",\"bwa\",\"hkg\",\"vir\",\"irq\",\"btn\"]","xx"]

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
     state $validator = gen_validator("country::code*");
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
             schema => ['country::code*'],
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

 % validate-with-sah '"country::code*"' '"data..."'

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
         sah2type('country::code*', name=>'CountryCode')
     );
 }

 use My::Types qw(CountryCode);
 CountryCode->assert_valid($data);

=head1 DESCRIPTION

Accept only current (not retired) codes. Alpha-2 or alpha-3 codes are accepted.

Code will be converted to lowercase.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Country>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Country>.

=head1 SEE ALSO

L<Sah::Schema::country::code::alpha2>

L<Sah::Schema::country::code::alpha3>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Country>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
