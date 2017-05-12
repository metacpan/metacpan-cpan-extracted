=head1 NAME

Software::Packager::Svr4 - The Software::Packager extension for System VR4 packages

=head1 SYNOPSIS

 use Software::Packager;
 my $packager = new Software::Packager('svr4');

=head1 DESCRIPTION

This module is used to create software packages in a format
suitable for installation with pkgadd.

=head1 FUNCTIONS

=cut

package	Software::Packager::Svr4;

use strict;
use File::Copy;
use File::Path;
use File::Basename;
use IO::File;
use POSIX qw(uname);

use base qw( Software::Packager );
use Software::Packager::Object::Svr4;
our $VERSION;
$VERSION = substr(q$Revision: 1.2 $, 9);

=head2 B<new()>

This method creates and returns a new Software::Packager::SVR4 object.

=cut
sub new {
  my $class = shift;
  my $self = bless {}, $class;

  return $self;
}

=head2 B<add_item()>

 $packager->add_item(%object_data);

Adds a new object (file, link, etc) to the package.

=cut

sub add_item {
  my $self = shift;
  my %data = @_;
  my $object = Software::Packager::Object::Svr4->new(%data) || return;

  # check that the object has a unique destination
  return
    if exists $self->{OBJECTS}->{$object->destination};

  $self->{OBJECTS}->{$object->destination} = $object;
}

sub get_all_classes {
  my $self = shift;
  my %class;

  foreach($self->get_directory_objects, $self->get_file_objects,
	  $self->get_link_objects) {
    $class{$_->class}++;
  }
  return keys %class;
}

=head2 B<package()>

 $packager->package();

Create the package.

=cut

sub package {
  my $self = shift;
  my $dir = $self->output_dir;

  my $pkginfo = IO::File->new(">$dir/pkginfo")
    || die "Couldn't open pkginfo for output: $!\n";
  my %info = $self->info;
  print $pkginfo "$_=$info{$_}\n"
    for keys %info;

  my $pkgmap = IO::File->new(">$dir/pkgmap")
    || die "Couldn't open pkgmap for output: $!\n";

  mkdir "$dir/reloc", 0755;
  chdir "$dir/reloc";
  my $maxlength = 0;
  foreach($self->get_directory_objects, $self->get_file_objects,
	  $self->get_link_objects) {
warn $_->destination, ", ", $_->prototype, "\n";
    if($_->prototype eq 'f') {
      open(IN,  $_->source)
	|| die "Couldn't open ", $_->source, " for input: $!\n";
      open(OUT, ">./".$_->destination)
	|| die "Couldn't open ", $_->destination, " for output: $!\n";
      ($_->{length},$_->{crc}) = _sum_copy(\*IN, \*OUT);
      $maxlength = $_->{length} if $_->{length} > $maxlength;
      $_->{mtime} = [lstat($_->source)]->[10];
      close IN;
      close OUT;
      chmod $_->mode, $_->destination;
    } elsif($_->prototype eq 'd') {
      mkdir $_->destination, $_->mode;
    }

    $pkgmap->print(_pkgmap_line($_));
  }
  chdir "../..";

  print $pkgmap ":1 ". int($maxlength / 512). "\n";
  $pkgmap->close;
}

# an implementation of the 'cksum' utility in perl.  written for the perl
# power tools (ppt) project by theo van dinter (felicity@kluge.net).
#
# id: cksum,v 1.3 1999/03/04 17:14:08 felicity exp
# modified to copy the file while it sums
sub _sum_copy {
  my($fh) = shift;
  my($ofh) = shift;
  my($crc) = my($len) = 0;
  my($buf,$num,$i);
  my($buflen) = 4096; # buffer is "4k", you can up it if you want...

  while($num = sysread $fh, $buf, $buflen) {
    $len += $num;
    $crc += unpack("%32C*", $buf);
    syswrite $ofh, $buf;
  }

  # crc = s (total of bytes)
  $crc = ($crc & 0xffff) + ($crc & 0xffffffff) / 0x10000; # r
  $crc = ($crc & 0xffff) + ($crc / 0x10000); # cksum

  return $len,int($crc),($len+511)/512; # round # of blocks up ...
}

sub _pkgmap_line {
  my $finfo = shift;

  (defined $finfo->part ? $finfo->part : "1") . " " .
    $finfo->prototype . " " . 
    (defined $finfo->class ? $finfo->class : "none") . " " .

      $finfo->destination . " " . sprintf("%04o",$finfo->mode)
	. " " . $finfo->user . " " . $finfo->group . " " .
	  ($finfo->prototype eq 'f' ? $finfo->{length} .
	   " " . $finfo->{crc} . " "
	   . $finfo->{mtime} . "\n" : "\n")
}

=head2 B<info>

This method returns a hash that is filled with the necessary
information for a pkginfo file that conforms to the SYSV format.

=cut

sub info {
  my $self = shift;
  my %info;

  $info{PKG} = $self->package_name || warn "No package name.\n";
  $info{NAME} = $self->program_name || warn "No program name.\n";
  $info{VERSION} = $self->version || warn "No version number.\n";
  $info{ARCH} = $self->architecture
    if $self->architecture;
  $info{PSTAMP} = $self->creator
    || POSIX::strftime([POSIX::uname]->[1].'%Y%m%d%H%M%S', localtime);
  $info{CLASSES} = join(", ",$self->get_all_classes);
  $info{CATEGORY} = $self->category
    if $self->category;
  $info{VENDOR} = $self->vendor
    if $self->vendor;
  $info{BASEDIR} = $self->install_dir;
  $info{EMAIL} = $self->email_contact
    if $self->email_contact;

  return %info;
}


