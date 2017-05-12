#!/usr/bin/perl -wT

# $Id: 81-RealFile.t,v 1.2 2003/05/28 14:32:24 unimlo Exp $

use strict;

my $file = '/prod/routerconf/arkiv/name/val_dix1_core/rd2003-05-01';
unless (-e $file)
 {
  eval "use Test::More skip_all => 'Release test only runs on my machine! ;-)'; ";
 }
else
 { 
  eval "use Test::More tests => 22; ";
 };

# Use
use_ok('Cisco::Reconfig');
use_ok('Net::ACL::File');
use_ok('Net::ACL::File::IPAccess');
use_ok('Net::ACL::File::IPAccessExt');
use_ok('Net::ACL::File::Community');
use_ok('Net::ACL::File::ASPath');
use_ok('Net::ACL::File::Prefix');
use_ok('Net::ACL::File::RouteMap');
use_ok('Data::Dumper');

# Load it!
open(FILE,$file); my $strconf = join('',<FILE>); close(FILE);
my $conf = Cisco::Reconfig::stringconfig($strconf);
ok(ref $conf eq 'Cisco::Reconfig','Config loaded');
my $lists = load Net::ACL::File($conf);

# Remember lines
my %l;
foreach my $line (split(/\n/,$strconf))
 {
  next if $line =~ /^\!/;
  $line =~ s/  +/ /g;
  $l{$line} ||= 0;
  $l{$line} += 1;
 }

# Verify result
foreach my $type (sort keys %{$lists})
 {
  my $ok = 1;
  my $missing = '';
  my $count = 0;
  foreach my $name (sort keys %{$lists->{$type}})
   {
    my $l = $lists->{$type}->{$name};
    $ok &&= $l->isa('Net::ACL::File');
    $count += 1;
    my $tconf = $l->asconfig;
    foreach my $line (split(/\n/,$tconf))
     {
      next if $line =~ /^!/;
      unless (defined $l{$line})
       {
        #warn "--BEGIN--\n>$line<\n" . $tconf . "--END--\n";
        $missing = $line;
        next;
       };
      $l{$line} -= 1;
      delete $l{$line} unless $l{$line};
     };
   };
  ok($ok,"Loaded $count $type");
  ok($missing eq '',"All output found in source '$missing'");
 };

__END__
