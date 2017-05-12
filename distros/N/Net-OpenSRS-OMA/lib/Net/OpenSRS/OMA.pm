package Net::OpenSRS::OMA::Response;  # internal package, defined below
1;
package Net::OpenSRS::OMA;

use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Carp;

our $VERSION = "0.02";
$VERSION = eval $VERSION;

=head1 NAME

Net::OpenSRS::OMA - Client library for the OpenSRS Mail API

=head1 SYNOPSIS

  use Data::Dumper;
  use Net::OpenSRS::OMA;

  my $oma = new Net::OpenSRS::OMA(
    uri => 'https://admin.a.hostedemail.com/api',
    user => 'admin@domain.adm',
    client => 'my client 0.1',
    password => 'abc123',
  );
    

  my $response = $oma->get_user(
    user => 'user@domain.com'
  );

  if ($response->is_success)
  {
    print Dumper $response->content;
  }
  elsif ($response->error)
  {
    print "Request didn't work at OMA level: " . $response->error . "\n";
  }
  else
  {
    print "Request didn't work at HTTP level: " . $response->http_status;
  }

=head1 DEPENDENCIES

This module requires these modules. 

=over

=item LWP::UserAgent

=item LWP::Protocol::https

=item JSON

=back

=head1 CAVEAT

This API is still under development and thus the 
method calls, arguments and functions are subject to change.

Consult the API documentation for up to date information.

=head1 METHODS

=cut

=head2 new

Create and return a new Net::OpenSRS::OMA object. 

Takes the following arguments (in a single hash argument)

  uri - base uri for the api: http://example.com/api/
  user - username  for authentication
  password - password for authentication
  token - token for authentication
  client - client identification string

uri, user and either password or token are required.

=cut

sub new($@) 
{
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %args = @_;
  my $self = {};
  unless ($args{uri} && $args{user} && 
      ($args{password} || $args{token} ))
  {
    warn('Need uri, user and password or token'); 
    return undef;
  }
  $self->{URI} = $args{uri};
  my $client = $args{client};
  $client = "Perl OMA Client\\$VERSION" unless $client;
  $self->{CREDENTIALS} = { 
    user => $args{user}, 
    client => $client
  };
  
  if ($args{password}) {$self->{CREDENTIALS}->{password} = $args{password}}
  else { $self->{CREDENTIALS}->{token} = $args{token}}

  $self->{UA} = LWP::UserAgent->new;
  $self->{UA}->agent($client);

  return bless($self, $class);
}

=head2 uri

Get the API address this object is using

=head2 user

Get the username this object is using

=head2 client

Get the client identifier string this object is using

=cut

sub uri($){return $_[0]->{URI}};
sub user($){return $_[0]->{CREDENTIALS}->{user}}
sub client($){return $_[0]->{CREDENTIALS}->{client}}

=head2 API Methods

API methods are called as object methods.  All methods take a hash argument, that hash has
a credentials hashref added, is converted to JSON and sent to the API.  Method calls return a
Net::OpenSRS::OMA::Response object containing the response from the server.

Consult the API documentation for the arguments and response formats for each method.

The callable methods are:

=over

=item add_role

=item authenticate

=item change_company

=item change_company_bulletin

=item change_domain

=item change_domain_bulletin

=item change_user

=item change_brand

=item create_workgroup

=item delete_company

=item delete_domain

=item delete_user

=item delete_workgroup

=item echo

=item generate_token

=item get_company

=item get_company_bulletin

=item get_company_changes

=item get_deleted_contacts

=item get_deleted_messages

=item get_domain

=item get_domain_bulletin

=item get_domain_changes

=item get_user

=item get_user_attribute_history

=item get_user_changes

=item get_user_folders

=item get_user_messages

=item get_valid_languages

=item get_valid_timezones

=item logout_user

=item migration_add

=item migration_jobs

=item migration_status

=item migration_threads

=item migration_trace

=item move_user_messages

=item post_domain_bulletin

=item post_company_bulletin

=item remove_role

=item rename_user

=item restore_deleted_contacts

=item restore_deleted_messages

=item restore_domain

=item restore_user

=item search_brand_members

=item search_brands

=item search_companies

=item search_domains

=item search_users

=item search_workgroups

=item set_role

=item stats_summary

=item stats_list

=item stats_snapshot

=back

=cut

