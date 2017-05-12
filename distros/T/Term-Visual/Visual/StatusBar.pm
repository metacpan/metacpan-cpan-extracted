# $Id: StatusBar.pm,v 1.1 2003/04/06 12:39:02 lunartear Exp $
### Manage the status bar.

package Term::Visual::StatusBar;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = (qw($Revision: 1.1 $ ))[1];

use Carp qw(croak);


sub DEBUG () { 0 }
if (DEBUG) { open ERRS, ">status_error_file"; }

sub FIELD_TO_LINE () { 0 }  # A hash mapping field names to their lines.
sub STATUS_LINES  () { 1 }  # A list of status line definitions.

sub SL_FORMAT  () { 0 } # The sprintf format for a status line.
sub SL_VALUES  () { 1 } # The values for fields in a line.
sub SL_OFFSETS () { 2 } # A hash mapping field names to array offsets.

sub new {
  my $package = shift;
  my $self =
    bless [ { },  # FIELD_TO_LINE
            [ ],  # STATUS_LINES
          ], $package;
  return $self;
}

sub set_format {
  my $self = shift;
  my %hash = @_;
  if (DEBUG) { print ERRS %hash, " <-in statusbar\n"; }    
  for my $line (keys %hash) {
    if (DEBUG) { print ERRS "in for loop of statusbar set_format\n"; }
    if (DEBUG) { print ERRS "$hash{$line}{format} <-format value\n"; }
    if (DEBUG) { print ERRS "@{$hash{$line}{fields}} <-fields values\n"; }
    my $format = $hash{$line}{format};
    my @fields = @{$hash{$line}{fields}}; 
    if (DEBUG) { 
      print ERRS $line,"<-line\n", $format,"<-format\n", @fields,"<-fields\n";
    }

    # Build a list of values for each field.  Also build a hash to map
    # the field name to its offset in the list of values.

    my (@values, %offsets);
    for my $index (0..$#fields) {
      push @values, '';
      $offsets{$fields[$index]} = $index;
    }
    if (DEBUG) { print ERRS "built list of values and hash to map of field\n"; }

    # If the line is being redefined, then remove the old line's
    # definitions.

    if (defined $self->[STATUS_LINES]->[$line]) {
      if (DEBUG) { print ERRS "the line is being redefined\n"; }
      for my $field (keys %{$self->[STATUS_LINES]->[$line]->[SL_OFFSETS]}) {
        delete $self->[FIELD_TO_LINE]->{$field};
      }
    }

    # Store the fields to lines.

    for my $field (@fields) {
      $self->[FIELD_TO_LINE]->{$field} = $line;
    }

    if (DEBUG) { print ERRS "stored the fields to lines\n"; }

    # Store the status line definition in the object.

    $self->[STATUS_LINES]->[$line] =
      [ $format,   # SL_FORMAT
        \@values,  # SL_VALUES
        \%offsets, # SL_OFFSETS
      ];
    if (DEBUG) { print ERRS "stored the status line in the object\n"; }
  }

  if (DEBUG) { print ERRS "left main for loop in set_format\n"; }
  #TODO return the status_lines to eliminate having to call get();
  return;
}

# Set a status line value.

sub set {
if (DEBUG) { print ERRS "set called\n"; }
  my $self = shift;
#  my ($status_line, $line);
  while (@_) {
    if (DEBUG) { print ERRS "entered while loop of set()\n"; }
    my ($status_line, $line);
    my ($field, $value) = (shift, shift);

    # Find out which line the field is in.

     $line = $self->[FIELD_TO_LINE]->{$field};
    croak "unknown field \"$field\"" unless defined $line;

    # Store the value in SL_VALUES based on its offset from SL_OFFSETS.

    $status_line = $self->[STATUS_LINES]->[$line];
    my $offset = $status_line->[SL_OFFSETS]->{$field};
    $status_line->[SL_VALUES]->[$offset] = $value;
  }

  # Create a formatted line based on SL_FORMAT, and give it to the
  # terminal to display.
  my @status_lines;
  for my $line (0..$#{$self->[STATUS_LINES]}) {
    my $status_line = $self->[STATUS_LINES]->[$line];
    my $formatted_status_line = sprintf( $status_line->[SL_FORMAT],
                                         @{$status_line->[SL_VALUES]} );
    push(@status_lines, $line, $formatted_status_line);
  }
  if (DEBUG) { print ERRS join(' ', @status_lines), " <-status_lines in set\n";}
  return \@status_lines;
}

sub get {
  if (DEBUG) { print ERRS "StatusBar->get called\n"; }
  my $self = shift;
  my @status_lines;
  for my $line (0..$#{$self->[STATUS_LINES]}) {
    my $status_line = $self->[STATUS_LINES]->[$line];
    my $formatted_status_line = sprintf( $status_line->[SL_FORMAT],
                                         @{$status_line->[SL_VALUES]} );
    push(@status_lines, $line, $formatted_status_line);
  }
  return \@status_lines;
}


### End.

1;
