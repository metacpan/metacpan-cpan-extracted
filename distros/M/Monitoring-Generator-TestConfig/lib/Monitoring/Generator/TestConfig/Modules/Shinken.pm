package Monitoring::Generator::TestConfig::Modules::Shinken;

use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Monitoring::Generator::TestConfig::Modules::Shinken - shinken specificy functions

=head1 METHODS

=over 4

=item new

    returns a shinken module object

=back

=cut


########################################
sub new {
    my($class,%options) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}


=head1 METHODS

=over 4

=cut

########################################
sub _get_shinken_specific_cfg {
    my $self = shift;

    my $max_workers = ($self->{'hostcount'} * $self->{'services_per_host'}) / 256 / 10; # 100000 services -> 39
    $max_workers = ($max_workers < 10) ? 10 : abs($max_workers);
    my $cfg = "
define scheduler{
       scheduler_name           scheduler-All
       address                  localhost
       port                     7768
       spare                    0
       realm                    All
       weight                   1
}
define reactionner{
       reactionner_name         reactionner-All
       address                  localhost
       port                     7769
       spare                    0
       realm                    All
       manage_sub_realms        0
}
define poller{
       poller_name              poller-All
       address                  localhost
       port                     7771
       realm                    All
       manage_sub_realms        0
       min_workers              4
       max_workers              $max_workers
       processes_by_worker      256
       polling_interval         1
}
define broker{
       broker_name              broker-All
       address                  localhost
       port                     7772
       spare                    0
       realm                    All
       manage_sub_realms        0
       modules                  Simple-log,Status-Dat,Livestatus
}
define module{
       module_name              Simple-log
       module_type              simple_log
       path                     $self->{'output_dir'}/var/shinken.log
       archive_path             $self->{'output_dir'}/archives/
}
define module{
       module_name              Status-Dat
       module_type              status_dat
       status_file              $self->{'output_dir'}/var/status.dat
       object_cache_file        $self->{'output_dir'}/var/objects.cache
       status_update_interval   15 ; update status.dat every 15s
}
define module{
       module_name              Livestatus
       module_type              livestatus
       host                     *   ; * = listen on all configured ip addresses
       port                     50000
       database_file            $self->{'output_dir'}/var/livestatus.db
}
define realm {
       realm_name               All
       default                  1
}
";
    return($cfg);
}

########################################
sub _get_shinken_schedulerd_cfg {
    my $self    = shift;

    my $cfg = "[daemon]
workdir=$self->{'output_dir'}/var
pidfile=%(workdir)s/schedulerd.pid
port=7768
host=0.0.0.0
user=$self->{'user'}
group=$self->{'group'}
idontcareaboutsecurity=0
";
    return($cfg);
}

########################################
sub _get_shinken_pollerd_cfg {
    my $self    = shift;

    my $cfg = "[daemon]
workdir=$self->{'output_dir'}/var
pidfile=%(workdir)s/pollerd.pid
interval_poll=5
maxfd=1024
port=7771
host=0.0.0.0
user=$self->{'user'}
group=$self->{'group'}
idontcareaboutsecurity=no
";
    return($cfg);
}

########################################
sub _get_shinken_brokerd_cfg {
    my $self    = shift;

    ($self->{'shinken_dir'} = $self->{'binary'}) =~ s/\/[^\/]*?\/[^\/]*?$//mxg;
    my $cfg = "[daemon]
workdir=$self->{'output_dir'}/var
pidfile=%(workdir)s/brokerd.pid
interval_poll=5
maxfd=1024
port=7772
host=0.0.0.0
user=$self->{'user'}
group=$self->{'group'}
idontcareaboutsecurity=no
modulespath=$self->{'shinken_dir'}/modules
";
    return($cfg);
}

########################################
sub _get_shinken_reactionnerd_cfg {
    my $self    = shift;

    my $cfg = "[daemon]
workdir=$self->{'output_dir'}/var
pidfile=%(workdir)s/reactionnerd.pid
interval_poll=5
maxfd=1024
port=7769
host=0.0.0.0
user=$self->{'user'}
group=$self->{'group'}
idontcareaboutsecurity=no
";
    return($cfg);
}

########################################
sub _get_shinken_initscript {
    my $self    = shift;
    return "";
}

1;

__END__

=back

=head1 AUTHOR

Sven Nierlein, <nierlein@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Sven Nierlein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
