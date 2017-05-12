package Munin::Plugin::ApacheRequest;

use warnings;
use strict;

our $VERSION = '0.04';

=head1 NAME

Munin::Plugin::ApacheRequest - Monitor Apache requests with Munin

=head1 SYNOPSIS

This is the contents of a apache_request_$VHOST file, stored in the 
/etc/munin/plugins directory.

    #!/usr/bin/perl -w
    use strict;

    use Munin::Plugin::ApacheRequest;

    my ($VHOST) = ($0 =~ /_([^_]+)$/);
    Munin::Plugin::ApacheRequest::Run($VHOST,1000);

=head1 DESCRIPTION

C<Munin::Plugin::ApacheRequest> provides the mechanism to trigger Apache
request monitoring for a specific VHOST, using Munin.

This distribution is based on a script written by Nicolas Mendoza.

NOTE: In order to use this module, you will need to add a field in your Apache 
logs showing time executed. This is normally done using the %T (seconds) or 
%D (microseconds). For instance: 

    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\" %T %v"

See L<http://httpd.apache.org/docs/2.2/mod/mod_log_config.html#formats> for 
more info.

=head1 VARIABLES

By default several variables are set by default, based on traditional paths and
log format orders. However, should you need to amend these, you can amend them
with in the calling script, before calling Run().

=over 4

=item * ACCESS_LOG_PATTERN

The sprintf format string. If this selects the path based on the named VHOST.
By default this is "/var/www/logs/%s-access.log", where your access log uses a
VHOST prefix. If you don't require this, simple change this to the explicit
path, e.g. "/var/www/logs/access.log".

If you have several log files, which are rotated and/or gzipped, you can
include a catchall in the path such as: "/var/www/logs/%s-access.log.*".

=item * TIME_FIELD_INDEX 

By default this assumes the second to last field of the output line of the log,
which is set as '-2'. Setting this to a positive value, will select the 
respective field from left to right.

=back

=cut

#----------------------------------------------------------------------------
# Base Settings

our $ACCESS_LOG_PATTERN  = "/var/www/logs/%s-access.log";    # log pattern
our $TIME_FIELD_INDEX    = -2;                               # second last field

my $types = {
    # any kind of request
    total => {
        munin_fields => {
            label => 'All requests',	
            draw => 'LINE2',
            info => 'Average seconds per any request',
        },
        sum => 0,
        lines => 0,
        matches => sub { 
            return 1; 
        },
    },

    # image requests
    images => {
        munin_fields => {
            label => 'Image requests',
            draw => 'LINE2',
            info => 'Average seconds per image request',
        },
        sum => 0,
        lines => 0,
        matches => sub { 
            my ($fields) = @_; 
            my $script; 
            ($script = $fields->[6]) =~ s/\?.*\z //mx; 
            return $script =~ m{ \.(png|jpe?g|jpg|gif|tiff|ilbm|tga) \z }mx; 
        },
    },
};

#----------------------------------------------------------------------------
# Functions

=head1 FUNCTIONS

=over 4

=item * Run

This is used to call the underlying plugin process. If the script is called
with the 'config' argument, the configuration details are returned, otherwise
the current values are calculated and returned.

=back

=cut

sub Run {
    my ($VHOST,$LAST_N_REQUESTS) = @_;
    $LAST_N_REQUESTS ||= 1000; # calculate based on this amount of requests

    my $access_log_pattern = 
        $ACCESS_LOG_PATTERN =~ /\%s/
            ? sprintf $ACCESS_LOG_PATTERN, $VHOST
            : $ACCESS_LOG_PATTERN;

    my $config =<< "CONFIG"
graph_title $VHOST ave msecs last $LAST_N_REQUESTS requests
graph_args --base 1000
graph_scale no
graph_vlabel Average request time (msec)
graph_category Apache
graph_info This graph shows average request times for the last $LAST_N_REQUESTS requests
images.warning 30000000
images.critical 60000000
total.warning 10000000
total.critical 60000000
CONFIG
;

    if (@ARGV && ($ARGV[0] eq 'config')) {
        print $config;

        for my $type (sort keys %{$types}) {
            for my $key (sort keys %{$types->{$type}->{'munin_fields'}}) {
                printf "%s.%s %s\n", ($type, $key, $types->{$type}->{'munin_fields'}->{$key});
            }
        }
        return;
    }    

    my $config_file;
    eval { $config_file = `ls -1 $access_log_pattern 2>/dev/null| tail -1`; };

    chomp $config_file;
    if($@ || !$config_file) {
        for my $type (sort keys %{$types}) {
            printf "%s.value U\n", $type;
        }
    }

    my @lines = `tail -$LAST_N_REQUESTS "$config_file"`;

    for my $line (@lines) {
        for my $type (keys %{$types}) {
            my @fields = split /\s+/, $line;
            if ($types->{$type}->{'matches'}(\@fields)) {
                $types->{$type}->{'sum'} += $fields[$TIME_FIELD_INDEX];
                $types->{$type}->{'lines'}++;
            }
        }
    } 

    for my $type (sort keys %{$types}) {
        my $value = $types->{$type}->{'lines'}
              ? sprintf "%.10f", $types->{$type}->{'sum'} / $types->{$type}->{'lines'} : 'U';
        printf "%s.value %s\n", ($type, $value);
    }

    return;
}

1;

# Author: Nicolas Mendoza <nicolasm@opera.com> - 2008-06-18
# Modified by Barbie <barbie@cpan.org> - 2008-10-21

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2008-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
