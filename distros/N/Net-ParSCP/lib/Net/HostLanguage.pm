package Net::HostLanguage;
use strict;
use warnings;

use Set::Scalar;

use base 'Exporter';

our @EXPORT = qw{
  parse_configfile
  translate
  $VERBOSE
};

our $VERBOSE = 0;

# Create methods for each defined machine or cluster
sub create_machine_alias {
  my %cluster = @_;

  my %method; # keys: machine addresses. Values: the unique name of the associated method

  no strict 'refs';
  for my $m (keys(%cluster)) {
    my $name  = uniquename($m);
    *{__PACKAGE__.'::'.$name} = sub { 
      $cluster{$m} 
     };
    $method{$m} = $name;
  }

  return \%method;
}

# sub read_csshrc
# Configuration dump produced by 'cssh -u'
# Example of .csshrc file:
# window_tiling=yes
# window_tiling_direction=right
# clusters = beno ben beo bno bco be bo eo et num beat local beow
# beow = beowulf europa orion tegasaste
# beno = beowulf europa nereida orion
# ben = beowulf europa nereida 
# beo = beowulf europa orion
# bno = beowulf nereida orion
# bco = beowulf casnereida orion
# be  = beowulf europa
# bo  = beowulf orion
# eo  =  europa orion
# et  = europa etsii
# #     europa          etsii
# num = 193.145.105.175 193.145.101.246
# # With @
# beat  = casiano@beowulf casiano@europa
# local = local1 local2 local3 
sub read_csshrc {
  my $configfile = shift;

  open(my $f, $configfile);

  # We are interested in lines matching 'option = values'
  my @desc = grep { m{^\s*(\S+)\s*=\s*(.*)} } <$f>;
  close($f);

  my %config = map { m{^\s*(\S+)\s*=\s*(.*)} } @desc;

  # From cssh man page:
  # extra_cluster_file = <null>
  # Define an extra cluster file in the format of /etc/clusters.  
  # Multiple files can be specified, seperated by commas.  Both ~ and $HOME
  # are acceptable as a to reference the users home directory, i.e.
  # extra_cluster_file = ~/clusters, $HOME/clus
  # 
  if (defined($config{extra_cluster_file})) {
    $config{extra_cluster_file} =~ s/(\~|\$HOME)/$ENV{HOME}/ge;
    my @extra = split /\s*,\s*/, $config{extra_cluster_file};
    for my $extra (@extra) {
      if (-r $extra) {
        open(my $e, $extra);
        push @desc, grep { 
                      my $def = $_ =~ m{^\s*(\S+)\s*=\s*(.*)};
                      my $cl = $1;
                      $config{clusters} .= " $cl" if ($cl && $config{clusters} !~ /\b$cl\b/);
                      $def;
                    } <$e>;
        close($e);
      }
    }
  }
  chomp(@desc);

  # Get the clusters. It starts 'cluster = ... '
  #    clusters = beno ben beo bno bco be bo eo et num beat local beow
  my $regexp = $config{clusters};

  # We create a regexp to search for the clusters definitions.
  # The regexp is the "or" of the cluster names followed by '='
  #            (^beo\s*=)|(^be\s*=) | ...
  $regexp =~ s/\s*(\S+)\s*/(^$1\\s*=)|/g;
  # (beno\s*=) | (ben\s*=) | ... | (beow\s*=) |
  # Chomp the final or '|'
  $regexp =~ s/[|]\s*$//;

  # Select the lines that correspond to clusters
  return grep { m{$regexp}x } @desc;
}

sub slurp {
  my $configfile = shift;

  open(my $f, $configfile);
  my @desc = <$f>;
  chomp(@desc);

  return @desc;
}

# read_configfile: Return an array with the relevant lines of the config file
sub read_configfile {
  my $configfile = $_[0];

  return slurp($configfile) if (defined($configfile) && -r $configfile);

  # Configuration file not found. Try with ~/.clustersrc of cssh
  $configfile = $_[0] = "$ENV{HOME}/.clustersrc";
  return slurp($configfile) if (defined($configfile) && -r $configfile);

  # Configuration file not found. Try with ~/.csshrc of cssh
  $configfile = $_[0] = "$ENV{HOME}/.csshrc";
  return read_csshrc($configfile) if (-r $configfile);

  # Configuration file not found. Try with /etc/clusters of cssh
  $configfile = $_[0] = "/etc/clusters";
  return read_csshrc($configfile) if (-r $configfile);

  warn("Warning. Configuration file not found!\n") if $VERBOSE;

  return ();
}

