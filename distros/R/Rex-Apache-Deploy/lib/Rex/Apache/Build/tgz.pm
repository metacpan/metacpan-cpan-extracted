#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Build::tgz - Build tgz packages

=head1 DESCRIPTION

With this module you can build TGZ packages to distribute your application.

=head1 SYNOPSIS

 build "my-software",
   type   => "tgz",
   version => "1.0",
   source  => "/path/to/your/software",
   # below this, it is all optional
   exclude => [qw/file1 file2/];


=cut


package Rex::Apache::Build::tgz;

use strict;
use warnings;

use Cwd qw(getcwd);
use Rex -base;
use Data::Dumper;

use Rex::Apache::Build::Base;
use base qw(Rex::Apache::Build::Base);

sub new {
  my $that = shift;
  my $proto = ref($that) || $that;
  my $self = $proto->SUPER::new(@_);

  bless($self, $proto);

  # compatibility for < 0.11
  if($self->{source} eq ".") {
    $self->{source} = undef;
    delete $self->{source};
  }

  $self->{exclude} = [".git", ".svn", ".*.sw*", "*~", "yuicompressor.jar", "._yuicompressor.jar"];

  return $self;
}

sub build {
  my ($self, $name) = @_;

  $name ||= $self->{name};

  my $old_dir = getcwd();

  my $excludes = "";
  if(exists $self->{exclude}) {
    if($^O =~ m/^MSWin/) {
      $excludes = " --exclude \"" . join("\" --exclude \"", @{$self->{exclude}}) . "\"";
    }
    else {
      $excludes = " --exclude '" . join("' --exclude '", @{$self->{exclude}}) . "'";
    }
  }

  my $version = $self->version;

  my $dir = getcwd();

  # compatibility for < 0.11 versions
  if(exists $self->{path}) {
    $dir = $self->{path};
  }

  # if source is present, this will overwrite path parameter
  # because path can also be used in deploy() with an other meaning (prefix)
  if(exists $self->{source}) {
    $dir = $self->{source};
  }

  chdir($dir);

  my $package_name = "$name-$version.tar.gz";

  Rex::Logger::info("Building: $package_name");
  if($^O =~ m/^MSWin/i) {
    run "tar -c $excludes --exclude \"$name-*.tar.gz\" --exclude \".*.sw*\" --exclude \"*~\" --exclude Rexfile.lock --exclude Rexfile --exclude $package_name -z -f $old_dir/$package_name .";
  }
  else {
    run "tar -c $excludes --exclude '$name-*.tar.gz' --exclude '.*.sw*' --exclude '*~' --exclude Rexfile.lock --exclude Rexfile --exclude $package_name -z -f $old_dir/$package_name .";
  }
  Rex::Logger::info("Your build is now available: $name-$version.tar.gz");

  chdir($old_dir);

  return $package_name;
}

1;
