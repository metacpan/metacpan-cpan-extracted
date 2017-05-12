=head1 NAME

Monitoring::Icinga - An object oriented interface to Icinga

=head1 SYNOPSIS

Simple example:

  use Monitoring::Icinga;
  
  my $api = Monitoring::Icinga->new(
      AuthKey => 'ThisIsTheAuthKey'
  );
  
  $api->set_columns('HOST_NAME', 'HOST_OUTPUT', 'HOST_CURRENT_STATE');
  my $hosts = $api->get_hosts(1,2);

This will query the Icinga Web REST API on localhost. $hosts is an array
reference containing the information for every host object, which is currently
is DOWN (1) or UNREACHABLE (2).

=head1 DESCRIPTION

This module implements an object oriented interface to Icinga using its REST
API. It is tested with the Icinga Web REST API v1.2 only, so sending commands
via PUT is not yet supported (but will be in the future).

=head1 METHODS

=cut

package Monitoring::Icinga;

use strict;
use warnings;
use Carp qw(carp croak);
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use JSON::XS;

our $VERSION = '0.02';


=over

=item new (%config)

Constructor. You can set the following parameters during construction:

  BaseURL             - The URL pointing to the Icinga REST API (default: 'http://localhost/icinga-web/web/api').
  AuthKey             - The Auth key to use (mandatory)
  Target              - 'host' or 'service' (default: 'host')
  Columns             - List (array) of columns to return from API calls
  Filters             - API filter as a hash reference
  ssl_verify_hostname - Verify the SSL hostname. Sets the 'verify_hostname' option of LWP::UserAgent (default: 1)

Example, that returns a hash reference containing some data of all hosts
whose state is 1 (that means: WARNING):

  my $api = Monitoring::Icinga->new(
      BaseURL      => 'https://your.icinga.host/icinga-web/web/api',
      AuthKey      => 'ThisIsTheAuthKey',
      Target       => 'host',
      Filters      => {
          'type'  => 'AND',
          'field' => [
              {   
                  'type'   => 'atom',
                  'field'  => [ 'HOST_CURRENT_STATE' ],
                  'method' => [ '=' ],
                  'value'  => [ 1 ],
              },
          ],
      },
      Columns      => [ 'HOST_NAME', 'HOST_OUTPUT', 'HOST_CURRENT_STATE' ],
  );
  
  my $result = $api->call;

You can recall the setters to thange the parameters, filters and columns for
later API calls.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};

    return undef unless defined $args{'AuthKey'};

    $self->{'baseurl'}             = $args{'BaseURL'}             || 'http://localhost/icinga-web/web/api';
    $self->{'authkey'}             = $args{'AuthKey'};
    $self->{'ssl_verify_hostname'} = $args{'ssl_verify_hostname'} || 1;
    $self->{'params'}              = [];

    bless ($self, $class);

    # Initialize some values
    $self->set_target( ($args{'Target'} ? $args{'Target'} : 'host') );
    $self->set_filters($args{'Filters'})    if $args{'Filters'};

    # Initialize columns
    if ($args{'Columns'}) {
        $self->set_columns(@{$args{'Columns'}});
    }
    else {
        # Set some default columns
        $self->set_columns('HOST_NAME', 'SERVICE_NAME');
    }

    # Construct the complete URL
    $self->{'url'} = $self->{'baseurl'} . '/authkey=' . $self->{'authkey'} . '/json';

    # Exit if HTTPS requested, but LWP::Protocol::https not found
    if ($self->{'baseurl'} =~ /^https:/i) {
        eval {
            require LWP::Protocol::https;
        };
        croak 'Error: HTTPS requested, but module \'LWP::Protocol::https\' not installed.' if $@;
    }

    # Prepare the LWP::UserAgent object for later use
    $self->{'ua'} = LWP::UserAgent->new( ssl_opts => { verify_hostname => $self->{'ssl_verify_hostname'} } );
    $self->{'ua'}->agent('Monitoring::Icinga/' . $VERSION . ' ');

    return $self;
}


