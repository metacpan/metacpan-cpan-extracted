package VCP::Dest::topo_table ;

=head1 NAME

VCP::Dest::topo_table - An experimental diagram drawing "destination"

=head1 SYNOPSIS

   vcp <source> topo_table:foo.png
   vcp <source> topo_table:foo.png --skip=none ## for verbose output

=head1 DESCRIPTION

This generates an HTML chart of all files and their relationships.

=head1 OPTIONS

=over

=item --skip=#

Set the revision "skip" threshold.  This is the minimum number of
revisions you should see in a "# skipped" message in the resulting
graph.  use C<--skip=none> to prevent skipping.  The default is 5.

=back

=head1 EXAMPLES

    vcp \
      p4:public.perforce.com:1666://public/perforce/webkeeper/mod_webkeep.c \
        --rev-root= \
        --follow-branch-into \
      topo_table:foo3.png

The --rev-root= is because the presumed rev root is
"//public/perforce/webkeeper" and perforce branches sail off in to other
directories.

    vcp \
      cvs:/home/barries/src/VCP/tmp/xfree:/xc/doc/Imakefile \
      topo_table:foo3.png

=cut

$VERSION = 1 ;

use strict ;

use Carp ;
use File::Basename ;
use File::Path ;
use VCP::Debug ':debug' ;
use VCP::Dest ;
use VCP::Utils qw( empty );

use base qw( VCP::Dest ) ;
use fields (
   'TT_SKIP_THRESHOLD',    ## Where to start skipping.
   'TT_BRANCH_COLORS',     ## A hash of branch_id to color
   'TT_REV_FOO',           ## Data we need to keep per rev
   'TT_REVS',              ## an ARRAY of Revs
) ;

=item new

Creates a new instance of a VCP::Dest::topo_table.

=cut

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Dest::topo_table $self = $class->SUPER::new( @_ ) ;

   $self->{TT_SKIP_THRESHOLD} = 5;
   $self->{TT_BRANCH_COLORS} = {};
   $self->{TT_REV_FOO} = {};

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $self->parse_repo_spec( $spec ) ;

   $self->repo_id( "topo_table:" . ( $self->repo_server || "" ) );

   $self->parse_options(
      $options,
      "skip=s" => \$self->{TT_SKIP_THRESHOLD},
   );

   return $self ;
}


sub backfill {
   my VCP::Dest::topo_table $self = shift ;
   my VCP::Rev $r ;
   ( $r ) = @_ ;

confess unless defined $self && defined $self->header ;

   return 1 ;
}


sub handle_header {
   my VCP::Dest::topo_table $self = shift ;
   $self->SUPER::handle_header( @_ ) ;
}


sub handle_rev {
   my VCP::Dest::topo_table $self = shift ;
   my ( $r ) = @_;

   push @{$self->{TT_REVS}}, $r;

   $self->{TT_REV_FOO}->{$r->previous_id}->{COUNT}++
      if defined $r->previous_id;
}

sub _html_esc {
   my $s = shift;
   $s =~ s/\&/\&amp;/g;
   $s =~ s/\"/\&quot;/g;
   $s =~ s/\>/\&gt;/g;
   $s =~ s/\</\&lt;/g;
   $s =~ s/ /&#160;/g;
   $s =~ s/\n/<br \/>\n/g;
   return $s;
}

sub emit_table {
   my $self = shift;

   my $name = shift;

   print "<table border='1'>\n";
   print "  <caption>", _html_esc( $name ), "</caption>\n";
   for my $row ( @_ ) {
      print "  <tr valign='top'>\n";
      for my $cell ( @$row ) {
         my ( $tag, $text, $bgcolor, $align ) = ref $cell
            ? (
               ( $cell->{type} || "" ) eq "label" ? "th" : "td",
               @{$cell}{"text", "bgcolor", "align" },
            )
            : ( "td", $cell );

         $text = "" unless defined $text;

         my @attrs;

         push @attrs, "bgcolor='" . _html_esc( $bgcolor ) . "'"
            unless empty $bgcolor;

         push @attrs, "align='" . _html_esc( $align ) . "'"
            unless empty $align;

         $tag = join " ", $tag, @attrs;
          
         print "    <$tag>", _html_esc( $text ), "</$tag>\n";
      }
      print "  </tr>\n";
   }
   print "</table>\n";
}


