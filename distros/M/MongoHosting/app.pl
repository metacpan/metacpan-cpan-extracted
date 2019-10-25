#!/usr/bin/env perl
use strict;
use warnings;
use v5.24;
use UI::Dialog::Backend::CDialog;
use DigitalOcean;
use DDP;
use Number::Format qw(format_bytes format_price);

my $key = '';

my $do = DigitalOcean->new(oauth_token => $key);
my $d = UI::Dialog::Backend::CDialog->new(
  backtitle  => 'MongoDB Cluster Management',
  title      => 'MongoDB',
  height     => 20,
  width      => 65,
  listheight => 10,
  order      => ['zenity', 'xdialog']
) or die $@;

sub zones {
  my %zones              = ();
  my $regions_collection = $do->regions(20);
  my $r;
  $zones{$r->slug} = $r while $r = $regions_collection->next;
  return %zones;
}

sub sizes {
  my $zone             = shift;
  my $sizes_collection = $do->sizes;
  my @sizes;
  my $size;

  $zone ~~ $size->regions && push @sizes, $size
    while $size = $sizes_collection->next;

  return sort { $a->price_hourly <=> $b->price_hourly } @sizes;
}

sub mongo_image {
  my $images_collection = $do->application_images;
  while (my $obj = $images_collection->next) {
    return $obj if $obj->name =~ /mongodb/i;
  }
}

sub create_box {
  my $image = 1;
}

sub pick_zone {
  my %zones       = zones();
  my $mongo_image = mongo_image();
  my $zone        = $d->menu(
    text => 'What region you want to install the cluster:',
    list => [
      map { $_->slug, $_->name }
      sort { $a->slug cmp $b->slug }
      grep {defined} @zones{$mongo_image->regions->@*}
    ]
  );
}

sub droplets {
  my $droplets_collection = $do->droplets;
  my $obj;

  while ($obj = $droplets_collection->next) {
    p($obj);
  }
}
# say sprintf(
#   '%s [CPUs: %s; MEM: %s; DISK: %s; PRICE(monthly): %s]',
#   $_->slug,
#   $_->vcpus,
#   format_bytes($_->memory * (1024**2), precision => 0, unit => 'G',),
#   format_bytes($_->disk *   (1024**3), precision => 0, unit => 'G',),
#   format_price($_->price_monthly)
# ) for sizes('nyc3');
droplets;

#pick_zone;

exit;

__DATA__

@@ mongos.service

[Unit]
Description=Mongo Cluster Router
After=network.target

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongos --config /etc/mongos.conf
# file size
LimitFSIZE=infinity
# cpu time
LimitCPU=infinity
# virtual memory size
LimitAS=infinity
# open files
LimitNOFILE=64000
# processes/threads
LimitNPROC=64000
# total threads (user+kernel)
TasksMax=infinity
TasksAccounting=false

[Install]
WantedBy=multi-user.target  
