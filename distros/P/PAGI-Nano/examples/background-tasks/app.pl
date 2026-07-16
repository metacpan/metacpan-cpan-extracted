use v5.40;
use experimental 'signatures';
use Future;
use Future::AsyncAwait;
use Future::IO;
use PAGI::Nano;

# Ports PAGI-Tools' background-tasks to PAGI::Nano.
# Respond immediately, then do work in the background. Nano sends the handler's
# return value after the handler returns, so a Future that is *retained* (not
# awaited) keeps running on the loop without delaying the response.
#
#     pagi-server app.pl
#     curl -X POST -H 'content-type: application/json' -d '{"email":"a@b.com"}' \
#          http://127.0.0.1:5000/signup

# Fire-and-forget background work. Returns a Future the handler retains.
sub send_welcome_email ($address) {
    return (async sub {
        await Future::IO->sleep(1);          # pretend to talk to an SMTP server
        warn "[bg] welcome email sent to $address\n";
    })->();
}

my $app = app {
    get '/' => sub ($c) { { hint => 'POST /signup {"email":...} to fire a background task' } };

    post '/signup' => async sub ($c) {
        my $attrs = await $c->params->permitted('email');
        my $email = $attrs->{email} // 'anonymous';

        # Kick off the slow work and retain it: not awaited, so the 202 returns now.
        send_welcome_email($email)->retain;

        $c->json({ status => 'accepted', email => $email }, status => 202);
    };
};

$app;
