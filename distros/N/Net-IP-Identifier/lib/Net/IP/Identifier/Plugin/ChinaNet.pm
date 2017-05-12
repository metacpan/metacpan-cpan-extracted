#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::ChinaNet
#     ABSTRACT:  identify ChinaNet (often 163data.com) IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Wed May 20 12:46:07 PDT 2015
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::ChinaNet;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known ChinaNet IP blocks as of May 2015
    $self->ips(
        # 266 Network Blocks
        '1.0.8.0/21',
        '1.0.32.0/19',
        '1.1.8.0/21',
        '1.1.32.0/19',
        '1.2.0.0/23',
        # extending 1.2.9.0/24 to include 1.2.10.0/23
        # extending 1.2.9.0-1.2.11.255 to include 1.2.12.0/22
        # extending 1.2.9.0-1.2.15.255 to include 1.2.16.0/20
        # extending 1.2.9.0-1.2.31.255 to include 1.2.32.0/19
        '1.2.9.0-1.2.63.255',
        '1.3.0.0/16',
        '1.4.2.0/23',
        '1.4.64.0/18',
        '1.10.8.0/23',
        '1.10.64.0/18',
        # extending 1.48.0.0/15 to include 1.50.0.0/16
        '1.48.0.0-1.50.255.255',
        '1.68.0.0/14',
        '1.80.0.0/13',
        '1.180.0.0/14',
        '1.192.0.0/13',
        # extending 1.202.0.0/15 to include 1.204.0.0/14
        '1.202.0.0-1.207.255.255',
        '14.0.0.0/21',
        '14.16.0.0/12',
        # extending 14.104.0.0/13 to include 14.112.0.0/12
        '14.104.0.0-14.127.255.255',
        '14.134.0.0/15',
        '14.144.0.0/12',
        '14.208.0.0/12',
        '27.16.0.0/12',
        '27.34.232.0/21',
        '27.54.72.0/21',
        '27.128.0.0/15',
        # extending 27.148.0.0/14 to include 27.152.0.0/13
        '27.148.0.0-27.159.255.255',
        '27.184.0.0/13',
        '27.224.0.0/14',
        '36.0.0.0/22',
        # extending 36.0.16.0/20 to include 36.0.32.0/19
        '36.0.16.0-36.0.63.255',
        '36.4.0.0/14',
        '36.16.0.0/12',
        '36.37.0.0/19',
        '36.37.40.0/21',
        # extending 36.40.0.0/13 to include 36.48.0.0/15
        '36.40.0.0-36.49.255.255',
        '36.56.0.0/13',
        '36.96.0.0/11',
        '39.0.0.0/24',
        '39.0.8.0/21',
        # extending 39.0.32.0/19 to include 39.0.64.0/18
        '39.0.32.0-39.0.127.255',
        '42.0.8.0/21',
        '42.62.128.0/19',
        '42.80.0.0/15',
        '42.88.0.0/13',
        '42.97.0.0/16',
        '42.99.0.0/18',
        '42.100.0.0/14',
        '42.122.0.0/16',
        '42.156.64.0/18',
        '42.184.0.0/15',
        '42.187.120.0/22',
        '42.194.8.0/22',
        '42.202.0.0/15',
        '42.242.0.0/15',
        '42.248.0.0/13',
        '49.64.0.0/11',
        '49.112.0.0/13',
        '49.128.2.0/23',
        # extending 58.32.0.0/13 to include 58.40.0.0/15
        # extending 58.32.0.0-58.41.255.255 to include 58.42.0.0/16
        # extending 58.32.0.0-58.42.255.255 to include 58.43.0.0/16
        # extending 58.32.0.0-58.43.255.255 to include 58.44.0.0/14
        # extending 58.32.0.0/12 to include 58.48.0.0/13
        # extending 58.32.0.0-58.55.255.255 to include 58.56.0.0/15
        # extending 58.32.0.0-58.57.255.255 to include 58.58.0.0/16
        # extending 58.32.0.0-58.58.255.255 to include 58.59.0.0/17
        # extending 58.32.0.0-58.59.127.255 to include 58.59.128.0/17
        # extending 58.32.0.0-58.59.255.255 to include 58.60.0.0/14
        '58.32.0.0/11',
        '58.208.0.0/12',
        # extending 59.32.0.0/13 to include 59.40.0.0/15
        # extending 59.32.0.0-59.41.255.255 to include 59.42.0.0/16
        '59.32.0.0-59.42.255.255',
        # extending 59.44.0.0/14 to include 59.48.0.0/16
        # extending 59.44.0.0-59.48.255.255 to include 59.49.0.0/17
        # extending 59.44.0.0-59.49.127.255 to include 59.49.128.0/17
        # extending 59.44.0.0-59.49.255.255 to include 59.50.0.0/16
        # extending 59.44.0.0-59.50.255.255 to include 59.51.0.0/17
        # extending 59.44.0.0-59.51.127.255 to include 59.51.128.0/17
        # extending 59.44.0.0-59.51.255.255 to include 59.52.0.0/14
        # extending 59.44.0.0-59.55.255.255 to include 59.56.0.0/14
        # extending 59.44.0.0-59.59.255.255 to include 59.60.0.0/15
        # extending 59.44.0.0-59.61.255.255 to include 59.62.0.0/15
        '59.44.0.0-59.63.255.255',
        # extending 59.172.0.0/15 to include 59.174.0.0/15
        '59.172.0.0/14',
        # extending 60.160.0.0/15 to include 60.162.0.0/15
        # extending 60.160.0.0/14 to include 60.164.0.0/15
        # extending 60.160.0.0-60.165.255.255 to include 60.166.0.0/15
        # extending 60.160.0.0/13 to include 60.168.0.0/13
        # extending 60.160.0.0/12 to include 60.176.0.0/12
        '60.160.0.0/11',
        '60.235.0.0/16',
        '61.4.88.0/21',
        '61.128.128.0/17',
        # extending 61.130.0.0/16 to include 61.131.0.0/17
        # extending 61.130.0.0-61.131.127.255 to include 61.131.128.0/17
        # extending 61.130.0.0/15 to include 61.132.0.0/17
        # extending 61.130.0.0-61.132.127.255 to include 61.132.128.0/17
        '61.130.0.0-61.132.255.255',
        # extending 61.133.128.0/18 to include 61.133.192.0/19
        # extending 61.133.128.0-61.133.223.255 to include 61.133.224.0/19
        # extending 61.133.128.0/17 to include 61.134.0.0/18
        # extending 61.133.128.0-61.134.63.255 to include 61.134.64.0/19
        '61.133.128.0-61.134.95.255',
        # extending 61.136.128.0/17 to include 61.137.0.0/17
        '61.136.128.0-61.137.127.255',
        # extending 61.138.192.0/19 to include 61.138.224.0/19
        # extending 61.138.192.0/18 to include 61.139.0.0/17
        '61.138.192.0-61.139.127.255',
        # extending 61.139.192.0/18 to include 61.140.0.0/14
        # extending 61.139.192.0-61.143.255.255 to include 61.144.0.0/15
        # extending 61.139.192.0-61.145.255.255 to include 61.146.0.0/16
        # extending 61.139.192.0-61.146.255.255 to include 61.147.0.0/16
        '61.139.192.0-61.147.255.255',
        # extending 61.150.0.0/17 to include 61.150.128.0/17
        # extending 61.150.0.0/16 to include 61.151.0.0/16
        # extending 61.150.0.0/15 to include 61.152.0.0/16
        # extending 61.150.0.0-61.152.255.255 to include 61.153.0.0/16
        # extending 61.150.0.0-61.153.255.255 to include 61.154.0.0/16
        # extending 61.150.0.0-61.154.255.255 to include 61.155.0.0/16
        '61.150.0.0-61.155.255.255',
        '61.157.0.0/16',
        # extending 61.159.64.0/18 to include 61.159.128.0/18
        # extending 61.159.64.0-61.159.191.255 to include 61.159.192.0/18
        # extending 61.159.64.0-61.159.255.255 to include 61.160.0.0/16
        '61.159.64.0-61.160.255.255',
        '61.161.64.0/18',
        # extending 61.164.0.0/16 to include 61.165.0.0/16
        # extending 61.164.0.0/15 to include 61.166.0.0/16
        '61.164.0.0-61.166.255.255',
        # extending 61.169.0.0/16 to include 61.170.0.0/15
        # extending 61.169.0.0-61.171.255.255 to include 61.172.0.0/15
        # extending 61.169.0.0-61.173.255.255 to include 61.174.0.0/15
        '61.169.0.0-61.175.255.255',
        # extending 61.177.0.0/16 to include 61.178.0.0/16
        '61.177.0.0-61.178.255.255',
        '61.180.0.0/17',
        # extending 61.183.0.0/16 to include 61.184.0.0/16
        # extending 61.183.0.0-61.184.255.255 to include 61.185.0.0/16
        # extending 61.183.0.0-61.185.255.255 to include 61.186.0.0/18
        # extending 61.183.0.0-61.186.63.255 to include 61.186.64.0/18
        # extending 61.183.0.0-61.186.127.255 to include 61.186.128.0/17
        # extending 61.183.0.0-61.186.255.255 to include 61.187.0.0/16
        # extending 61.183.0.0-61.187.255.255 to include 61.188.0.0/16
        '61.183.0.0-61.188.255.255',
        # extending 61.189.128.0/17 to include 61.190.0.0/16
        # extending 61.189.128.0-61.190.255.255 to include 61.191.0.0/16
        '61.189.128.0-61.191.255.255',
        '101.0.0.0/22',
        '101.1.0.0/22',
        '101.2.172.0/22',
        '101.50.56.0/22',
        '101.53.100.0/22',
        '101.78.0.0/22',
        '101.80.0.0/12',
        '101.96.8.0/22',
        '101.102.104.0/21',
        '101.110.116.0/22',
        '101.128.0.0/22',
        '101.128.16.0/20',
        '101.203.172.0/22',
        '101.224.0.0/13',
        '101.234.76.0/22',
        '101.248.0.0/15',
        '101.251.0.0/22',
        '106.0.4.0/22',
        # extending 106.4.0.0/14 to include 106.8.0.0/15
        '106.4.0.0-106.9.255.255',
        # extending 106.16.0.0/12 to include 106.32.0.0/12
        '106.16.0.0-106.47.255.255',
        # absorbs:
        #    106.33.0.0 - 106.33.255.255
        #    106.34.0.0 - 106.34.255.255 (from 106.33.0.0/16)
        '106.56.0.0/13',
        '106.80.0.0/12',
        # extending 106.108.0.0/14 to include 106.112.0.0/13
        # extending 106.108.0.0-106.119.255.255 to include 106.120.0.0/13
        '106.108.0.0-106.127.255.255',
        # absorbs:
        #    106.120.0.0/15 (from 106.120.0.0/19)
        '106.224.0.0/12',
        '110.76.156.0/22',
        '110.76.184.0/22',
        # extending 110.80.0.0/13 to include 110.88.0.0/14
        '110.80.0.0-110.91.255.255',
        # extending 110.152.0.0/14 to include 110.156.0.0/15
        '110.152.0.0-110.157.255.255',
        '110.166.0.0/15',
        # extending 110.176.0.0/13 to include 110.184.0.0/13
        '110.176.0.0/12',
        '111.72.0.0/13',
        '111.112.0.0/15',
        # extending 111.120.0.0/14 to include 111.124.0.0/16
        '111.120.0.0-111.124.255.255',
        '111.126.0.0/15',
        '111.170.0.0/16',
        # extending 111.172.0.0/14 to include 111.176.0.0/13
        '111.172.0.0-111.183.255.255',
        '111.224.0.0/14',
        '111.235.156.0/22',
        '112.66.0.0/15',
        # extending 112.98.0.0/15 to include 112.100.0.0/14
        '112.98.0.0-112.103.255.255',
        # extending 112.112.0.0/14 to include 112.116.0.0/15
        '112.112.0.0-112.117.255.255',
        # extending 113.12.0.0/14 to include 113.16.0.0/15
        '113.12.0.0-113.17.255.255',
        '113.24.0.0/14',
        # extending 113.62.0.0/15 to include 113.64.0.0/11
        # extending 113.62.0.0-113.95.255.255 to include 113.96.0.0/12
        # extending 113.62.0.0-113.111.255.255 to include 113.112.0.0/13
        # extending 113.62.0.0-113.119.255.255 to include 113.120.0.0/13
        # extending 113.62.0.0-113.127.255.255 to include 113.128.0.0/15
        '113.62.0.0-113.129.255.255',
        # extending 113.132.0.0/14 to include 113.136.0.0/13
        '113.132.0.0-113.143.255.255',
        # extending 113.218.0.0/15 to include 113.220.0.0/14
        '113.218.0.0-113.223.255.255',
        # extending 113.240.0.0/13 to include 113.248.0.0/14
        '113.240.0.0-113.251.255.255',
        # extending 114.80.0.0/12 to include 114.96.0.0/13
        # extending 114.80.0.0-114.103.255.255 to include 114.104.0.0/14
        '114.80.0.0-114.107.255.255',
        '114.135.0.0/16',
        '114.138.0.0/15',
        # extending 114.216.0.0/13 to include 114.224.0.0/12
        '114.216.0.0-114.239.255.255',
        # extending 115.148.0.0/14 to include 115.152.0.0/15
        '115.148.0.0-115.153.255.255',
        '115.168.0.0/14',
        # extending 115.192.0.0/11 to include 115.224.0.0/12
        '115.192.0.0-115.239.255.255',
        '116.0.8.0/21',
        '116.1.0.0/16',
        # extending 116.4.0.0/14 to include 116.8.0.0/14
        '116.4.0.0-116.11.255.255',
        '116.16.0.0/12',
        '116.52.0.0/14',
        '116.192.0.0/16',
        # extending 116.207.0.0/16 to include 116.208.0.0/14
        '116.207.0.0-116.211.255.255',
        '116.224.0.0/12',
        # extending 116.246.0.0/15 to include 116.248.0.0/15
        '116.246.0.0-116.249.255.255',
        '116.252.0.0/15',
        # extending 117.21.0.0/16 to include 117.22.0.0/15
        # extending 117.21.0.0-117.23.255.255 to include 117.24.0.0/13
        # extending 117.21.0.0-117.31.255.255 to include 117.32.0.0/13
        # extending 117.21.0.0-117.39.255.255 to include 117.40.0.0/14
        # extending 117.21.0.0-117.43.255.255 to include 117.44.0.0/15
        '117.21.0.0-117.45.255.255',
        '117.57.0.0/16',
        # extending 117.60.0.0/14 to include 117.64.0.0/13
        '117.60.0.0-117.71.255.255',
        '117.80.0.0/12',
        '118.84.0.0/15',
        # extending 118.112.0.0/13 to include 118.120.0.0/14
        # extending 118.112.0.0-118.123.255.255 to include 118.124.0.0/15
        '118.112.0.0-118.125.255.255',
        '118.127.128.0/19',
        '118.180.0.0/14',
        '118.213.0.0/16',
        '118.239.0.0/16',
        # extending 118.248.0.0/13 to include 119.0.0.0/15
        '118.248.0.0-119.1.255.255',
        '119.41.0.0/16',
        '119.60.0.0/16',
        '119.84.0.0/14',
        '119.96.0.0/13',
        # extending 119.120.0.0/13 to include 119.128.0.0/12
        # extending 119.120.0.0-119.143.255.255 to include 119.144.0.0/14
        '119.120.0.0-119.147.255.255',
        '119.151.192.0/18',
        # extending 120.32.0.0/13 to include 120.40.0.0/14
        '120.32.0.0-120.43.255.255',
        '120.68.0.0/14',
        '121.8.0.0/13',
        '121.32.0.0/14',
        # extending 121.56.0.0/15 to include 121.58.0.0/17
        '121.56.0.0-121.58.127.255',
        '121.60.0.0/14',
        '121.101.0.0/18',
        '121.204.0.0/14',
        '121.224.0.0/12',
        '122.4.0.0/14',
        # extending 122.224.0.0/12 to include 122.240.0.0/13
        '122.224.0.0-122.247.255.255',
        '123.52.0.0/14',
        '123.96.0.0/15',
        '123.101.0.0/16',
        # extending 123.149.0.0/16 to include 123.150.0.0/15
        '123.149.0.0-123.151.255.255',
        # extending 123.160.0.0/14 to include 123.164.0.0/14
        # extending 123.160.0.0/13 to include 123.168.0.0/14
        # extending 123.160.0.0-123.171.255.255 to include 123.172.0.0/15
        # extending 123.160.0.0-123.173.255.255 to include 123.174.0.0/15
        '123.160.0.0/12',
        # extending 123.177.0.0/16 to include 123.178.0.0/15
        # extending 123.177.0.0-123.179.255.255 to include 123.180.0.0/14
        # extending 123.177.0.0-123.183.255.255 to include 123.184.0.0/14
        '123.177.0.0-123.187.255.255',
        '123.244.0.0/14',
        '124.31.0.0/16',
        '124.40.192.0/19',
        # extending 124.72.0.0/16 to include 124.73.0.0/16
        # extending 124.72.0.0/15 to include 124.74.0.0/15
        # extending 124.72.0.0/14 to include 124.76.0.0/14
        '124.72.0.0/13',
        # extending 124.112.0.0/15 to include 124.114.0.0/15
        # extending 124.112.0.0/14 to include 124.116.0.0/16
        # extending 124.112.0.0-124.116.255.255 to include 124.117.0.0/16
        # extending 124.112.0.0-124.117.255.255 to include 124.118.0.0/15
        '124.112.0.0/13',
        # extending 124.224.0.0/16 to include 124.225.0.0/16
        # extending 124.224.0.0/15 to include 124.226.0.0/15
        # extending 124.224.0.0/14 to include 124.228.0.0/14
        # extending 124.224.0.0/13 to include 124.232.0.0/15
        # extending 124.224.0.0-124.233.255.255 to include 124.234.0.0/15
        # extending 124.224.0.0-124.235.255.255 to include 124.236.0.0/14
        '124.224.0.0/12',
        # extending 125.64.0.0/13 to include 125.72.0.0/16
        # extending 125.64.0.0-125.72.255.255 to include 125.73.0.0/16
        # extending 125.64.0.0-125.73.255.255 to include 125.74.0.0/15
        # extending 125.64.0.0-125.75.255.255 to include 125.76.0.0/17
        # extending 125.64.0.0-125.76.127.255 to include 125.76.128.0/17
        # extending 125.64.0.0-125.76.255.255 to include 125.77.0.0/16
        # extending 125.64.0.0-125.77.255.255 to include 125.78.0.0/16
        # extending 125.64.0.0-125.78.255.255 to include 125.79.0.0/16
        # extending 125.64.0.0/12 to include 125.80.0.0/13
        # extending 125.64.0.0-125.87.255.255 to include 125.88.0.0/13
        '125.64.0.0/11',
        # extending 125.104.0.0/13 to include 125.112.0.0/12
        '125.104.0.0-125.127.255.255',
        '150.0.0.0/16',
        '150.138.0.0/15',
        '153.118.0.0/15',
        '171.8.0.0/13',
        '171.40.0.0/13',
        '171.80.0.0/14',
        '171.88.0.0/13',
        # extending 171.104.0.0/13 to include 171.112.0.0/14
        '171.104.0.0-171.115.255.255',
        '171.208.0.0/12',
        '175.0.0.0/12',
        '175.30.0.0/15',
        '180.96.0.0/11',
        '180.136.0.0/13',
        # extending 180.152.0.0/13 to include 180.160.0.0/12
        '180.152.0.0-180.175.255.255',
        '180.212.0.0/15',
        '182.32.0.0/12',
        '182.84.0.0/14',
        '182.96.0.0/12',
        # extending 182.128.0.0/12 to include 182.144.0.0/13
        '182.128.0.0-182.151.255.255',
        '182.200.0.0/13',
        '182.240.0.0/13',
        # extending 183.0.0.0/10 to include 183.64.0.0/13
        '183.0.0.0-183.71.255.255',
        # extending 183.91.32.0/21 to include 183.91.40.0/21
        '183.91.32.0/20',
        # extending 183.128.0.0/11 to include 183.160.0.0/13
        '183.128.0.0-183.167.255.255',
        '202.6.6.0/23',
        '202.12.98.0/23',
        '202.80.192.0/22',
        '202.84.8.0/21',
        '202.86.252.0/22',
        # extending 202.96.96.0/19 to include 202.96.128.0/18
        # extending 202.96.96.0-202.96.191.255 to include 202.96.192.0/18
        # extending 202.96.96.0-202.96.255.255 to include 202.97.0.0/19
        # extending 202.96.96.0-202.97.31.255 to include 202.97.32.0/19
        '202.96.96.0-202.97.63.255',
        # extending 202.97.80.0/20 to include 202.97.96.0/19
        '202.97.80.0-202.97.127.255',
        # extending 202.98.32.0/19 to include 202.98.64.0/19
        # extending 202.98.32.0-202.98.95.255 to include 202.98.96.0/19
        # extending 202.98.32.0-202.98.127.255 to include 202.98.128.0/19
        # extending 202.98.32.0-202.98.159.255 to include 202.98.160.0/19
        # extending 202.98.32.0-202.98.191.255 to include 202.98.192.0/19
        # extending 202.98.32.0-202.98.223.255 to include 202.98.224.0/19
        '202.98.32.0-202.98.255.255',
        # extending 202.100.0.0/18 to include 202.100.64.0/19
        # extending 202.100.0.0-202.100.95.255 to include 202.100.96.0/19
        # extending 202.100.0.0/17 to include 202.100.128.0/19
        # extending 202.100.0.0-202.100.159.255 to include 202.100.160.0/19
        # extending 202.100.0.0-202.100.191.255 to include 202.100.192.0/18
        '202.100.0.0/16',
        # extending 202.101.64.0/19 to include 202.101.96.0/19
        # extending 202.101.64.0/18 to include 202.101.128.0/19
        # extending 202.101.64.0-202.101.159.255 to include 202.101.160.0/19
        # extending 202.101.64.0-202.101.191.255 to include 202.101.192.0/18
        # extending 202.101.64.0-202.101.255.255 to include 202.102.0.0/17
        '202.101.64.0-202.102.127.255',
        '202.102.192.0/19',
        # extending 202.103.0.0/18 to include 202.103.64.0/18
        # extending 202.103.0.0/17 to include 202.103.128.0/18
        # extending 202.103.0.0-202.103.191.255 to include 202.103.192.0/18
        # extending 202.103.0.0/16 to include 202.104.0.0/16
        # extending 202.103.0.0-202.104.255.255 to include 202.105.0.0/16
        '202.103.0.0-202.105.255.255',
        # extending 202.107.128.0/18 to include 202.107.192.0/18
        '202.107.128.0/17',
        # extending 202.109.0.0/17 to include 202.109.128.0/18
        # extending 202.109.0.0-202.109.191.255 to include 202.109.192.0/18
        '202.109.0.0/16',
        '202.110.128.0/18',
        '202.111.0.0/17',
        '202.111.192.0/19',
        '202.150.224.0/19',
        '203.15.112.0/21',
        '203.15.232.0/21',
        '203.16.16.0/21',
        '203.19.32.0/21',
        '203.22.78.0/24',
        '203.26.84.0/24',
        '203.30.87.0/24',
        '203.86.96.0/19',
        '203.144.96.0/19',
        '210.5.56.0/21',
        # extending 218.0.0.0/16 to include 218.1.0.0/16
        # extending 218.0.0.0/15 to include 218.2.0.0/15
        # extending 218.0.0.0/14 to include 218.4.0.0/16
        # extending 218.0.0.0-218.4.255.255 to include 218.5.0.0/16
        # extending 218.0.0.0-218.5.255.255 to include 218.6.0.0/17
        # extending 218.0.0.0-218.6.127.255 to include 218.6.128.0/17
        '218.0.0.0-218.6.255.255',
        # extending 218.13.0.0/16 to include 218.14.0.0/15
        # extending 218.13.0.0-218.15.255.255 to include 218.16.0.0/14
        # extending 218.13.0.0-218.19.255.255 to include 218.20.0.0/16
        # extending 218.13.0.0-218.20.255.255 to include 218.21.0.0/19
        # extending 218.13.0.0-218.21.31.255 to include 218.21.32.0/20
        # extending 218.13.0.0-218.21.47.255 to include 218.21.48.0/20
        # extending 218.13.0.0-218.21.63.255 to include 218.21.64.0/18
        '218.13.0.0-218.21.127.255',
        # absorbs:
        #    218.16.0.0 - 218.17.255.255 (from 218.13.0.0/16)
        #    218.18.0.0 - 218.18.255.255 (from 218.13.0.0/16)
        '218.22.0.0/15',
        '218.30.0.0/15',
        # extending 218.62.128.0/17 to include 218.63.0.0/16
        # extending 218.62.128.0-218.63.255.255 to include 218.64.0.0/16
        # extending 218.62.128.0-218.64.255.255 to include 218.65.0.0/17
        # extending 218.62.128.0-218.65.127.255 to include 218.65.128.0/17
        # extending 218.62.128.0-218.65.255.255 to include 218.66.0.0/16
        # extending 218.62.128.0-218.66.255.255 to include 218.67.0.0/17
        '218.62.128.0-218.67.127.255',
        # extending 218.70.0.0/16 to include 218.71.0.0/16
        # extending 218.70.0.0/15 to include 218.72.0.0/15
        # extending 218.70.0.0-218.73.255.255 to include 218.74.0.0/16
        # extending 218.70.0.0-218.74.255.255 to include 218.75.0.0/17
        # extending 218.70.0.0-218.75.127.255 to include 218.75.128.0/17
        # extending 218.70.0.0-218.75.255.255 to include 218.76.0.0/16
        # extending 218.70.0.0-218.76.255.255 to include 218.77.0.0/17
        # extending 218.70.0.0-218.77.127.255 to include 218.77.128.0/17
        # extending 218.70.0.0-218.77.255.255 to include 218.78.0.0/15
        # extending 218.70.0.0-218.79.255.255 to include 218.80.0.0/14
        # extending 218.70.0.0-218.83.255.255 to include 218.84.0.0/16
        # extending 218.70.0.0-218.84.255.255 to include 218.85.0.0/16
        # extending 218.70.0.0-218.85.255.255 to include 218.86.0.0/17
        # extending 218.70.0.0-218.86.127.255 to include 218.86.128.0/17
        # extending 218.70.0.0-218.86.255.255 to include 218.87.0.0/16
        # extending 218.70.0.0-218.87.255.255 to include 218.88.0.0/15
        # extending 218.70.0.0-218.89.255.255 to include 218.90.0.0/15
        # extending 218.70.0.0-218.91.255.255 to include 218.92.0.0/15
        # extending 218.70.0.0-218.93.255.255 to include 218.94.0.0/16
        # extending 218.70.0.0-218.94.255.255 to include 218.95.0.0/17
        # extending 218.70.0.0-218.95.127.255 to include 218.95.128.0/18
        # extending 218.70.0.0-218.95.191.255 to include 218.95.192.0/19
        # extending 218.70.0.0-218.95.223.255 to include 218.95.224.0/19
        '218.70.0.0-218.95.255.255',
        '218.100.88.0/21',
        '218.185.240.0/21',
        # extending 219.128.0.0/13 to include 219.136.0.0/15
        # extending 219.128.0.0-219.137.255.255 to include 219.138.0.0/15
        # extending 219.128.0.0-219.139.255.255 to include 219.140.0.0/16
        # extending 219.128.0.0-219.140.255.255 to include 219.141.0.0/17
        # extending 219.128.0.0-219.141.127.255 to include 219.141.128.0/17
        # extending 219.128.0.0-219.141.255.255 to include 219.142.0.0/15
        # extending 219.128.0.0/12 to include 219.144.0.0/15
        # extending 219.128.0.0-219.145.255.255 to include 219.146.0.0/16
        # extending 219.128.0.0-219.146.255.255 to include 219.147.0.0/19
        # extending 219.128.0.0-219.147.31.255 to include 219.147.32.0/20
        # extending 219.128.0.0-219.147.47.255 to include 219.147.48.0/20
        # extending 219.128.0.0-219.147.63.255 to include 219.147.64.0/19
        # extending 219.128.0.0-219.147.95.255 to include 219.147.96.0/19
        # extending 219.128.0.0-219.147.127.255 to include 219.147.128.0/17
        # extending 219.128.0.0-219.147.255.255 to include 219.148.0.0/17
        # extending 219.128.0.0-219.148.127.255 to include 219.148.128.0/19
        # extending 219.128.0.0-219.148.159.255 to include 219.148.160.0/19
        # extending 219.128.0.0-219.148.191.255 to include 219.148.192.0/18
        # extending 219.128.0.0-219.148.255.255 to include 219.149.0.0/17
        # extending 219.128.0.0-219.149.127.255 to include 219.149.128.0/18
        # extending 219.128.0.0-219.149.191.255 to include 219.149.192.0/18
        # extending 219.128.0.0-219.149.255.255 to include 219.150.0.0/19
        # extending 219.128.0.0-219.150.31.255 to include 219.150.32.0/19
        # extending 219.128.0.0-219.150.63.255 to include 219.150.64.0/19
        # extending 219.128.0.0-219.150.95.255 to include 219.150.96.0/20
        # extending 219.128.0.0-219.150.111.255 to include 219.150.112.0/20
        # extending 219.128.0.0-219.150.127.255 to include 219.150.128.0/17
        # extending 219.128.0.0-219.150.255.255 to include 219.151.0.0/19
        # extending 219.128.0.0-219.151.31.255 to include 219.151.32.0/19
        '219.128.0.0-219.151.63.255',
        # extending 219.151.128.0/17 to include 219.152.0.0/15
        '219.151.128.0-219.153.255.255',
        # extending 219.159.64.0/18 to include 219.159.128.0/17
        '219.159.64.0-219.159.255.255',
        # extending 220.160.0.0/15 to include 220.162.0.0/16
        # extending 220.160.0.0-220.162.255.255 to include 220.163.0.0/16
        # extending 220.160.0.0/14 to include 220.164.0.0/15
        # extending 220.160.0.0-220.165.255.255 to include 220.166.0.0/16
        # extending 220.160.0.0-220.166.255.255 to include 220.167.0.0/17
        # extending 220.160.0.0-220.167.127.255 to include 220.167.128.0/17
        # extending 220.160.0.0/13 to include 220.168.0.0/15
        # extending 220.160.0.0-220.169.255.255 to include 220.170.0.0/16
        # extending 220.160.0.0-220.170.255.255 to include 220.171.0.0/17
        # extending 220.160.0.0-220.171.127.255 to include 220.171.128.0/18
        # extending 220.160.0.0-220.171.191.255 to include 220.171.192.0/18
        # extending 220.160.0.0-220.171.255.255 to include 220.172.0.0/16
        # extending 220.160.0.0-220.172.255.255 to include 220.173.0.0/16
        # extending 220.160.0.0-220.173.255.255 to include 220.174.0.0/16
        # extending 220.160.0.0-220.174.255.255 to include 220.175.0.0/16
        # extending 220.160.0.0/12 to include 220.176.0.0/15
        # extending 220.160.0.0-220.177.255.255 to include 220.178.0.0/15
        # extending 220.160.0.0-220.179.255.255 to include 220.180.0.0/16
        # extending 220.160.0.0-220.180.255.255 to include 220.181.0.0/16
        # extending 220.160.0.0-220.181.255.255 to include 220.182.0.0/18
        '220.160.0.0-220.182.63.255',
        '220.184.0.0/13',
        # extending 221.224.0.0/13 to include 221.232.0.0/14
        # extending 221.224.0.0-221.235.255.255 to include 221.236.0.0/15
        # extending 221.224.0.0-221.237.255.255 to include 221.238.0.0/16
        # extending 221.224.0.0-221.238.255.255 to include 221.239.0.0/17
        # extending 221.224.0.0-221.239.127.255 to include 221.239.128.0/17
        '221.224.0.0/12',
        # extending 222.64.0.0/13 to include 222.72.0.0/15
        # extending 222.64.0.0-222.73.255.255 to include 222.74.0.0/16
        # extending 222.64.0.0-222.74.255.255 to include 222.75.0.0/16
        # extending 222.64.0.0-222.75.255.255 to include 222.76.0.0/14
        # extending 222.64.0.0/12 to include 222.80.0.0/15
        # extending 222.64.0.0-222.81.255.255 to include 222.82.0.0/16
        # extending 222.64.0.0-222.82.255.255 to include 222.83.0.0/17
        # extending 222.64.0.0-222.83.127.255 to include 222.83.128.0/17
        # extending 222.64.0.0-222.83.255.255 to include 222.84.0.0/16
        # extending 222.64.0.0-222.84.255.255 to include 222.85.0.0/17
        # extending 222.64.0.0-222.85.127.255 to include 222.85.128.0/17
        # extending 222.64.0.0-222.85.255.255 to include 222.86.0.0/15
        # extending 222.64.0.0-222.87.255.255 to include 222.88.0.0/15
        # extending 222.64.0.0-222.89.255.255 to include 222.90.0.0/15
        # extending 222.64.0.0-222.91.255.255 to include 222.92.0.0/14
        '222.64.0.0/11',
        # extending 222.168.0.0/15 to include 222.170.0.0/15
        # extending 222.168.0.0/14 to include 222.172.0.0/17
        # extending 222.168.0.0-222.172.127.255 to include 222.172.128.0/17
        # extending 222.168.0.0-222.172.255.255 to include 222.173.0.0/16
        # extending 222.168.0.0-222.173.255.255 to include 222.174.0.0/15
        # extending 222.168.0.0/13 to include 222.176.0.0/13
        # extending 222.168.0.0-222.183.255.255 to include 222.184.0.0/13
        '222.168.0.0-222.191.255.255',
        # extending 222.208.0.0/13 to include 222.216.0.0/15
        # extending 222.208.0.0-222.217.255.255 to include 222.218.0.0/16
        # extending 222.208.0.0-222.218.255.255 to include 222.219.0.0/16
        # extending 222.208.0.0-222.219.255.255 to include 222.220.0.0/15
        # extending 222.208.0.0-222.221.255.255 to include 222.222.0.0/15
        '222.208.0.0/12',
        '222.240.0.0/13',
        '223.8.0.0/13',
        '223.144.0.0/12',
        '223.198.0.0/15',
        '223.214.0.0/15',
        '223.220.0.0/15',
        '223.240.0.0/13',
    );
    return $self;
}