=item set_target ($value)

Set target for API call. Can be 'host' or 'service'. See Icinga Web REST API
Documentation at http://docs.icinga.org/latest/en/icinga-web-api.html for
details on allowed targets.

=cut

sub set_target {
    my ($self, $target) = @_;
    unless (defined $target and ($target eq 'host' or $target eq 'service')) {
        carp 'Invalid target specified';
        return 0;
    }

    $self->{'target'} = [];
    push @{$self->{'target'}}, 'target';
    push @{$self->{'target'}}, $target;
}


=item set_columns (@array)

Set columns that get returned by a call. The parameters are a list of columns.
For a list of valid columns, see the source code of Icinga Web at:

  app/modules/Api/models/Store/LegacyLayer/TargetModifierModel.class.php

Example:

  $api->set_columns('HOST_NAME', 'HOST_CURRENT_STATE', 'HOST_OUTPUT');

=cut

sub set_columns {
    my ($self, @columns) = @_;

    my $columncount = 0;
    $self->{'columns'} = [];
    foreach (@columns) {
        push @{$self->{'columns'}}, 'columns[' . $columncount . ']';
        push @{$self->{'columns'}}, $_;
        $columncount++;
    }
}


=item set_filters ($hash_reference)

Set filters for API call using a hash reference. See Icinga Web REST API
Documentation at http://docs.icinga.org/latest/en/icinga-web-api.html for
details on how filters need to be defined. Basically, they define it in JSON
syntax, but this module requires a Perl hash reference instead.

Simple Example:

  $api->set_filters( {
      'type'  => 'AND',
      'field' => [
          {   
              'type'   => 'atom',
              'field'  => [ 'HOST_CURRENT_STATE' ],
              'method' => [ '>' ],
              'value'  => [ 0 ],
          },
      ],
  } );

