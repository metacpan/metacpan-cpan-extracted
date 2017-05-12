#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Apache::Inject::Command;

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
use File::Basename qw(dirname basename);
use Cwd qw(getcwd);

#require Exporter;
#use base qw(Exporter);

use vars qw(@EXPORT $inject_command);
@EXPORT = qw(inject
  inject_command);

my $work_dir = getcwd;

############ deploy functions ################

sub inject {
  my ( $to, @options ) = @_;

  my $option = {@options};

  my $cmd1 = sprintf( _get_extract_command($to), "../$to" );
  my $cmd2 = sprintf( _get_pack_command($to), "../$to", "." );

  mkdir("tmp");
  chdir("tmp");
  run $cmd1;

  for my $opt ( $option->{"inject"} ) {
    run sprintf( $inject_command, $opt->{"key"}, $opt->{"value"} );
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

sub inject_command {
  $inject_command = shift;
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
  elsif ( $file =~ m/\.war$/ ) {
    return "unzip %s";
  }
  elsif ( $file =~ m/\.jar$/ ) {
    return "unzip %s";
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
  elsif ( $file =~ m/\.war$/ ) {
    return "zip -r %s %s";
  }
  elsif ( $file =~ m/\.jar$/ ) {
    return "zip -r %s %s";
  }

  die("Unknown Archive Format.");
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
  elsif ( $file =~ m/\.war$/ ) {
    return ".war";
  }
  elsif ( $file =~ m/\.jar$/ ) {
    return ".jar";
  }

  die("Unknown Archive Format.");

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
