use strict;
use warnings;

package Net::OneSky::Project;
$Net::OneSky::Project::VERSION = '0.0.3';
use namespace::autoclean;
use Moose;

use File::Basename;

use JSON qw( decode_json );

has 'client' => (
  is => 'ro',
  isa => 'Net::OneSky',
  required => 1
);

has 'id' => (
  is => 'ro',
  isa => 'Num',
  required => 1
);


sub locales {
  my $self = shift;
  my $include_base = shift;
  my $uri = $self->base_uri . '/languages';
  my $resp = $self->client->get($uri);
  die "ERROR Fetching locales:" unless $resp->is_success;
  my $data = decode_json($resp->content);

  grep { defined }
    map { (!$_->{is_base_language} || $include_base) ? $_->{code} : undef}
      @{$data->{data}};
}


sub list_files {
  my $self = shift;

  my $uri = $self->base_uri . '/files';
  my @files;
  my $page_count = 0;
  my $page = 0;
  my $per_page = 100;
  my $form_data = [
    page => -1,
    per_page => $per_page
  ];

  # The first condition makes sure the loop executes at least once, in which
  # $page_count is initialized to be used in the second condition in
  # subsequent iterations.
  until ($page_count > 0 && $page >= $page_count) {
    $form_data->[1] = ++$page;
    my $resp = $self->client->get($uri, $form_data);
    die "ERROR fetching file list:" unless $resp->is_success;
    my $data = decode_json($resp->content);

    $page_count = $data->{meta}->{page_count} unless $page_count;
    die "NO files fetching list" unless $page_count;

    push @files, map { $_->{file_name} } @{$data->{data}};
  }

  return @files;
}


sub upload_file {
  my $self = shift;
  my $file = shift || die 'Missing file';
  my $format = shift || die 'Missing format';
  my $locale = shift;

  my $uri = $self->base_uri . '/files';

  my $form_data = [
    file => [$file, basename($file)],
    file_format => $format,
  ];

  push(@$form_data, locale => $locale) if $locale;

  $self->client->file_upload($uri, $form_data)
}


sub export_file {
  my $self = shift;
  my $locale = shift || die 'missing locale';
  my $remote_file = shift || die 'missing remote_file';
  my $local_file = shift;
  my $block_until_finished = shift || 0;

  die 'block_until_finished is not (yet) implemented!' if $block_until_finished;

  my $uri = $self->base_uri . '/translations';

  my $form_data = [
    locale => $locale,
    source_file_name => $remote_file
  ];

  push(@$form_data, export_file_name => $local_file) if $local_file;

  my $resp = $self->client->get($uri, $form_data);

  die $resp->content unless $resp->is_success;

  die 'OneSky returned incomplete response (expecting you to retry later) and block_until_finished is not implemented.'
    if($resp->code == 202);

  $resp->content;
}

sub base_uri {
  my $self = shift;
  my $version = shift || 1;

  "/$version/projects/" . $self->id;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

# ABSTRACT: OneSky Project interface https://github.com/onesky/api-documentation-platform/blob/master/resources/project.md
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::OneSky::Project - OneSky Project interface https://github.com/onesky/api-documentation-platform/blob/master/resources/project.md

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

    use Net::OneSky;

    my $project = $one_sky_client->project(42);

    my @languages = $project->locales

    my @files = $project->list_files

    $project->upload_file($filename, $file_format, $locale);

    my $file = $project->export_file($locale, $remote_file, $local_file_name, $block_until_finished)

=head1 METHODS

=head2 locales([$include_base_language])

Returns a list of locales in a project. By default this call skips the base
language, but passing a true value as the first argument will cause it to be
included.

=head2 list_files()

Returns a list of file names in a project

=head2 upload_file($filename, $file_format[, $locale])

Uploads a file in the given format. $locale is optional. If undefined, the
file is assumed to be the base locale.

=head2 export_file($locale, $remote_file [, $local_file, $block_until_finished])

Downloads a file for the given locale.

=head1 AUTHOR

Erik Ogan <erik@change.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2018 by Change.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