sub name {
    return 'ChinaNet';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::ChinaNet - identify ChinaNet (often 163data.com) IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::ChinaNet;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::ChinaNet identifies ChinaNet IPs.  These often
resolve to 163data.com.cn.  Autonomous System (AS) numbers include (many
thanks to Hurricane Electric and their BGP toolkit at http://bgp.he.net/):

    AS63825     CHINANET Hubei province Xiantao network
    AS63824     CHINANET Hubei province Qianjiang network
    AS63823     CHINANET Hubei province Tianmen network
    AS63822     CHINANET Hubei province Enshi network
    AS63821     CHINANET Hubei province Shuizhou network
    AS63820     CHINANET Hubei province Xianning network
    AS63819     CHINANET Hubei province Huanggang network
    AS63818     CHINANET Hubei province Jingzhou network
    AS63817     CHINANET Hubei province Xiaogan network
    AS63816     CHINANET Hubei province Jingmen network
    AS63815     CHINANET Hubei province Xiangfan network
    AS63814     CHINANET Hubei province Yichang network
    AS63813     CHINANET Hubei province Shiyan network
    AS63812     CHINANET Hubei province Ezhou network
    AS63811     CHINANET Hubei province Huangshi network
    AS63810     CHINANET Hubei province Wuhan network
    AS59391     CHINANET Liaoning province network
    AS59390     CHINANET Liaoning province network
    AS59389     CHINANET Liaoning province network
    AS59388     CHINANET Liaoning province network
    AS59387     CHINANET Liaoning province network
    AS59386     CHINANET Liaoning province network
    AS59385     CHINANET Liaoning province network
    AS59384     CHINANET Liaoning province network
    AS59314     CHINANET Sichuan province Liangshan MAN network
    AS59313     CHINANET Sichuan province Ganzi MAN network
    AS59312     CHINANET Sichuan province Ziyang MAN network
    AS59311     CHINANET Sichuan province Bazhong MAN network
    AS59310     CHINANET Sichuan province Yaan MAN network
    AS59309     CHINANET Sichuan province Dazhou MAN network
    AS59308     CHINANET Sichuan province Guangan MAN network
    AS59307     CHINANET Sichuan province Yibing MAN network
    AS59306     CHINANET Sichuan province Meishan MAN network
    AS59305     CHINANET Sichuan province Nanchong MAN network
    AS59304     CHINANET Sichuan province Leshan MAN network
    AS59303     CHINANET Sichuan province Neijiang MAN network
    AS59302     CHINANET Sichuan province Suining MAN network
    AS59301     CHINANET Sichuan province Guangyuan MAN network
    AS59300     CHINANET Sichuan province Mianyang MAN network
    AS59299     CHINANET Sichuan province Deyang MAN network
    AS59298     CHINANET Sichuan province Luzhou MAN network
    AS59297     CHINANET Sichuan province Luzhou MAN network
    AS59296     CHINANET Sichuan province Zigong MAN network
    AS59294     CHINANET Sichuan province Ningbo MAN network
    AS59293     CHINANET Sichuan province Chengdu MAN network
    AS59233     CHINANET Zhejiang province Wenzhou MAN network
    AS59232     CHINANET Zhejiang province Lishui MAN network
    AS59231     CHINANET Zhejiang province Taizhou MAN network
    AS59230     CHINANET Zhejiang province Zhoushan MAN network
    AS59229     CHINANET Zhejiang province Quzhou MAN network
    AS59228     CHINANET Zhejiang province Jinhua MAN network
    AS59227     CHINANET Zhejiang province Shaoxing MAN network
    AS59226     CHINANET Zhejiang province Huzhou MAN network
    AS59225     CHINANET Zhejiang province Jiaxing MAN network
    AS59224     CHINANET Zhejiang province Ningbo MAN network
    AS59223     CHINANET Zhejiang province Hangzhou MAN network
    AS58777     CHINANET Fujian province Putian IDC network
    AS58776     CHINANET Fujian province Longyan IDC network
    AS58775     CHINANET Fujian province Zhangzhou IDC network
    AS58774     CHINANET Fujian province Quanzhou IDC network
    AS58773     CHINANET Fujian province Xiamen IDC network
    AS58772     CHINANET Fujian province Fuzhou IDC network
    AS58771     CHINANET Neimenggu province MAN network
    AS58770     CHINANET Neimenggu province MAN network
    AS58769     CHINANET Neimenggu province MAN network
    AS58574     CHINANET Guangdong province Foshan network
    AS58573     CHINANET Guangdong province Foshan network
    AS58572     CHINANET Guangdong province Foshan network
    AS58571     CHINANET Guangdong province Foshan network
    AS58570     CHINANET Guangdong province Foshan network
    AS58569     CHINANET Guangdong province Foshan network
    AS58568     CHINANET Guangdong province Foshan network
    AS58567     CHINANET Guangdong province Foshan network
    AS58566     CHINANET Guangdong province Zhuhai network
    AS58565     CHINANET Guangdong province Zhongshan network
    AS58564     CHINANET Guangdong province Dongguan network
    AS58563     CHINANET Guangdong province Shenzhen network
    AS58466     CHINANET Guangdong province network
    AS4810      CHINANET core WAN Central
    AS38283     CHINANET SiChuan Telecom Internet Data Center
    AS23650     AS Number for CHINANET jiangsu province backbone
    AS18344     USED IN NORTH CHINANET BACKBONE

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::ChinaNet object.

=back

=head1 SEE ALSO

=over

=item IP::Net

=item IP::Net::Identifier

=item IP::Net::Identifier_Role

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
