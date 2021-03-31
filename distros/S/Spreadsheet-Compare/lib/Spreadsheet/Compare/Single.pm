package Spreadsheet::Compare::Single;

use Mojo::Base 'Mojo::EventEmitter', -signatures;
use Spreadsheet::Compare::Common;
use Spreadsheet::Compare::Record;

#<<<
use Spreadsheet::Compare::Config {
    allow_duplicates        => 0,
    below_limit_is_equal    => 0,
    convert_numbers         => 0,
    decimal_separator       => '.',
    diff_relative           => [],
    digital_grouping_symbol => '',
    fetch_size              => 1000,
    fetch_limit             => 0,
    ignore                  => [],
    ignore_strings          => 0,
    is_sorted               => 0,
    left                    => 'left',
    limit_abs               => 0,
    limit_rel               => 0,
    _numerical_regex        => sub {     #<<<
        my $ds  = $_[0]->_ds;
        my $dgs = $_[0]->_dgs;
        return qr/
            ^
            [-+]?
            [0-9$dgs]*
            $ds?
            [0-9]+
            ([eE][-+]?[0-9]+)?
            $
        /x;
    },    #>>>
    readers             => [],
    report_all_data     => 0,
    report_diff_row     => 0,
    right               => 'right',
    title               => '',
}, protected => 1, make_attributes => 1;
#>>>
sub counter_names { return qw/left right same diff limit miss add dup/ }

has _ds  => sub { quotemeta( $_[0]->decimal_separator ) };
has _dgs => sub { quotemeta( $_[0]->digital_grouping_symbol ) };

my( $debug, $trace );

sub init ($self) {

    croak 'The ignore parameter has to be an array reference'
        unless ref( my $ignore = $self->ignore ) eq 'ARRAY';
    croak 'The diff_relative parameter has to be an array reference'
        unless ref( my $diffr = $self->diff_relative ) eq 'ARRAY';

    # speed up logging
    ( $trace, $debug ) = get_log_settings();

    $self->diff_relative( { map { $_ => 1 } @$diffr } );

    # make sure certain attributes are evaluated and available as hash values
    $self->$_ for qw(
        convert_numbers diff_relative _dgs _ds ignore
        limit_abs limit_rel _numerical_regex
    );

    return $self;
}


