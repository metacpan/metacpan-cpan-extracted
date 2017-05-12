#!/usr/bin/env perl

use lib "lib/";

use strict;
use warnings;

use Net::DNS::Dynamic::Proxyserver 1.1;

use Getopt::Long;
use Pod::Usage;

our $VERSION = '0.05';

my $debug 				= 0;
my $verbose				= 0;
my $help				= 0;
my $host 				= undef;
my $port				= undef;
my $background			= 0;
my $ask_etc_hosts		= undef;
my $uid					= undef;
my $gid					= undef;
my $nameserver			= undef;
my $nameserver_port		= 0;

GetOptions(
    'debug|d'			=> \$debug,
    'verbose|v'			=> \$verbose,
    'help|?|h'			=> \$help,
    'host=s'			=> \$host,
    'port|p=s'			=> \$port,
    'background|bg'		=> \$background,
	'ttl=s'				=> \$ask_etc_hosts,
	'uid|u=s'			=> \$uid,
	'gid|g=s'			=> \$gid,
	'nameserver|ns=s'	=> \$nameserver,
);

pod2usage(1) if $help;

fork && exit if $background;

($nameserver, $nameserver_port) = split(':', $nameserver) if $nameserver && $nameserver =~ /\:/;

my $args = {};

$args->{debug}				= ($verbose ? 1 : ($debug ? 3 : 0));
$args->{host}				= $host if $host;
$args->{port}				= $port if $port;
$args->{uid}				= $uid if $uid;
$args->{gid}				= $gid if $gid;
$args->{nameservers}		= [ $nameserver ] if $nameserver;
$args->{nameservers_port} 	= $nameserver_port if $nameserver_port;
$args->{ask_etc_hosts} 		= { ttl => $ask_etc_hosts } if $ask_etc_hosts;

Net::DNS::Dynamic::Proxyserver->new( $args )->run();

=head1 NAME

dns-proxy.pl - A dynamic DNS proxy server

=head1 SYNOPSIS

dns-proxy.pl [options]

 Options:
   -h  -help          display this help
   -v  -verbose       show server activity
   -d  -debug         enable debug mode
       -host          host (defaults to all)
   -p  -port          port (defaults to 53)
   -u  -uid           run with user id
   -g  -gid           run with group id
   -bg -background    run the process in the background
       -ttl           use /etc/hosts to answer DNS queries with specified ttl (seconds)
   -ns -nameserver    forward queries to this nameserver (<ip>:<port>)
       
 See also:
   perldoc Net::DNS::Dynamic::Proxyserver

=head1 DESCRIPTION

This script implements a dynamic DNS proxy server provided
by Net::DNS::Dynamic::Proxyserver. See 

 perldoc Net::DNS::Dynamic::Proxyserver

for detailed information what this server can do for you.

=head1 AUTHOR

Marc Sebastian Jakobs <mpelzer@cpan.org>

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

