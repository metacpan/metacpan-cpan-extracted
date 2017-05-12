=head1 NAME

pm-metainfo - dump meta info from a perl module

=head1 SYNOPSIS

  pm-metainfo perl-module-distfile.tar.gz

=head1 DESCRIPTION

This is a demonstrator program which simply dumps a description of all
it can work out about a perl module to B<stdout>.  It could be used
for more interesting things, but normally a different program which
interfaces B<Module::MetaInfo.pm> would be written instead.

The output of this program can also be read from and parsed directly
for use in shell scripts.

=head1 OPTIONS

=head2 --modlist=<filename>

This option tells C<pm-metainfo> to use C<filename> as the file where
the I<uncompressed> machine readable version of the modules list is
stored (normally distributed as C<03modlist.data.gz>).  When this is
activated extra meta information will be provided where available.

=head2 --verbose

this option turns on debugging information

=head1 AUTHOR

This program is copyright to Michael De La Rue and is distributed
under the General Public License.  If you would like to use parts of
this program in developing perl then please contact the author who
will almost certainly be willing to relicense those parts under the
same terms as perl its self.

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General
Public License version 2 or later.

=head1 SEE ALSO

L<Module::MetaInfo>

=cut

use warnings;
use strict;
use Getopt::Long;
use Module::MetaInfo;

my $verbose = '';   # option variable with default value (false)
my $modlist = 0;   # option variable with default value (false)
GetOptions ('verbose|v!' => \$verbose, 'modlist|m=s' => \$modlist );

foreach (@ARGV) {

  -e $_ or die "module $_ doesn't exist";

  my $mod= ( $modlist ? new Module::MetaInfo($_,$modlist)
	              : new Module::MetaInfo($_) );

  my $package=$mod->name();

  print "\nPerl module $package\n\n";

  my $desc=$mod->description();

  if (defined $desc) {
    print "DESCRIPTION:\n\n$desc\n\n";
  } else { 
    print "NO DESCRIPTION FOUND\n\n";
  }

  my $doc_files=$mod->doc_files();

  print "DOCUMENTATION FILES:\n\n" , ( join "\n", @$doc_files ) , "\n\n";

  exit 0 unless $modlist;

  my $author=$mod->author();

  if (defined $author) {
    print "AUTHOR:  $author\n";
  } else { 
    print "NO AUTHOR FOUND\n";
  }

  my $dev=$mod->development_stage();

  if (defined $dev) {
    print "DEV STAGE: $dev ; ";
  } else {
    print "NO DEV STAGE FOUND;  ";
  }

  my $support=$mod->support_level() ;

  if (defined $support) {
    print "SUPPORT LEVEL: $support\n";
  } else { 
    print "NO SUPPORT LEVEL FOUND\n";
  }
}