sub compare ($self) {    ## no critic (ProhibitExcessComplexity)

    my $readers = $self->readers;
    croak "readers is not an array ref" unless $readers and ref($readers) eq 'ARRAY';
    for my $idx ( 0, 1 ) {
        my $r = $readers->[$idx];
        croak "invalid reader at index $idx" unless ref($r) and $r->isa('Spreadsheet::Compare::Reader');
        $r->setup();
    }

    $debug and DEBUG "Header left :", sub { Dump( $readers->[0]->header ) };
    $debug and DEBUG "Header right:", sub { Dump( $readers->[1]->header ) };

    # create internal lookups
    $self->{_look}{hdr} = $readers->[0]->header;
    $self->{_look}{h2i} = my $h2i = $readers->[0]->h2i;
    $self->{_look}{i2h} = { reverse %$h2i };
    $self->{_look}{ign} = { map { defined( $h2i->{$_} ) ? ( $h2i->{$_} => 1 ) : () } $self->ignore->@* };

    $self->emit( '_after_reader_setup', $self->{_look} );
    $self->_set_limits( $self->{_look}{hdr} );

    # shortcuts to the result arrays
    my $list_l = $readers->[0]->result();
    my $list_r = $readers->[1]->result();

    $trace and TRACE "Array ref left:",  $list_l;
    $trace and TRACE "Array ref right:", $list_r;

    my @streams = qw/Differences Missing Additional Duplicates/;
    push @streams, 'All' if $self->report_all_data;

    # emit events for each stream, this will be subscribed by reporters
    for my $name (@streams) {
        $self->emit( 'add_stream',   $name );
        $self->emit( 'write_header', $name );
    }

    my @diff_columns;

    # fetch a configured number of records possibly sorted by the identity column
    # and compare everything that is alphanumerically smaller than the
    # last fetched identity value
    my $size      = $self->is_sorted ? $self->fetch_size : ~0;
    my $last_pass = 0;
    my $fetches   = 0;
    my %count     = qw/left 0 right 0 same 0 diff 0 miss 0 add 0 dup 0 limit 0/;
    while ( $last_pass == 0 ) {

        my $done = 1;
        for my $r (@$readers) {
            my $fnbr = $r->fetch($size);
            INFO "Fetched $fnbr records from ", $r->side;
            $done &&= $r->exhausted;
        }

        my $limit_reached =
            $self->is_sorted && $self->fetch_size && $self->fetch_limit && ( ++$fetches >= $self->fetch_limit );
        $last_pass = $done || $limit_reached;

        $self->emit('after_fetch');

        # TODO: (issue) solve contradiction of chunks <> partial fetches
        #       chunks are always complete but can be unsorted, last_id makes no sense in that case
        #       this will mess up duplicate counting
        #       partial fetches are always sorted

        $last_pass = 1 if $readers->[0]->exhausted and $readers->[1]->exhausted;
        INFO "last_pass:$last_pass";

        $trace and TRACE "Ids on the left:", sub {
            Dump( [ map { $_->id } @$list_l ] );
        };
        $trace and TRACE "Ids on the right:", sub {
            Dump( [ map { $_->id } @$list_r ] );
        };

        my $last_id_l = @$list_l ? $list_l->[-1]->id : '';
        my $last_id_r = @$list_r ? $list_r->[-1]->id : '';

        unless ( $self->allow_duplicates ) {
            # check for duplicates in the id column and
            # put them into the 'Duplicates' sheet

            for my $rec ( $self->_check_duplicates( $list_l, $readers->[0]->side )->@* ) {
                $self->emit( 'write_row', 'Duplicates', $rec );
            }

            for my $rec ( $self->_check_duplicates( $list_r, $readers->[1]->side )->@* ) {
                $self->emit( 'write_row', 'Duplicates', $rec );
            }

            $count{dup} = $self->{_dup_sum};
        }

        # generate lookup hash by identity column
        my %look_r;
        for my $i ( 0 .. $#$list_r ) {
            my $r = $list_r->[$i];
            $look_r{ $r->id } //= [];
            push $look_r{ $r->id }->@*, $i;
        }

        $debug and DEBUG scalar( keys %look_r ), "  unique ids found on the right";

        # pass 1: loop over all records on the left
        #         if a corresponding record on the right is found
        #         ==> calculate the diffs
        #         ==> write to the corresponding output stream
        #         ==> mark record on the right side as DONE
        $debug and DEBUG "Processing ", scalar(@$list_l), " records on the left";
        LEFT_ROW: while ( my $rec = shift @$list_l ) {

            $self->emit( 'counters', \%count ) if $count{left} % $self->fetch_size == 0;

            my $id = $rec->id;

            $debug and DEBUG "left row with ID >>$id<<";
            $self->emit( 'write_row', 'All', $rec )
                if $self->report_all_data;

            # compare only those records that are safe and will not
            # be fetched later
            if (
                    $self->is_sorted
                and not $last_pass
                and (  $id eq $last_id_l
                    or $id eq $last_id_r )
            ) {
                $debug and DEBUG "reached end of last fetch on the left side";
                unshift @$list_l, $rec;
                if ( !$self->allow_duplicates ) {
                    $self->{_dup_seen}{ $readers->[0]->side }{$id}--;
                }
                last LEFT_ROW;
            }

            $count{left}++;

            # get the corresponding record on the right side
            my( $cor, $diff_rec ) = $self->_get_match( $rec, $list_r, $look_r{$id} );

            # add to missing sheet if no corresponding record is found
            unless ($cor) {

                $debug and DEBUG "Missing right row for ID >>$id<<";

                $self->emit( 'write_row', 'Missing', $rec );
                $count{miss}++;

                $self->emit(
                    'write_row',
                    'All',
                    Spreadsheet::Compare::Record->new(
                        rec    => [],
                        reader => $readers->[1],
                    )
                ) if $self->report_all_data;

                next LEFT_ROW;
            }

            $debug and DEBUG "found record on the right side";

            $count{right}++;

            $self->emit( 'write_row', 'All', $cor )
                if $self->report_all_data;

            my $diff = $diff_rec->diff_info;

            # skip record if no difference is found
            if (
                $diff->{equal}
                or (    $diff->{limit}
                    and $self->below_limit_is_equal )
            ) {
                $debug and DEBUG "the records are identical";
                $count{same}++;
                next LEFT_ROW;
            }

            $debug and DEBUG "difference found";

            $count{diff}++;
            $count{limit}++ if $diff->{limit};

            for my $i ( 0 .. $diff_rec->limit_mask->$#* ) {
                $diff_columns[$i]++ if $diff_rec->limit_mask->[$i] > 0;
            }

            $self->emit( 'write_fmt_row', 'Differences', $rec );

            $self->emit( 'write_fmt_row', 'Differences', $cor );

            $self->emit( 'write_fmt_row', 'Differences', $diff_rec )
                if $self->report_diff_row;

        }    # pass 1 LEFT_ROW

        $self->emit( 'counters', \%count );

        $debug and DEBUG scalar( keys $self->{_matched_right}->%* ), " matched records on the right";

        # use not already matched records from the right
        @$list_r = map { $self->{_matched_right}{$_} ? () : $list_r->[$_] } 0 .. $#$list_r;

        $debug and DEBUG scalar(@$list_r), " records left after pass 1";

        # pass 2: loop over all remaining entries on the right
        #         and add them to the additional sheet
        RIGHT_ROW: while ( my $rec = shift @$list_r ) {

            my $id = $rec->{id};
            # compare only those records that are safe and will not
            # be fetched later
            if (
                not $last_pass
                and (  $id eq $last_id_l
                    or $id eq $last_id_r )
            ) {
                $debug and DEBUG "reached end of last fetch on the right side";
                unshift @$list_r, $rec;
                if ( !$self->allow_duplicates ) {
                    $self->{_dup_seen}{ $readers->[1]->side }{$id}--;
                }
                last RIGHT_ROW;
            }

            $debug and DEBUG "found additional record on the right side $id";

            $count{right}++;

            if ( $self->report_all_data ) {
                $self->emit(
                    'write_row',
                    'All',
                    Spreadsheet::Compare::Record->new(
                        rec    => [],
                        reader => $readers->[0],
                    )
                );
                $self->emit( 'write_row', 'All', $rec );
            }

            $self->emit( 'write_row', 'Additional', $rec );

            $count{add}++;
        }    # pass 2 RIGHT_ROW

        $self->emit( 'counters', \%count );

    }    # fetch data

    $self->emit( 'mark_header', 'Differences', \@diff_columns );

    $self->emit( 'final_counters', \%count );

    $debug and DEBUG "Counters:", sub { Dump( \%count ) };

    return \%count;
}


