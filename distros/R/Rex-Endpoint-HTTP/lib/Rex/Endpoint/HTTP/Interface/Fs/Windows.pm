#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Endpoint::HTTP::Interface::Fs::Windows;
   
use strict;
use warnings;

use Rex::Endpoint::HTTP::Interface::Fs::Base;
use base qw(Rex::Endpoint::HTTP::Interface::Fs::Base);

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   return $self;
}

sub ln {
   my ($self, $from, $to) = @_;
   die("Symlink is not implemented on this platform.");
}

sub rmdir {
   my ($self, $path) = @_;

   system("rd /Q /S " . $path);

   if($? == 0) {
      return 1;
   }

   die("Error deleting directory.");
}

sub chown {
   my ($self, $user, $file, $options) = @_;
   die("Not implemented on this platform.");
}

sub chgrp {
   my ($self, $group, $file, $options) = @_;
   die("Not implemented on this platform.");
}

sub chmod {
   my ($self, $mode, $file, $options) = @_;
   die("Not implemented on this platform.");
}

sub cp {
   my ($self, $source, $dest) = @_;

   system("xcopy /E /C /I /H /K /O /Y $source $dest");

   if($? == 0) {
      return 1;
   }

   die("Error copying file");
}

sub rename {
   my ($self, $old, $new) = @_;

   system("move $old $new >/dev/null 2>&1");

   if($? == 0) { return 1; }
}

1;