sub handle_footer {
   my VCP::Dest::topo_table $self = shift ;

   my $fn = $self->repo_filespec;

#   my ( $ext ) = ( $fn =~ /\.([^.]*)\z/ );
#   my $method = "as_$ext";

   my @names = do {
      my %names;
      $names{$_->source_name} = 1
         for @{$self->{TT_REVS}};
      sort keys %names;
   };

   my %name_to_column_map;
   for my $name ( @names ) {
      $name_to_column_map{$name} = keys %name_to_column_map;
   }

   my @rev_rows;
   my %invariants;
   my @row_invariants;
   my @col_invariants;
   my @disp_fields = qw(
      source_repo_id source_name name change_id rev_id time action branch_id user_id comment
   );

   {
      my $row;
      my $prev_r;

      for my $r ( @{$self->{TT_REVS}} ) {
         $prev_r = undef unless $prev_r && $prev_r->change_id == $r->change_id;
         push @rev_rows, $row = [] unless $prev_r;
         my $row_num = $#rev_rows;
         my $col_num = $name_to_column_map{$r->source_name};
         $row->[$col_num] = $r;
         $prev_r = $r;

         for my $field ( @disp_fields ) {
            my $value = { text => $r->$field() };

            for (
               \%invariants,
               $row_invariants[$row_num],
               $col_invariants[$col_num]
            ) {
               if ( ! exists $_->{$field} ) {
                  ## First entry for this column
                  $_->{$field} = $value;
               }
               elsif ( ! defined $_->{$field} ) {
                  ## It's not aggregatable according to previous entries
               }
               elsif (
                  defined $_->{$field}->{text} 
                     ? defined $value->{text}
                        ? $_->{$field}->{text} ne $value->{text}
                        : 0
                     : defined $value->{text}
               ) {
                  ## It's not aggregatable
                  $_->{$field} = undef;
               }
            }
         }
      }
   }

   ## Clean up all the undefs
   for my $h ( \%invariants, @row_invariants, @col_invariants ) {
      delete $h->{$_} for grep ! defined $h->{$_}, keys %$h;
   }

   my @table_invariant_fields = grep exists $invariants{$_}, @disp_fields;

   ## Don't report table-wide invariants in rows and in columns
   for my $field ( @table_invariant_fields ) {
      delete $_->{$field} for @row_invariants, @col_invariants;
   }

   ## Eliminate row and column invariants that aren't always
   ## invariants
   for my $inv_array ( \@col_invariants, \@row_invariants ) {
      my $count = 0;
      my %counts;

      ## Count how many of each there are
      for my $inv ( @$inv_array ) {
         ++$count;
         ++$counts{$_} for keys %$inv;
      }

      ## Remove those that vary too much
      for my $field ( keys %counts ) {
         if ( $counts{$field} < $count * 1 ) {
            for my $inv ( @$inv_array ) {
               delete $inv->{$field};
            }
         }
      }
   }

   ## Figure out what label rows and cols we need.
   my @col_invariant_fields;
   my @row_invariant_fields;
   for my $field ( @disp_fields ) {
      push @col_invariant_fields, $field
         if grep exists $_->{$field}, @col_invariants;
      push @row_invariant_fields, $field
         if grep exists $_->{$field}, @row_invariants;
   }

   my @rows;  ## The main table
   {
      my $label_cols = @row_invariant_fields;
      ## Leave room for the col labels even if there are no per-row labels
      $label_cols = 1 if @col_invariants && ! $label_cols;

      ## Leave room for the row labels even if there is no per-col labels
      my $label_rows = @col_invariant_fields;
      $label_rows = 1 if @row_invariants && ! $label_rows;

      ++$label_rows, ++$label_cols
         if $label_rows && $label_cols;

      {
         ## Label and fill in the column invariants
         my $row_num = 0;
         for my $field ( @col_invariant_fields ) {
            $rows[$row_num]->[$label_cols-1] = {
               type => "label",
               text => $field,
            };
            my $col_num = $label_cols;
            for ( @col_invariants ) {
               $rows[$row_num]->[$col_num] = $_->{$field};
               ++$col_num;
            }

            ++$row_num;
         }

         ## Grey out the cells under the col invariants
         ## and to the right of the row of row invariant labels
         if ( $label_cols ) {
            my $col_num = $label_cols;
            for ( @col_invariants ) {
               $rows[$row_num]->[$col_num] = {
                  text    => "\n",
                  bgcolor => "#808080",
               };
               ++$col_num;
            }
         }
      }

      {
         ## Label and fill in the row invariants
         my $col_num = 0;
         for my $field ( @row_invariant_fields ) {
            $rows[$label_rows-1]->[$col_num] = {
               type => "label",
               text => $field
            };
            my $row_num = $label_rows;
            for ( @row_invariants ) {
               $rows[$row_num]->[$col_num] = $_->{$field};
               ++$row_num;
            }
            ++$col_num;
         }

         ## Grey out the cells under the col invariants
         ## and to the right of the row of row invariant labels
         ## Grey out the cells under the col invariants
         if ( $label_rows ) {
            my $row_num = $label_rows;
            for ( @row_invariants ) {
               $rows[$row_num]->[$col_num] = {
                  text    => "\n",
                  bgcolor => "#808080",
               };
               ++$row_num;
            }
         }
      }

      my %cell_fields = map { ( $_ => undef ) } @disp_fields;
      delete $cell_fields{$_}
         for @table_invariant_fields,
             @col_invariant_fields,
             @row_invariant_fields;

      my @cell_fields = grep exists $cell_fields{$_}, @disp_fields;

      {
         my $row_num = $label_rows;
         for my $rev_row ( @rev_rows ) {
            my $col_num = $label_cols;
            for my $r ( @$rev_row ) {
               if ( $r ) {
                  my $v =  join "\n",
                     map { defined $r->$_() ? $r->$_() : "undef" }
                        @cell_fields;
                  $rows[$row_num]->[$col_num] = $v;
               }
               ++$col_num;
            }
            ++$row_num;
         }
      }
   }
   print "<html><body bgcolor='#FFFFFF'>\n";

   $self->emit_table(
      "Invariant Fields",
      map [
         {
            type => "label",
            text => $_,
         },
         $invariants{$_}
      ],
         grep exists $invariants{$_}, @disp_fields
   ) if keys %invariants;

   $self->emit_table(
      "Revisions",
      @rows
   ) if @rows;

   print "</body></html>\n";
}


=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
