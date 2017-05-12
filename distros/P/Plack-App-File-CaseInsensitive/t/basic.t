use strict;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;
use Plack::App::File::CaseInsensitive;

my $app = Plack::App::File::CaseInsensitive->new();
test_psgi $app, sub {
    my $cb = shift;

    my $warnings = '';
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    my $res = $cb->(GET "/t/fOo");
    like($warnings, qr/CASE INSENSITIVE MODE/i, 'correctly warned user');
    like($warnings, qr(t/foo)i, 'warning contains path');
    is $res->code, 200;
    like $res->content, qr/Plack/;
};

done_testing;
