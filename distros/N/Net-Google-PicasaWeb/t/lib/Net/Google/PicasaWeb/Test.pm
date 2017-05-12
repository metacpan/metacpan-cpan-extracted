package Net::Google::PicasaWeb::Test;
use Test::Able::Simple;


has '+test_packages' => (
    default    => sub { [ qw(
    ) ] },
);
