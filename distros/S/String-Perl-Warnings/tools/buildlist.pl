use strict;
use warnings;
use File::Fetch;
use IPC::Cmd qw[run];
use Perl::Version;
use Module::CoreList;
use File::Spec::Unix;
use File::Path qw[rmtree];

$|=1;

my $mirror = 'http://cpan.mirror.local/CPAN/';
my $prefix = '/home/ftp/CPAN/';

my %lines;
my @perls =
  map { s/^v//; "perl-$_" }
  map { $_->normal }
  grep { ( $_->version % 2 ) == 0 }
  map { Perl::Version->new($_) }
  grep { $_ >= 5.006 and length($_) > 4 }
  sort keys %Module::CoreList::version;

for my $perl ( @perls ) {
  my $stat;
  if ( $mirror ) {
    my $url = $mirror . File::Spec::Unix->catfile( 'src/5.0', "$perl.tar.gz" );
    warn "Downloading '$url'\n";
    my $ff = File::Fetch->new( uri => $url );
    $stat = $ff->fetch();
  }
  else {
    $stat = File::Spec->catfile( $prefix, 'src/5.0', "$perl.tar.gz" );
  }
  if ( $stat ) {
    my $cmd = [ 'gtar', 'zxf', $stat, File::Spec::Unix->catfile( $perl, 'pod', 'perldiag.pod' ) ];
    if ( run( command => $cmd, verbose => 0 ) ) {
      warn "Extracted '$stat'\n";
      unlink $stat;
      open my $pod, '<', File::Spec->catfile( $perl, 'pod', 'perldiag.pod' ) or die "$!\n";
      while (<$pod>) {
        chomp;
        next unless /^\=item/i;
        s/^\=item\s+//g;
        $_ = quotemeta($_);
        s/(\\\%(?:lx|s|c|d|u|x|X))/.+?/g;
        $lines{$_}++;
      }
      close $pod;
      #rmtree $perl;
    }
  }
}

print "q{$_},\n" for sort keys %lines;
