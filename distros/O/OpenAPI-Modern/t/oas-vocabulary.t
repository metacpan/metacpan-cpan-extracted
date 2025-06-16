# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::JSON::Schema::Acceptance 1.014;
use Path::Tiny;
use Config;

use lib 't/lib';
use Helper;

my $accepter = Test::JSON::Schema::Acceptance->new(
  verbose => 1,
  test_schemas => 0,  # some schemas are not valid, as we are testing error handling in traverse()
  specification => 'draft2020-12',
  test_dir => 't/oas-vocabulary',
);
$accepter->json_decoder->allow_bignum if Test::JSON::Schema::Acceptance->VERSION < '1.022';

my $js = JSON::Schema::Modern->new(
  specification_version => 'draft2020-12',
  validate_formats => 1,
);

# construct a minimal document in order to get the vocabulary and formats loaded
my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
  evaluator => $js,
  schema => {
    openapi => OAS_VERSION,
    info => {
      title => 'my title',
      version => '1.2.3',
    },
    paths => {},
  },
);

$accepter->acceptance(
  validate_data => sub ($schema, $instance_data) {
    my $result = $js->evaluate($instance_data, $schema);

    my $encoder = JSON::Schema::Modern::_JSON_BACKEND()->new->allow_nonref(1)->utf8(0)->convert_blessed(1)->canonical(1)->pretty(1);
    $encoder->indent_length(2) if $encoder->can('indent_length');
    note 'result: ', $encoder->encode($result);

    warn('evaluation generated an exception: '.$encoder->encode($_))
      foreach
        grep +($_->{error} =~ /^EXCEPTION/),
          ($result->TO_JSON->{errors}//[])->@*;

    $result->valid;
  },
  @ARGV ? (tests => { file => \@ARGV }) : (),
);

path('t/results/oas-vocabulary.txt')->spew_utf8($accepter->results_text)
  if -d '.git' or $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};

done_testing;
__END__
see t/results/oas-vocabulary.txt for test results
