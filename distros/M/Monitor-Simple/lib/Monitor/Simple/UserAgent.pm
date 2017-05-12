#-----------------------------------------------------------------
# Monitor::Simple::UserAgent
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# ABSTRACT: See documentation in Monitor::Simple
# PODNAME: Monitor::Simple::UserAgent
#-----------------------------------------------------------------

package Monitor::Simple::UserAgent;
use warnings;
use strict;
use LWP::UserAgent;
use Monitor::Simple;
use Log::Log4perl qw(:easy);

our $VERSION = '0.2.8'; # VERSION

#-----------------------------------------------------------------
# Create and return a user agent HTTP header.
#-----------------------------------------------------------------
sub _get_agent_name {
    my ($self, $plugin_name) = @_;
    my $name =
        'User-Agent: Monitor_Simple' . ($plugin_name ? "_$plugin_name" : '') . ' (nagios-plugin)';
    return $name;
}

#-----------------------------------------------------------------
# Create and return an LWP::UserAgent instance, potentially filled by
# properties from the given $service_config for the given test (whose
# properties are defined in $test_config).
# -----------------------------------------------------------------
sub _get_agent {
    my ($self, $service_id, $service_config, $test_config) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent ($self->_get_agent_name ($service_config->{plugin}->{command}));
    if (defined $test_config->{timeout}) {
        if (! Monitor::Simple::Utils->is_integer ($test_config->{timeout})) {
            Monitor::Simple::Utils->report_and_exit ($service_id, undef,
                                                     Monitor::Simple::RETURN_WARNING,
                                                     'Test cannot be executed (a non-integer value in timeout)');
        }
        $ua->timeout ($test_config->{timeout});
    }
    # add here more properties from $config to $ua - as we need them

    return $ua;
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub head_or_exit {
    my ($self, $service_id, $full_config) = @_;
    my $config = Monitor::Simple::Utils->service_config_or_exit ($service_id, $full_config);

    # warn (and exit) if the test cannot be executed
    unless (exists $config->{plugin}->{'head-test'}) {
        # a warning: test ignored
        Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                               Monitor::Simple::RETURN_WARNING,
                                               'HEAD test(s) ignored');
    }
    foreach my $headtest (@{ $config->{plugin}->{'head-test'} }) {
        unless ($headtest->{url}) {
            # a warning: test cannot be executed
            Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                   Monitor::Simple::RETURN_WARNING,
                                                   'HEAD test cannot be executed (missing URL parameter)');
        }

        # make the test
        my $ua = $self->_get_agent ($service_id, $config, $headtest);
        DEBUG ("Invoking HTTP HEAD: " . $headtest->{url});
        my $response = $ua->head ($headtest->{url});

        # an error: report it and exit accordingly
        unless ($response->is_success) {
            Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                   Monitor::Simple::RETURN_CRITICAL,
                                                   $response->status_line() . ' - ' . $headtest->{url});
        }
    }

    # everything is okay
    return;
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub post_or_exit {
    my ($self, $service_id, $full_config) = @_;
    my $config = Monitor::Simple::Utils->service_config_or_exit ($service_id, $full_config);

    # warn (and exit) if the test cannot be executed
    unless (exists $config->{plugin}->{'post-test'}) {
        # a warning: test ignored
        Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                               Monitor::Simple::RETURN_WARNING,
                                               'POST test(s) ignored');
    }
    foreach my $posttest (@{ $config->{plugin}->{'post-test'} }) {
        unless ($posttest->{url}) {
            # a warning: test cannot be executed
            Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                   Monitor::Simple::RETURN_WARNING,
                                                   'POST test cannot be executed (missing URL parameter)');
        }
        my $content = $posttest->{data};
        unless (defined $content) {
            # a warning: test cannot be executed - no input data
            Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                   Monitor::Simple::RETURN_WARNING,
                                                   'POST test cannot be executed (missing input data)');
        }

        # make the test
        my $ua = $self->_get_agent ($service_id, $config, $posttest);
        DEBUG ("Invoking HTTP POST: " . $posttest->{url});
        my $response = $ua->post ($posttest->{url}, Content => $content);

        $self->process_response ($response, { service_id => $service_id,
                                              config     => $full_config,
                                              test       => $posttest });
    }

    # everything is okay
    return;
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub get_or_exit {
    my ($self, $service_id, $full_config) = @_;
    my $config = Monitor::Simple::Utils->service_config_or_exit ($service_id, $full_config);

    # warn (and exit) if the test cannot be executed
    unless (exists $config->{plugin}->{'get-test'}) {
        # a warning: test ignored
        Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                               Monitor::Simple::RETURN_WARNING,
                                               'GET test(s) ignored');
    }
    foreach my $gettest (@{ $config->{plugin}->{'get-test'} }) {
        unless ($gettest->{url}) {
            # a warning: test cannot be executed
            Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                   Monitor::Simple::RETURN_WARNING,
                                                   'GET test cannot be executed (missing URL parameter)');
        }

        # make the test
        my $ua = $self->_get_agent ($service_id, $config, $gettest);
        DEBUG ("Invoking HTTP GET: " . $gettest->{url});
        my $response = $ua->get ($gettest->{url});

        $self->process_response ($response, { service_id => $service_id,
                                              config     => $full_config,
                                              test       => $gettest });
    }

    # everything is okay
    return;
}

#-----------------------------------------------------------------
# $args: { service_id => $service_id,
#          config     => $config,
#          test       => $test }
#-----------------------------------------------------------------
sub process_response {
    my ($self, $response, $args) = @_;
    my $full_config = $args->{config};
    my $test = $args->{test};
    my $service_id = $args->{service_id};

    # error: report it and exit accordingly
    unless ($response->is_success) {
        Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                 Monitor::Simple::RETURN_CRITICAL,
                                                 $response->status_line() . ' - ' . $test->{url});
    }

    # optionally make more tests on the returned data
    if (exists $test->{response}) {
        # have we got an expected Content-Type?
        my $expected_content_type = $test->{response}->{'content-type'};
        if ($expected_content_type and $expected_content_type ne $response->content_type) {
            Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                     Monitor::Simple::RETURN_WARNING,
                                                     'Unexpected Content-Type returned: ' . $response->content_type);
        }
        # have we got an expected content?
        my $expected = $test->{response}->{contains};
        if (defined $expected) {
            foreach my $content (@$expected) {
                my $quoted = quotemeta ($content);
                if ($response->content !~ m{$quoted}) {
                    Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                             Monitor::Simple::RETURN_WARNING,
                                                             "Returned content does not contain: $content");
                }
            }
        }
        # have we got an exact content?
        $expected = $test->{response}->{equal};
        if (defined $expected) {
            $expected =~ s{^\s*|\s*$}{}g;
            if (defined $expected) {
                my $obtained_value = $response->content;
                $obtained_value =~ s{^\s*|\s*$}{}g;
                if ($obtained_value ne $expected) {
                    Monitor::Simple::Utils->report_and_exit ($service_id, $full_config,
                                                             Monitor::Simple::RETURN_WARNING,
                                                             "Returned content is not equal to expected value: $obtained_value <=> $expected");
                }
            }
        }
    }
    return;
}


1;


=pod

=head1 NAME

Monitor::Simple::UserAgent - See documentation in Monitor::Simple

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
