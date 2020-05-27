#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use File::Basename qw(dirname);
use Cwd qw(abs_path);

my $path = abs_path;
# dirname($path);
$path =~ /.*\/(.*?)\/install/;

my $engine_path = dirname(dirname abs_path);
my $enginename = $1;
my $lc_enginename = lc $1;
# locations
my $unit_path = '/etc/systemd/system/'. lc $lc_enginename . '.service';

my $unit_file = qq{
[Unit]
 Description=$enginename Service

[Service]	
 ExecStart=$engine_path/start-engine.pl

};

LOG($unit_path,$unit_file);

say("start the service with: service $lc_enginename start");

sub LOG {

	my ($filename, $text) = @_;
        
    open(F, ">$filename");
    print F $text;
    close(F);
    
    return '';

}

1;
