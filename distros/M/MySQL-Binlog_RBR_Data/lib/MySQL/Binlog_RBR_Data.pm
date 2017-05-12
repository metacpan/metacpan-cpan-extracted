package MySQL::Binlog_RBR_Data;

use 5.008005;

# be as strict and verbose as possible
use warnings;
use strict;

# set version info
our $VERSION = "1.02";

use Carp qw( confess croak );

sub parse {
    my ( $class, $handle, $start_position, @interesting_tables ) = @_;

    my %interesting_tables;
    @interesting_tables{ @interesting_tables } = @_;

    my $pos;
    my @transactions;
    my $trans;

    # mysqlbinlog outputs the binlog data between two lines with:
    # DELIMITER
    # so start working after the first one
    while ( <$handle> ) {
        if ( substr( $_, 0, 5 ) eq '# at ' ) {
            $pos = 0 + substr( $_, 5 );
            next;
        }

        last
            if substr( $_, 0, 9 ) eq 'DELIMITER';
    }

    # it's an error if we didn't get the DELIMITER, probably
    # not a binlog file or a corrupted one
    $_ && substr( $_, 0, 9 ) eq 'DELIMITER'
        or croak "not a binlog file, didn't find DELIMITER";

    # want to start at some position? mysqlbinlog seeks on it, but we
    # must parse the full output until we get at that position
    if ( $start_position ) {
        while ( <$handle> ) {
            if ( substr( $_, 0, 5 ) eq '# at ' ) {
                $pos = 0 + substr( $_, 5 );

                last if $pos >= $start_position;
            }

            # got to EOF?
            last
                if substr( $_, 0, 9 ) eq 'DELIMITER';
        }

        if ( $pos < $start_position ) {
            # no guarantee $. points to 'at'
            croak "position $start_position not found in binlog, last one found was: $pos";
        }
        elsif ( $pos > $start_position ) {
            croak "position $start_position not found in binlog, next one after was: $pos, at $.";
        }
    }

    my ( $new_row, $old_row, $row );
    my $end_pos;

    return sub {
        while ( <$handle> ) {
            # position update
            if ( substr( $_, 0, 5 ) eq '# at ' ) {
                $pos = 0 + substr( $_, 5 );
                next;
            }

            # EOF?
            last
                if substr( $_, 0, 9 ) eq 'DELIMITER';

            # new transaction?
            # transactions have a BEGIN and a COMMIT
            if ( substr( $_, 0, 5 ) eq 'BEGIN' ) {
                my %transaction;

                while ( <$handle> ) {
                    # EOT?
                    last
                        if substr( $_, 0, 6 ) eq 'COMMIT';

                    # end of current record indicated by
                    # #<date and time at server> end_log_pos <position>
                    if ( substr( $_, 0, 2 ) eq '#1' # FIXME in 2020
                            && /^#\d.*end_log_pos (\d+)/ ) {
                        $end_pos = $1;
                        next;
                    }

                    # not RBR? not interested
                    substr( $_, 0, 4 ) eq '### '
                        or next;

                    # RBR statements format:

                    # INSERT INTO ...
                    # SET
                    #   values...

                    # UPDATE ...
                    # WHERE
                    #   old values...
                    # SET
                    #   new values...

                    # DELETE FROM ...
                    # WHERE
                    #   old values...

                    # so... SET defines new values
                    #       WHERE defines old values

                    if ( $old_row && substr( $_, 4, 5 ) eq 'WHERE' ) {
                        $row = $old_row;
                    }
                    elsif ( $new_row && substr ( $_, 4, 3 ) eq 'SET' ) {
                        $row = $new_row;
                    }
                    elsif ( /^### INSERT INTO (\S+)/ ) {
                        $old_row = $row = undef;

                        if ( ! @interesting_tables
                            || exists $interesting_tables{ $1 } ) {
                            $new_row = [];
                            push @{ $transaction{ $1 } }, [ $new_row ];
                        }
                        else {
                            $new_row = undef;
                        }
                    }
                    elsif ( /^### DELETE FROM (\S+)/ ) {
                        $new_row = $row = undef;

                        if ( ! @interesting_tables
                            || exists $interesting_tables{ $1 } ) {
                            $old_row = [];
                            push @{ $transaction{ $1 } }, [ undef, $old_row ];
                        }
                        else {
                            $old_row = undef;
                        }
                    }
                    elsif ( /^### UPDATE (\S+)/ ) {
                        $row = undef;

                        if ( ! @interesting_tables
                            || exists $interesting_tables{ $1 } ) {
                            $new_row = [];
                            $old_row = [];
                            push @{ $transaction{ $1 } }, [ $new_row, $old_row ];
                        }
                        else {
                            $new_row = $old_row = undef;
                        }
                    }
                    elsif ( $row && /@(\d+)=(.+)/ ) {
                        $row->[ $1 - 1 ] = $2;
                    }
                }

                # did actually get EOT?
                $_ && substr( $_, 0, 6 ) eq 'COMMIT'
                    or croak "truncated binlog file, at " . $handle->input_line_number() . ": $_";

                # last 'end_log_pos' seen
                $transaction{ end_position } = $end_pos;
                # first 'at' seen
                $transaction{ start_position } = $pos;

                return \%transaction;
            }
        }

        # actually got EOF?
        $_ && substr( $_, 0, 9 ) eq 'DELIMITER'
            or croak "truncated binlog file, at " . $handle->input_line_number() . ": $_";

        return;
    };
}

1;

__END__

=head1 NAME

MySQL::Binlog_RBR_Data - extract changed rows from RBR binlogs

=head1 SYNOPSIS

  use MySQL::Binlog_RBR_Data;

  open my $binlog, "mysqlbinlog --base64-output=DECODE-ROWS --verbose binlog.000999|";
  my $parser = MySQL::Binlog_RBR_Data->parse(
    $binlog,
    0,
    qw( accounts.User visits.Pageviews ),
  );

  while ( my $trans = $parser->() ) {
    # do stuff
  }

=head1 FUNCTIONS

=head2 parse

  my $parser = MySQL::Binlog_RBR_Data->parse( $file_handle );
  my $parser = MySQL::Binlog_RBR_Data->parse( $file_handle, $start_position );
  my $parser = MySQL::Binlog_RBR_Data->parse( $file_handle, $start_position, @tables_interested_in )

Returns a closure that will itself return the data for the next transaction, or undef if
no more data is available.

=head2 $parser

  $parser->()

Returned by L<parse>, it will return an hashref with the data for the next transaction,
or false if no more data is available.

The returned hash has the structure:

  {
    end_position => <number>,
    start_position => <number>,
    <table> => [
        # changed rows
        [
            # updated row:
            [ new row values ],
            [ old row values ],
        ],
        [
            # inserted row:
            [ new row values ],
        ]
        [
            # deleted row:
            undef,
            [ old row values ],
        ]
    ],
    ...
  }

=head1 AUTHOR

Luciano Rocha <luciano.rocha@booking.com>

=head1 COPYRIGHT

Copyright (C) 2012 by Booking.com.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
