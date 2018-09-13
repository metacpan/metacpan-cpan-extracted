package Net::OneSky;
$Net::OneSky::VERSION = '0.0.1';
use strict;
use warnings;

use namespace::autoclean;
use Moose;

use LWP::UserAgent;
use HTTP::Request::Common qw(GET POST);

use Digest::MD5 qw(md5_hex);

use Net::OneSky::Project;

use URI;
use Time::Local;

# Do not specify version in the base URL, to allow clients to specify as needed
use constant BASE_URL => URI->new('https://platform.api.onesky.io/');

has 'api_key' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);

has 'api_secret' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);

has 'base_url' => (
  is => 'ro',
  isa => 'URI',
  required => 1,
  default => sub { BASE_URL } # must be a sub even though it is a constant
);


sub project {
  my $self = shift;
  my $id = shift;

  return new Net::OneSky::Project(id => $id, client => $self);
}


sub get {
  my $self = shift;
  my $uri = shift;
  my $data = shift || [];

  $data = $self->authenticate($data);

  $uri = URI->new_abs($uri, $self->{base_url});
  $uri->query_form(@$data);
  my $req = GET($uri);

  return $self->user_agent->request($req);
}


sub file_upload {
  my $self = shift;
  my $uri = shift;
  my $data = shift;

  $data = $self->authenticate($data);

  my $req = POST(URI->new_abs($uri, $self->{base_url}),
              Content_Type => 'form-data',
              Content => $data);

  return $self->user_agent->request($req);
}


sub user_agent {
  my $self = shift;

  $self->{_user_agent} ||= LWP::UserAgent->new;
  my $v = $self->version_string;
  $self->{_user_agent}->agent("Net::OneSky [$v] ");
  return $self->{_user_agent};
}


sub version_string {
  return $Net::OneSky::VERSION || `git rev-parse --short HEAD`
}


sub authenticate {
  my $self = shift;
  my $data = shift;

  # copy it
  $data = [@$data];

  my $timestamp = timegm(gmtime(time));

  push(@$data,
    api_key => $self->api_key,
    timestamp => $timestamp,
    dev_hash => md5_hex($timestamp . $self->api_secret)
  );

  return $data;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

# ABSTRACT: Simple interface to the OneSky API: http://developer.oneskyapp.com/
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::OneSky - Simple interface to the OneSky API: http://developer.oneskyapp.com/

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    use Net::OneSky;

    my $client = Net::OneSky->new(api_key => $key, api_secret => $secret);

    my $response = $client->get('/1/locales');

    my $project = $client->project($project_id);

    my @languages = $project->locales
    my @files = $project->list_files

    $project->upload_file($filename, $file_format, $locale);
    my $file = $project->export_file($locale, $remote_file, $local_file_name, $block_until_finished)

=head1 METHODS

=head2 project($project_id)

Returns a Net::OneSky::Project object for the given $project_id

=head2 get($uri, $query_data)

GET an authenticated API request.

=head2 file_upload($uri, $post_data)

POST an authenticated File upload request. $post_data should be a standard
format for a file-upload. More information
L<in the LWP Cookbook|http://search.cpan.org/~ether/HTTP-Message-6.11/lib/HTTP/Request/Common.pm#POST>

=head2 authenticate($data)

Returns a new data object with authentication params added.

=head1 AUTHOR

Erik Ogan <erik@change.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2018 by Change.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
