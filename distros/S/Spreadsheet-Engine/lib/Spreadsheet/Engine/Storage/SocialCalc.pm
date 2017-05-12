package Spreadsheet::Engine::Storage::SocialCalc;

use strict;
use warnings;

use Carp;
use IO::File;

use Spreadsheet::Engine;

=head1 NAME

Spreadsheet::Engine::Storage::SocialCalc - load SocialCalc files

=head1 SYNOPSIS

  use Spreadsheet::Engine::Storage::SocialCalc;

  my Spreadsheet::Engine $sheet =
       Spreadsheet::Engine:Storage::SocialCalc->load($file);

=head1 DESCRIPTION

This instantiates a Spreadsheet::Engine from a saved file in the
SocialCalc format.

=head1 METHODS

=head2 load

  my Spreadsheet::Engine $sheet =
       Spreadsheet::Engine:Storage::SocialCalc->load($file);

Load a saved file.

=cut

sub load {
  my ($class, $file) = @_;
  my $datafile = IO::File->new($file) or croak "Can't open $file: $!\n";

  my ($line,        $boundary);
  my ($headerlines, $sheetlines);

  while ($line = <$datafile>) {
    last if $line =~ m/^Content-Type:\smultipart\/mixed;/i;
  }
  $line =~ m/\sboundary=(\S+)/i;
  $boundary = $1 or croak "No boundary found in $file";

  while ($line = <$datafile>) {
    $line =~ s/\r//g;
    last if $line =~ m/^--$boundary$/o;
  }

  while ($line = <$datafile>) {    # go to blank line
    chomp $line;
    $line =~ s/\r//g;
    last unless $line;
  }

  my $bregex = qr/^--$boundary/;

  while ($line = <$datafile>) {    # copy header lines
    last if $line =~ m/$bregex/;
    push @{$headerlines}, $line if $headerlines;
  }

  while ($line = <$datafile>) {    # go to blank line
    chomp $line;
    $line =~ s/\r//g;
    last unless $line;
  }

  while ($line = <$datafile>) {    # copy sheet lines
    last if $line =~ m/$bregex/;
    push @{$sheetlines}, $line;
  }

  return Spreadsheet::Engine->load_data($sheetlines);

}

1;

=head1 HISTORY

This is a modified version of code from SocialCalc::DataFiles in
SocialCalc 1.1.0

=head1 AUTHORS

wikiCalc was developed by Dan Bricklin, at Software Garden, Inc. 

SocialCalc 1.1.0 was developed by Dan Bricklin, Casey West, and Tony
Bowden, at Socialtext, Inc. 

Spreadsheet::Engine is developed and maintained by Tony Bowden
<tony@tmtm.com>

=head1 COPYRIGHT

Portions (c) Copyright 2005, 2006, 2007 Software Garden, Inc.
All Rights Reserved.

Portions (c) Copyright 2007 Socialtext, Inc.
All Rights Reserved.

Portions (c) Copyright 2007 Tony Bowden

=head1 LICENCE

The contents of this file are subject to the Artistic License 2.0;
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.perlfoundation.org/artistic_license_2_0

=cut

