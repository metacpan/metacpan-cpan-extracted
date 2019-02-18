package Music::KNRadio::NowPlaying;
use strict;
use warnings;
use open qw(:utf8 :std);

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
  @ISA = qw(Exporter);

  $VERSION = '0.012';
  @EXPORT_OK = qw(knnp);
}



use LWP::Simple;

my $url = 'http://www.knradio.se/latlist/exfile.php';

sub knnp {
  my @content = split(/\n/, get($url));
  my %now_playing = (
    artist => 'undef',
    title  => 'undef',
    state  => 'undef',
  );

  for my $line(reverse(@content)) {
    if($line =~ m/Spelas just nu:(.+)/) {
      unless($1) {
        $now_playing{state} = 'paused';
        last;
      }
      ($now_playing{artist}, $now_playing{title}) = $1 =~ m/(.+) - (.+)/;

      last unless defined $now_playing{artist};
      $now_playing{artist} =~ s/[^[:ascii:]]//g;
      $now_playing{title}  =~ s/[^[:ascii:]]//g;
      $now_playing{title}  =~ s/\r//g;

      $now_playing{state} = 'playing';
      last;
    }
    else {
      $now_playing{state} = 'paused';
    }
  }
  return \%now_playing;
}



1;

__END__

=pod

=head1 NAME

Music::KNRadio::NowPlaying - Now playing metadata for Karlstad Rock 92.2

=head1 SYNOPSIS

    use Music::KNRadio::NowPlaying qw(knnp);

    my $info = knnp();

    printf "artist: %s | title: %s\n", $info->{artist}, $info->{title};


=head1 DESCRIPTION

Music::KNRadio::NowPlaying provides a method for looking up now-playing
metadata for the swedish radiostation 'Karlstad Rock 92.2', also known
as 'knradio'.

=head1 EXPORTS

None by default.

=head1 FUNCTIONS

=head2 knnp()

=over 4

=item    Arguments: $none

=item Return value: \%info

=back

example return data structure:

    $info->{artist} => 'Laleh'
    $info->{title}  => 'Der Yek Gooshe'
    $info->{state}  => 'playing'

=head1 Scripts

An example script is provided in the bin/ directory as knnp.

=head1 REPORTING BUGS

Report bugs and/or feature requests on rt.cpan.org, the repository issue tracker
or directly to L<m@japh.se>

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  m@japh.se
  http://japh.se
  http://github.com/trapd00r

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2019- B<THIS MODULE>s L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<~/|http://japh.se>

=cut