# Check a list of record-hashes for duplicates in the field(s)
# specified by the identity. Return all affected records.
sub _check_duplicates ( $self, $list, $side ) {

    $debug and DEBUG "checking duplicates";

    my @dup_list;

    for my $rec (@$list) {

        my $id = $rec->id;

        $trace and TRACE "id:$id";
        if ( $self->{_dup_seen}{$side}{$id} ) {
            $debug and DEBUG "duplicate for id=$id, side $side";
            push @dup_list, $rec;
        }
        $self->{_dup_seen}{$side}{$id}++;
    }

    for my $side (qw/left right/) {
        $self->{_dup_side}{$side} = 0;
        for my $id ( keys $self->{_dup_seen}{$side}->%* ) {
            $self->{_dup_side}{$side}++ if $self->{_dup_seen}{$side}{$id} > 1;
        }
    }

    $self->{_dup_sum} = max( $self->{_dup_side}{$side}, $self->{_dup_side}{$side} );

    return ( \@dup_list );
}


# compare two records $l and $r:
#  - ignore fields in the ign lookup
#  - mark records as different if the absolute or relative limits are exceeded
#  - convert strings to numbers if configured
sub _compare_record ( $self, $l, $r ) {    ## no critic (ProhibitExcessComplexity)

    state $diff_default = {
        ABS_FIELD => '',
        ABS_VALUE => '',
        REL_FIELD => '',
        REL_VALUE => '',
        limit     => 0,
        equal     => 1,
    };

    my %diff = %$diff_default;
    my @limit_mask;
    my @diff_rec;

    my $drec = Spreadsheet::Compare::Record->new(
        diff_info  => \%diff,
        limit_mask => \@limit_mask,
        rec        => \@diff_rec,
        side       => 'diff',
        side_name  => 'diff',
        h2i        => $self->{_look}{h2i},
    );

    $l->diff_info( \%diff );
    $r->diff_info( \%diff );
    $l->limit_mask( \@limit_mask );
    $r->limit_mask( \@limit_mask );

    my $lrec = $l->rec;
    my $rrec = $r->rec;

    $trace and TRACE "LREC", sub { Dump($lrec) };
    $trace and TRACE "RREC", sub { Dump($rrec) };

    if ( $l->hash eq $r->hash ) {
        $debug and DEBUG "the record hashes are identical";
        @diff_rec   = map { 'EQ_HASH' } @$lrec;
        @limit_mask = map { 0 } @$lrec;
        return $drec;
    }

    my $i2h       = $self->{_look}{i2h};
    my $all_check = my $all_below = 0;
    for my $idx ( 0 .. $#$lrec ) {

        my $key = $i2h->{$idx};

        $limit_mask[$idx] = 0;

        if ( $self->{_look}{ign}{$idx} ) {
            $diff_rec[$idx] = 'IGNORED';
            next;
        }

        my $lorig = my $lval = $lrec->[$idx] // '';
        my $rorig = my $rval = $rrec->[$idx] // '';

        if ( $self->{convert_numbers} ) {
            $self->_convert_number($lval);
            $self->_convert_number($rval);
            $debug and DEBUG "$key: converted values >>$lval<< >>$rval<<";
            $lrec->[$idx] = $lval;
            $rrec->[$idx] = $rval;
        }

        if ( $lorig eq $rorig ) {
            $debug and DEBUG "$key: $lorig == $rorig in string comparison";
            $diff_rec[$idx] = 'EQ_STR';
            next;
        }

        my $rxreal = $self->{_numerical_regex};
        if ( $self->ignore_strings and $lorig !~ /$rxreal/ and $rorig !~ /$rxreal/ ) {
            $debug and DEBUG "$key: skip string comparison because ignore_strings is set";
            $diff_rec[$idx] = 'SKIP_STR';
            next;
        }
        elsif ( $lorig !~ /$rxreal/ or $rorig !~ /$rxreal/ ) {
            $debug and DEBUG "$key: $lorig != $rorig in string comparison";
            $diff_rec[$idx]   = 'NEQ_STR';
            $diff{equal}      = 0;
            $limit_mask[$idx] = 1;
            next;
        }

        no warnings qw/numeric/;    ## no critic (ProhibitNoWarnings)

        $self->_convert_number( $lval, 1 );
        $self->_convert_number( $rval, 1 );

        if ( $lval == $rval ) {
            $debug and DEBUG "$key: $lval == $rval in numerical comparison";
            $diff_rec[$idx] = 'EQ_NUM';
            next;
        }

        $debug and DEBUG "$key: $lval != $rval in numerical comparison";

        my $limit_abs = $self->{limit_abs}{$key};
        my $limit_rel = $self->{limit_rel}{$key};

        my $diff = abs( $rval - $lval );

        $diff_rec[$idx]   = $diff;
        $diff{equal}      = 0;
        $limit_mask[$idx] = 1;

        my $below = my $check = 0;
        if ( $limit_abs ne 'none' ) {
            $check++;
            if ( $diff <= $limit_abs ) {
                $debug and DEBUG "$key: diff $diff is below absolute limit ", $limit_abs;
                $below++;
            }
            if ( $diff > $diff{ABS_VALUE} ) {
                $diff{ABS_FIELD} = $key;
                $diff{ABS_VALUE} = $diff;
            }
        }

        my $rdiff =
            ( $rval == 0 or $lval == 0 )
            ? 1
            : ( $diff / abs($lval) );

        $diff_rec[$idx] = sprintf( '%.4f', $rdiff ) if $self->{diff_relative}{$key};

        if ( $limit_rel ne 'none' ) {
            $check++;
            if ( $rdiff <= $limit_rel ) {
                $debug and DEBUG "$key: diff $rdiff is below relative limit ", $limit_rel;
                $below++;
            }
            if ( $rdiff > $diff{REL_VALUE} ) {
                $diff{REL_FIELD} = $key;
                $diff{REL_VALUE} = $rdiff;
            }
        }

        if ( $check && ( $below == $check ) ) {
            $debug and DEBUG "$key: mark as diff but below limit";
            $limit_mask[$idx] = -1;
        }

        $all_check += $check;
        $all_below += $below;
    }

    $diff{limit} = $all_check && ( $all_check == $all_below );

    return $drec;
}


