package Proc::ProcessTableLight;

$VERSION     = '0.01';
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(process_table);
use strict;

=head1 NAME

Proc::ProcessTableLight - Very simple variant of Proc::ProcessTable based on ps unix command

=head1 SYNOPSIS

  use strict;
  use Proc::ProcessTableLight 'process_table';
  use Data::Dumper 'Dumper';
  
  my $process_table = process_table;
  
  
  foreach my $process (@{$process_table}){
    print Dumper($process);
  }

=head1 DESCRIPTION

This module provides access to list of process.

=cut

sub process_table{
  
  my @rows=`ps axu`;
  my @process_table=();
  my @nams=();
  my $i=0;
  foreach my $row (@rows){
    $i++;
    my @p=split(/\t/, $row);
  
    if ($row=~/^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$/g){
      if ($i==1){
        @nams = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
      } else {
        my @vals = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
        my $process={};
        for (my $i=0; $i <= $#vals; $i++){
          $process->{$nams[$i]} = $vals[$i];
        }
      
        push(@process_table, $process);
      }
    }
  }

  return \@process_table;
}

=head2 process_table

run ps axu unix command and parce it in array of hash`s and return it

=cut


=head1 SEE ALSO

L<Proc::ProcessTableLight>.

=head1 AUTHOR

Bulichev Evgeniy, <F<bes@cpan.org>>.

=head1 COPYRIGHT

  Copyright (c) 2017 Bulichev Evgeniy.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut


1;