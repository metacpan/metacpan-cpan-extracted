#!perl -T

use Test::More;

use Template;
use Template::Plugin::MIME;
use MIME::Entity;

my $template = Template->new;

sub io {
    my $in = shift;
    my $stash = shift || {};
    my $out;
    $template->process(\$in, $stash, \$out) or die $template->error;
    return $out;
}

my $cid = io('[%- USE MIME; MIME.attach("fourdots.gif") %]');

my $mail = MIME::Entity->build(
    Data => [qw[foo]]
);

Template::Plugin::MIME->merge($template, $mail);

is($mail->mime_type, 'multipart/related');

my @parts = $mail->parts;

is (@parts => 2, 'MIME parts');

my ($partA, $partB) = @parts;

is ($partA->mime_type, 'text/plain');

my $alts = join '|', map quotemeta, qw( image/gif application/octet-stream );
like ($partB->mime_type, qr{^$alts$});

done_testing;