# Try to find the best matching record on the right list and
# save the result in an internal lookup hash

sub _get_match ( $self, $lrec, $rrecs, $rindexes ) {

    my @found;
    my $pos = 0;
    for my $ridx (@$rindexes) {
        my $rrec = $rrecs->[$ridx];

        # compare the records
        my $diff_rec   = $self->_compare_record( $lrec, $rrec );
        my $limit_mask = $diff_rec->limit_mask;
        my %found      = (
            ridx  => $ridx,
            drec  => $diff_rec,
            pos   => $pos++,
            below => scalar( grep { $_ == -1 } @$limit_mask ),
            above => scalar( grep { $_ == 1 } @$limit_mask ),
        );

        my $diff = $diff_rec->diff_info;
        if ( $diff->{equal} or ( $diff->{limit} and $self->below_limit_is_equal ) ) {
            $debug and DEBUG "found direct match";
            @found = \%found;
            last;
        }
        else {
            push @found, \%found;
        }
    }

    return unless @found;

    my $match = ( sort { $a->{below} <=> $b->{below} || $a->{above} <=> $b->{above} } @found )[0];
    splice( @$rindexes, $match->{pos}, 1 );
    my $ridx = $match->{ridx};
    $self->{_matched_right}{$ridx} = 1;

    return $rrecs->[$ridx], $match->{drec};
}

