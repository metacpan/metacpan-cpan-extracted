package Parse::Flexget;
use strict;

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT_OK);

  $VERSION = '0.014';
  @ISA     = qw(Exporter);

  @EXPORT_OK = qw(
    flexparse
  );
}

use Carp qw(croak);

sub flexparse {
  my @data;
  if(ref($_[0]) eq 'ARRAY') {
    push(@data, @{$_[0]});
  }
  elsif(ref($_[0]) eq '') {
    push(@data, @_);
  }
  else {
    croak("Reference type " . ref($_[0]) . " not supported\n");
  }

  my @downloads;
  for my $element(@data) {
    if($element =~ m/Downloading: (\S+)/) {
      push(@downloads, $1);
    }
  }
  return wantarray() ? @downloads : scalar(@downloads);
}


1;

__END__

=pod

=head1 NAME

Parse::Flexget - Parse the flexget program output

=head1 SYNOPSIS

    use Parse::Flexget qw(flexparse);

    open(my $fh, '<', "$ENV{HOME}/.flexget.log") or die($!);
    my @data = <$fh>;
    close($fh);

    print "$_\n" for flexparse(@data);

=head1 DESCRIPTION

B<Parse::Flexget> parses the output from flexget(1) and returns a list of
successfully downloaded files.
This module was initially written to be used together with L<File::Media::Sort>
and L<File::PatternMatch>.

=head1 EXPORTS

None by default.

=head1 FUNCTIONS

=head2 flexparse()

Parameters: @content | \@content

Returns:    @downloads

In list context, returns an array with all files downloaded by flexget.

In scalar context, returns the number of files downloaded by flexget.

=head1 SEE ALSO

L<File::Media::Sort>, L<File::PatternMatch>, L<flexget(1)>

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  magnus@trapd00r.se
  http://japh.se

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2010, 2011 the B<Parse::Flexget>s L</AUTHOR> and L</CONTRIBUTORS> as
listed above.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
