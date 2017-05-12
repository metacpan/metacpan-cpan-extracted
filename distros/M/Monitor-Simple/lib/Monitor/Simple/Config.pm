#-----------------------------------------------------------------
# Monitor::Simple::Config
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# ABSTRACT: See documentation in Monitor::Simple
# PODNAME: Monitor::Simple::Config
#-----------------------------------------------------------------

package Monitor::Simple::Config;
use warnings;
use strict;
use Carp;
use XML::Simple;
use File::Spec;
use File::Basename;
use Monitor::Simple;
use Log::Log4perl qw(:easy);

our $VERSION = '0.2.8'; # VERSION

our $DEFAULT_CONFIG_FILE = 'monitor-simple-cfg.xml';
our $ENV_CONFIG_DIR = 'MONITOR_SIMPLE_CFG_DIR';

#-----------------------------------------------------------------
# Try to locate given $filename and return its full path:
#  a) as it is - if such file exists
#  b) as $ENV{MONITOR_SIMPLE_CFG_DIR}/$filename
#  c) in the directory where the main invoker (script) is located
#  d) in one of the @INC directories
#  e) return undef
#-----------------------------------------------------------------
sub resolve_config_file {
    my $self = shift;   # invocant
    my $filename = shift;
    $filename = $DEFAULT_CONFIG_FILE unless $filename;
    return $filename if -f $filename;

    my $realfilename;
    if ($ENV{$ENV_CONFIG_DIR}) {
        $realfilename = File::Spec->catdir ($ENV{$ENV_CONFIG_DIR}, $filename);
        return $realfilename if -f $realfilename;
    }

    my $dirname = dirname ($0);
    $realfilename = File::Spec->catdir ($dirname, $filename);
    return $realfilename if -f $realfilename;

    foreach my $prefix (@INC) {
        $realfilename = File::Spec->catfile ($prefix, $filename);
        return $realfilename if -f $realfilename;
    }
    return;
}

#-----------------------------------------------------------------
# Return a hashref with the full configuration.
#
# The configuration is looked for in the given configuration file
# ($config_file), or in a default configuration file. The path to both
# given and default configuration file is resolved by rules defined in
# the subroutine resolve_config_file (elsewhere in this module).
# -----------------------------------------------------------------
sub get_config {
    my ($self, $config_file) = @_;
    my $resolved_config_file = $self->resolve_config_file ($config_file);  # may be undef
    LOGDIE ("Cannot find '" . (defined $config_file ? $config_file : 'any') . "' configuration file.\n")
        unless $resolved_config_file;
    my $xs = XML::Simple->new (
        ForceArray    => [ 'service', 'email', 'email-group', 'notifier', 'contains',
                           'prg-test', 'post-test', 'head-test', 'get-test', 'arg' ],
        GroupTags     => { services => 'service', args     => 'arg' },
        KeyAttr       => [],
        SuppressEmpty => undef,
        );
    my $config;
    eval { $config = $xs->XMLin ($resolved_config_file) };
    if ($@) {
        my $msg = $@;
        $msg =~ s{^\s*|\s*$}{};
        chomp ($msg);
        $msg =~ s{ at /.+$}{};
        LOGDIE ("Errors in configuration file '$resolved_config_file': $msg\n");
    }
    $config = {} unless $config;

    # check the validity of the config file
    my $doc = $self->validate ($config);
    LOGDIE ("Errors in configuration file '$resolved_config_file': $doc") if $doc;

    return $config;
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub validate {
    my ($self, $config) = @_;
    my $doc = '';

    # add default values for missing configuration properties
    my $location = $INC{'Monitor/Simple.pm'};  # Monitor/Simple.pm => /usr/lib/perl/5.10/Monitor/Simple.pm
    $location =~ s{\.pm$}{};
    $config->{general}->{'plugins-dir'} = File::Spec->catfile ($location, 'plugins')
        unless $config->{general}->{'plugins-dir'};
    $config->{general}->{'notifiers-dir'} = File::Spec->catfile ($location, 'notifiers')
        unless $config->{general}->{'notifiers-dir'};

    if (exists $config->{services}) {
        my $count = 0;
        foreach my $service (@{ $config->{services} }) {
            $count++;
            # each service must have an ID
            if ($service->{id}) {
                # copy service ID into NAME if name is missing
                $service->{name} = $service->{id} unless defined $service->{name};
            } else {
                $doc .= "Service number $count does not have an ID attribute.\n";
                $service->{name} = 'unidentifed';
            }

            if (exists $service->{plugin}) {
                # there can be only one plugin per service
                if (ref ($service->{plugin}) ne 'HASH') {
                    $doc .= "Service '$service->{name}' has more than one plugin tag.\n";
                } else {
                    # each plugin must have a command
                    $doc .= "Service '$service->{name}' has a plugin without any 'command' attribute.\n"
                        unless $service->{plugin}->{command};
                }
            } else {
                # each service must have a plugin
                $doc .= "Service number $count does not have any plugin section.\n";
            }

            # each notifier must have a command
            if (exists $service->{notifier}) {
                my $ncount = 0;
                foreach my $notifier (@{ $service->{notifier} }) {
                    $ncount++;
                    $doc .= "Notifier number $ncount in service '$service->{name}' has no 'command' attribute.\n"
                        unless $notifier->{command};
                }
            }
        }
    }

    # each general notifier must have a command
    if (exists $config->{general}->{notifier}) {
        my $ncount = 0;
        foreach my $notifier (@{ $config->{general}->{notifier} }) {
            $ncount++;
            $doc .= "General notifier number $ncount has no 'command' attribute.\n"
                unless $notifier->{command};
        }
    }

    return $doc;
}

#-----------------------------------------------------------------
# Return a hashref with configuration for a given service (identified
# by its $service_id). If such configuration cannot be found, a warning is
# issued and undef is returned.
#
# The service configuration is looked for in the given hashref $config
# containing the full configuration.
# -----------------------------------------------------------------
sub extract_service_config {
    my ($self, $service_id, $config) = @_;
    if (exists $config->{services}) {
        foreach my $service (@{ $config->{services} }) {
            return $service if $service->{id} eq $service_id;
        }
    }
    # return an undef
    LOGWARN ("Service name '$service_id' was not found in the current configuration.");
    return;
}

#-----------------------------------------------------------------
# Extract proper command-line arguments from the $full_config for the
# $service_id and return them as an array (which may be empty but
# never undef).
#
# Returned arguments are taken either from:
# {
#    'plugin' => {
#       'args' => [
#          ...,
#          ...,
#       ],
#    },
# }
#
# or (if no 'args' exists) they will be as described in
# Monitor::Simple::Utils->parse_plugin_args().
# -----------------------------------------------------------------
sub create_plugin_args {
    my ($self, $config_file, $full_config, $service_id) = @_;
    my $service_config = $self->extract_service_config ($service_id, $full_config);
    return () unless $service_config;  # service not found

    if (exists $service_config->{plugin}->{args}) {
        # args exists: use them
        return @{ $service_config->{plugin}->{args} };
    }
    # last resort (but used for the most of our plugins)
    return ('-cfg',     $config_file,
            '-service', $service_id,
            Monitor::Simple::Log->logging_args());
}

1;


=pod

=head1 NAME

Monitor::Simple::Config - See documentation in Monitor::Simple

=head1 VERSION

version 0.2.8

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC-KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