# TODO: (issue) tests for individual limits

# transform limit configuration into separate limits for each header column
sub _set_limits ( $self, $head ) {

    my $labs = $self->limit_abs;
    my $lrel = $self->limit_rel;
    my $def  = config_defaults();

    my $limit_abs_def =
        ref($labs)
        ? ( $labs->{__default__} // $def->{limit_abs} )
        : ( $labs // $def->{limit_abs} );

    my $limit_rel_def =
        ref($lrel)
        ? ( $lrel->{__default__} // $def->{limit_rel} )
        : ( $lrel // $def->{limit_rel} );

    $self->limit_abs( $labs = {} ) if ref($labs) ne 'HASH';
    $self->limit_rel( $lrel = {} ) if ref($lrel) ne 'HASH';
    for my $key (@$head) {
        $labs->{$key} //= $limit_abs_def;
        $lrel->{$key} //= $limit_rel_def;
    }

    $debug and DEBUG "absolute limits:", sub { Dump($labs) };
    $debug and DEBUG "relative limits:", sub { Dump($lrel) };

    return 1;
}


# Converts $string to a numerical value. Unless $force is
# true conversion will only be performed if $string matches
# the internal representation for numerical strings (depending
# on the setings for decimal_separator and digital_grouping_symbol)
sub _convert_number ( $self, $string, $force = '' ) {    ## no critic (RequireArgUnpacking)
    my $rir = $self->{_numerical_regex};
    my $dgs = $self->{_dgs};
    my $ds  = $self->{_ds};

    return $self unless $force or $string =~ /^$rir$/;

    no warnings qw/numeric/;                             ## no critic (ProhibitNoWarnings)
    $_[1] =~ s/$dgs//g if $dgs;
    $_[1] =~ s/$ds/\./ if $ds and $ds ne '\.';
    $_[1] += 0;

    return $self;
}


1;

=head1 NAME

Spreadsheet::Compare::Single - Module for comparing two spreadsheet datasets

=head1 SYNOPSIS

    use Spreadsheet::Compare::Single;
    my $single = Spreadsheet::Compare::Single->new(%args);
    my $result = $single->compare();

=head1 DESCRIPTION

Spreadsheet::Compare::Single analyses differences between two similar record sets
according to a defined configuration set.

=head1 ATTRIBUTES

All attributes return the object on setting and the current value if called without parameter.

    $single->attr($value);
    my $value = $single->attr;

They will usually be set by L<Spreadsheet::Compare>, after reading the values from a config file.

=head2 allow_duplicates

    possible values: 0|1
    default: 0

Try to match identical records even when a unique identity cannot be
constructed. This can significantly increase compare times on large datasets.

=head2 below_limit_is_equal

    possible values: 0|1
    default: 0

Normally differences that are inside configured limits will still be counted as
differences (only marked visually as low priority). Setting below_limit_is_equal
to a true value will result in the record counted as equal.

=head2 convert_numbers

    possible values: 0|1
    default: 0

Convert content that is treated as a numerical value to an actual numeric
value (by simply adding 0). This is e.g. handy for having numerical data in
Excel output instead of strings that look like numbers. This will not affect
the optional 'All' report that can be created with the L<report_all_data> option.

=head2 decimal_separator

    possible values: <string>
    default: '.'

Decimal separator for numerical values

=head2 diff_relative

    possible values: <list of column names>
    default: []

Report the relative instead of the absolute difference if
L<Spreadsheet::Compare::Reporter/report_diff_row> is set to a true value.

Example (as YAML config):

    diff_relative: [2,3,4]

or

    diff_relative:
        - Price
        - Quantity

=head2 digital_grouping_symbol

    possible values: <string>
    default: ','

Digital grouping symbol for numerical values

=head2 fetch_size

    possible values: <integer>
    default: 1000

When L</is_sorted> is set, L</fetch_size> determines the number of records
fetched into memory at a time.

=head2 fetch_limit

    possible values: <integer>
    default: 0

When L</is_sorted> is set, L</fetch_limit> determines the number of fetches
(of size L</fetch_size>) before the comparison stops. This is useful during
setup with large datasets where you may have columns that are different for
every row and that you better add to the ignore list. Just remember to unset
this value once you are done.

=head2 ignore

    possible values: <list of columns>
    default: empty list

Columns to ignore while comparing data. If L<Spreadsheet::Compare::Reader/header> is set
the column names have to be used. Else use the zero based column number.

=head2 ignore_strings

    possible values: 0|1
    default: 0

Only compare numerical data. This skips comparisons where both sides are not considered
to be numerical values. This depends on the setting for L</decimal_separator> and
L</digital_grouping_symbol>

=head2 is_sorted

    possible values: 0|1
    default: 0

Assume data is sorted by identity. This is needed for fetching data in
smaller batches (see L</fetch_size>) to use less memory.

=head2 left

    possible values: <string>
    default: 'left'

Name for the input on the left side of the comparison. Used for reporting.

=head2 limit_abs

    possible values: <number or key/value pairs>
    default: 0

Single value or one entry per column for specifying absolute tolorance intervals.
Differences inside the tolerance interval will be counted and reported
separately from differences outside of it. The default value of 0 means no tolerance
limit, the value B<'none'> skips the limit check with the side effect that the deviation
will not be considered in statistics output (column with highest absolute deviation).
The special key B<'__default__'> can be used to set a default for all (numerical)
columns, and subsequently setting a different limit on selected columns.

Example (as YAML config):

    limit_abs: 0.01

    or

    limit_abs:
        __default__: 0.01
        Price: 0.0001
        Quantity: 1
        Size: none

=head2 limit_rel

    possible values: <number or keys/values>
    default: undef

Single value or one entry per column for specifying relative tolerance intervals
(decimal value, not a percentage). Differences inside the tolerance
interval will be counted and reported separately from differences outside of it.
The default value of 0 means no tolerance limit, the value B<'none'> skips the
limit check with the side effect that the deviation will not be considered in
statistics output (column with highest relative deviation). The special key
B<'__default__'> can be used to set a default for all (numerical) columns, and
subsequently setting a different limit on selected columns.

    limit_rel: 0.01

or

    limit_rel:
        __default__: 0.1
        Price: 0.01
        Quantity: 1
        Size: none


=head2 readers

This attribute cannot be set from a config file.

    possible values: <list of exactly 2 Reader objects>
    default: []

The readers have to be two objects of L<Spreadsheet::Compare::Reader> subclasses
representing the left and the right side of the comparison.

=head2 report_all_data

Add an additional output stream containing all data from both sides of the comparison.
This will slow down reporting on large datasets.

=head2 right

    possible values: <string>
    default: 'right'

Name for the input on the right side of the comparison. Used for reporting.

=head2 title

    possible values: <string>
    default: ''

A title for the comparison

=head1 CONSTRUCTOR

=head2 new

    my $single = Spreadsheet::Compare::Single->new(%attributes);
    my $single = Spreadsheet::Compare::Single->new(\%attributes);

or

    my $single = Spreadsheet::Compare::Single->new
        ->title('Regression Test 1')
        ->readers([$r_left, $r_right]);

Construct a new Spreadsheet::Compare::Single object. All comparison attributes can be given to the
constructor or set individualy via their chainable set methods.

=head1 METHODS

=head2 compare

Run all configured tests of the run configuration.
Return a hashref with counters:

    {
        add   => <number of additional records on the right>,
        diff  => <number of found differences>,
        dup   => <number of duplicate rows (maximum of left and right)>,
        left  => <number of records on the left>,
        limit => <number of record with differences below set ste limits>,
        miss  => <number of records missing on the right>,
        right => <number of records on the right>,
        same  => <number of identical records>,
    }

Before running compare the readers have to be set.

=head1 EVENTS

Spreadsheet::Compare::Single is a L<Mojo::EventEmitter>.

The reporting events correspond to the methods that are implemented by
sublasses of L<Spreadsheet::Compare::Reporter>. L<Spreadsheet::Compare>
will subscribe to the events and call the methods.

Spreadsheet::Compare::Single emits the following events

=head2 add_stream

    $single->on(add_stream => sub ($obj, $name) {
        say "new stream $name for ", $obj->title;
    });

Reporting event. Signaling that a new reporting stream should be created and will be later
referenced for reporting data lines.

The possible stream names are 'Differences', 'Missing', 'Additional', 'Duplicates' and 'All'.

=head2 after_fetch

    $single->on(after_fetch => sub ($obj) {
        say "next fetch for ", $obj->title;
    });

Emitted directly after a fetch from the readers.

=head2 counters

    require Data::Dumper;
    $single->on(counters => sub ($obj, $counters) {
        say "next fetch for ", $obj->title, ":", Dumper($counters);
    });

Emitted for every handled record. Don't rely on the numbers of calls, but on the content
of the %$counters hash if you want to know how many lines where actually read from the readers.
This can be used for progress reporting.

=head2 final_counters

    require Data::Dumper;
    $single->on(final_counters => sub ($obj, $counters) {
        say "next fetch for $title:", Dumper($counters);
    });

Emitted after completing a single comparison.

=head2 mark_header

    $single->on(mark_header => sub ($obj, 'Differences', $mask) {
        # mark columns
    });

Reporting event. Emitted after completing a single comparison with a mask describing which columns
had differences (key:column_index, value:false/true)

=head2 write_fmt_row

    $single->on(write_fmt_row => sub ($obj, 'Differences', $record) {
        # write record to stream;
    });

Reporting event. Write a formatted record to the 'Differences' output stream
The record is an L<Spreadsheet::Compare::Record> and will contain information
about the differences found (see L<Spreadsheet::Compare::Record/limit_mask>).

=head2 write_header

    $single->on(write_header => sub ($obj, $stream) {
        # write header for stream;
    });

Reporting event. Write the header for an output stream.

=head2 write_row

    $single->on(write_row => sub ($obj, $stream, $record) {
        # write record to stream;
    });

Reporting event. Write a default formatted record to an output stream.
The record is an L<Spreadsheet::Compare::Record>

=cut
