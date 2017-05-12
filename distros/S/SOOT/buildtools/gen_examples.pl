use strict;
use warnings;
use File::Spec::Functions;
use File::Path 'mkpath';

my $libdir = catdir(qw(lib SOOT Examples));
my $exdir = 'examples';
mkpath($libdir);

my @example_dirs = do {
  opendir my $dh, $exdir or die $!;
  grep {!/\/\./ and /\// and -d $_} map {catdir($exdir, $_)} readdir($dh)
};

my $template = join '', <DATA>;

foreach my $exdir (@example_dirs) {
  my $exdirname = $exdir;
  $exdirname =~ s{^.*/([^/]+)$}{$1};
  my $pod = $template;
  $pod =~ s/\$DIRNAME/$exdirname/g;
  my @examples;
  opendir my $dh, $exdir or die $!;
  my @examples_files;
  while (defined(my $file = readdir($dh))) {
    my $fullpath = catfile($exdir, $file);
    next unless $fullpath =~ /\.pl$/i and -f $fullpath;
    push @examples_files, $fullpath;
  }
  push @examples, make_example($_) for sort @examples_files;
  $pod =~ s/\$EXAMPLES/join '', @examples/ge;

  open my $oh, '>', catfile($libdir, $exdirname.".pod") or die "Could not open file for writing: $!";
  print $oh $pod;
  close $oh;
}

sub make_example {
  my $file = shift;
  my $text = do {local $/; open my $fh, '<', $file or die "Could not open file '$file' for reading: $!"; <$fh>};

  my $filename = $file;
  $filename =~ s{^.*/([^/]+)$}{$1};
  $text =~ s/^/  /mg;
  my $pod = <<HERE;

=head2 $filename

$text

HERE
}

__DATA__

=head1 NAME

SOOT::Examples::$DIRNAME - SOOT Examples for $DIRNAME

=head1 DESCRIPTION

This is a listing of all SOOT examples for $DIRNAME.

=head1 EXAMPLES

$EXAMPLES

=head1 SEE ALSO

L<SOOT>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

SOOT, the Perl-ROOT wrapper, is free software; you can redistribute it and/or modify
it under the same terms as ROOT itself, that is, the GNU Lesser General Public License.
A copy of the full license text is available from the distribution as the F<LICENSE> file.

=cut

