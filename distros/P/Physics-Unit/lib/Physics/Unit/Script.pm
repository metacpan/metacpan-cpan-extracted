package Physics::Unit::Script;

use strict;
use warnings;

use Physics::Unit ':ALL';
use Physics::Unit::Script::GenPages;

our $VERSION = '0.54';
$VERSION = eval $VERSION;

use base 'Exporter';
our @EXPORT_OK = qw/run_script name_info/;


sub run_script {
  my $opts = shift;

  if ($opts->{export}) {
    my @files = GenPages();
    print join(' ', @files), "\n";
  }

  if ($opts->{types}) {
    print "$_\n" for ListTypes;
  }

  if ($opts->{units}) {
    print "$_\n" for ListUnits;
  }

  foreach my $name (@ARGV) {
    name_info($name);
  }
}

my %classes = (
  3 => 'Type',
  2 => 'Unit',
  1 => 'Reserved',
  0 => 'Not Known',
  -1 => 'Derived',
);

sub name_info {
    my $name = shift;

    my $class = Physics::Unit::LookName($name);
    print "Name:  $name\n";

    my $u;
    if ($class == 0) {
        $u = GetUnit($name);
        if (defined $u) { $class = -1; }
    }
    elsif ($class == 2) {
        $u = GetUnit($name);
    }
    print "Class:  $classes{$class}\n";

    if ($class == -1 || $class == 2) {
        print "Type:  " . ( $u->type() || '' ) . "\n" .
              "Definition:  " . $u->def() . "\n" .
              "Expanded:  " . $u->expanded() . "\n";
    }
    print "\n";
}

1;
