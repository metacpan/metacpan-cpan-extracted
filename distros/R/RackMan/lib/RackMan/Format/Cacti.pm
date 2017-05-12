package RackMan::Format::Cacti;

use strict;
use Carp;
use IPC::Run;


use constant {
    CONFIG_SECTION  => "format:cacti",
    DEFAULT_PATH    => "/var/lib/cacti/cli",
    DEFAULT_PHP     => "/usr/bin/php",
};

my @SUDO;
my @PHP   = ( DEFAULT_PHP, "-q" );
my $CACTI = DEFAULT_PATH;


#
# write()
# -----
sub write {
    my ($class, $args) = @_;

    my $rackdev = $args->{rackdev};
    my $rackman = $args->{rackman};
    my $name    = $rackdev->object_name;
    my $fqdn    = $rackdev->attributes->{FQDN} || $name;

    cacti_configure($rackman);

    my %is = ( lc($rackdev->object_type) => 1 );
    $is{cisco_switch} = 1 if $is{switch} and $rackdev->class =~ /Cisco/;

    # determine the template ID from the object type
    my $tmpl_id = $is{server} ? 3 : $is{cisco_switch} ? 5 : 1;

    # add the device in Cacti
    print "  x adding device $name\n" if $args->{verbose};
    my $host_id = cacti_add_device({
        description => $name,  ip => $fqdn,
        version => 2,  template => $tmpl_id,
    }) or return;

    if ($tmpl_id > 1) {
        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # add data queries
        print "  x adding data queries\n" if $args->{verbose};

        # common options
        my %opts = ( "host-id" => $host_id, "reindex-method" => "fields" );

        # data query: SNMP - Interface Statistics
        cacti_add_data_query({ %opts, "data-query-id" => 1 });

        # data query: SNMP - Get Processor Information
        cacti_add_data_query({ %opts, "data-query-id" => 9 });

        if ($is{server}) {
            # data query: ucd/net - Get Monitored Partitions
            cacti_add_data_query({ %opts, "data-query-id" => 2 });
        }

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # add graph templates
        print "  x adding graph templates\n" if $args->{verbose};

        # common options
        %opts = ( "host-id" => $host_id );

        # graph template: Interface - Traffic (bits/sec)
        cacti_add_graph_template({ %opts, "graph-template-id" => 2 });

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # add non-indexed graphs
        print "  x adding non-indexed graphs\n" if $args->{verbose};

        # common options
        %opts = ( "host-id" => $host_id, "graph-type" => "cg" );

        if ($is{cisco_switch}) {
            # graph: Cisco - CPU Usage
            cacti_add_graphs({ %opts, "graph-template-id" => 18 });
        }

        if ($is{server}) {
            # graph: ucd/net - Available Disk Space
            cacti_add_graphs({ %opts, "graph-template-id" => 3 });

            # graph: ucd/net - CPU Usage
            cacti_add_graphs({ %opts, "graph-template-id" => 4 });

            # graph: ucd/net - Load Average
            cacti_add_graphs({ %opts, "graph-template-id" => 11 });

            # graph: ucd/net - Memory Usage
            cacti_add_graphs({ %opts, "graph-template-id" => 13 });
        }
    }
}


#
# cacti_configure()
# ---------------
sub cacti_configure {
    my $rackman = shift;

    $CACTI = $rackman->config->val(CONFIG_SECTION, "path", DEFAULT_PATH);

    @PHP = split / +/,
        $rackman->config->val(CONFIG_SECTION, "php", DEFAULT_PHP." -q");

    if (my $user = $rackman->config->val(CONFIG_SECTION, "sudo_as")) {
        @SUDO = ( "/usr/bin/sudo", "-u", $user );
    }
}


#
# cacti_exec()
# ----------
sub cacti_exec {
    my ($cacti_cmd, $opts, $out) = @_;

    my @cacti_args = map "--$_=$opts->{$_}", keys %$opts;
    my @cmd = ( @SUDO, @PHP, "$CACTI/$cacti_cmd", @cacti_args );
    my ($in, $err);  # note: Cacti commands do not use stderr
    return IPC::Run::run(\@cmd, \$in, $out, \$err);
}


#
# cacti_add_device()
# ----------------
sub cacti_add_device {
    my $opts = shift;

    my $r = cacti_exec("add_device.php", $opts, \my $out);
    my ($host_id) = $out =~ /device-id: +\((\d+)\)/m;
    RackMan->warning("can't obtain ID from Cacti for host ",
        "$opts->{description}: $out") unless $host_id;

    return $host_id
}


#
# cacti_add_data_query()
# --------------------
sub cacti_add_data_query {
    my $opts = shift;

    my $r = cacti_exec("add_data_query.php", $opts, \my $out);
}


#
# cacti_add_graph_template()
# ------------------------
sub cacti_add_graph_template {
    my $opts = shift;

    my $r = cacti_exec("add_graph_template.php", $opts, \my $out);
}


#
# cacti_add_graphs()
# ----------------
sub cacti_add_graphs {
    my $opts = shift;

    my $r = cacti_exec("add_graphs.php", $opts, \my $out);
}


__PACKAGE__

__END__

=pod

=head1 NAME

RackMan::Format::Cacti - Create Cacti graphs for the given RackObject

=head1 SYNOPSIS

    use RackMan::Format::Cacti;

    RackMan::Format::Cacti->write({
        rackdev => $rackdev,  # a RackMan::Device instance
        rackman => $rackman,  # a RackMan instance
    });


=head1 DESCRIPTION

This module declares the given RackObject within Cacti and creates a few
associated graphs or graph templates.


=head1 METHODS

=head2 write

Do the work.

B<Arguments>

Arguments are expected as a hashref with the following keys:

=over

=item *

C<rackdev> - I<(mandatory)> a RackMan::Device instance

=item *

C<rackman> - I<(mandatory)> a RackMan instance

=item *

C<verbose> - I<(optional)> boolean, set to true to be verbose

=back


=head1 CONFIGURATION

This module gets its configuration from the C<[format:cacti]> section
of the main F<rack.conf>, with the following parameters:

=head2 path

Path of the directory where the Cacti command line programs are located.


=head2 php

Path of the PHP interpreter. Default to F</usr/bin/php>


=head2 sudo_as

Specify an optional user account to execute the Cacti programs under,
using sudo(8).


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

