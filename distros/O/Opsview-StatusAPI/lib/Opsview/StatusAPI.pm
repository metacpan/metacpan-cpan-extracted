package Opsview::StatusAPI;

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

Opsview::StatusAPI - Module to help you query the Opsview Status API

=head1 SYNOPSIS

  use Opsview::StatusAPI;
  
  my $api = Opsview::StatusAPI->new(
    'user' => 'opsview_user',
    'password' => 'opsview_password',
    'host' => 'opsview.example.com',
    'secure' => 1
  );

  my $status = $api->hostgroup();

=head1 DESCRIPTION

This module queries the Opsview Status API for you, returning data structures as appropiate. 

Documetation of the Status API is here: http://docs.opsview.com/doku.php?id=opsview-community:api

Note: this module only queries the "status API", it doesn't understand about the API to create/delete objects

Note2: the data structures returned are only deserialized by this module. Different versions of Opsview
may return different data structures.

=cut

use strict;
use warnings;
use Carp;
use HTTP::Request;
use LWP::UserAgent;
use JSON::Any;

our $VERSION = '0.02';

our $states = { 'ok' => 0, 'warning' => '1', 'critical' => '2', 'unknown' => '3' };

=head1 CONSTRUCTOR

=head2 new(user => 'user', 'password' => 'pass', 'host' => 'host.name.com', secure => [0|1])

Create the object. Only the host parameter is required. If not specified, the constructor will die.

Optionally you can pass secure => 1 to make the object access the status API via HTTPS

=cut

sub new {
  my ($class, %params) = @_;
  $params{'secure'} = 0 if (not defined $params{'secure'});
  croak "Must specify host" if (not defined $params{'host'});

  my $self = { %params };

  bless $self, $class;

  $self->{'_url'} = $self->_get_url();
  $self->{'_ua'} = LWP::UserAgent->new;
  $self->{'_json'} = JSON::Any->new;

  return $self;
}

sub _get_url {
  my $self = shift;
  return sprintf('%s://%s/api/status/', ($self->{'secure'}==1?'https':'http'), $self->{'host'});
}

sub _dorequest {
  my ($self, $url) = @_;

  croak "Must specify user" if (not defined $self->{'user'});
  croak "Must specify password" if (not defined $self->{'password'});

  my $req = HTTP::Request->new( GET => $url );
  $req->header( 'Content-Type' => 'text/json' );
  $req->header( 'X-Username' => $self->{'user'} );
  $req->header( 'X-Password' => $self->{'password'} );
  
  my $res = $self->{'_ua'}->request($req);
  if ($res->is_success){
    return ($self->{'_json'}->decode($res->content));
  } else {
    die sprintf('Response from host: \'%s\' for \'%s\'', $res->status_line, $url);
  }
}

sub _resolve_filter {
  my ($self, $filter) = @_;
  my $params = '';
  if (ref($filter) eq 'SCALAR') {
    $params = $filter;
  } elsif (ref($filter) eq 'HASH'){
    if ((defined $filter->{'state'}) && (defined $states->{ $filter->{'state'} })) {
      $filter->{'state'} = $states->{ $filter->{'state'} };
    }
    my $q = join '&', map {
       if (ref($filter->{$_}) eq 'ARRAY'){
          my $key = $_;
          join '&', map { "$key=$_" } @{ $filter->{$_} }
       } else {
          "$_=$filter->{$_}";
       }
    } keys %$filter;
    $params = "?$q" if ($q);
  }
  return $params;
}

=head1 METHODS

=head2 host($hostname [, $filter])

retrieve monitoring information for $hostname. Additionally apply a filter.

This is really a shortcut for:

  $api->service({'host' => $hostname, ...filter... })

=cut

sub host {
  my ($self, $host, $filter) = @_;
  croak "must specify host" if (not defined $host);
  my $params = $self->_resolve_filter({ (defined $filter)?%$filter:() , host => $host });
  return $self->_dorequest("$self->{'_url'}service$params");
}

=head2 user([$value])

Set/Retrieve the user for the API.

=cut

