use strict;

use Test::More;
use Test::Exception;
use Data::Dumper;

use constant TMPFILE => "./blib/amazon.credentials";

my $auth;
my $results;
my %conf;

if (open AUTH , "<".TMPFILE) {
  $auth = <AUTH>;
  chomp $auth;
  close AUTH;
  my $args = 0;
  ($conf{key_id}, $conf{access_key}) = split(quotemeta('|+++|'), $auth);
  unless($conf{key_id} || $conf{access_key}) {
	  $conf{debug} = *DATA;
	  $args++;
  }
  &run_test($args);
}
else {
  BAIL_OUT("Cannot open tempfile to read required credentials, clean up and run test over");
}

sub run_test {
  my ($args) = @_;
  my $results;
  my $testnum = ($args == 0) ? 26 : 10;
  plan tests => $testnum;

  unless($args) {
    ok($conf{key_id}, "Read Amazon key id");
    ok($conf{access_key}, "Read Amazon access key");
  }

  use_ok("Net::Amazon::Thumbnail");
  my %badconf = (size => 'small', key_id => 'badID', access_key => 'badKey');
  my $badthumb = Net::Amazon::Thumbnail->new(\%badconf);
  dies_ok { $results = $badthumb->post_thumbnail('http://digg.com')} 'Bad Connection';

  my $thumb = Net::Amazon::Thumbnail->new(\%conf);
  isa_ok($thumb,"Net::Amazon::Thumbnail");

  is($thumb->thumb_size(), 'Large', 'Default thumb size');
  is($thumb->empty_image(), 0, 'Default empty image');
  dies_ok { $results = $thumb->post_thumbnail()} 'No Url';

  my @domains = ('perl.com', 'http://perlmonks.org');
  lives_ok { $results = $thumb->post_thumbnail(\@domains)} 'Amazon connection';
  is(scalar @{ $results }, 2);
  like  (${ $results }[0], qr/http/);
  like  (${ $results }[1], qr/http/);
  return if($args);

  lives_ok { $results = $thumb->post_thumbnail('yahoo.com')} 'Amazon connection 2';
  is(scalar @{ $results }, 1);
  like  (${ $results }[0], qr/http/);

  lives_ok { $results = $thumb->post_thumbnail('http://stonehenge.com')} 'Amazon connnection 3';
  is(scalar @{ $results }, 1);
  like  (${ $results }[0], qr/http/);

  $conf{path} = "./blib";
  $conf{size} = "small";

  $thumb = Net::Amazon::Thumbnail->new(\%conf);

  lives_ok { $results = $thumb->post_thumbnail('http://perlmonks.org')} 'Amazon connection 4';
  my $exists = -e "./blib/perlmonks.org.jpg";
  is($exists, 1);
  is(scalar @{ $results }, 1);
  unlike(${ $results }[0], qr/http/);

  my %domains = ( 'http://perl.org' => 'thenameiwanted' );
  lives_ok { $results = $thumb->post_thumbnail(\%domains)} 'Amazon connection 5';
  $exists = -e "./blib/thenameiwanted.jpg";
  is($exists, 1);
  is(scalar @{ $results }, 1);
  unlike(${ $results }[0], qr/http/);

}

__DATA__
<?xml version="1.0"?>
<aws:ThumbnailResponse xmlns:aws="http://ast.amazonaws.com/doc/2005-10-05/">
    <aws:Response>
        <aws:OperationRequest>
            <aws:RequestId>0379177f-7a21-436a-ac81-39089f702824</aws:RequestId>
        </aws:OperationRequest>
        <aws:ThumbnailResult>
            <aws:Thumbnail Exists="true">http://s3-external-1.amazonaws.com/alexa-thumbnails/8B73F06519330A18C025A0482654A8C8FAC5CC8Cl?Signature=HZZMAUN5h558Y74xKD4GsRvldbY%3D&amp;Expires=1181247230&amp;AWSAccessKeyId=1FVZ0JNEJDA5TK457CR2</aws:Thumbnail>
            <aws:RequestUrl>http://perl.com</aws:RequestUrl>
        </aws:ThumbnailResult>
        <aws:ResponseStatus>
            <aws:StatusCode>Success</aws:StatusCode>
        </aws:ResponseStatus>
     </aws:Response>
     <aws:Response>
        <aws:OperationRequest>
            <aws:RequestId>0379177f-7a21-436a-ac81-39089f702824</aws:RequestId>
        </aws:OperationRequest>
        <aws:ThumbnailResult>
            <aws:Thumbnail Exists="true">http://s3-external-1.amazonaws.com/alexa-thumbnails/23575D9D14CEFE86CA788601744F3B0364D925FDl?Signature=vF1Ms2tOUBQ0moM1ZSQ%2BE67kQr0%3D&amp;Expires=1181247230&amp;AWSAccessKeyId=1FVZ0JNEJDA5TK457CR2</aws:Thumbnail>
            <aws:RequestUrl>http://perlmonks.org</aws:RequestUrl>
        </aws:ThumbnailResult>
        <aws:ResponseStatus>
            <aws:StatusCode>Success</aws:StatusCode>
        </aws:ResponseStatus>
    </aws:Response>
</aws:ThumbnailResponse>
