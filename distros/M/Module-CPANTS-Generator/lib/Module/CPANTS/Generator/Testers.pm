package Module::CPANTS::Generator::Testers;
use strict;
use Carp;
use DBI;
use Clone qw(clone);
use File::stat;
use LWP::Simple;
use Net::NNTP;
use Module::CPANTS::Generator;
use base 'Module::CPANTS::Generator';

use vars qw($VERSION);
$VERSION = "0.006";

sub download {
  my $self = shift;

  my $url = "http://testers.astray.com/testers.db";
  mirror($url, "../testers.db");
}

sub generate {
  my $self = shift;
  my $stat = stat("testers.db");

  my $cpants = $self->grab_cpants;

  if ($stat && time - $stat->mtime < 60*60*24) {
    print "  all testers cached, copying\n";
    foreach my $dist (keys %$cpants) {
      next unless exists  $cpants->{$dist}->{testers}; 
      next unless -d $dist;
      $cpants->{cpants}->{$dist}->{testers} = 
	clone($cpants->{$dist}->{testers});
    }
    $self->save_cpants($cpants);
    return;
  }

  $self->download;

  my $dbh = DBI->connect("dbi:SQLite:dbname=../testers.db","","", { RaiseError => 1});

  foreach my $dist (keys %$cpants) {
    delete $cpants->{$dist}->{testers}->{pass};
    delete $cpants->{$dist}->{testers}->{fail};
  }

  my $action_sth = $dbh->prepare("SELECT id, action, version, distversion, platform FROM reports");
  $action_sth->execute();
  my($id, $action, $version, $distversion, $platform);
  $action_sth->bind_columns(\$id, \$action, \$version, \$distversion, \$platform);
  while ($action_sth->fetch) {
    next unless $version;
    next unless exists $cpants->{cpants}->{$distversion};
    $cpants->{cpants}->{$distversion}->{testers}->{lc $action}++;
  }

  $self->save_cpants($cpants);
}

1;
