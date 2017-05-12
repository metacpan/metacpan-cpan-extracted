package PPM::Make::Search;
use strict;
use warnings;
use PPM::Make::Config qw(WIN32 HAS_CPAN HAS_PPM HAS_MB);
use PPM::Make::Util qw(:all);

our $VERSION = '0.9904';
our ($ERROR);

sub new {
  my ($class, %opts) = @_;
  my $self = {%opts,
              query => undef,
              args => {},
              todo => [],
              mod_results => {},
              dist_results => {},
              dist_id => {},
             };
  bless $self, $class;
}

sub search {
  my ($self, $query, %args) = @_;

  return if $self->{no_remote_lookup};

  unless ($query) {
    $ERROR = q{Please specify a query term};
    return;
  }
  $self->{query} = $query;
  $self->{args} = \%args;
  $self->{todo} = ref($query) eq 'ARRAY' ? $query : [$query];
  my $mode = $args{mode};
  unless ($mode) {
    $ERROR = q{Please specify a mode within the search() method};
    return;
  }
  if ($mode eq 'dist') {
    return $self->dist_search(%args);
  }
  if ($mode eq 'mod') {
    return $self->mod_search(%args);
  }
  $ERROR = q{Only 'mod' or 'dist' modes are supported};
  return;
}

sub mod_search {
  my $self = shift;
  if (defined $self->{cpan_meta} or HAS_CPAN) {
    return 1 if $self->cpan_mod_search();
  }
  $ERROR = q{Not all query terms returned a result};
  return 0;
}

sub cpan_mod_search {
  my $self = shift;
  my @mods = @{$self->{todo}};
  my @todo = ();
  my $cpan_meta = $self->{cpan_meta};
  foreach my $m (@mods) {
    my $obj;
    if ($cpan_meta) {
      $obj = $cpan_meta->instance('CPAN::Module', $m);
    } else {
      $obj = CPAN::Shell->expand('Module', $m);
    }
    unless (defined $obj) {
      push @todo, $m;
      next;
    }
    my $mods = {};
    my $string = $obj->as_string;
    my $mod;
    if ($string =~ /id\s*=\s*(.*?)\n/m) {
      $mod = $1;
      next unless $mod;
    }
    $mods->{mod_name} = $mod;
    if (my $v = $obj->cpan_version) {
      $mods->{mod_vers} = $v;
    }
    if ($string =~ /\s+DESCRIPTION\s+(.*?)\n/m) {
      $mods->{mod_abs} = $1;
    }
    if ($string =~ /\s+CPAN_USERID.*\s+\((.*)\)\n/m) {
      $mods->{author} = $1;
    }
    if ($string =~ /\s+CPAN_FILE\s+(\S+)\n/m) {
      $mods->{dist_file} = $1;
    }
    ($mods->{cpanid} = $mods->{dist_file}) =~ s{\w/\w\w/(\w+)/.*}{$1};
    $mods->{dist_name} = file_to_dist($mods->{dist_file});
    $self->{mod_results}->{$mod} = $mods;
    $self->{dist_id}->{$mods->{dist_name}} ||=
      check_id($mods->{dist_file});
  }
  if (scalar @todo > 0) {
    $self->{todo} = \@todo;
    return;
  }
  $self->{todo} = [];
  return 1;
}

sub dist_search {
  my $self = shift;
  if (defined $self->{cpan_meta} or HAS_CPAN) {
    return 1 if $self->cpan_dist_search();
  }
  $ERROR = q{Not all query terms returned a result};
  return;
}

sub cpan_dist_search {
  my $self = shift;
  my @dists = @{$self->{todo}};
  my @todo = ();
  my $cpan_meta = $self->{cpan_meta};
  my $dist_id = $self->{dist_id};
  foreach my $d (@dists) {  
    my $query = $dist_id->{$d}
      || $self->guess_dist_from_mod($d)
        || $self->dist_from_re($d);
    unless (defined $query) {
      push @todo, $d;
      next;
    }
    my $obj;
    if ($cpan_meta) {
      $obj = $cpan_meta->instance('Distribution', $query);
    } else {
      $obj = CPAN::Shell->expand('Distribution', $query);
    }
    unless (defined $obj) {
      push @todo, $d;
      next;
    }
    my $dists = {};
    my $string = $obj->as_string;
    my $cpan_file;
    if ($string =~ /id\s*=\s*(.*?)\n/m) {
      $cpan_file = $1;
      next unless $cpan_file;
    }
    my ($dist, $version) = file_to_dist($cpan_file);
    $dists->{dist_name} = $dist;
    $dists->{dist_file} = $cpan_file;
    $dists->{dist_vers} = $version;
    if ($string =~ /\s+CPAN_USERID.*\s+\((.*)\)\n/m) {
      $dists->{author} = $1;
      $dists->{cpanid} = $dists->{author};
    }
    $self->{dist_id}->{$dists->{dist_name}} ||=
      check_id($dists->{dist_file});
    my $mods;
    if ($string =~ /\s+CONTAINSMODS\s+(.*)/m) {
      $mods = $1;
    }
    next unless $mods;
    my @mods = split ' ', $mods;
    next unless @mods;
    (my $try = $dist) =~ s{-}{::}g;
    foreach my $mod(@mods) {
      my $module;
      if ($cpan_meta) {
        $module = $cpan_meta->instance('Module', $mod);
      } else {
        $module = CPAN::Shell->expand('Module', $mod);
      }
      next unless $module;
      if ($mod eq $try) {
        my $desc = $module->description;
        $dists->{dist_abs} = $desc if $desc;
      }
      my $v = $module->cpan_version;
      $v = undef if $v eq 'undef';
      if ($v) {
        push @{$dists->{mods}}, {mod_name => $mod, mod_vers => $v};
      }
      else {
        push @{$dists->{mods}}, {mod_name => $mod};        
      }
    }
    $self->{dist_results}->{$dist} = $dists;
  }
  if (scalar @todo > 0) {
    $self->{todo} = \@todo;
    return;
  }
  $self->{todo} = [];
  return 1;
}

