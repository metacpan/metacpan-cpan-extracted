#!perl -w
use strict;
use warnings;
use Test::More;
use Test::CGI::Multipart;
use Test::Exception;
use Readonly;
use lib qw(t/lib);
use Utils;
srand(0);

eval {require Test::CGI::Multipart::Gen::Text;};
if ($@) {
    my $msg = "This test requires Text::Lorem";
    plan skip_all => $msg;
}

Readonly my $PETS => ['Rex','Oscar','Bidgie','Fish'];
Readonly my $NAMES => ['first_name', 'paragraphs', 'pets', 'sentences', 'uninteresting', 'words'];
Readonly my $PARAGRAPH => qq{Reprehenderit similique a accusamus neque ad quaerat. Iusto temporibus consequuntur vitae earum accusantium sequi eum sequi. Debitis et voluptatem ipsam assumenda odit assumenda.\n\nOmnis velit est non quas. Iusto est in harum laudantium harum eos sapiente. Ducimus quia tenetur ea. Aut tenetur maiores in et voluptatem. Et veritatis tenetur delectus repellendus aut sunt veniam sapiente.};

my @cgi_modules = Utils::get_cgi_modules;
plan tests => 22+(2+scalar @$NAMES)*@cgi_modules;

my $tcm = Test::CGI::Multipart->new;
isa_ok($tcm, 'Test::CGI::Multipart');

ok(!defined $tcm->set_param(
    name=>'first_name',
    value=>'Jim'),
'setting parameter');
my @values = $tcm->get_param(name=>'first_name');
is_deeply(\@values, ['Jim'], 'get param');
my @names= $tcm->get_names;
is_deeply(\@names, ['first_name'], 'first name deep');

ok(!defined $tcm->set_param(
    name=>'pets',
    value=>$PETS),
'setting parameter');
@values = $tcm->get_param(name=>'pets');
is_deeply(\@values, $PETS, 'get param');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name','pets'], 'names deep');

ok(!defined $tcm->upload_file(
    name=>'uninteresting',
    file=>'other.blah',
    value=>'Fee Fi Fo Fum',
), 'uploading other file');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name', 'pets', 'uninteresting'], 'names deep');

ok(!defined $tcm->upload_file(
    name=>'words',
    file=>'words.txt',
    type=>'text/plain',
    words=>5,
    sentences=>2,
    paragraphs=>2,
), 'uploading other file');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name', 'pets', 'uninteresting', 'words'], 'names deep');
is_deeply(Utils::get_expected($tcm, 'words'), [{name=>'words',value=>'ipsum placeat explicabo accusamus in',file=>'words.txt',type=>'text/plain'}], 'words');

ok(!defined $tcm->upload_file(
    name=>'sentences',
    file=>'sentences.txt',
    type=>'text/plain',
    sentences=>2,
    paragraphs=>2,
), 'uploading other file');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name', 'pets', 'sentences', 'uninteresting', 'words']);
is_deeply(Utils::get_expected($tcm, 'sentences'), [{name=>'sentences',value=>'Eligendi consequatur officiis maxime ducimus ex minus quaerat. Omnis nulla in porro vitae blanditiis.',file=>'sentences.txt',type=>'text/plain'}], 'sentences');

ok(!defined $tcm->upload_file(
    name=>'paragraphs',
    file=>'paragraphs.txt',
    type=>'text/plain',
    paragraphs=>2,
), 'uploading other file');
@names= sort $tcm->get_names;
is_deeply(\@names, $NAMES);
is_deeply(Utils::get_expected($tcm, 'paragraphs')->[0]->{value}, $PARAGRAPH, 'paragraphs');

throws_ok {$tcm->upload_file(
    name=>'paragraphs',
    file=>'paragraphs.txt',
    type=>'text/plain',
)} qr/No words, sentences or paragraphs specified/, 'inadequately specified';

throws_ok {$tcm->upload_file(
    name=>'paragraphs',
    file=>'paragraphs.txt',
    type=>'text/plain',
    words=>'twenty',
)} qr/No words, sentences or paragraphs specified/, 'inadequately specified';

throws_ok {$tcm->upload_file(
    name=>'paragraphs',
    file=>'paragraphs.txt',
    type=>'application/blah',
    words=>'twenty',
)} qr/The following parameter was passed in the call to Test::CGI::Multipart::_upload_file but was not listed in the validation options: words/, 'wrong type';

throws_ok {$tcm->upload_file(
    name=>'paragraphs',
    file=>'paragraphs.txt',
    value=>'Hello world',
    type=>'text/plain',
    words=>'twenty',
)} qr/The following parameter was passed in the call to Test::CGI::Multipart::_upload_file but was not listed in the validation options: words/, 'words and value specified';

foreach my $class (@cgi_modules) {

    if ($class) {
        diag "Testing with $class";
    }

    my $cgi = undef;
    if ($class) {
        $cgi = $tcm->create_cgi(cgi=>$class);
    }
    else {
        $cgi = $tcm->create_cgi;
    }
    isa_ok($cgi, $class||'CGI', 'created CGI object okay');

    @names = grep {$_ ne '' and $_ ne '.submit'} sort $cgi->param;
    is_deeply(\@names, $NAMES, 'names deep');
    foreach my $name (@names) {
        my $expected = Utils::get_expected($tcm, $name);
        my $got = undef;
        if (ref $expected->[0] eq 'HASH') {
            $got = Utils::get_actual_upload($cgi, $name);
        }
        else {
            my @got = $cgi->param($name);
            $got = \@got;
        }

        is_deeply($got, $expected, $name);
    }

}