=head2 B<package_name()>

Define the package name.

=cut

sub package_name {
  my $self = shift;
  my $name = shift;

  return $self->{PACKAGE_NAME}
    unless $name;

  for ($name) {
    if (m{^(?![a-zA-Z])}) {
      warn qq{Warning: Package name "$name" does not start with a letter.
Removing non letters from the start.\n};
      s{^(.*?)(?=[a-zA-Z])(.*)}{$2};
    }
    if (/[^a-zA-Z0-9+-]!/) {
      warn qq{Warning: Package name "$name" contains
charaters other that alphanumeric, + and -. Removing them.\n};
      tr/a-zA-Z0-9+-//cd;
    }
    if (length > 256) {
      warn qq{Warning: Package name "$name" is longer than 9 charaters.
Truncating to 9 charaters.\n};
      $_ = substr($_, 0, 256);
    }
    if (/^install$|^new$|^all$/) {
      warn "Warning: The package name $name is reserved.\n";
    }
    $self->{PACKAGE_NAME} = $_;
  }

}

=head2 B<program_name()>

This is used to specify the full package name.

The program name must be less that 256 charaters.

For more details see the pkginfo(4) man page.

=cut

sub program_name {
  my $self = shift;
  my $name = shift;

  return ($self->{PROGRAM_NAME} || $self->package_name)
    unless $self->{PROGRAM_NAME};
  for($name) {
    if (length > 256) {
      warn qq{Warning: Package name "$_" is longer than 256 charaters.
Truncating to 256 charaters.\n};
      $_ = substr($_, 0, 256);
    }
    $self->{PROGRAM_NAME} = $_;
  }

}

=head2 B<architecture()>

The architecture must be a comma seperated list of alphanumeric tokens that
indicate the architecture associated with the package.

The maximum length of a token is 16 charaters.

A token should be in the format "instruction set"."platform group"
where:

=over

=item instruction set is in the format of `uname -p`

=item platform group is in the format of `uname -m`

=back

If the architecture is not set then the current instruction set is used.

For more details see the pkginfo(4) man page.

=cut

sub architecture {
  my $self = shift;
  my $name = shift;

  $self->{ARCHITECTURE} = $name
    if $name;
  $self->{ARCHITECTURE} ||= [uname]->[4];
}

=head2 B<version()>

This method is used to check the format of the version and return it in the
format required for SVR4.

=item *

The version must be 256 charaters or less.

=item *

The first charater cannot be a left parenthesis.

The recommended format is an arbitrary string of numbers in Dewey-decimal
format.
For more datails see the pkginfo(4) man page.

=cut
sub version {
  my $self = shift;
  my $version = shift;

  if ($version) {
    if (substr($version, 0, 1) eq '(') {
      warn "Warning: The version starts with a left parenthesis.
Removing it.\n";
      $version = substr($version,1);
    }
    if (length $version > 256) {
      warn "Warning: The version is longer than 256 charaters.
Truncating it.\n";
      $version = substr($version,0,256);
    }
    $self->{PACKAGE_VERSION} = $version;
  }

  return $self->{PACKAGE_VERSION};
}

=head2 B<install_dir()>

 $packager->install_dir('/usr/local');
 my $base_dir = $packager->install_dir;

This method sets the base directory for the software to be installed.
The installation directory must start with a "/".

=cut

sub install_dir {
  my $self = shift;
  my $value = shift;

  return ($self->{BASEDIR} || '/')
    unless $value;
  for($value) {
    if (substr($_,0,1) ne '/') {
      warn qq{Warning: The installation directory does not start with a "/".
Prepending "/" to $value.};
      $_ = "/$value";
    }
    $self->{BASEDIR} = $_;
  }
}

=head2 B<compatible_version()>

 $packager->compatible_version('/some/path/file');

or

 $packager->compatible_version($compver_stored_in_string);

 my $compatible_version = $packager->compatible_version();

This method sets the compatible versions file for the software to
be installed.

=cut

sub compatible_version {
  my $self = shift;
  my $value = shift;

  $self->{COMPVER} = $value
    if $value;
  return $self->{COMPVER};
}

=head2 B<space()>

 $packager->space('/some/path/file');

or

 $packager->space($space_data_stored_in_string);
 my $space = $packager->space();

This method sets the space file for the software to be installed.

=cut

sub space {
  my $self = shift;
  my $value = shift;

  $self->{SPACE} = $value
    if $value;
  return $self->{SPACE};
}

=head2 B<request_script()>

 $packager->request_script('/some/path/file');

or

 $packager->request_script($request_script_stored_in_string);
 my $request_script = $packager->request_script();

This method sets the space file for the software to be installed.

=cut

sub request_script {
  my $self = shift;
  my $value = shift;

  $self->{REQUEST_SCRIPT} = $value
    if $value;
  return $self->{REQUEST_SCRIPT};
}

1;
__END__

=head1 SEE ALSO

Software::Packager
Software::Packager::Object::SVR4

The Software::Packager homepage:
http://bernard.gondwana.com.au


=head1 AUTHOR

Mark A. Hershberger <mah@everybody.org>
Based on work by R Bernard Davison <rbdavison@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003 Mark A. Hershberger. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

