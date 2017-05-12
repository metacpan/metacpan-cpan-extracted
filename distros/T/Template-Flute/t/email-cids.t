use strict;
use warnings;

use Template::Flute;
use Test::More tests => 10;


my $html = <<'HTML';
<html><head><body>
<img src="foo.png" alt="Foo" />
<img src="foo2.png" />
</body></html>"
HTML

my $spec = <<'SPEC';
<specification></specification>
SPEC

my $cids = {};
my $flute = Template::Flute->new(template => $html,
                                 specification => $spec,
                                 email_cids => $cids);

my $out = $flute->process;

like $out, qr/src="cid:foopng".*src="cid:foo2png"/, "Found the cids";

is_deeply $cids, {
                  foopng => {
                             filename => "foo.png",
                            },
                  foo2png => {
                              filename => "foo2.png",
                             }
                 }, "the email_cids has been correctly populated";

$html = <<'HTML';
<html><head><body>
<img src="foo.png" alt="Foo" />
<img src="foo2.png" />
<div class="list-container">
 <div class="listing">
  <img class="picture" src="/blabla/bla" />
 </div>
</div>
</body></html>"
HTML

$spec = <<'SPEC';
<specification>
 <list name="listing" iterator="mylist">
   <param name="image" class="picture" target="src" />
 </list>
</specification>
SPEC

$cids = {};
$flute = Template::Flute->new(template => $html,
                                 specification => $spec,
                                 email_cids => $cids,
                                 values => {
                                            mylist => [{
                                                        image => 'pippo1.png',
                                                       },
                                                       {
                                                        image => 'pippo2.png',
                                                       },
                                                       {
                                                        image => 'http://example.com/image.jpg',
                                                       }
                                                      ],
                                           },
                                );

$out = $flute->process;

like $out, qr/pippo1.*pippo2/, "list appears interpolated ok";
like $out, qr/src="cid:pippo1png".*src="cid:pippo2png"/, "Found the cids";
like $out, qr!src="http://example.com/image.jpg"!, "URL left intact";

is_deeply $cids, {
                  foopng => {
                             filename => "foo.png",
                            },
                  foo2png => {
                              filename => "foo2.png",
                             },
                  pippo1png => {
                                filename => "pippo1.png",
                               },
                  pippo2png => {
                                filename => "pippo2.png"
                               },
                 }, "the email_cids has been correctly populated with lists";



$html = <<'HTML';
<html><head><body>
<img src="foo.png" alt="Foo" />
<img src="foo2.png" />
<div class="list-container">
 <div class="listing">
  <img class="picture" src="/blabla/bla" />
 </div>
</div>
</body></html>"
HTML

$spec = <<'SPEC';
<specification>
 <list name="listing" iterator="mylist">
   <param name="image" class="picture" target="src" />
 </list>
</specification>
SPEC

$cids = {};
$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              email_cids => $cids,
                              cids => {
                                       base_url => 'http://example.com/',
                                      },
                              values => {
                                         mylist => [{
                                                     image => 'pippo1.png',
                                                    },
                                                    {
                                                     image => 'pippo2.png',
                                                    },
                                                    {
                                                     image => 'http://example.com/image.jpg',
                                                    },
                                                   ],
                                        },
                             );

$out = $flute->process;

like $out, qr/pippo1.*pippo2/, "list appears interpolated ok";
like $out, qr/src="cid:pippo1png".*src="cid:pippo2png"/, "Found the cids";
like $out, qr/src="cid:pippo1png".*src="cid:httpexamplecomimagejpg"/, "Found the cids";


is_deeply $cids, {
                  foopng => {
                             filename => "foo.png",
                            },
                  foo2png => {
                              filename => "foo2.png",
                             },
                  pippo1png => {
                                filename => "pippo1.png",
                               },
                  pippo2png => {
                                filename => "pippo2.png"
                               },
                  httpexamplecomimagejpg => {
                                             filename => 'image.jpg',
                                            },
                 }, "the email_cids has been correctly populated with lists";





