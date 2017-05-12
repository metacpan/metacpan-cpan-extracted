package Plack::App::File::CaseInsensitive;
{
  $Plack::App::File::CaseInsensitive::VERSION = '0.001000';
}

# ABSTRACT: Serve static files with case insensitive paths

use strict;
use warnings;

use base 'Plack::App::File';

use mro 'c3';
use File::Find;

sub locate_file {
   my ($self, $env) = @_;

   {
      my ($file, $path_info) = $self->next::method($env);

      return ($file, $path_info)
         unless ref $file && ref $file eq 'ARRAY' && $file->[0] == 404;
   }

   warn "Case insensitive mode!  Beware performance problems! ($env->{PATH_INFO})";

    # the rest of this is more or less copied verbatim from the base class
    my $path = $env->{PATH_INFO} || '';

    if ($path =~ /\0/) {
        return $self->return_400;
    }

    my $docroot = $self->root || ".";
    my @path = split /[\\\/]/, $path;
    if (@path) {
        shift @path if $path[0] eq '';
    } else {
        @path = ('.');
    }

    if (grep $_ eq '..', @path) {
        return $self->return_403;
    }

    my ($file, @path_info);
    OUTER:
    while (@path) {
        for my $try ($self->_find_file($docroot, @path)) {
           if ($self->should_handle($try)) {
               $file = $try;
               last OUTER;
           } elsif (!$self->allow_path_info) {
               last OUTER;
           }
        }
        unshift @path_info, pop @path;
    }

    if (!$file) {
        return $self->return_404;
    }

    if (!-r $file) {
        return $self->return_403;
    }

    return $file, join("/", "", @path_info);
}

sub _find_file {
   my ($self, $docroot, @path) = @_;

   my $full_path = join '/', $docroot, @path;
   my $re = qr/\Q$full_path\E/i;

   my @files;
   find(sub {
      if(-d $File::Find::name && $full_path !~ /^\Q$File::Find::name/i) {
         $File::Find::prune = 1;
         return;
      }
      push @files, $File::Find::name
         if $File::Find::name =~ $re
   }, $docroot);

   warn "multiple files found!" if @files > 1;

   return @files;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::File::CaseInsensitive - Serve static files with case insensitive paths

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

 use Plack::App::File::CaseInsensitive;
 my $app = Plack::App::File::CaseInsensitive
    ->new(root => "/path/to/htdocs")->to_app;

=head1 DESCRIPTION

This is a static file server PSGI application that tries its best to work with
urls that have a different case than the files on disk.  The idea is to help
porting away from case insensitive systems like Windows.  It probably doesn't
work very well for unicode and it is B<certainly> inefficient, but it is mostly
just made as a stopgap.  It will warn when the case insensitive codepath is
triggered and it will also warn if it finds multiple files with the same case
insensitive name (ie C<foo> and C<FOO>.)

=head1 CONFIGURATION

See L<Plack::App::File/CONFIGURATION>

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
