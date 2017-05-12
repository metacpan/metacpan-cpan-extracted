package Rex::Group::Lookup::Nagios;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Rex -base;
use Rex::Group::Entry::Server;
use Rex::Logger;
use Carp;
use Nagios::Config;
use File::Spec;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(groups_nagios);

sub groups_nagios {
    my %option = @_;

    my $path = $option{path} || '/etc/nagios3';
    my $cfg  = $option{cfg}  || 'nagios.cfg';

    my $nagios_cfg = Nagios::Config->new( filename => File::Spec->catfile( $path, $cfg ) );
    my @hg = $nagios_cfg->list_hostgroups();

    my %group;
    my %all_hosts;

    foreach my $g (@hg) {
        foreach my $host ( @{ $g->members } ) {
            my $name = $host->name;
            if ($option{filter} ) {
                $name = &{$option{filter}}($name, $host->address);
                next unless $name;
            }
            my $add      = {};
            Rex::Logger::debug('Add host '. $name);
            my $rex_host = Rex::Group::Entry::Server->new(
                name => $name,
                %{$add}
            );
            push @{ $group{ $g->name } }, $rex_host;
            $all_hosts{ $host->name } = $rex_host;
        }
    }

    for my $g ( keys %group ) {
        group( "$g" => @{ $group{$g} } );
    }

    if ( exists $option{create_all_group} && $option{create_all_group} ) {
        group( "all", values %all_hosts );
    }
}

1;

=pod

=head1 NAME

Rex::Group::Lookup::Nagios - read hostnames and groups from a Nagios config

=head1 DESCRIPTION

With this module you can define hostgroups out of an Nagios configuration.
The module requires L<Nagios::Config> to work. 

=head1 SYNOPSIS

 use Rex::Group::Lookup::Nagios;
 groups_nagios (path => '/etc/nagios3')

=head1 EXPORTED FUNCTIONS

=over 4

=item groups_nagios (%options) 

Reads the given  Nagios  configfiles and adds hostgroups and hosts  defined there to Rex.

Valid options are:

=over 4

=item path 

Path to nagios config,  default = '/etc/nagios3'

=item cfg

Name of the base config file, default 'nagios.cfg'

=item create_all_group

Create  a group "all_hosts".

=item filter => sub {}

You can  modify the host names added to Rex by defining a filter sub. The sub will be called with two parameters:
 ( host_name, address ). The returned value is used as host name added to Rex. If you return undef, this host will be skipped.

Example:

 groups_nagios( filter => sub { my ($host_name, $address) =@_; return  $host_name . '.my.domain';} );

=back

=back

=CAVEATS

This module hasn't been tested on Windows platforms.

=AUTHOR

Rolf Schaufelberger, E<lt>rolfschau@cpan.orgE<gt>

=head1  COPYRIGHT AND LICENSE

Copyright 2015 Rolf Schaufelberger

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

