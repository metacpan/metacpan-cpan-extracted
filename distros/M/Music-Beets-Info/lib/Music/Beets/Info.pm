package Music::Beets::Info;
use strict;
use utf8;
use open qw(:std :utf8);

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
  @ISA = qw(Exporter);

  $VERSION = '0.002';

  @EXPORT_OK = qw(beet_info);
  %EXPORT_TAGS = [ qw() ];
}

use Carp qw(croak);

use IPC::Cmd qw(run);

sub beet_info {
  my $file = shift;
  croak("Not a file: '$file'") unless -f $file;

  my $buffer;
  my %info;

  if(scalar run(
    command => "beet info '$file'",
    verbose => 0,
    buffer  => \$buffer,
    timeout => 20,
  )) {
    %info = $buffer =~ /\s+(\S+):\s(.+)/g;
  }
  return \%info;
}

1;

__END__

=pod

=head1 NAME

Music::Beets:Info - Import data from Beets database into a perl data structure

=head1 SYNOPSIS

    use Music::Beets::Info qw(beet_info);
    my $info = beet_info($filename);

=head1 DESCRIPTION

Given a valid filename known to Beets, returns all available info for
a song. This will be data from musicbrainz or discogs, fetched at
import time.

=head1 EXPORTS

None by default.

=head1 FUNCTIONS

=head2 beet_info()

=over 4

=item    Arguments: $filename

=item Return value: \%info

=back


=head1 REPORTING BUGS

Report bugs and/or feature requests on rt.cpan.org, the repository issue tracker
or directly to L<m@japh.se>

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  m@japh.se
  L<~/|http://japh.se>
  L<git|http://github.com/trapd00r>

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2021- B<THIS MODULE>s L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<~/|http://japh.se>

=cut

