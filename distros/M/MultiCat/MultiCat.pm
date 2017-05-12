package File::MultiCat; 
use 5.008;
use strict;
# use -w;  -- replaced by the better...
use warnings;
# require Exporter;
# our @ISA = qw(Exporter);
# our %EXPORT_TAGS = ( 'all' => [qw(multicat)] );
# our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
# our @EXPORT = qw();
our $VERSION = '0.04';

# use vars qw(@f $f @ar $ar $fout);
use subs qw(new multicat _multicat_error);

sub new {
  my $class = shift;
  my($self)= {};
  bless ($self, $class);
  # multicat($ar);
  return ($self);
}

sub multicat {
  use vars qw(@f $f $ar @ar $fout $self);
  ($self, $ar) = @_;
  #Get the name of the site description file, open it, or open default multicat.dat
  if ($ar) {
   open(IN, $ar ) || _multicat_error('open', 'file');
  } else {
   open(IN, "multicat.dat") || _multicat_error('open', 'file', 'multicat.dat');
  }
  @f = <IN>;
  close IN || _multicat_error('close', 'file', 'multicat.dat');

  foreach $f (@f){
  # take each line of the site description file
    my (@splitLine, $ofi, $ifi);

    $f =~ s/#.*//;
    # strip comments

    # @splitLine=split(/ +/, $f);
    if($f) {@splitLine = split(' ', $f);}
      # split the line, at any number of space characters, into an array
    if (@splitLine) {$ofi = pop(@splitLine); }

      # remove last item in line, the  output filename; ('pop' it),dddd
      # leaving the rest of the line in @splitline.
    if (@splitLine){
      # test because multicat.dat might have empty lines
      # and throw an error otherwise.
        open(OUT, ">$ofi") || _multicat_error('opensk', 'file', $ofi);
          #open line's output file, the last filename on the line
        foreach $ifi (@splitLine) {
          # print "-$ifi-";
            # take each remaining filename from the line
          open(XIN, "<$ifi")|| _multicat_error('open', 'file', $ifi);
          my @dat = <XIN>;
            # write that file's data, in order read in,
            # to the line's output file
          print OUT "@dat\n";
          close XIN || _multicat_error('close', 'file', $ifi);
        }
        close OUT || _multicat_error('close', 'file', $ofi); #close line's output file
    }
  }
  return 1;
}

sub _multicat_error{
   print "problem, can't $_[0] a $_[1], named $_[2]";
   exit;   # or comment this line out and do not exit
}

1;
__END__
# Below is stub documentation for this module:

=head1 NAME

File::MultiCat - Perl extension for preprocessing/concatenating files
for websites.

=head1 SYNOPSIS

  use File::MultiCat;
  my $ob = File::MultiCat->new();
  $ob->multicat;

=head1 ABSTRACT

  Abstract for File::MultiCat, PPD (Perl Package Description) files.
  Read a file to make a website by concatenating files.
   First filenames on each line are concatenated
   to the last filename on that line, in order.

=head1 DESCRIPTION

Stub documentation for File::MultiCat, templeted by h2xs.
multicat is a module that does the following:

 Opens the specified input file,
   or 'multicat.dat' if none specified.

 Each line in the file is parsed.

 First filenames on each line are concatenated
   to the last filename on that line, in order.

 Separator between filenames is any number of spaces.

Example  of a single line of a multicat.dat file:

header.txt menu.txt a.txt footer.txt a.html

...would create a.html from
header.txt, menu.txt, a.txt, and footer.txt.
This module doesn't
have to be used to preprocess websites -- this is just the
most obvious use.  Since each line builds a file, you can
describe how to build an entire website in minutes.

(Most preprocessors work more as macro processors,
but this one acts entirely from
outside the files being created.)

The challenge to the website author is to find the best way
to make up each concatenated file leaving maximum room for
modifying the website later.

=head2 EXPORT

None by default.



=head1 SEE ALSO

See http://www.mbstevens.com/preprocessor/index.html   for further info.
The download from that site has a script (as opposed to module) under the
name mcat.pl.

Email:  webmaster@mbstevens.com

=head1 AUTHOR

Michael B. Stevens, E<lt>webmaster@mbstevens.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Michael B. Stevens

This library is free software; you can redistribute it and/or modify
it under terms of the Gnu Public License.

=cut
