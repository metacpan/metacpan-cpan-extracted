use Test::More tests => 4;

use qbit;
use QBit::Validator;

#
# pre_run
#

my $error;
try {
    QBit::Validator->new(data => 123, template => {}, pre_run => undef);
}
catch {
    $error = TRUE;
};
ok($error, 'Option "pre_run" must be code');

$error = FALSE;
try {
    QBit::Validator->new(data => 123, template => {}, pre_run => 'pre_run');
}
catch {
    $error = TRUE;
};
ok($error, 'Option "pre_run" must be code');

ok(QBit::Validator->new(data => 123, template => {type => 'hash'}, pre_run => sub { })->has_errors, 'Useless pre_run');

ok(
    !QBit::Validator->new(
        data     => 123,
        template => {type => 'hash'},
        pre_run  => sub {
            my ($qv) = @_;

            my $template = $qv->template;

            $template = {type => 'scalar'};

            $qv->template($template);
        }
      )->has_errors,
    'Change template from pre_run'
  );
