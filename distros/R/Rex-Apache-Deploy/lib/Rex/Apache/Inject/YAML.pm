#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Apache::Inject::YAML;

=begin

=head2 SYNOPSIS

This is a (R)?ex module to ease the deployments of PHP, Perl or other languages.

=cut

use strict;
use warnings;

use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;
use Rex::Commands;
use Rex::Config;
use File::Basename qw(dirname basename);

use YAML;
use Data::Dumper;

#require Exporter;
#use base qw(Exporter);

use vars qw(@EXPORT $template_file $template_pattern);
@EXPORT = qw(inject
  template_file template_search_for);

############ deploy functions ################

sub inject {
  my ( $to, @options ) = @_;

  my $option = {@options};

  my $cmd1 = sprintf( _get_extract_command($to), "../$to" );
  my $cmd2 = sprintf( _get_pack_command($to), "../$to", "." );

  my $template_params = _get_template_params($template_file);

  mkdir("tmp");
  chdir("tmp");
  run $cmd1;

  my $is_w = $^W;

  my $find = "find . -name '$template_pattern'";
  if ( $^O =~ m/^MSWin/i ) {
    $find = "find2 . -name \"$template_pattern\"";
  }

  for my $file (`$find`) {
    chomp $file;
    Rex::Logger::debug("Found file: $file");

    my $content;
    {
      local $/ = undef;
      local *FILE;
      open FILE, "<$file";
      $content = <FILE>;
      close FILE
    }

    my $data;
    eval {
      $^W = 0 if $is_w;
      Rex::Logger::debug("Loading content from $file");
      $data = Load($content);
      $^W = 1 if $is_w;
    };

    if ($@) {
      Rex::Logger::info("Syntax-Error in $file -> skipping");
      next;
    }

    Rex::Logger::debug("Updating \$data - hash");
    my $new = _update_hash( $data, $template_params );

    Rex::Logger::debug("Writing new content to $file");
    open( my $fh, ">", $file ) or die($!);
    print $fh Dump($new);
    close($fh);
  }

  if ( exists $option->{"pre_pack_hook"} ) {
    &{ $option->{"pre_pack_hook"} };
  }

  run $cmd2;
  if ( $? != 0 ) {
    chdir("..");
    system("rm -rf tmp");
    die("Can't re-pack archive. Please check permissions. Command was: $cmd2");
  }

  if ( exists $option->{"post_pack_hook"} ) {
    &{ $option->{"post_pack_hook"} };
  }

  chdir("..");
  system("rm -rf tmp");
}

############ configuration functions #############

sub template_file {
  $template_file = shift;
}

sub template_search_for {
  $template_pattern = shift;
}

############ helper functions #############

sub _get_extract_command {
  my ($file) = @_;

  if ( $file =~ m/\.tar\.gz$/ ) {
    return "tar xzf %s";
  }
  elsif ( $file =~ m/\.zip$/ ) {
    return "unzip %s";
  }
  elsif ( $file =~ m/\.tar\.bz2$/ ) {
    return "tar xjf %s";
  }

  die("Unknown Archive Format.");
}

sub _get_pack_command {
  my ($file) = @_;

  if ( $file =~ m/\.tar\.gz$/ ) {
    return "tar czf %s %s";
  }
  elsif ( $file =~ m/\.zip$/ ) {
    return "zip -r %s %s";
  }
  elsif ( $file =~ m/\.tar\.bz2$/ ) {
    return "tar cjf %s %s";
  }

  die("Unknown Archive Format.");
}

# read the template file and return a hashref.
sub _get_template_params {
  my ($template_file) = @_;

  if ( -f "$template_file." . Rex::Config->get_environment ) {
    $template_file = "$template_file." . Rex::Config->get_environment;
  }

  my $content;
  {
    local $/ = undef;
    local *FILE;
    open FILE, "<$template_file";
    $content = <FILE>;
    close FILE
  }

  return Load($content);
}

sub _get_ext {
  my ($file) = @_;

  if ( $file =~ m/\.tar\.gz$/ ) {
    return ".tar.gz";
  }
  elsif ( $file =~ m/\.zip$/ ) {
    return ".zip";
  }
  elsif ( $file =~ m/\.tar\.bz2$/ ) {
    return ".tar.bz2";
  }

  die("Unknown Archive Format.");

}

sub _update_hash {
  return $_[1] unless ( ref( $_[0] ) );
  map {
    $_[0]->{$_} = _update_hash( $_[0]->{$_}, $_[1]->{$_} )
      if ( defined $_[1]->{$_} )
  } keys %{ $_[0] } if ( ref( $_[0] ) eq "HASH" );
  if ( ref( $_[0] ) eq "ARRAY" ) {
    $_[0] = $_[1];
  }

  $_[0];
}

####### import function #######

sub import {

  no strict 'refs';
  for my $func (@EXPORT) {
    Rex::Logger::debug("Registering main::$func");
    *{"$_[1]::$func"} = \&$func;
  }

}

1;
