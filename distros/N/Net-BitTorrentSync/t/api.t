#!/usr/bin/perl

use strict;
use warnings;
use Cwd 'abs_path';
use Test::More;

use_ok( 'Net::BitTorrentSync');

# start_btsync

my $btsync = start_btsync();

# set_config
my $config = set_config();

ok (ref $config->{'webui'} eq 'HASH', 'correct structure returned');

like (
    $config->{'webui'}->{'listen'},
    qr/^[0-9]{1,3}(?:\.[0-9]{1,3}){3}:[0-9]+$/,
    'listened address is [ip:port]'
);

# set_listened_address

set_listened_address($config->{'webui'}->{'listen'});

# add_folder
my $response = add_folder(abs_path './t/data/sync_test');

is_deeply($response, { result => 0 }, 'folder added ok');

# get_folders
$response = get_folders();

ok (ref $response eq 'ARRAY', 'get_folders returns an ArrayRef');

ok (ref $response->[0] eq 'HASH', 'Each element is a HashRef');

is_deeply (
    [sort keys %{$response->[0]}],
    [(qw/dir error files indexing secret size type/)],
    'correct items'
);

my $secret = $response->[0]->{secret};

# get_secrets
$response = get_secrets($secret);

ok (ref $response eq 'HASH', 'get_secrets returns a hashref');
ok ($response->{read_write} eq $secret,
    'the read_write secret is folder secret');
ok ($response->{read_only} ne $secret,
    'and the read_only secret is different');

# get_files

$response = get_files($secret);

my $compare = [
  {
    have_pieces => 1,
    name => "New Text Document.txt",
    size => 3359,
    state => "created",
    total_pieces => 1,
    type => "file",
  },
  { name => "sub", state => "created", type => "folder" },
];

is_deeply ($response, $compare, 'matching file structures');

$response = get_files($secret, 'sub');

$compare = [
  {
    have_pieces => 1,
    name => "index.html",
    size => 290,
    state => "created",
    total_pieces => 1,
    type => "file",
  },
];

is_deeply ($response, $compare, 'matching file structures');

# get_folder_peers

$response = get_folder_peers($secret);

is_deeply ($response , [], 'Should get an empty arrayref');

# get_folder_prefs

$response = get_folder_prefs($secret);

$compare = {
  search_lan       => 1,
  selective_sync   => 0,
  use_dht          => 0,
  use_hosts        => 0,
  use_relay_server => 1,
  use_sync_trash   => 1,
  use_tracker      => 1,
};

is_deeply ($response, $compare, 'Correct folder preferences');

# set_folder_prefs

$response = set_folder_prefs($secret, {
  selective_sync => 1,
  use_hosts      => 1,
  use_sync_trash => 0,
});

$compare = {
  search_lan       => 1,
  selective_sync   => 1,
  use_dht          => 0,
  use_hosts        => 1,
  use_relay_server => 1,
  use_sync_trash   => 0,
  use_tracker      => 1,
};

is_deeply ($response, $compare, 'Correct new folder preferences');

# get_folder_hosts

$response = get_folder_hosts($secret);

is_deeply($response, { hosts => [] }, 'empty arrayref for now');

# get_prefs

$response = get_prefs();

my @keys = qw/
              device_name disk_low_priority download_limit
              folder_rescan_interval lan_encrypt_data lan_use_tcp
              lang listening_port max_file_size_diff_for_patching
              max_file_size_for_versioning rate_limit_local_peers
              recv_buf_size send_buf_size sync_max_time_diff sync_trash_ttl
              upload_limit use_upnp
             /;

is_deeply([sort keys %{$response}], [@keys], 'same keys');

# TODO: set_file_prefs
# TODO: set_folder_hosts
# TODO: set_prefs

# remove_folder
is_deeply(
  remove_folder($secret),
  {error => 0},
  'folder removed ok'
);

$response = get_folders();

is_deeply ($response, [], 'should now be empty ArrayRef');

# General information methods

# get_speed

$response = get_speed();
is_deeply ($response, { download => 0, upload => 0 }, 'no speed');

# get_version
$response = get_version();

my $version = (split " ", (split "\n",  `$btsync --help`)[0])[2];

ok ($response->{version} eq $version, 'same version reported');

# get_os
$response = get_os();

if ($^O eq 'MSWin32') {
        is_deeply ($response, { os => "win32" }, 'OS identified as MSWin32');
} elsif ($^O eq 'linux') {
        is_deeply ($response, { os => "linux" }, 'OS identified as linux');
}

shutdown_btsync();

done_testing;
