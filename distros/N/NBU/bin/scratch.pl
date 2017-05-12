#!/usr/local/bin/perl -w

use strict;

use XML::XPath;
use XML::XPath::XMLParser;

use Getopt::Std;

my %opts;
getopts('d?nf:', \%opts);

if ($opts{'?'}) {
  print STDERR <<EOT;
Usage: scratch.pl [-n] [-f <config.xml>]
Options:
  -n       Don't actually scratch volumes; only list them
  -f       Use alternate config file
EOT
  exit;
}

use NBU;
NBU->debug($opts{'d'});

my $file = "/usr/local/etc/robot-conf.xml";
if (defined($opts{'f'})) {
  $file = $opts{'f'};
  die "No such configuration file: $file\n" if (! -f $file);
}

my $xp;
if (-f $file) {
  $xp = XML::XPath->new(filename => $file);
  die "robot-snapshot.pl: Could not parse XML configuration file $file\n" unless (defined($xp));
}

#
# Rather than XPath-ing on every volume, we build a little hash of the density/pool
# combinations we're allowed to scratch.
my %itchy;
my $nodeset = $xp->find('//itchy/pool');
foreach my $pool ($nodeset->get_nodelist) {
  my $poolName = $pool->getAttribute('name');
  my $nodeset = $pool->find('density');
  foreach my $density ($nodeset->get_nodelist) {
    my $densityCode = $density->getAttribute('code');
    my $key = $densityCode.":".$poolName;
    $itchy{$key} += 1;
  }
}

my $scratch = NBU::Pool->scratch;
die "No scratch pool defined\n" unless (defined($scratch));

NBU::Media->populate(1);
my $tc = 0;
my $sc = 0;
for my $m (NBU::Media->list) {
  next if ($m->cleaningTape);
  $tc += 1;
  next if ($m->allocated);
  next if ($m->netbackup);

  next if (defined($m->pool) && !exists($itchy{$m->type.":".$m->pool->name}));

  $sc += 1;
  if ($opts{'n'}) {
    print "Could scratch ".$m->id." from ".$m->pool->name."\n";
  }
  else {
    $m->pool($scratch);
  }
}
printf("Scratched $sc volumes (%.2f%%)\n", ($sc * 100) / $tc);

=head1 NAME

scratch.pl - Return empty volumes back to scratch pool

=head1 SYNOPSIS

    scratch.pl [-n] [-f <config.xml>]

=head1 DESCRIPTION

Although NetBackup will move volumes from the scratch pool (vmpool -listscratch) to
whatever pool it deems necessary, once the images on these volumes expire the volumes
are not automatically returned to the scratch pool.  Scratch.pl addresses this need
by locating all unassigned volumes NOT in the scratch pool, matching them up against
a set of rules gleaned from a configuration file and returning back to the scratch
pool.

=head1 OPTIONS

=over 4

=item B<-n>

Don't actually return the volumes to the scratch pool, just list which ones are eligible
to be returned.

=item B<-f> config.xml

The default configuration file is /usr/local/etc/robot-conf.xml but this option allows you
to override this with a selection of your own.

=back

=head1 FILES

As alluded to above, the return of volumes to the scratch pool is controlled via
a configuration file, the default being /usr/local/etc/robot-conf.xml.  This is an XML
file and in particular, scratch.pl concerns itself with the the element called <itchy/>
Here is an example of such an element:
 
  <itchy>
    <pool name="NetBackup">
      <density code="11"/>
      <density code="14"/>
    </pool>
    <pool name="MAXpool">
      <density code="11"/>
      <density code="14"/>
    </pool>
    <pool name="SAP_Production">
      <density code="14"/>
    </pool>
  </itchy>

Each <pool/> element sets the rules volumes in that pool have
to obey in order to be returned to the scratch pool.  In the above example,
only SAP_Production volumes of density "14" (i.e. hcart2) will be
scratched whereas dlt volumes are left alone.

=head1 SEE ALSO

=over 4

=item L<volume-list.pl|volume-list.pl>

=back

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002 Paul Winkeler

=cut
