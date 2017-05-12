#-----------------------------------------------------------------
# Monitor::Simple::Notifier
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# ABSTRACT: See documentation in Monitor::Simple
# PODNAME: Monitor::Simple::Notifier
#-----------------------------------------------------------------

package Monitor::Simple::Notifier;
use warnings;
use strict;
use Monitor::Simple;
use Log::Log4perl qw(:easy);
use IO::CaptureOutput qw(capture_exec);
use File::Spec;
use File::Temp;

our $VERSION = '0.2.8'; # VERSION

my $Codes = {
    Monitor::Simple::NOTIFY_OK       => 1,
    Monitor::Simple::NOTIFY_WARNING  => 1,
    Monitor::Simple::NOTIFY_CRITICAL => 1,
    Monitor::Simple::NOTIFY_UNKNOWN  => 1,
    Monitor::Simple::NOTIFY_ALL      => 1,
    Monitor::Simple::NOTIFY_ERRORS   => 1,
    Monitor::Simple::NOTIFY_NONE     => 1,
};


#-----------------------------------------------------------------
# Recognized arguments:
#    config  => <config>
#    cfgfile => <config-file>
#-----------------------------------------------------------------
sub new {
    my ($class, %args) = @_;

    # create an object and fill it from $args
    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }

    # done
    return $self;
}

#------------------------------------------------------------------
# Given a $result of a service check, make all expected notifications
# (as defined in the $config given in a Notifier constructor). The
# $result is a hashref with this content:
#
#    { service => $service_id,
#      code    => $code,
#      msg     => $msg }
#
# -----------------------------------------------------------------
sub notify {
    my ($self, $result) = @_;

    # some defaults
    $result->{code} = Monitor::Simple::NOTIFY_ERRORS
        unless exists $result->{code};

    # find all relevant notifiers (both general and service specific)
    my @all_relevant_notifiers = $self->get_relevant_notifiers ($result);

    # notify
    my $msg_files = {};   # keys are formats, values are names of temporary files
    foreach my $notifier (@all_relevant_notifiers) {
        my $notifier_str =
            join (', ',
                  map { "$_ => " .
                            (ref ($notifier->{$_}) ? join (',', @{ $notifier->{$_} }) : $notifier->{$_})
                  } keys %$notifier);
        DEBUG ("Using notifier: $notifier_str");

        # create (or re-use) a temporary file with the message
        # (content depends on the format in the notifier)
        my $format = $notifier->{format} || 'human';
        my $msgfile = $msg_files->{$format};
        unless ($msgfile) {
            $msgfile = File::Temp->new();
            my $outputter = Monitor::Simple::Output->new (outfile  => $msgfile,
                                                        'format' => $format,
                                                        config   => $self->{config});
            $outputter->header();
            $outputter->out ($result->{service}, $result->{code}, $result->{msg});
            $outputter->footer();
            close $msgfile;
            $msg_files->{$format} = $msgfile;   # remember this file for other notifiers
        }

        # execute an external notifier...
        my $command = $notifier->{command};
        unless (File::Spec->file_name_is_absolute ($command)) {
            my $notifiers_dir = $self->{config}->{general}->{'notifiers-dir'};
            if ($notifiers_dir) {
                $command = File::Spec->catfile ($notifiers_dir, $command);
            }
        }
        my @command = ($command, $self->create_notifier_args ($notifier,
                                                              $msgfile));
        DEBUG ("Calling notifier: " . join (' ', @command));
        my ($stdout, $stderr, $success, $exit_code) = capture_exec (@command);
        if ($success) {
            DEBUG ("Notification for '$notifier_str' successful." .
                   ($stderr ? " STDERR: $stderr" : '') .
                   ($stdout ? " STDOUT: $stdout" : ''));
        } else {
            ERROR ("Notification for '$notifier_str' failed: EXIT: $exit_code" .
                   ($stderr ? ", STDERR: $stderr" : '') .
                   ($stdout ? ", STDOUT: $stdout" : ''));
        }
    }
}

