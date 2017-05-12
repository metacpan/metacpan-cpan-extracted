#!/usr/bin/perl

use lib 'lib';

package MyScanner;

use lib 'lib';
use Nmap::Scanner;
use strict;

use vars qw(@ISA);

@ISA = qw(Nmap::Scanner::Scanner);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    $self->register_scan_started_event(\&started);
    $self->register_port_found_event(\&port);
    return bless $self, $class;
}

#  We get passed a $self reference and
#  an Nmap::Scanner::Host reference

sub started {
    die unless scalar(@_) == 2;
}

#  We get passed a $self reference,
#  an Nmap::Scanner::Host reference,
#  and an Nmap::Scanner::Port reference

sub port {
    die unless scalar(@_) == 3;
}

1;

use Test;
use strict;

BEGIN { plan tests => 3 }

my $SKIP = Nmap::Scanner::Scanner::_find_nmap() ? 0 : 
           "nmap not found in PATH (See http://www.insecure.org/nmap/)";

if ($SKIP) {
    skip($SKIP);
    skip($SKIP);
    skip($SKIP);
    exit;
}

my $scan = MyScanner->new();

ok($scan);

$scan->add_target('localhost');
$scan->add_scan_port('1-1024');
$scan->tcp_connect_scan();

my $localhost = $scan->scan()->get_host_list()->get_next();
ok(sub { $localhost->hostname() ne "" });

my $aport = $localhost->get_port_list()->get_next();
ok($aport->portid());

1;
