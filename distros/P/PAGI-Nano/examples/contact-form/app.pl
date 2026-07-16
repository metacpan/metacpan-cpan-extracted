use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use FindBin;
use PAGI::Nano;

# Ports PAGI-Tools' 13-contact-form to PAGI::Nano.
# Form parsing, whitelisting, and a custom 400 on missing fields via
# $c->params->required; an optional multipart file upload read through
# $c->req->upload; and the form page served statically.
#
#     pagi-server app.pl
#     curl -X POST -F email=a@b.com -F message=hi -F attachment=@README \
#          http://127.0.0.1:5000/submit

my $app = app {
    static '/form' => "$FindBin::Bin/public/";

    post '/submit' => async sub ($c) {
        # Strong parameters: whitelist + a chosen 400 if a required field is absent.
        my $attrs = await $c->params->required(
            'email', 'message',
            sub ($c, $missing) {
                $c->json({ error => 'missing fields', fields => $missing }, status => 400);
            },
        );

        # Optional file upload (multipart). $req->upload is async; undef if absent.
        my $upload = await $c->req->upload('attachment');
        my $file = $upload ? { filename => $upload->filename, size => $upload->size } : undef;

        $c->json({ received => $attrs, attachment => $file }, status => 201);
    };
};

$app;