#-----------------------------------------------------------------
# Find and return an array with all relevant notifiers (both general
# and services specific) for the given $result which is a hashref with
# this content:
#
#    { service => $service_id,
#      code    => $code,
#      msg     => $msg }
#
# It also copies service ID from the $result into each returned
# notifier.
# -----------------------------------------------------------------
sub get_relevant_notifiers {
    my ($self, $result) = @_;

    my @all_relevant_notifiers = ();
    if (exists $self->{config}->{general}->{notifier}) {
        foreach my $notifier (@{ $self->{config}->{general}->{notifier} }) {
            push (@all_relevant_notifiers, $notifier)
                if $self->matching_code ($result->{code}, $notifier->{on});
        }
    }
    foreach my $service (@{ $self->{config}->{services} }) {
        next unless $result->{service} eq $service->{id};
        @all_relevant_notifiers = ()
            if exists $service->{'ignore-general-notifiers'};
        foreach my $notifier (@{ $service->{notifier} }) {
            push (@all_relevant_notifiers, $notifier)
                if $self->matching_code ($result->{code}, $notifier->{on});
        }
    }

    foreach my $notifier (@all_relevant_notifiers) {
        $notifier->{service} = $result->{service};
    }

    return @all_relevant_notifiers;
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub matching_code {
    my ($self, $code_from_result, $code_from_config) = @_;

    foreach my $code (split (m{\s*,\s*}, $code_from_config)) {
        next unless exists $Codes->{$code};
        next if $code eq Monitor::Simple::NOTIFY_NONE;
        return 1
            if $code eq Monitor::Simple::NOTIFY_ALL;
        return 1
            if $code_from_result == Monitor::Simple::RETURN_OK and $code eq Monitor::Simple::NOTIFY_OK;
        return 1
            if $code_from_result != Monitor::Simple::RETURN_OK and $code eq Monitor::Simple::NOTIFY_ERRORS;
        return 1
            if $code_from_result == Monitor::Simple::RETURN_WARNING and $code eq Monitor::Simple::NOTIFY_WARNING;
        return 1
            if $code_from_result == Monitor::Simple::RETURN_UNKNOWN and $code eq Monitor::Simple::NOTIFY_UNKNOWN;
        return 1
            if $code_from_result == Monitor::Simple::RETURN_CRITICAL and $code eq Monitor::Simple::NOTIFY_CRITICAL;
    }
    return 0;
}

#-----------------------------------------------------------------
# Extract proper command-line arguments for the given $notifier.
# Similar to Monitor::Simple::Config::create_plugin_args().
# -----------------------------------------------------------------
sub create_notifier_args {
    my ($self, $notifier, $msgfile) = @_;

    my @args = ();
    if (exists $notifier->{args}) {
        # args exists: use them
        push (@args, @{ $notifier->{args} });
    }

    # ...add email addresses (if any)
    my $emails = $self->extract_emails ($notifier);
    push (@args, '-emails', join (',', @$emails))
        if @$emails > 0;

    # ...and the default arguments
    push (@args, (  # '-cfg',      $self->{cfgfile},
                  '-service',  $notifier->{service},
                    # '-notifier', $notifier->{command},
                  '-msg',      $msgfile,
                  Monitor::Simple::Log->logging_args()));
    return @args;
}

# -----------------------------------------------------------------
# Extract all email addresses from the given notifier (and from the
# current $config). Return them as an arrayref (which may be empty but
# not undef). Make sure that there are no duplicates returned.
# -----------------------------------------------------------------
sub extract_emails {
    my ($self, $notifier) = @_;
    my @results = ();
    if (my $email = $notifier->{email}) {
        push (@results, split (m{\s*,\s*}, $email));
    }
    if (my $group = $notifier->{'email-group'}) {
        my @email_groups_in_notifier = split (m{\s*,\s*}, $group);
        if (my $email_groups_in_config = $self->{config}->{general}->{'email-group'}) {
            foreach my $eg (@email_groups_in_notifier) {
                foreach my $eg_in_config (@$email_groups_in_config) {
                    if ($eg_in_config->{id} eq $eg and $eg_in_config->{email}) {
                        push (@results, @{ $eg_in_config->{email} });
                        last;
                    }
                }
            }
        }
    }

#    return \@results;
    return [ keys %{{ map { $_ => 1 } @results }} ];   # removing duplicates
}


1;


=pod

=head1 NAME

Monitor::Simple::Notifier - See documentation in Monitor::Simple

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
