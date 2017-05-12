# -*- perl -*-

use strict;
use warnings;

use Test::More;
use Path::Class qw(file dir);

BEGIN {
  use FindBin '$Bin';
  $ENV{RAPIFS_SHARE_DIR} = "$Bin/../share";
  
  use Rapi::Fs;
  
  Rapi::Fs->new({
    appname => 'TestRA::RapiFs',
    mounts  => [{ 
      name => 'Rapi-Fs-Dist',
      args => "$Bin/../" 
    }]
  })->ensure_bootstrapped 
}

use RapidApp::Test 'TestRA::RapiFs';

run_common_tests();




# Node fetch:
{ 
  my $dir = 'lib/Rapi/Fs';
  my @real = map {
    (reverse split(/\//,$_))[0]
  } glob("$Bin/../$dir/*");

  my $decoded = (client->ajax_post_decode(
    '/files/nodes',
    [ node => "root/Rapi-Fs-Dist/$dir", root_node => 1 ]
  )) || [];

  my @names = map { $_->{name} } @$decoded;
  shift @names; #<-- the up/link node

  is_deeply(
    [sort @names],
    [sort @real],
    "Node fetch matches real files on disk"
  );
}

# File content fetch
{

  my $fn = 'LICENSE';

  my $content = client->browser_get_raw(
    join('','/files/Rapi-Fs-Dist/',$fn,'?method=open')
  );
  
  is(
    $content,
    file("$Bin/../",$fn)->slurp,
    "File open fetch matches content on disk"
  );

}

done_testing;