sub guess_dist_from_mod {
  my ($self, $dist) = @_;
  my $query_save = $self->{query};
  my $args_save = $self->{args};
  my $todo_save = $self->{todo};
  (my $try = $dist) =~ s{-}{::}g;
  my $dist_file = '';
  if ($self->search($try, mode => 'mod')) {
    $dist_file = $self->{mod_results}->{$try}->{dist_file};
  }
  $self->{query} = $query_save;
  $self->{args} = $args_save;
  $self->{todo} = $todo_save;
  return check_id($dist_file);
}

sub dist_from_re {
  my ($self, $d) = @_;
  foreach my $match (CPAN::Shell->expand('Distribution', qq{/$d/})) {
    my $string = $match->as_string;
    my $cpan_file;
    if ($string =~ /id\s*=\s*(.*?)\n/m) {
      $cpan_file = $1;
      next unless $cpan_file;
    }
    my $dist = file_to_dist($cpan_file);
    if ($dist eq $d) {
      return check_id($cpan_file);
    }
  }
  return;
}

sub search_error {
  my ($self, $additional_error) = @_;
  return if $self->{no_remote_lookup};
  warn $ERROR;
  warn $additional_error if $additional_error;
}

sub check_id {
  my $dist_file = shift;
  if ($dist_file =~ m{^\w/\w\w/}) {
    $dist_file =~ s{^\w/\w\w/}{};
  }
  return $dist_file;
}

1;

__END__


=head1 NAME

  PPM::Make::Search - search for info to make ppm packages

=head1 SYNOPSIS

  use PPM::Make::Search;
  my $search = PPM::Make::Search->new();

  my @query = qw(Net::FTP Math::Complex);
  $search->search(\@query, mode => 'mod') or $search->search_error();
  my $results = $search->{mod_results};
  # print results

=head1 DESCRIPTION

This module either queries a remote SOAP server (if
L<SOAP::Lite> is available), uses L<CPAN.pm>, if
configured, or uses L<LWP::Simple> for a connection
to L<http://cpan.uwinnipeg.ca/> to provide information on 
either modules or distributions needed to make a ppm package.
The basic object is created as

  my $search = PPM::Make::Search->new();

with searches being performed as

  my @query = qw(Net::FTP Math::Complex);
  $search->search(\@query, mode => 'mod') or $search->search_error();

The first argument to the C<search> method is either a
string containing the name of the module or distribution,
or else an array reference containing module or distribution
names. The results are contained in C<$search-E<gt>{mod_results}>,
for module queries, or C<$search-E<gt>{dist_results}>,
for distribution queries. Supported values of C<mode> are

=over

=item C<mode =E<gt> 'mod'>

This is used to search for modules.
The query term must match exactly, in a case
sensitive manner. The results are returned as a hash reference,
the keys being the module name, and the associated values
containing the information in the form:

  my @query = qw(Net::FTP Math::Complex);
  $search->search(\@query, mode => 'mod') or $search->search_error();
  my $results = $search->{mod_results};
  foreach my $m(keys %$results) {
    my $info = $results->{$m};
    print <<"END"
  For module $m:
   Module: $info->{mod_name}
    Version: $info->{mod_vers}
    Description: $info->{mod_abs}
    Author: $info->{author}
    CPANID: $info->{cpanid}
    CPAN file: $info->{dist_file}
    Distribution: $info->{dist_name}
  END
  }

=item C<mode =E<gt> 'dist'>

This is used to search for distributions.
The query term must match exactly, in a case
sensitive manner. The results are returned as a hash reference,
the keys being the distribution name, and the associated values
containing the information in the form:

  my @d = qw(Math-Complex libnet);
  $search->search(\@d, mode => 'dist') or $search->search_error();
  my $results = $search->{dist_results};
  foreach my $d(keys %$results) {
    my $info = $results->{$d};
    print <<"END";
   For distribution $d:
    Distribution: $info->{dist_name}
    Version: $info->{dist_vers}
    Description: $info->{dist_abs}
    Author: $info->{author}
    CPAN file: $info->{dist_file}
  END
    my @mods = @{$info->{mods}};
    foreach (@mods) {
      print "Contains module $_->{mod_name}: Version: $_->{mod_vers}\n";
    }
  }

=back

=head1 COPYRIGHT

This program is copyright, 2008 by
Randy Kobes E<lt>r.kobes@uwinnipeg.caE<gt>.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<PPM>.

=cut