sub user {
  my ($self, $value) = @_;
  $self->{'user'} = $value if (defined $value);
  return $self->{'user'};
}

=head2 password([$value])

Set/Retrieve the password for the API.

=cut

sub password {
  my ($self, $value) = @_;
  $self->{'password'} = $value if (defined $value);
  return $self->{'password'};
}


=head2 service($filter)

=head2 service()

If called without parameters, will return info for all services.
See FILTERS for information on how 

The returned data structure will be something like this:

    {  'service' => {
         'summary' => {
           'handled' => 15,
           'unhandled' => 0,
           'service' => {
             'ok' => 14,
             'handled' => 14,
             'unhandled' => 0,
             'total' => 14
           },
           'total' => 15,
           'host' => {
             'handled' => 1,
             'unhandled' => 0,
             'up' => 1,
           'total' => 1
         }
       },
      'list' => [
        { 'icon' => 'debian',
          'summary' => {
            'handled' => 14,
            'unhandled' => 0,
            'total' => 14
          },
          'unhandled' => '0',
          'downtime' => 0,
          'name' => 'servername.example.com',
          'alias' => 'Description of the server',
          'state' => 'up'
          'services' => [
            { 'max_check_attempts' => '3',
              'state_duration' => 5893554,
              'name' => '/',
              'output' => 'DISK OK - free space: / 12207 MB (42% inode=-):',
              'current_check_attempt' => '1',
              'state' => 'ok',
              'service_object_id' => '176',
              'unhandled' => '0',
              'downtime' => 0,
              'last_check' => '2010-06-02 00:32:20',
              'perfdata_available' => '1'
            },
            ... one hashref for each service in the host ...
          ]
        },
        ... one hashref for each host returned ...
      ]
    }

=cut

sub service {
  my ($self, $filter) = @_;
  my $params = $self->_resolve_filter($filter);
  return $self->_dorequest("$self->{'_url'}service$params")->{'service'};
}

=head2 hostgroup()

=head2 hostgroup($hostgroup_id)

If called without parameters, it will return the information about the root hostgroup. 
If hostgroup_id is passed, it will return information about the hostgroup with that ID.

The returned data structure will be something like this:

    { 'summary' => {
        'handled' => 20,
        'unhandled' => 2,
        'service' => {
            'ok' => 14,
            'critical' => 2,
            'handled' => 16,
            'unhandled' => 2,
            'warning' => 4,
            'total' => 18
        },
        'total' => 20,
        'host' => {
            'handled' => 2,
            'unhandled' => 0,
            'up' => 2,
            'total' => 2
        }
      },
      'list' => [
        {   'hosts' => {
              'handled' => 1,
              'unhandled' => 0,
              'up' => {
                'handled' => 1
              },
              'total' => 1
            },
            'hostgroup_id' => '3',
            'services' => {
              'ok' => {
                'handled' => 3
              },
              'handled' => 3,
              'highest' => 'warning',
              'unhandled' => 1,
              'warning' => {
                'unhandled' => 1
              },
              'total' => 4
            },
            'downtime' => undef,
            'name' => 'Hostgroup Name'
        },
        ...
      ]
    }

=cut

sub hostgroup {
  my ($self, $hg_id) = @_;
  
  $hg_id = '' if (not defined $hg_id);
  return $self->_dorequest("$self->{'_url'}hostgroup/$hg_id")->{'hostgroup'};
}

=head1 FILTERS

A filter is a hashref that can contain the following keys with these values:

  hostgroupid => id, # the id of a hostgroup
  host => 'host',    # the name of a host
  state => 0, 1, 2, 3, 'ok, 'warning', 'critical', 'unknown' # 0 == 'ok', 3 == 'unknown'
  filter => 'handled' | 'unhandled' # filter by handled or unhandled services

  If you want all unhandled warnings, the filter would be

  { 'filter' => 'unhandled', 'state' => 'warning' }

  keys can also have multiple values: if you want only WARNINGS and CRITICALS

  { 'state' => [ 1, 2 ] } 

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com
    http://www.pplusdomain.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

http://www.opsview.org/

http://docs.opsview.com/doku.php?id=opsview-community:api

=cut


1;
