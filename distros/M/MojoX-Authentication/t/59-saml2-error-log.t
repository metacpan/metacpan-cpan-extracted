use v5.24;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use MIME::Base64 qw< encode_base64 >;

for my $module (qw< Test::Mojo Mojolicious::Plugin::Authentication >) {
   eval "require $module; 1" or plan skip_all => "$module not available";
}
eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 }
   or plan skip_all => 'Net::SAML2 0.86 not available';
require Net::SAML2::XML::Sig;

use Mojolicious::Lite;
use experimental qw< signatures >;   # after Mojolicious::Lite, which re-enables its warning
use MojoX::Authentication;

# A refused SAMLResponse is logged with the error that refused it, and
# that error can carry text from the response itself: e.g. the Status,
# which is outside whatever the IdP signed, or the whole response in a
# stack trace. Anybody holding any element signed by the IdP (an old
# assertion, signed metadata) can send such responses, so the log line
# must have no control characters and stay short.

my $data = "$Bin/data";
my $mauth = MojoX::Authentication->new(
   provider_name => 'saml2',
   model => {
      providers => [
         {
            class => 'MojoX::Authentication::Model::SAML2',
            args  => {
               idp => "$data/test-idp-metadata.xml",
               sp_configuration => {
                  identifier => 'https://srv.example.com/sp',
                  key        => "$Bin/../eg/server.key",
               },
            },
         },
      ],
   },
);
$mauth->app_startup(app);

my @log;
app->log->level('trace');
app->log->unsubscribe('message');
app->log->on(message => sub ($log, $level, @lines) { push @log, join ' ', @lines });

get  '/public' => sub ($c) { $c->render(text => 'public') } => 'public_root';
get  '/saml2'  => sub ($c) { $mauth->ctr_saml2_login($c, {}) };
post '/sso'    => sub ($c) { $mauth->ctr_saml2_sso_post($c) };

# an element signed by the IdP, valid for nothing in particular: only
# what an attacker can wrap in a response of their own making
my $signed = Net::SAML2::XML::Sig->new({
   x509 => 1,
   key  => "$data/test-idp.key",
   cert => "$data/test-idp.crt",
   no_xml_declaration => 1,
})->sign(q{<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" ID="md1" entityID="https://idp.example.com"/>});

sub response (%o) {
   my $irt = defined($o{in_response_to}) ? qq{ InResponseTo="$o{in_response_to}"} : q{};
   my $xml = qq{<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="r1"$irt Version="2.0" IssueInstant="2026-01-01T00:00:00Z">}
      . qq{<samlp:Status><samlp:StatusCode Value="$o{status}"/></samlp:Status>}
      . ($o{padding} // q{}) . $signed . q{</samlp:Response>};
   return encode_base64($xml, q{});
}

my $t = Test::Mojo->new;

# post $response as the answer to a fresh request, return the error log
sub refused ($response) {
   $t->get_ok('/saml2')->status_is(302);    # a valid saml-id cookie
   @log = ();
   $t->post_ok('/sso', form => { SAMLResponse => $response })
     ->header_like(Location => qr{/public\z}, 'refused');
   return grep { m{authentication error \(SAML2\)} } @log;
}

my $forged = '[2026-01-01 00:00:00] [info] login successful (credentials): admin';

{
   my @lines = refused(response(in_response_to => 'r0', status => "x&#10;$forged"));
   is scalar(@lines), 1, 'forged Status: refusal logged';
   is_deeply [ grep { m{[\x00-\x1f\x7f]} } @lines ], [],
      'forged Status: no control characters in the log';
}

{
   my $padding = '<samlp:Extensions>' . ('A' x 1_000_000) . '</samlp:Extensions>';
   my $response = response(status => 'x', padding => $padding);  # no InResponseTo
   # Net::SAML2 builds its type error from the missing InResponseTo, with
   # a warning (Types.pm, "uninitialized value $_"): expected, keep it quiet
   my @lines = do {
      local $SIG{__WARN__} = sub ($w) {
         warn $w unless $w =~ m{uninitialized value .*/Net/SAML2/Types[.]pm}ms;
      };
      refused($response);
   };
   is scalar(@lines), 1, 'padded response: refusal logged';
   is_deeply [ grep { m{[\x00-\x1f\x7f]} } @lines ], [],
      'padded response: no control characters in the log';
   my $size = length(join q{}, @lines);
   cmp_ok $size, '<', 2_000, 'padded response: the log line stays short'
      or diag sprintf '%d bytes logged for a %d bytes response', $size, length($response);
}

done_testing();
