#
# $Id: Tools.pm,v 1.4 2003/06/05 16:00:58 goedicke Exp $
#
# Copyright (c) 2003 William Goedicke. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

=head1 NAME

PeopleSoft::Tools - Procedural interface for working with tools, so
far just SQR.

=head1 SYNOPSIS

 use PeopleSoft::Tools;
 $new_buf = munge($sqr_prog_buf);
 $new_buf = unmunge($munged_sqr_buf);
 $results_in_html = profile($output_log_buf);

=cut

use strict;
use Time::Local;
use Graph;
use Getopt::Std;
use Data::Dumper;

package PeopleSoft::Tools;
use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);

@EXPORT = qw(munge
	     unmunge
	     profile
	    );
my ( $label, $max_lvl, $result_data );

=head1 DESCRIPTION

This module provides functions for working with various PeopleSoft
add-on tools, so far an SQR profiling function is provided.

The following functions are provided (and exported) by this module:

=cut

# --------------------------------- munge()

=over 3

=item munge($buf, $debug_ltr)

The munge function takes two parameters.  First, a string buffer
containing a complete SQR program.  Second is an optional letter
specifying a debug level (default is "p".  It returns another buffer
of the original SQR with debug statements for every subroutine, select
and DDL.

=back

=cut

#--------------------------------------------------
sub munge {
  my ( $sqr, $letter ) = @_;
  if ( ! defined $letter ) { $letter = "p"; }

  my ( %not_profiling, $rbuf );
  my @sqr_lines = split "\n", $sqr;

 MAN: foreach ( @sqr_lines ) {
    my $test=0;
    if ( ( /^\s*begin\-/i or /^\s*end\-/i ) and not 
	  ( /^\s*end-if\s*/i or /^\s*end-while\s*/i or /^\s*end-declare\s*/i or 
	       /^\s*end-evaluate\s*/i or
	       /^\s*begin-heading\s*/i or /^\s*end-heading\s*/i or
	       /^\s*begin-setup\s*/i or /^\s*end-setup\s*/i )
       ) { 
      $test = 1;
      my ( $locale, $type ) = parse_stmt($_);

      my $start = "#debug$letter let \$BRTimeStamp = 'PFLR:' || '$label' || ':START:' || ";
      $start .= "datetostr(datenow(),'YYYY-MM-DD HH24MISSNNNNNN')!PFLR\n";
      $start .= "#debug$letter display \$BRTimeStamp !PFLR\n";

      my $end = "#debug$letter let \$BRTimeStamp = 'PFLR:' || '$label' || ':END:' || ";
      $end .= "datetostr(datenow(),'YYYY-MM-DD HH24MISSNNNNNN')!PFLR\n";
      $end .= "#debug$letter display \$BRTimeStamp !PFLR\n";

      if ( defined $not_profiling{$label} ) { next; }

      if ( $locale eq "begin" and $type eq "dml" ) {
	$rbuf .= $start;
	$rbuf .= $_ . "\n";
      } 
      elsif ( $locale eq "end" and $type eq "dml" ) {
	$rbuf .= $_ . "\n";
	$rbuf .= $end;
      }
      elsif ( $locale eq "begin" and ( $type eq "proc" or $type eq "block" ) ) {
	$rbuf .= $_ . "\n";
	$rbuf .= $start;
      }
      elsif ( $locale eq "end" and ( $type eq "proc" or $type eq "block" ) ) {
	$rbuf .= $end;
	$rbuf .= $_ . "\n";
      } 
    }
    if ($test != 1) {
      $rbuf .= $_ . "\n";
    }
  }
  return $rbuf;
}
# --------------------------------- munge()

=over 3

=item unmunge($buf)

unmunge takes a single argument of a string buffer which contains the
contents of a previously munged SQR.  It returns an SQR with the
profiling statements removed.

=back

=cut

#----------------------------------- unmunge()
sub unmunge {
  my ( $mbuf ) = @_;
  my ( $rbuf );

  my @mbuf_lines = split "\n", $mbuf;

  foreach ( @mbuf_lines ) {
    if ( /\!PFLR/ ) { next; }
    $rbuf .= $_ . "\n";
  }
  return $rbuf;
}
# --------------------------------- 

=over 3

=item profile($output_log_buf);

profile reads a buffer containing the contents of the output from a
munged SQR.  It recurses a directed graph of the subroutines, DDL and
DML that were executed and returns HTML of the calling tree with times
called and intrinsic seconds of execution time.

=back

=cut

#--------------------------------------------------
sub profile {
  my ( $log_output ) = @_;
  my @edata = split "\n", $log_output;
  my $G_calls = new Graph;
  my ( @call_stack );

  foreach ( @edata ) {
    chomp;
    if ( ! m/^PFLR/ ) {
      next;
    }
    my ( $junk, $subr, $phase, $tstmp ) = split ":";
    my ( $year, $mon, $day, $hour, $min, $sec, $ms ) = 
      ( $tstmp =~ /(....)-(..)-(..) (..)(..)(..)(...)/ );
    my $time = Time::Local::timelocal( $sec, $min, $hour, $day, $mon, $year );
    $time += $ms/1000;

#    print "$tstmp\n";
    if ( $phase eq "START" ) {
      if ( ! $G_calls->has_vertex($subr) ) {
	$G_calls->add_vertex($subr);
	$G_calls->set_attribute("Count", $subr);
      }
      my $count = $G_calls->get_attribute("Count", $subr);
      $G_calls->set_attribute("Count", $subr, $count+1);
      if ( $#call_stack >=0 and not $G_calls->has_edge($call_stack[-1], $subr) ) {
	$G_calls->add_edge($call_stack[-1], $subr);
      }
      if ( $#call_stack >=0 ) {
	$G_calls->set_attribute("CalcTime", $call_stack[-1], $subr, $time);
      }
      push @call_stack, $subr;
    }
    elsif ( $phase eq "END" ) {
      if ( $#call_stack >0 ) {
	my $start = $G_calls->get_attribute("CalcTime", $call_stack[-2], $subr);
	my $duration = ( $time - $start ) + 
	  $G_calls->get_attribute("Duration", $call_stack[-2], $subr);
	$G_calls->set_attribute("Duration", $call_stack[-2], $subr, $duration);
      }
      pop @call_stack;
    }
    else {
      die "Not START or END; that's bad";
    }
  }

    my $lvl=1;
  foreach my $parent ( sort $G_calls->source_vertices ) {
    if ( $G_calls->has_attribute("Done", $parent) ) {
      next;
    }
    recurse( $G_calls, $parent, $lvl );
    $G_calls->set_attribute("Done", $parent, 1);
  }

  foreach my $vertex ( keys %{$G_calls->{'V'}} ) {
    my ( $ex_dur, $in_dur );
    foreach my $in_edges ( $G_calls->in_edges($vertex) ) {
      if ( $in_edges eq $vertex ) { next; }
      $ex_dur += $G_calls->get_attribute("Duration", $in_edges, $vertex);
#      print "Ex: $ex_dur, $vertex, $in_edges\n";
    }
    foreach my $out_edges ( $G_calls->out_edges($vertex) ) {
      if ( $out_edges eq $vertex ) { next; }
      $in_dur += $G_calls->get_attribute("Duration", $vertex, $out_edges);
#      print "In: $in_dur, $vertex, $out_edges\n";
    }
    my $fin_in = $ex_dur - $in_dur;
    if ( $fin_in < 0 ) {
      $ex_dur = $fin_in * -1;
      $fin_in = 0;
    }
    $G_calls->set_attribute("Ex_Dur", $vertex, $ex_dur);
    $G_calls->set_attribute("In_Dur", $vertex, $fin_in);
  }

#  print Data::Dumper::Dumper($G_calls);
#  exit;

  my $hbuf .= "<table border=1>\n<tr>";
  for ( my $i=0;$i<$max_lvl-1;$i++) {
    $hbuf .= "<th>Function"
  }
  $hbuf .= "</th><th>Count</th><th>Total</th><th>Intrinsic</th></tr>\n";
  foreach ( split "\n", $result_data ) {
    $hbuf .= "<tr><td>&nbsp;";
    my ( $subr, $lvl ) = split "!";
    for (my $i=1;$i<$max_lvl;$i++) {
      if ( $i == $lvl ) {
	$hbuf .= "$subr</td><td>&nbsp;";
      } else {
	$hbuf .= "</td><td>&nbsp;";
      }
    }
    $hbuf .= $G_calls->get_attribute("Count", $subr);
    $hbuf .= "</td><td>";
    $hbuf .= sprintf("%0.3f",$G_calls->get_attribute("Ex_Dur", $subr));
    $hbuf .= "</td><td>";
    $hbuf .= sprintf("%0.3f",$G_calls->get_attribute("In_Dur", $subr));
    $hbuf .= "</td></tr>\n";
  }
  $hbuf .= "</table>";

  my @junk = values( %{$G_calls->{'VertexSetParent'}} );
  my $total = $G_calls->get_attribute("Ex_Dur", $junk[0]);
  
  my ( %count, %norm, %intrin );
  foreach my $v ( $G_calls->vertices ) {
    $count{$v} = $G_calls->get_attribute("Count", $v);
    $intrin{$v} = $G_calls->get_attribute("In_Dur", $v);
    $norm{$v} = $intrin{$v} / $count{$v};
  }

  my $sum_buf = "<html><body>\n";

  $sum_buf .= "<table><tr>\n\n";
  $sum_buf .= "<td><table border=1>\n";
  $sum_buf .= "<tr><th colspan=2, align=\"center\">Normalized Intrinsic Duration</th></tr>\n";

  my $i=0;
  foreach my $v (sort { $norm{$b} <=> $norm{$a} } keys %norm ) {
    if ( $i++ >= 5 ) { last; }
    $sum_buf .= "<tr><td>$v</td><td>";
    $sum_buf .= sprintf("%.2f",$norm{$v});
    $sum_buf .= "</td></tr>\n";
  }
  $sum_buf .= "</table></td><td>&nbsp</td>\n";

  $sum_buf .= "<td><table border=1>\n";
  $sum_buf .= "<tr><th colspan=3, align=\"center\">Intrinsic Duration</th></tr>\n";

  my $i=0;
  foreach my $v (sort { $intrin{$b} <=> $intrin{$a} } keys %intrin ) {
    if ( $i++ >= 5 ) { last; }
    $sum_buf .= "<tr><td>$v</td><td>";
    $sum_buf .= sprintf("%.2f",$intrin{$v});
    $sum_buf .= "</td><td>";
    my $pct = sprintf("%.2f",$intrin{$v} / $total * 100);
    $sum_buf .= "$pct\%";
    $sum_buf .= "</td></tr>\n";
  }
  $sum_buf .= "</table></td><td>&nbsp</td>\n";

  $sum_buf .= "<td><table border=1>\n";
  $sum_buf .= "<tr><th colspan=2, align=\"center\">Counts</th></tr>\n";

  my $i=0;
  foreach my $v (sort { $count{$b} <=> $count{$a} } keys %count ) {
    if ( $i++ >= 5 ) { last; }
    $sum_buf .= "<tr><td>$v</td><td>$count{$v}</td></tr>\n";
  }
  $sum_buf .= "</table></td>\n";
  $sum_buf .= "</tr></table>\n\n";

  $hbuf = $sum_buf . $hbuf . "</body></html>\n";

  return $hbuf;
}
#--------------------------------------------------
sub recurse {
  my ( $G_calls, $v, $lvl ) = @_;

  $result_data .= "$v!$lvl\n";
  if ( defined $G_calls->{'Succ'}{$v} ) {
    $lvl++;
    if ( $max_lvl < $lvl ) { $max_lvl = $lvl; }
    foreach my $child ( sort keys %{$G_calls->{'Succ'}{$v}} ) {
      recurse( $G_calls, $child, $lvl );
    }
  }
  $G_calls->set_attribute("Done", $v, 1);
}
#--------------------------------------------------
sub parse_stmt {
# be aware we just get $_ in this routine we use that
  my ( $type, $locale );

  if    ( /^\s*begin-/i ) { $locale = "begin";  }
  elsif ( /^\s*end-/i   ) { $locale = "end";    }
  else { die "FATAL: I can't tell whether we're starting or ending!"; }

  if    ( /^\s*${locale}-select\s*/i     ) { $type = "select";    }
elsif ( /^\s*${locale}-sql\s*/i        ) { $type = "sql";       }
elsif ( /^\s*${locale}-procedure\s*/i  ) { $type = "proc";      }
  else                                   { $type = "block";     }

#  print "DBG2:$locale\t$type\t$_\n";

  if ( $type eq "proc" and $locale eq "begin" ) {
    ( $label ) = ( /\s*$locale-procedure\s*([-\#\w]*)/i );
  }
  elsif ( $type eq "block" ) {
    ( $label ) = ( /\s*$locale-([-\#\w]*)/i );
  }
  elsif ( ($type eq "select" or $type eq "sql" ) and 
	  $locale eq "begin" ) {
    $label .= "-dml";
    $type = "dml";
  }
  elsif ( ($type eq "select" or $type eq "sql" ) and 
	  $locale eq "end" ) {
    $type = "dml";
  }
  elsif ( $type eq "proc" and $locale eq "end" ) {
    $label =~ s/-dml//g;
  }

  return( $locale, $type );
}

1;