my @_methods = qw(
add_role
authenticate
change_company
change_company_bulletin
change_domain
change_domain_bulletin
change_user
change_brand
create_workgroup
delete_company
delete_domain
delete_user
delete_workgroup
echo
generate_token
get_company
get_company_bulletin
get_company_changes
get_deleted_contacts
get_deleted_messages
get_domain
get_domain_bulletin
get_domain_changes
get_user
get_user_attribute_history
get_user_changes
get_user_folders
get_user_messages
get_valid_languages
get_valid_timezones
logout_user
migration_add
migration_jobs
migration_status
migration_threads
migration_trace
move_user_messages
post_domain_bulletin
post_company_bulletin
remove_role
rename_user
restore_deleted_contacts
restore_deleted_messages
restore_domain
restore_user
search_brand_members
search_brands
search_companies
search_domains
search_users
search_workgroups
set_role
stats_summary
stats_list
stats_snapshot
);

my @_deprecated_methods = qw(
_audit
_change_brand
_delete_brand
_get_brand
_get_brand_changes
_get_brand_trace
_get_company_trace
_get_domain_trace
_get_user_trace
_id_to_name
_list_brand_traces
_list_company_traces
_list_domain_traces
_list_user_traces
_name_to_id
);

our $AUTOLOAD;
sub AUTOLOAD {
  return if our $AUTOLOAD =~ /::DESTROY$/;
  my $self = shift;
  my $sub = $AUTOLOAD;
  (my $method = $sub) =~ s/.*:://;
  unless (grep {$_ eq $method} (@_methods, @_deprecated_methods))
  {
    croak("Undefined method $AUTOLOAD");
  }
  my %body = @_;
  return $self->_do_method($method, \%body);
}


#
# don't call this
#
sub _do_method($$$)
{
  my ($self, $method, $body) = @_;
  my $muri = $self->{URI} . '/' . $method;

  # create request body (add credentials)
  my %body_copy = %$body;
  $body_copy{'credentials'} = $self->{'CREDENTIALS'};
  my $body_text = to_json(\%body_copy);

  # create request
  my $request = HTTP::Request->new(POST => $muri);
  $request->content_type('application/json');
  $request->content($body_text);

  #send request
  my $response = $self->{UA}->request($request);

  # deal with response
  if ($response->is_success)
  {
    my $j;
    eval {$j = from_json($response->content)}; 
    if ($@)
    {
      warn "Invalid JSON from API: -(" . $response->content . ")-";
      $j = '';
    }
    return new Net::OpenSRS::OMA::Response(
      status => $response->status_line,
      raw_content => $response->content,
      content => $j,
      );
  }
  else
  {
    return new Net::OpenSRS::OMA::Response(
      status => $response->status_line,
    );
  }
}


1;

package Net::OpenSRS::OMA::Response;


=head1 RESPONSE OBJECT METHODS

=cut

sub new($@)
{
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %args = @_;
  my $self = {};
  $self->{CONTENT} = $args{content} if $args{content};
  $self->{RAW_CONTENT} = $args{raw_content} if $args{raw_content};
  $self->{HTTP_STATUS} = $args{status} if $args{status};
  return bless($self, $class);
}

=head2 is_success

Returns true if the HTTP status of the request was 200, the response had valid
JSON content, and the 'success' field of the response is true.

=cut
sub is_success($)
{
  my $self = shift;
  return  
    $self->{HTTP_STATUS} =~ /^200/ &&
    $self->{CONTENT} && 
    $self->{CONTENT}->{success} ;
}

=head2 content

Returns a hashref, the decoded JSON content of the response, or undef if 
there is no content.

=cut

sub content($) {return $_[0]->{CONTENT}};

=head2 raw_content

Returns a scalar, string, the raw response fromt he server, or undef if
there is no content

=cut

sub raw_content($) {return $_[0]->{RAW_CONTENT}};

=head2 http_status

Returns a scalar, the HTTP status of the request, from the LWP module.

=cut

sub http_status($) {return $_[0]->{HTTP_STATUS}};

=head2 error_number

Returns a scalar, the error number from the JSON content of the response,
or undef if no error number.

=cut

sub error_number($) {return $_[0]->{CONTENT}->{error_number}};

=head2 error

Returns a scalar, the error string from the JSON content of the response,
or undef if no error string.

=cut

sub error($) {return $_[0]->{CONTENT}->{error}};

1;

=head1 AUTHOR

Richard Platel <rplatel@opensrs.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 Richard Platel <rplatel@opensrs.org>

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
 
=cut
