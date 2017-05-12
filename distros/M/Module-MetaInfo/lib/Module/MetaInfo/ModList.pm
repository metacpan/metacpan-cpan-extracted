=head1 NAME

Module::MetaInfo::ModList.pm - get meta information from the modlist

=head1 DESCRIPTION

This uses the 03modlist.data file from CPAN to get meta information
about perl modules.

=head1 FUNCTIONS

=head1 new(filename)

Creates an object and reads the modlist file if needed.  At present
the module list is read in for every ModList object created.  This may
change in future for greater efficiency, e.g. by doing it once and
storing the result in a hash in the class.

=cut

package Module::MetaInfo::ModList;
use warnings;

use Symbol;
use Carp;

sub _read_modlist {
  my $self=shift;
  my $file=shift;
  my $fh = Symbol::gensym();
  my $data;

  open $fh, "<$file";

  my $contents="";

  while (<$fh>) {
    m/^\s*\$cols/ and do {
      $contents .=$_;
      last;
    };
  }
  while (<$fh>) {
    $contents .=$_;
  }
  eval $contents;

  $self->{array}=$data;

#  # We hardwire the column into the code here.  Argument is that since
#  # it's the first column it's unlikely to change,

#    $col=0;

  my $col;
  my $primary = "modid";
  my %colhash=();

  for (my $i=0;$i <= $#$cols; $i++) {
    $colhash{$cols->[$i]}=$i;
    $cols->[$i] eq $primary and do {
      $col=$i;
    }
  }

  $self->{colhash}=\%colhash;

  die "undefined column $primary" unless defined $col;

  my %hash;
  foreach (@$data) {
    $hash{$_->[$col]} = $_;
  }

  $self->{hash}=\%hash;

  die "Failed eval contents of modlist file: $@" if $@;
  die "\$data variable empty after modlist file" unless $data;
  die "\$data is not an aray ref" unless (ref $data) =~ m/ARRAY/;

}

sub new {
  my $s  = shift;
  my $dist_name  = shift;
  my $mod_file_name  = shift;

  croak "usage \$thing->new <distfilename> <modlist_filename>"
    if (not $mod_file_name) or @_;

  my $class = ref($s) || $s;
  my $self={};


  my $name=$dist_name;
  die "dist file name can't end in /" if $name=~m,/$,;
  $name =~ s,^.*/,,;

# checking the complete list teaches us that all module versions have
# a number in them but they can have a letter at any point including
# as the first character of the version...  Which is not helpful.

  $name =~ s/-[^-][^0-9][^-]*(.tar.gz)?$//
    or warn "lack of version in package name: $name";

  $name =~ s/-/::/g;

  croak "failed to get package name" unless $name;

  $self->{name}=$name;
  $self->{dist_name}=$dist_name;

  bless $self, $class;

  $self->_read_modlist($mod_file_name);

  return $self;

}

sub _return_col {
  my $self=shift;
  my $col=shift;
  return $self->{hash}->{$self->{name}}->[$self->{colhash}->{$col}];
}

=head1 FUNCTIONS

=head2 development_stage() support_level()

these functions return the development stage / support level as
defined in the perl modules list using the coding defined in the
modules list.  This is an interface which is almost certain to change.

=cut

sub development_stage {
  return shift->_return_col("statd");
}

sub support_level {
  return shift->_return_col("stats");
}

=head1 description() summary()

these functions return the description from the modules list.  This
isn't really a very good description, but is better than nothing.  As
a summary though it's fine.

=cut

sub description {
  #FIXME; add a slightly more verbose explanation that this is a perl module.
  return shift->_return_col("description");
}

sub summary {
  return shift->_return_col("description");
}

=head2 author()

This returns the pause userid of the author of the module.  This can
normally be converted into an email address by adding C<@cpan.org> at
the end of it.  Please don't put that on any web pages without using
web trawler poison.

=cut

sub author {
  return shift->_return_col("userid");
}

1;
