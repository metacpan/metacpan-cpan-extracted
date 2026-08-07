#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use MIME::Base64 ();

# The `api` mount's security-as-guards compiler (xs/oamount.xs): every
# securityScheme shape the spec can name, the OR of alternatives and the AND
# of schemes within one, what reaches the checker, and the 401 when none pass.
#
# t/10-under-openapi.t covers one apiKey header end to end; this covers the
# matrix, which is the part with the most ways to be subtly wrong.


my $spec = {
  openapi => '3.1.0', info => { title => 's', version => '1' },
  components => { securitySchemes => {
      hdrKey  => { type => 'apiKey', in => 'header', name => 'X-Key' },
      qryKey  => { type => 'apiKey', in => 'query',  name => 'k' },
      ckKey   => { type => 'apiKey', in => 'cookie', name => 'sid' },
      basic   => { type => 'http', scheme => 'basic' },
      bearer  => { type => 'http', scheme => 'bearer' },
  } },
  paths => {
    '/hdr'   => { get => { operationId=>'opHdr',   security=>[{hdrKey=>[]}],  responses=>{200=>{description=>'k'}} } },
    '/qry'   => { get => { operationId=>'opQry',   security=>[{qryKey=>[]}],  responses=>{200=>{description=>'k'}} } },
    '/ck'    => { get => { operationId=>'opCk',    security=>[{ckKey=>[]}],   responses=>{200=>{description=>'k'}} } },
    '/basic' => { get => { operationId=>'opBasic', security=>[{basic=>[]}],   responses=>{200=>{description=>'k'}} } },
    '/or'    => { get => { operationId=>'opOr',    security=>[{hdrKey=>[]},{bearer=>[]}], responses=>{200=>{description=>'k'}} } },
    '/and'   => { get => { operationId=>'opAnd',   security=>[{hdrKey=>[],bearer=>['s1']}], responses=>{200=>{description=>'k'}} } },
    '/open'  => { get => { operationId=>'opOpen',  security=>[], responses=>{200=>{description=>'k'}} } },
  },
};

my @seen;
my %checkers = map { my $n = $_; $n => sub {
    my ($cred, $c, $id, $scopes) = @_;
    push @seen, [ $n, $cred, $id, $scopes ];
    return $cred eq "good-$n" ? { who => $n } : undef;
} } qw(hdrKey qryKey ckKey basic bearer);

package M; use Punk;
under('/api')->api($spec, {
    security => \%checkers,
    handlers => { map { my $o = $_; $o => sub {
        my ($c) = @_; return { op => $o, auth => $c->stash->{auth} };
    } } qw(opHdr opQry opCk opBasic opOr opAnd opOpen) },
});
package main;
my $app = M->to_app;

sub call {
    my ($path, %env) = @_;
    my $r = $app->({ REQUEST_METHOD=>'GET', PATH_INFO=>"/api$path",
        QUERY_STRING=>'', 'psgi.url_scheme'=>'http', SERVER_NAME=>'l',
        SERVER_PORT=>80, HTTP_HOST=>'l', %env });
    return ($r->[0], join '', @{$r->[2]});
}

my ($s,$b);
($s,$b) = call('/hdr', HTTP_X_KEY=>'good-hdrKey'); is($s,200,'apiKey header ok'); like($b,qr/"who":"hdrKey"/,'  auth stashed');
($s,$b) = call('/hdr', HTTP_X_KEY=>'bad');         is($s,401,'apiKey header wrong -> 401');
($s,$b) = call('/hdr');                            is($s,401,'apiKey header missing -> 401');
is($b, '{"errors":[{"message":"unauthorized"}]}', '  401 body intact');

($s,$b) = call('/qry', QUERY_STRING=>'k=good-qryKey'); is($s,200,'apiKey query ok');
($s,$b) = call('/qry', QUERY_STRING=>'k=nope');        is($s,401,'apiKey query wrong');

($s,$b) = call('/ck', HTTP_COOKIE=>'sid=good-ckKey; other=x'); is($s,200,'apiKey cookie ok');
($s,$b) = call('/ck', HTTP_COOKIE=>'sid=bad');                 is($s,401,'apiKey cookie wrong');

my $ok64 = MIME::Base64::encode_base64('good-basic', '');
($s,$b) = call('/basic', HTTP_AUTHORIZATION=>"Basic $ok64"); is($s,200,'http basic ok');
($s,$b) = call('/basic', HTTP_AUTHORIZATION=>"basic $ok64"); is($s,200,'  scheme is case-insensitive');
($s,$b) = call('/basic', HTTP_AUTHORIZATION=>"Bearer $ok64"); is($s,401,'  wrong scheme -> 401');
($s,$b) = call('/basic', HTTP_AUTHORIZATION=>"Basic !!!!");   is($s,401,'  non-base64 -> 401');

# OR: either alternative authorizes
($s,$b) = call('/or', HTTP_X_KEY=>'good-hdrKey');            is($s,200,'OR: first alternative');
($s,$b) = call('/or', HTTP_AUTHORIZATION=>'Bearer good-bearer'); is($s,200,'OR: second alternative');
like($b, qr/"who":"bearer"/, '  and the passing one is stashed');
($s,$b) = call('/or', HTTP_X_KEY=>'bad');                    is($s,401,'OR: neither');

# AND: both schemes in one alternative must pass
($s,$b) = call('/and', HTTP_X_KEY=>'good-hdrKey', HTTP_AUTHORIZATION=>'Bearer good-bearer');
is($s,200,'AND: both pass'); like($b, qr/hdrKey/, '  both stashed'); like($b, qr/bearer/, '  both stashed');
($s,$b) = call('/and', HTTP_X_KEY=>'good-hdrKey'); is($s,401,'AND: one missing -> 401');
($s,$b) = call('/and', HTTP_X_KEY=>'bad', HTTP_AUTHORIZATION=>'Bearer good-bearer'); is($s,401,'AND: one wrong -> 401');

# scopes reach the checker
@seen = ();
call('/and', HTTP_X_KEY=>'good-hdrKey', HTTP_AUTHORIZATION=>'Bearer good-bearer');
my ($bear) = grep { $_->[0] eq 'bearer' } @seen;
is_deeply($bear->[3], ['s1'], 'scopes reach the checker');
is($bear->[2], 'opAnd', 'operationId reaches the checker');

# an empty security list means no guard
($s,$b) = call('/open'); is($s,200,'empty security => no guard');

done_testing();