############################################################
# limitation: label expansion isn't allowed. Like in:
# clusters = <tag1> <tag2> <tag3>
#                 <tag1> = host1 host2 host3
#                 <tag2> = user@host4 user@host5 host6
#                 <tag3> = <tag1> <tag2>
sub parse_configfile {
  my $configfile = $_[0];
  my %cluster;

  my @desc = read_configfile($_[0]);

  for (@desc) {
    next if /^\s*(#.*)?$/;

    my ($cluster, $members) = split /\s*=\s*/;
    die "Error in configuration file $configfile invalid cluster name $cluster" unless $cluster =~ /^[\w.]+$/;

    my @members = split /\s+/, $members;

    my @result;
    for my $m (@members) {
      die "Error in configuration file $_[0] invalid name $m" unless $m =~ /^[\@\w.]+$/;

      # Net::ParSCP admits cluster ranges as cc137..139
      my $range = expand_ranges($m);
      push @result, $range->members;
      for my $r ($range->members) {
        $cluster{$r} = Set::Scalar->new($r) unless exists $cluster{$r};
      }

    }
    $cluster{$cluster} = Set::Scalar->new(@result);
  }

  # keys: machine and cluster names; values: name of the associated method 
  my $method = create_machine_alias(%cluster); 

  return (\%cluster, $method);
}

############################################################
{
  my $pc = 0;

  sub uniquename {
    my $m = shift;

    $m =~ s/\W/_/g;
    $pc++;
    return "_$pc"."_$m";
  }
}

sub warnundefined {
  my ($configfile, @errors) = @_;

  local $" = ", ";
  my $prefix = (@errors > 1) ?
      "Machine identifiers (@errors) do"
    : "Machine identifier (@errors) does";
  warn "$prefix not correspond to any cluster or machine defined in ".
       " cluster description file '$configfile'.\n";
}

# expand_ranges
# Receives a range (num...num) specifying a cluster like: 
#            cc124..125.a1..2
# and returns the Set::Scalar object containing the elements:
#     cc124.a1 cc124.a2 cc125.a1 cc125.a2
sub expand_ranges {
  my $cluster = shift;

  my @result;
  my @processing = ($cluster);
  while (@processing) {
    my $c = shift @processing;
    my ($b, $e) = $c =~ m{(\d+)\.\.+(\d+)};
    if (defined($b)) {
      @processing = map { my $d = $c; $d =~ s/$b\.\.+$e/$_/; $d } $b..$e;
    }
    else {
      push @result, $c;
    }
  }
  return Set::Scalar->new(@result);
}

sub non_declared_machines {
  my $configfile = shift;
  my $clusterexp = shift;
  my %cluster = @_;

  my @unknown;
  my @clusterexp = $clusterexp =~ m{([\w.\@]+)}g;
  if (@unknown = grep { !exists($cluster{$_}) } @clusterexp) {
    warnundefined($configfile, @unknown) if $VERBOSE;
  }
  return @unknown;
}

sub translate {
  my ($configfile, $clusterexp, $cluster, $method) = @_;

  # Autodeclare unknown machine identifiers
  my @unknown = non_declared_machines($configfile, $clusterexp, %$cluster);
  my %unknown = map { $_ => expand_ranges($_)} @unknown;
  %$cluster = (%$cluster, %unknown); # union: add non declared machines
  %$method = (%$method, %{create_machine_alias(%unknown)});

  # Translation: transform user's formula into a valid Perl expression
  # Cluster names are translated into a call to the associated method
  # The associated method returns the set of machines for that cluster
  $clusterexp =~ s/(\w[\w.\@]*)/$method->{$1}()/g;

  my $set = eval $clusterexp;

  unless (defined($set) && ref($set) && $set->isa('Set::Scalar')) {
    $clusterexp =~ s/_\d+_//g;
    $clusterexp =~ s/()//g;
    warn "Error. Expression '$clusterexp' has errors. Skipping.\n";
    return;
  }
  return $set;
}

1;

__END__

