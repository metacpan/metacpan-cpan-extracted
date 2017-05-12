package PDF::Report::Table;

=head1 NAME

PDF::Report::Table - Adds table support to PDF::Report

=head1 SYNOPSIS
	
use PDF::Report;
use PDF::Report::Table;

my $pdf = new PDF::Report(
  'PageSize' => 'letter',
  'PageOrientation' => 'Portrait',
);

my $table_writer = PDF::Report::Table->new($pdf);
  
my $some_data =[
  ["test1", "test2", "test3"],
  ["test4", "test5", "test6"],
  ["test7", "test8", "test9"],
];
  
$table_writer->addTable($some_data);

=head1 DESCRIPTION

Add tables to PDF::Report.
  
=cut

use strict;
use warnings;

use PDF::Report;
use PDF::Table;

our $VERSION = '1.01';


=item $new($pdf);

my $pdf = new PDF::Report(
  'PageSize' => 'letter',
  'PageOrientation' => 'Portrait',
);
  
my $table_writer = PDF::Report::Table->new($pdf);

=cut

sub new {
  my $class = shift;
  my $report = shift;
  
  my $self = {};
  bless $self, $class;

  $self->{report} = $report;
  
  return $self;
}

=item $table_writer->addTable(@data);

$table_writer->addTable(
  $some_data,       # 2d array
  $width,           # default is none
  $padding,         # default is 5
  $bgcolor_odd,     # default is '#FFFFFF'
  $bgcolor_even,    # default is '#FFFFCC'
  );

=cut

sub addTable {
  my $self = shift @_;
  my $data = shift @_;
  my $width = shift @_ || '';
  my $padding = shift @_ || 5;
  my $bgcolor_odd = shift @_ || "#FFFFFF";
  my $bgcolor_even = shift @_ || "#FFFFCC";
  
  my $pdftable = new PDF::Table;
  
  # Figure out if it'll fit on the current page (this may need tweaking)
  if (($self->{report}->{vPos} - (length($data) * ((2 * $padding) + 12))) < 0) {
    $self->{report}->{vPos} = $self->{report}->{PageHeight} - $self->{report}->{Ymargin};
    $self->{report}->newpage();
  }
  
  # Add to page
  my ($end_page, $pages_spanned, $table_bot_y) = $pdftable->table(
    # required params
    $self->{report}->{pdf},
    $self->{report}->{page},
    $data,
    -x  => $self->{report}->{hPos},
    -start_y => $self->{report}->{vPos},
    -start_h => $self->{report}->{PageHeight},
    -w => $width, 
    -padding => $padding,
    -background_color_odd => $bgcolor_odd, 
    -background_color_even => $bgcolor_even,
  ); 
  
  # Set baseline for next position
  $self->{report}->{vPos} = $table_bot_y - 20;
}


1;
__END__

=head1 AUTHOR

Aaron Mitti, E<lt>mitti@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Aaron Mitti

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

