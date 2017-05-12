use strict;
use warnings;

package TCP::Rebuild::App;

=head1 NAME

TCP::Rebuild::App - the guts of the tcprebuild command

=head1 SYNOPSIS

  #!/usr/bin/perl
  use TCP::Rebuild::App;
  TCP::Rebuild::App->run;

=cut

use File::Spec;
use Getopt::Long qw(GetOptions);
use Pod::Usage;

sub _display_version {
  my $class = shift;
  no strict 'refs';
  print "tcprebuild",
    ($class ne 'TCP::Rebuild' ? ' (from TCP::Rebuild)' : q{}),
    ", powered by $class ", $class->VERSION, "\n\n";
  exit;
}

=head2 run

This method is called by F<tcprebuild> to do all the work.  Relying on it doing
something sensible is plain silly.

=cut

sub run {
  my %config;
  $config{class} = 'TCP::Rebuild';
  my $version;

  $config{filter} = '';
  $config{separator} = 0;

  GetOptions(
    "h|help"      => sub { pod2usage(1); },
    "v|version"   => sub { $version = 1 },
    "i|infile=s"  => \$config{infile},
    "f|filter=s"  => \$config{filter},
#    "files-from" => \$config{files-from},
    "s|separator+" => \$config{separator}
  ) or pod2usage(2);

  eval "require $config{class}";
  die $@ if $@;

  _display_version($config{class}) if $version;
  pod2usage(2) unless $config{infile};

  # Flush output after writes
  $|++;

  my $o = $config{class}->new(
    separator	=> $config{separator},
    filter	=> $config{filter}
  );

  $o->rebuild($config{infile});
}

=head1 SEE ALSO 

=head1 AUTHORS

David Cannings, <F<david at edeca.net>>

Copyright 2010, released under the same terms as Perl itself.

=cut

1;

