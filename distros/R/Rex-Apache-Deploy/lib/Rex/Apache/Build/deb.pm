#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Build::deb - Build deb packages

=head1 DESCRIPTION

With this module you can build Debian packages to distribute your application.

=head1 SYNOPSIS

 build "my-software",
   type   => "deb",
   version => "1.0",
   source  => "/path/to/your/software",
   path   => "/path/to/deploy/target",
   # below this, it is all optional
   description   => "some description of your package",
   url        => "website of the package",
   depends      => [qw/apache2 perl/],
   release      => 1,
   epoch       => 1,
   vendor      => "some vendor",
   license      => "your license for ex. GPL2",
   section      => "some/section",
   conflicts    => [qw/somepkg/],
   provides     => "some-package-name",
   arch        => "amd64",
   target      => "linux / the platform",
   post_install  => "filename or script to run after installation",
   pre_install   => "filename or script to run before installation",
   post_uninstall => "filename or script to run after uninstall",
   pre_uninstall  => "filename or script to run before uninstall",
   exclude      => [qw/file1 file2/],
   maintainer    => "your name",
   priority     => "optional",
   config_files  => [qw/special files for configuration mostly for etc directory/];


=cut

package Rex::Apache::Build::deb;

use strict;
use warnings;
use attributes;

use Cwd qw(getcwd);
use Digest::MD5;
use Rex -base;
use Rex::Template;
use Data::Dumper;

$Rex::Template::DO_CHOMP = TRUE;

use Rex::Apache::Build::Base;
use base qw(Rex::Apache::Build::Base);

sub new {
  my $that = shift;
  my $proto = ref($that) || $that;
  my $self = $proto->SUPER::new(@_);

  bless($self, $proto);

  if($self->{arch} eq "x86_64") {
    $self->{arch} = "amd64";
  }

  $self->{priority} ||= "optional";
  $self->{exclude}  ||= [];

  push(@{ $self->{exclude} }, qr{^Rexfile$}, qr{^Rexfile\.lock$}, qr{^\.git}, qr{^\.svn}, qr{.*~$}, qr{\.sw[a-z]$}, qr{\.deb$});

  return $self;
}

sub build {
  my ($self, $name) = @_;

  $name ||= $self->{name};
  my $version = $self->version;

  my $old_dir = getcwd;

  mkdir "temp-deb-build";
  mkdir "temp-deb-build/control";
  mkdir "temp-deb-build/tree";

  $self->copy_files_to_tmp;

  file "temp-deb-build/debian-binary",
    content => "2.0\n";


  file "temp-deb-build/control/control",
    content => template('@control.file', pkg => $self);

  file "temp-deb-build/control/md5sums",
    content => $self->get_md5sums;

  $self->create_config_files;
  $self->create_scripts;

  $self->package_data;
  $self->package_control;

  rmdir "temp-deb-build/tree";
  rmdir "temp-deb-build/control";

  chdir "temp-deb-build";

  my $arch = $self->{arch};
  my $package_name = "${name}_${version}_${arch}.deb";
  run "ar -qc ../$package_name debian-binary control.tar.gz data.tar.gz";
  chdir "..";

  rmdir "temp-deb-build";

  Rex::Logger::info("Your build is now available: $package_name");

  return $package_name;
}

sub create_config_files {
  my ($self) = @_;

  if($self->{config_files}) {
    file "temp-deb-build/control/conffiles",
      content => join("\n", @{ $self->{config_files} });
  }
}

sub create_scripts {
  my ($self) = @_;

  if($self->{post_install}) {
    my $post_install = $self->{post_install};
    if($post_install !~ m/\n/sim && -f $post_install) {
      $post_install = eval { local(@ARGV, $/) = ($post_install); <>; };
    }

    file "temp-deb-build/control/postinst",
      content => $post_install,
      mode   => 755;
  }

  if($self->{pre_install}) {
    my $pre_install = $self->{pre_install};
    if($pre_install !~ m/\n/sim && -f $pre_install) {
      $pre_install = eval { local(@ARGV, $/) = ($pre_install); <>; };
    }

    file "temp-deb-build/control/preinst",
      content => $pre_install,
      mode   => 755;
  }

  if($self->{post_uninstall}) {
    my $post_uninstall = $self->{post_uninstall};
    if($post_uninstall !~ m/\n/sim && -f $post_uninstall) {
      $post_uninstall = eval { local(@ARGV, $/) = ($post_uninstall); <>; };
    }

    file "temp-deb-build/control/postrm",
      content => $post_uninstall,
      mode   => 755;
  }

  if($self->{pre_uninstall}) {
    my $pre_uninstall = $self->{pre_uninstall};
    if($pre_uninstall !~ m/\n/sim && -f $pre_uninstall) {
      $pre_uninstall = eval { local(@ARGV, $/) = ($pre_uninstall); <>; };
    }

    file "temp-deb-build/control/prerm",
      content => $pre_uninstall,
      mode   => 755;
  }

}

