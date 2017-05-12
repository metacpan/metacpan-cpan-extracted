#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
  
package Rex::Apache::Build::Base;

use strict;
use warnings;

use Data::Dumper;
use Rex::Commands::Gather;

sub new {
  my $that = shift;
  my $proto = ref($that) || $that;
  my $self = { @_ };

  my %sys_info = get_system_information();

  $self->{maintainer}  ||= ($ENV{USER} || "unknown");
  $self->{arch}      ||= $sys_info{architecture},
  $self->{section}    ||= "none";
  $self->{url}       ||= "http://example.tld/";
  $self->{version}    ||= "1.0";
  $self->{description}  ||= "No Description";
  $self->{target}     ||= "linux";
  $self->{depends}    ||= [];
  $self->{provides}    ||= [];
  $self->{conflicts}   ||= [];
  $self->{config_files} ||= [];

  $self->{exclude}    ||= [];
  push(@{ $self->{exclude} }, qr{^Rexfile$}, qr{^Rexfile\.lock$}, qr{^\.git}, qr{^\.svn}, qr{.*~$}, qr{\.sw[a-z]$}, qr{^tmp$}, qr{\.cache$});

  $self->{source}     ||= ".";


  bless($self, $proto);

  return $self;
}

for my $name (qw/
            path
            source
            release
            epoch
            version
            vendor
            license
            depends
            conflicts
            provides
            arch
            target
            description
            section
            url
            post_install
            pre_install
            post_uninstall
            pre_uninstall
            exclude
            maintainer
            priority
            name
            config_files
            file_user
            file_group
           /) {
  no strict 'refs';
  *{__PACKAGE__ . "::$name"} = sub {
    my ($self, $data) = @_;

    if($data) {
      $self->{$name} = $data;
    }

    $self->{$name};

  };
  use strict;
}

sub prefix {
  my ($self, $prefix) = @_;

  if($prefix) {
    $self->{prefix} = $prefix;
  }

  return $self->{prefix} || $self->{path};
}

sub build {
  my ($self, $target) = @_;
  die("Must be implemented by Class.");
}

1;
