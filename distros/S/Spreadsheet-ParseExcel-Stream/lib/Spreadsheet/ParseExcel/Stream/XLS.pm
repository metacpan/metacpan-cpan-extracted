package Spreadsheet::ParseExcel::Stream::XLS;

use strict;
use warnings;

use Spreadsheet::ParseExcel;
use Scalar::Util qw(weaken);
use Coro;

our $VERSION = '0.11';

sub new {
  my ($class, $file, $opts) = @_;

  $opts ||= {};
  my @password;
  if ( defined($opts->{Password}) && length($opts->{Password}) ) {
    @password = ( Password => $opts->{Password} );
  }

  my $main = Coro::State->new();
  my ($xls,$parser);

  my ($wb, $idx, $row, $col, $cell);
  my $tmp = my $handler = sub {
    ($wb, $idx, $row, $col, $cell) = @_;
    $parser->transfer($main);
  };

  my $tmp_p = $parser = Coro::State->new(sub {
    $xls->Parse($file);
    # Flag the generator that we're done
    undef $xls;
    # If we don't transfer back when done parsing,
    # it's an implicit program exit (oops!)
    $parser->transfer($main)
  });
  weaken($parser);

  $xls = Spreadsheet::ParseExcel->new(
    CellHandler => $handler,
    NotSetCell => 1,
    @password,
  );

  # Returns the next cell of the spreadsheet
  my $generator = sub {

    # Just in case we ask for the next cell when we're already done
    return unless $xls;

    $main->transfer($parser);
    return [ $wb, $idx, $row, $col, $cell ] if $xls;

    # We're done with these threads
    $main->cancel();
    $parser->cancel();
    return;
  };
  my $nxt_cell = $generator->();

  my $self = bless {
    # Save a reference to the parser so it doesn't disappear
    # until the object is destroyed.
    PARSER    => $tmp_p,
    NEXT_CELL => $nxt_cell,
    SUB       => $generator,
    TRIM      => $opts->{TrimEmpty},
    NEW_WS    => 0,
  }, 'Spreadsheet::ParseExcel::Stream::Sheet';
  $self->bind_columns( @{$opts->{BindColumns}} ) if $opts->{BindColumns};
  return $self;
}

package Spreadsheet::ParseExcel::Stream::Sheet;

sub sheet {
  my $self = shift;
  return unless $self->{NEXT_CELL};

  # NEW_WS:
  # undef - in the middle of a sheet.
  # 0 - Hit end of previous sheet and fetched next row.
  # 1 - At end of sheet but not fetched next row yet.
  # 0 and 1 will be treated as same, just undef NEW_WS and return.
  # If undef, advance to the next sheet.
  if ( ! defined $self->{NEW_WS} ) {
    # Advance to the next sheet
    my $curr_cell = $self->{NEXT_CELL};
    my $curr_sheet = $curr_cell->[1];
    my $f = $self->{SUB};
    my $nxt_cell = $f->();
    while ( $nxt_cell && $nxt_cell->[1] == $curr_sheet ) {
      $nxt_cell = $f->();
    }
    $self->{NEXT_CELL} = $nxt_cell or return;
  }
  $self->{NEW_WS} = undef;
  return $self;
}

sub workbook {
  my $self = shift;
  my $row = $self->{NEXT_CELL};
  return $row->[0];
}

sub worksheet {
  my $self = shift;
  my $row = $self->{NEXT_CELL};
  my $wb = $row->[0];
  return $wb->worksheet($row->[1]);
}

sub name {
  my $self = shift;
  return $self->worksheet()->{Name};
}

sub set_next_row {
  my ($self, $current) = @_;
  return $self->{CURR_ROW} if $current;

  return $self->{NEW_WS} = 0 if $self->{NEW_WS};

  # Save original cell so we can detect change in worksheet
  my $curr_cell = $self->{NEXT_CELL};
  my $f = $self->{SUB};

  # Initialize row with first cell
  my @row = ();
  my $nxt_cell = $f->();

  my $min_col = $self->{TRIM}
    ? ( $curr_cell->[0]->worksheet( $curr_cell->[1] )->col_range)[0]
    : 0;
  $row[ $curr_cell->[3] - $min_col ] = $curr_cell;

  # Collect current row on current worksheet
  my ( $curr_sheet, $curr_row ) = @$curr_cell[1,2];
  while ( $nxt_cell && $nxt_cell->[1] == $curr_sheet && $nxt_cell->[2] == $curr_row ) {
    $curr_cell = $nxt_cell;
    $row[ $curr_cell->[3] - $min_col ] = $curr_cell;
    $nxt_cell = $f->();
  }
  $self->{NEXT_CELL} = $nxt_cell;
  $self->{NEW_WS}++ if !$nxt_cell || $curr_sheet != $nxt_cell->[1];
  $self->{CURR_ROW} = \@row;
}

sub next_row {
  my ($self, $current, $f) = @_;
  $f ||= sub {$_->[4]};
  unless ($current) {
    my $row = $self->set_next_row();
    return unless $row;
    if ( $self->{BIND} ) {
      my @curr_row = map { defined $_ ? $f->() : $_ } @{$self->{CURR_ROW}};
      $$_ = shift @curr_row for @{$self->{BIND}};
      return 1;
    }
  }
  return [ map { defined $_ ? $f->() : $_ } @{$self->{CURR_ROW}} ];
}

sub row {
  my ($self,$current) = @_;
  return $self->next_row($current, sub {$_->[4]->value});
}

sub unformatted {
  my ($self, $current) = @_;
  return $self->next_row($current, sub {$_->[4]->unformatted});
}

sub bind_columns {
  my $self = shift;
  $self->{BIND} = [ @_ ];
}

sub unbind_columns { delete $_[0]->{BIND} }

1;

__END__

=head1 NAME

Spreadsheet::ParseExcel::Stream::XLS - Simple interface to Excel data with less memory overhead

=head1 SYNOPSIS

  my $xls = Spreadsheet::ParseExcel::Stream::XLS->new($xls_file, \%options);
  while ( my $sheet = $xls->sheet() ) {
    while ( my $row = $sheet->row ) {
      my @data = @$row;
    }
  }

=head1 DESCRIPTION

See L<Spreadsheet::ParseExcel::Stream>.

=head1 AUTHOR

Douglas Wilson, E<lt>dougw@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
