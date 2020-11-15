#!/usr/bin/perl
use strict;
use warnings;
use Net::Camera::Sercomm::ICamera2;

my $syntax   = "$0 [hostname]\n";
my $hostname = shift or die($syntax);
my $cam      = Net::Camera::Sercomm::ICamera2->new(hostname => $hostname);
my $jpeg     = $cam->getSnapshot;

print $jpeg;

__END__

=head1 NAME

perl-Net-Camera-Sercomm-ICamera2-getSnapshot.pl - Script to get JPEG snapshot from Sercomm ICamera2 network camera

=head1 SYNOPSIS

  perl-Net-Camera-Sercomm-ICamera2-getSnapshot.pl hostname > my.jpeg

=head1 DESCRIPTION

perl-Net-Camera-Sercomm-ICamera2-getSnapshot.pl is a script to get JPEG snapshot from Sercomm ICamera2 network camera

=cut
