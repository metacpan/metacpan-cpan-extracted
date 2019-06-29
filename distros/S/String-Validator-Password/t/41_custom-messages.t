#!perl -T
# String Validator Password

use Test::More tests => 6;
use Test::More;
use Data::Printer;

BEGIN {
  use_ok('String::Validator::Password') || print "Bail out!\n";
}

diag(
"Testing String::Validator::Password $String::Validator::Password::VERSION, Perl $], $^X"
);

my $messages = {
  common_strings_not_match => "Test non-match",
  password_typeprohibit    => sub {
    my $type = shift @_;
    if ( $type eq 'num' ) { $type = 'numeric' }
    return "Test type $type prohibited.";
  },
  somevalidator_sandworm => 'Shai-Halud'
};

my $Validator = String::Validator::Password->new(
  deny_punct      => 1,
  require_punct   => 0,
  custom_messages => $messages
);
is( $Validator->isa('String::Validator::Password'),
  1, 'New validator isa String::Validator::Password' );

is( $Validator->Check( 'aBC123*!', 'aBC123*!' ),
  1, 'A password containing punct when it is not allowed.' );
my $testabcerrstr = $Validator->errstr();
chomp $testabcerrstr; #responses end with a return
is(
  $testabcerrstr,
  "Test type punct prohibited.",
  "error message matches the custom coderef one we set."
);

is( $Validator->Check( 'aBC123*', '1234567689' ),
  1, 'Mismatched passwords fail.' );
is( $Validator->errstr(), "Test non-match\n",
  "Check non coderef custom error string");


done_testing();
