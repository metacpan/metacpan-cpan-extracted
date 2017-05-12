use strict;
use warnings;
package Net::CronIO;
{
  $Net::CronIO::VERSION = '0.01';
}

# ABSTRACT: Perl binding for cron.io

use Net::HTTP::API;
use Carp qw(croak);


net_api_declare cronio => (
    api_base_url    => 'http://api.cron.io/v1',
    api_format      => 'json',
    api_format_mode => 'content-type',
    authentication  => 1,
);


net_api_method create_user => (
    description => "Sign up for service and get a username/password",
    method => "POST",
    path => '/users',
    params => [qw(email username password)],
    required => [qw(email username password)],
    expected => [qw(201)],
);


net_api_method get_all_crons => (
    description => "List all the crons you have. Requires authentication.",
    method => "GET",
    path => '/crons',
    authentication => 1,
);


net_api_method create_cron => (
    description => "Create a new cron entry for your account. Requires authentication.",
    method => "POST",
    path => '/crons',
    params => [qw(name url schedule)],
    required => [qw(name url schedule)],
    authentication => 1,
);


net_api_method get_cron => (
    description => "List a specific cron entry. Requires a cron id and authentication.",
    method => "GET",
    path => '/crons/:id',
    params => [qw(id)],
    required => [qw(id)],
    authentication => 1,
);


net_api_method update_cron => (
    description => "Update a cron entry. Requires cron id and authentication.",
    method => "PUT",
    path => '/crons/:id',
    params => [qw(id name url schedule)],
    required => [qw(id)],
    authentication => 1,
);


net_api_method delete_cron => (
    descripton => "Delete a cron entry. Requires cron id and authentication.",
    method => "DELETE",
    path => '/crons/:id',
    params => [qw(id)],
    required => [qw(id)],
    expected => [qw(204)],
    authentication => 1,
);

around 'delete_cron' => sub {
    my $orig = shift;
    my $self = shift;

    my ($content, $response) = $self->$orig(@_);

    if ( $response->is_success ) {
        return 1;
    }
    else {
        croak $response->status_line;
    }
};

around 'create_user' => sub {
    my $orig = shift;
    my $self = shift;

    my ($content, $response) = $self->$orig(@_);

    if ( $response->is_success ) {
        return $content->{'message'};
    }
    else {
        croak $response->status_line . ": " . $response->content;
    }
};

1;


__END__
=pod

=head1 NAME

Net::CronIO - Perl binding for cron.io

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use 5.014;
  use Net::CronIO;

  my $cron = Net::CronIO->new(
      api_username => 'example',
      api_password => 'sekrit',
  );

  my $newjob = $cron->create_cron(
      name => 'Daily clean up job',
      url => 'http://example.com/blahblah/?cleanup=1',
      schedule => '46 0 * * *',
  );

  my $jobs = $cron->get_all_crons();

  foreach my $job ( $jobs ) {
      if ( $job->{'url'} =~ /deadhost.com/ ) {
          $cron->update_cron(
            id => $job->{'id'},
            url => $job->{'url'} =~ s/deadhost\.com/example\.com/r,
          );
      }
  }
  
  say "deleted" if ( $cron->delete_cron( id => $jobs->[0]->{'id'} ) );

This is a Perl binding for the L<cron.io|http://cron.io> service.  Cron is a Unix service which
executes jobs on a periodic basis. The cron.io service contacts URLs using the same
time period specification.

At the moment, the only way to generate a username and password for the service is by making 
a call on the C<create_user()> method.  Email verification is required before the 
credentials are valid.

=head1 ATTRIBUTES

=head2 api_username

You must supply an C<api_username> for every method except C<create_user()>.  This can be done at
object construction time, or later by calling the C<api_username()> method.

=head2 api_password

You must supply an C<api_password> for every method except C<create_user()>.  This can be done at
object construction time, or later by calling the C<api_username()> method.

=head1 METHODS

=head2 create_user()

This method requires the following parameters: C<email>, C<username>, C<password>. This call will register
a username/password with the service.  Human intervention (in the form of an email verification) is required
before your username/password are activated.

Once these credentials are active, you must provide them to this binding to execute other methods.

The return value is a string message provided by the API service (which evaluates to
a true value in Perl.)  This method dies on errors.

=head2 get_all_crons()

This method returns an arrayref containing hashes of all cron jobs for your username.

Hashes will contain the following keys:

=over

=item * C<id>

This is an internal ID used by the service to identify a specific cron job.  It is a required
parameter for most of the other methods.

=item * C<name>

This is the name you assigned to a specific job.

=item * C<url>

The URL to contact at the given schedule specification.

=item * C<schedule>

This is a standard Unix cron style specification.  See L<cron|http://en.wikipedia.com/wiki/Cron> on Wikipedia
for a verbose description of this format.

=back

It is possible this call will return a reference to an empty list.

=head2 create_cron()

This method creates a new job.  Required parameters are C<name>, C<url>, C<schedule>.

The return value is a hash of C<id>, plus the three params you provided.

=head2 get_cron()

This method retrieves a specific job by its C<id>.  C<id> is a required parameter for this
method.  The return value is a hash as described above.

=head2 update_cron()

This method changes values with jobs which already have ids. C<id> is a required parameter.
Optional parameters are any or all of C<name>, C<url>, and/or C<schedule>.

=head2 delete_cron()

This method removes a job from the service. C<id> is a required parameter.  On success, this
method returns a true value.  It dies on errors.

=head1 TESTING NOTE

To execute the full test suite, you must set CRONIO_API_USERNAME and CRONIO_API_PASSWORD environment 
variables with valid credentials.

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

