#!perl -T

use Test::More;

use Template;
use Template::Plugin::MIME;

my $template = Template->new;

sub io {
    my $in = shift;
    my $stash = shift || {};
    my $out;
    $template->process(\$in, $stash, \$out) or die $template->error;
    return $out;
}

my $html = io(<<'EOT');
[%- USE MIME hostname = 'localhost' -%]
[%- img = MIME.attach('fourdots.gif', Encoding => 'Base64', Type => 'image/gif') -%]
Four Dots: <img src="cid:[% img %]" />
EOT

is($html => <<'EOR');
Four Dots: <img src="cid:b3376abfd1f123b891dcb342ac5a7c2cc1da2e30b545b063806bf9f40a01033a@localhost" />
EOR

my $mail = build MIME::Entity(
    From => 'foo',
    To => 'bar',
    Subject => 'baz',
    Type => 'text/html',
    Data => \$html,
);

ok(defined $mail);

Template::Plugin::MIME->merge($template => $mail);

#diag($mail->as_string);

done_testing;
