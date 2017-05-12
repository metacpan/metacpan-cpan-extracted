package Module::MetaInfo::DirTree;
$VERSION = "0.01";
use warnings;
use strict;
use Carp;
use Symbol;
use Module::MetaInfo::_Extractor;

use vars qw(@ISA $AUTOLOAD);

@ISA= qw(Module::MetaInfo::_Extractor);


=head1 NAME

DirTree - get metainfo from a directory in a the perl module

=head1 DESCRIPTION

This is a (experimental) module designed to get meta information from
a special directory which is kept inside the perl-module.

=head1 DIRECTORY NAME

The main directory for meta data is PkgData.  This name is chosen
because within the CPAN collection distributed by RedHat none of the
existing modules had any files matching C</pck/i>.

Within that directory all names starting with C<opt_> are reserved for
subdirectories for use for meta information which overrides the
default in special circumstances.  E.g. C<opt_rpm> is for data which
should be different specifically for rpm.

=head1 DIRECTORY FORMAT

The directory contains files which contain the meta information.  The
files each have their own format.

=head2 summary

This should contain a one line summary of what the module is for.

=head2 description

This contains the description of the module.  This should be a few
lines of text which explain what the module does.  At present this
should be in plain text format (ASCII - no internationalisation !??!).

A typical maximum length would be about 20-30 lines.

=head2 doc

This will contain a list of documentation file names, one per line.
The names can refer to individual files or whole directories.  They
are relative to the top level directory of the perl module.

=head2 BuildMe.PL

This file contains a perl script for building the meta information.
This script will be run with the current directory the main directory
of the distribution

Avoid using this script

=head2 override directory

In order to provide your own descriptions of certain RPMs, you can put
a file with the name of the module into a specified directory.  This
will then be used in the description field exactly as it is.  This
file will override all other possibilities since we assume that the
package builder could delete the override file if wanted.  Where there
turns out to be an C<pkg-data-XXX/description> as well as a description we
give a warning.

=head2 rpm specific build scripts

build.sh install.sh clean.sh pre.sh post.sh preun.sh postun.sh
verify.sh

These give direct access to the various RPM scripts of (almost)the
same names.  The text included is copied verbatim into the spec file.

The prep and build scripts are run after makerpm's normal options.
The clean script is run before hand (whilst the build directory is
still there) install script is run after deleting the previous build
root, but before running the normal install options.  This means that
you have to create your own directories.


=head1 SEARCH PATH

The default search path is only the C<PkgData> directory in the base
directory of the perl module.  Calling the <add_option> function will
mean that the directory C<PkgData/opt_ARG> directory will be checked
where ARG is the argument to C<add_option>.  Option directories are
checked before the main package directory.

Calling the C<add_data_dir> function will cause the
C<ARG/package_name> directory to be searched.

Each directory on the path is checked in turn.

=head1 RULES FOR CREATING META INFO FILES

When creating a metainfo file, the general rule is to always create
the file in the generic (top level) directory.  The opt directories
should only be used for special cases.

=cut

=head2 $self->_read_file()

Given a filename this simply returns the contents.

=cut

sub _check_data_version {
  return 1;
}

sub _read_file {
    my $self=shift;
    my $filepath=shift;
    my $fh = Symbol::gensym();
    open ($fh, $filepath) || die "Failed to open file " .
	    $filepath . ": $!";
    print STDERR "Reading ". $filepath ."\n"
	if ${$self->{'_verbose'}};
    my $returnme="";
    while (<$fh>) {
	$returnme .= $_;
    }
    close($fh) or die "Failed to close " . $filepath .  ": $!";
    return $returnme;
}


=head2 $self->_search_config_file()

this finds the correct configuration file for a given name by
searching through the path of different directories where it could be
then calling _read_file() to read the file and returns the contents of
the file.

=cut

#search
#
#This function takes a filename and returns the entire contents of
#that file from the override directory or the module directory.
#


sub _search_path {
  my $self=shift;
  return ${$self->{"_scratch_dir"}} .'/'. $self->{distname}
      .'/'. $self->{package_name} .'/'. "PkgData";
}

sub _search_config_file {
  my $self=shift;
  my $filename=shift;

  my $returnme=undef;

#  my $user_file = $self->{"user-data-dir"} . "/" . $filename;
#  my $pkg_own_file = $self->{"perl-data-dir"} . "/" . $filename;

  print STDERR "searching for $filename\n"
    if ${$self->{'_verbose'}};

  foreach my $dir ( $self->_search_path() ) {
    _check_data_version($dir);
    print STDERR "Checking for $filename in given data directory\n"
      if ${$self->{'_verbose'}};
    my $file = $dir . '/' . $filename;
    $returnme = $self->_read_file($file) if -e $file;
    return $returnme if defined $returnme;
  }
  print STDERR "Couldn't find a data file named $filename anywhere\n"
    if ${$self->{'_verbose'}};
  return undef;
}

#1 for whole file returns
#2 for white space separated array returns - may become line separated
#  commented array returns..
my %meta_infos =  ( "description" => 1, "doc_files" => 2 );

sub AUTOLOAD {
  (my $sub = $AUTOLOAD) =~ s/.*:://;
  $sub =~ m/^DESTROY$/ && return;
  my $self=shift;
  croak "Function call into Module::MetaInfo wasn't a method call"
    unless ref $self;
  print STDERR "In autoload with sub $sub\n"
    if ${$self->{'_verbose'}};
  my $return=undef;
  my $meta_sub=$meta_infos{$sub};
  croak "meta information function $sub undefined" unless $meta_infos{$sub};
 
  $meta_sub == 1 && return $self->_search_config_file($sub);
  $meta_sub == 2 && do {
    my $file=$self->_search_config_file($sub);
    return undef unless defined $file;
    my @elts=grep ( /\S/, split /\s+/, $file);
    return wantarray ? @elts : \@elts;
  }
}

#  can here returns 1 if the function is defined.  This isn't exactly
#  what can should do since it should return a function reference.  We
#  could define can to create make a little closeure which then calls the
#  correct function.  Later dude...

sub can {
  my $self=shift;
  my $func=shift;
  my $can = $self->SUPER::can($func);

  return $can if defined $can;

  return 1 if $meta_infos{$func};
}

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General
Public License or the Artistic License, as specified in the
Perl README.

=cut