sub package_data {
  my ($self) = @_;

  chdir "temp-deb-build/tree";
  run "tar czf ../data.tar.gz .";
  chdir "../../";
}

sub package_control {
  my ($self) = @_;

  chdir "temp-deb-build/control";
  run "tar czf ../control.tar.gz .";
  chdir "../../";
}


sub copy_files_to_tmp {
  my ($self) = @_;

  my $prefix = $self->prefix || ".";
  mkdir "temp-deb-build/tree/$prefix";

  my @dirs = ($self->{source});

  for my $dir (@dirs) {
    opendir(my $dh, $dir) or die($!);

    DIR_ENTRY: while(my $entry = readdir($dh)) {
      next if ($entry eq "." or $entry eq ".." or $entry eq "temp-deb-build");

      for my $ex (@{ $self->exclude }) {
        if($entry =~ m/$ex/) {
          next DIR_ENTRY;
        }
      }

      my $new_dir = "$dir/$entry";
      $new_dir =~ s/^$dirs[0]//;
      $new_dir =~ s/^\///;

      if(-d "$dir/$entry") {
        mkdir "temp-deb-build/tree$prefix/$new_dir";

        push(@dirs, "$dir/$entry");
        next DIR_ENTRY;
      }

      cp "$dir/$entry", "temp-deb-build/tree$prefix/$new_dir";
    } # DIR_ENTRY

    closedir($dh);
  }

}

sub get_md5sums {
  my ($self) = @_;

  my @s = ();
  chdir "temp-deb-build/tree";

  my @dirs = (".");
  for my $dir (@dirs) {
    opendir(my $dh, $dir);
    while(my $entry = readdir($dh)) {
      next if($entry eq ".");
      next if($entry eq "..");

      my $file = "$dir/$entry";

      if(-d $file) {
        push(@dirs, $file);
        next;
      }

      my $md5 = Digest::MD5->new;
      open(my $fh, "<", $file) or die($!);
      $file =~ s/^\.\///;
      $md5->addfile($fh);
      push(@s, $md5->hexdigest . "  " . $file);
      close($fh);


    }
    closedir($dh);
  }

  chdir "../..";

  return join("\n", @s);

}

sub description {
  my ($self, $desc) = @_;

  if($desc) {
    $self->{description} = $desc;
  }

  my $s = "";

  my @lines = split(/\n/, $self->{description});
  $s = shift(@lines);

  for (@lines) {
    $s .= " $_";
  }

  return $s;
}

sub depends {
  my ($self, $dep) = @_;

  if($dep) {
    $self->{depends} = $dep;
  }

  my @s = ();

  for my $dep (@{ $self->{depends} }) {
    if(ref($dep)) {
      my ($pkg) = keys %{ $dep };
      my ($ver) = values %{ $dep };

      push(@s, $pkg . "($ver)");
    }
    else {
      push(@s, $dep);
    }
  }

  return join(", ", @s);
}

sub installed_size {
  my ($self) = @_;

  my $size = 0;

  chdir "temp-deb-build/tree";

  my @dirs = (".");
  for my $dir (@dirs) {
    opendir(my $dh, $dir);
    while(my $entry = readdir($dh)) {
      next if($entry eq ".");
      next if($entry eq "..");

      my $file = "$dir/$entry";

      if(-d $file) {
        push(@dirs, $file);
        next;
      }
      $size += -s $file;

    }
    closedir($dh);
  }

  chdir "../..";

  return $size;
}


1;

__DATA__

@control.file
Package: <%= $::pkg->name %>
Version: <% if($::pkg->epoch) { %><%= $::pkg->epoch %>:<% } %><%= $::pkg->version %><% if($::pkg->release) { %><%= $::pkg->release %><% } %>
License: <% if($::pkg->license) { %><%= $::pkg->license %><% } else { %>unknown<% } %>
Vendor: <% if($::pkg->vendor) { %><%= $::pkg->vendor %><% } else { %>unknown<% } %>
Architecture: <% if($::pkg->arch) { %><%= $::pkg->arch %><% } else { %>all<% } %>
Maintainer: <%= $::pkg->maintainer  %>
Installed-Size: <%= $::pkg->installed_size %>
<% if($::pkg->depends) { %>
Depends: <%= $::pkg->depends %>
<% } %>
<% if($::pkg->conflicts) { %>
Conflicts: <%= join(", ", @{ $::pkg->conflicts }) %>
<% } %>
<% if($::pkg->provides) { %>
Provides: <%= join(", ", @{ $::pkg->provides }) %>
<% } %>
Section: <%= $::pkg->section %>
Priority: <%= $::pkg->priority %>
Homepage: <%= $::pkg->url %>
Description: <%= $::pkg->description %>
@end