More complex example:

  $api->set_filters( {
      'type' => 'AND',
      'field' => [
          {
              'type' => 'atom',
              'field' => [ 'SERVICE_NAME' ],
              'method' => [ 'like' ],
              'value' => [ '*pop*' ],
          },
          {  
              'type' => 'OR',
              'field' => [
                  {
                      'type' => 'atom',
                      'field' => [ 'SERVICE_CURRENT_STATE' ],
                      'method' => [ '>' ],
                      'value' => [ 0 ],
                  },
                  {   
                      'type' => 'atom',
                      'field' => [ 'SERVICE_IS_FLAPPING' ],
                      'method' => [ '=' ],
                      'value' => [ 1 ],
                  },
              ],
          },
      ],
  };

You don't actually need a filter for the API calls to work. But it is strongly
recommended to define one whenever you fetch any data. Otherwise ALL host or
service objects will be returned.

By the way: You should filter for host or service objects, not both. Otherwise
you will most likely not get the results you want. I.e. if you want to get all
hosts and services with problems, you better do two API calls. One for the
hosts, another for the services.

=cut

sub set_filters {
    my ($self, $filters) = @_;
    my $json_data;
    eval {
        $json_data = encode_json($filters);
    };
    if ($@) {
        chomp $@;
        carp 'JSON ERROR: '.$@;
        return 0;
    }
    else {
        $self->{'filters'} = [];
        push @{$self->{'filters'}}, 'filters_json';
        push @{$self->{'filters'}}, $json_data;
    }
}


=item get_hosts (@states)

Return an array of all host objects matching the specified states. The
parameters can be:

  0 - OK
  1 - DOWN
  2 - UNREACHABLE

You should set the desired columns first, using either the Columns parameter of
the constructor or the set_columns() function, i.e.:

  $api->set_columns('HOST_NAME', 'HOST_CURRENT_STATE', 'HOST_OUTPUT');
  $hosts_array = $api->get_hosts(1,2);

That would return the name, state and check output of all hosts in state DOWN
or UNREACHABLE.

=cut

sub get_hosts {
    my ($self, @states) = @_;
    return $self->_get('host', @states);
}


=item get_services (@states)

Return an array of all service objects matching the specified states. The
parameters can be:

  0 - OK
  1 - WARNING
  2 - CRITICAL
  3 - UNKNOWN

You should set the desired columns first, using either the Columns parameter of
the constructor or the set_columns() function, i.e.:

  $api->set_columns('HOST_NAME', 'SERVICE_NAME', 'HOST_CURRENT_STATE', 'HOST_OUTPUT');
  $services_array = $api->get_services(1,2,3);

That would return the host name, service name, state and check output of all
services in state WARNING, CRITICAL or UNKNOWN.

=cut

sub get_services {
    my ($self, @states) = @_;
    return $self->_get('service', @states);
}


=item call

Do an API call using the current settings (Target, Columns and Filters) and
return the complete result as a hash reference. The data you usually want is in
$hash->{'result'}.

=cut

sub call {
    my $self = shift;

    my @params;
    push @params, @{$self->{'target'}};
    push @params, @{$self->{'columns'}};
    push @params, @{$self->{'filters'}};

    my $api_request = POST $self->{'url'}, \@params;
    my $api_result = $self->{'ua'}->request($api_request);
    my $content_type = $api_result->headers->header('Content-Type');

    if ($content_type =~ /^application\/json/) {
        # We got a (hopefully) correct answer
        my $api_result_hash = decode_json($api_result->content);
        return $api_result_hash;
    }
    elsif ($content_type =~ /^text\/html/) {
        # We got an error from the API
        my $errormsg = 'unknown error';
        foreach (split(/\n/, $api_result->content)) {
            #    SQLSTATE[42S22]: Column not found: 1054 Unknown column 'i.service_has_been_acknowleged' in 'field list'                        </div>
            $errormsg = $1 if $_ =~ /(SQLSTATE\[.*\]: .*)<\/div>/;
            $errormsg =~ s/\s+$//g;
        }
        carp 'JSON ERROR: ' . $errormsg;
        return undef;
    }
}


sub _get {
    my ($self, $target, @states) = @_;
    unless (defined $target and ($target eq 'host' or $target eq 'service')) {
        carp 'No valid target given';
        return undef;
    }
    unless (scalar @states) {
        carp 'No state given';
        return undef;
    }

    my $field = 'HOST_CURRENT_STATE';
    $field = 'SERVICE_CURRENT_STATE' if $target eq 'service';

    my $filters = {
        'type'  => 'OR',
        'field' => [],
    };

    foreach my $state (@states) {
        if ($target eq 'host' and $state !~ /^[012]$/) {
            carp 'Unknown host state: ' . $state;
            next;
        }
        if ($target eq 'service' and $state !~ /^[0123]$/) {
            carp 'Unknown service state: ' . $state;
            next;
        }

        my $subfilter = {
            'type'   => 'atom',
            'field'  => [ $field ],
            'method' => [ '=' ],
            'value'  => [ $state ],
        };

        push @{$filters->{'field'}}, $subfilter;
    }

    # Remember the original values to restore them later
    my $temp = {};
    $temp->{'target'}  = $self->{'target'};
    $temp->{'filters'} = $self->{'filters'};

    # Set appropriate values for this call
    $self->set_target($target);
    $self->set_filters($filters);

    # Do the call
    my $result = $self->call;

    # Restore the original values
    $self->{'target'}  = $temp->{'target'};
    $self->{'filters'} = $temp->{'filters'};

    return $result->{'result'} if $result->{'success'};
    carp 'API Error: ' . $result->{'result'} if $result->{'result'};
    return undef;
}

1;

__END__

=back

=head1 AUTHOR

Robin Schroeder, E<lt>schrorg@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Robin Schroeder

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.10 or, at your option, any
later version of Perl 5 you may have available.

=cut
