use strict;
use warnings;
package Mojo::File::Role::HomeDir;
$Mojo::File::Role::HomeDir::VERSION = '0.002';
# ABSTRACT: Adds File::HomeDir methonds to Mojo::File

use Mojo::Util qw/monkey_patch/;

use Role::Tiny;
use File::HomeDir;
use strict;


$\ = "\n"; $, = "\t";

my @subs = qw/
    my_home
    my_desktop
    my_documents
    my_music
    my_pictures
    my_videos
    my_data
    my_dist_config
    my_dist_data
    users_home
    users_documents
    users_data
    users_desktop
    users_music
    users_pictures
    users_videos
    /;


for my $name (grep { /^my_/ } @subs) {
    monkey_patch(__PACKAGE__, $name => sub { return shift()->new(File::HomeDir->$name, @_) });
};

for my $name (grep { /^users_/ } @subs) {
    monkey_patch(__PACKAGE__, $name => sub { return shift()->new(File::HomeDir->$name(shift()), @_) });
};

1;

=head1 NAME

Mojo::File::Role::HomeDir - Adds File::HomeDir methods to Mojo::File objects

=head1 SYNOPSIS

  use Mojo::File;
  use Mojo::File::Role::HomeDir;

  my $file = Mojo::File->new->with_roles('+Mojo::File::Role::HomeDir');

  # Use the methods provided by File::HomeDir:
  my $home_dir     = $file->my_home;
  my $desktop_dir  = $file->my_desktop;
  my $documents_dir = $file->my_documents;
  # ... and others

=head1 DESCRIPTION

This role adds a collection of directory-related methods from L<File::HomeDir> 
to L<Mojo::File> objects. Each method returns a new Mojo::File object pointing 
to the directory path provided by File::HomeDir.

The following methods are added:

=over 4

=item * my_home

=item * my_desktop

=item * my_documents

=item * my_music

=item * my_pictures

=item * my_videos

=item * my_data

=item * my_dist_config

=item * my_dist_data

=item * users_home

=item * users_documents

=item * users_data

=item * users_desktop

=item * users_music

=item * users_pictures

=item * users_videos

=back

=head1 METHODS

Each method corresponds to the similarly named method in L<File::HomeDir>.  
They return a L<Mojo::File> object pointing to the directory.

=head1 AUTHOR

Simone Cesano <scesano@cpan.org>

=head1 LICENSE

This software is copyright (c) 2025 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
