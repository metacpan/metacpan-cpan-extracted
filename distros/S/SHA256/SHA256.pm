package Digest::SHA256;

# SHA256 perl module written by Rafael R. Sevilla
# This program is free software; you can redistribute it and/or 
# modify it under the same terms as Perl itself.

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
@EXPORT = qw();
$VERSION = '0.01';

bootstrap Digest::SHA256 $VERSION;

sub addfile
{
    no strict 'refs';
    my ($self, $handle) = @_;
    my ($package, $file, $line) = caller;
    my $data = ' ' x 8192;

    if (!ref($handle)) {
	$handle = "$package::$handle" unless ($handle =~ /(\:\:|\')/);
    }
    while (read($handle, $data, 8192)) {
	$self->add($data);
    }
}

sub hexdigest
{
  my ($self) = shift;
  my ($tmp, $str, $i);

  $tmp = unpack("H*", ($self->digest()));
  $str = substr($tmp, 0,8) . " " . substr($tmp, 8,8) . " " .
    substr($tmp,16,8) . " " . substr($tmp,24,8) . " " .
      substr($tmp,32,8) . " " . substr($tmp,40,8) . " " .
	substr($tmp,48,8) . " " . substr($tmp,56,8);
  $i = $self->length();
  return($str) if ($self->length() == 256);
  $str =  substr($tmp, 0,16) . " " . substr($tmp,16,16) . " " .
    substr($tmp,32,16) . " " . substr($tmp,48,16) . " " .
      substr($tmp,64,16) . " " . substr($tmp,80,16);
  return($str) if ($self->length() == 384);
  $str = substr($tmp, 0,16) . " " . substr($tmp,16,16) . " " .
    substr($tmp,32,16) . " " . substr($tmp,48,16) . " " .
      substr($tmp,64,16) . " " . substr($tmp,80,16) . " " .
	substr($tmp,96,16) . " " . substr($tmp,112,16);
  return($str);

}

sub hash
{
    my($self, $data) = @_;

    if (ref($self)) {
	$self->reset();
    } else {
	$self = new Digest::SHA256;
    }
    $self->add($data);
    $self->digest();
}

sub hexhash
{
    my($self, $data) = @_;

    if (ref($self)) {
	$self->reset();
    } else {
	$self = new Digest::SHA256;
    }
    $self->add($data);
    $self->hexdigest();
}

1;
__END__
