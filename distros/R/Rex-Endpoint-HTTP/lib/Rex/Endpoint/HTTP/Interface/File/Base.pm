#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Endpoint::HTTP::Interface::File::Base;
   
use strict;
use warnings;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub open {
   my ($self, $mode, $path) = @_;

   CORE::open(my $fh, $mode, $path) or die($!);
   CORE::close($fh);

   return 1;
}

sub read {
   my ($self, $file, $start, $len) = @_;

   CORE::open(my $fh, "<", $file) or die($!);
   CORE::seek($fh, $start, 0);
   my $buf;
   sysread($fh, $buf, $len);
   CORE::close($fh);

   return $buf;
}

# this seems odd, but "write" is not allowed as an action
sub write_fh {
   my ($self, $file, $start, $buf) = @_;

   CORE::open(my $fh, "+<", $file) or die($!);
   CORE::seek($fh, $start, 0);
   my $bytes_written = syswrite($fh, $buf);
   CORE::close($fh);

   if(! defined $bytes_written) { die("Error writing to filehandle."); }

   return $bytes_written;
}

sub seek {
   my $self = shift;
   return 1;
}

sub close {
   my $self = shift;
   return 1;
}


1;
