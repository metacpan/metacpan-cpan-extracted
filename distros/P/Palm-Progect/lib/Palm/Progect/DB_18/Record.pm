

package Palm::Progect::DB_18::Record;
use base Palm::Progect::Record;
use Time::Local;

use Palm::Progect::Constants;

my $Perl_Version = $];

my @Extra_Block_Chars_Head = (
    51, 0, 0, 4
);
my @Extra_Block_Chars_Tail = (
    0, 0, 64, 0,
);

use strict;
use 5.004;

use CLASS;
use base qw(Class::Constructor);

CLASS->mk_constructor(
    Auto_Init    => [ CLASS->Accessors ],
    Init_Methods => '_init',
);

sub _init {
    my $self = shift;

    my %args = @_;

    if ($args{'from_record'}) {

        # create record the values of the provided record
        # assume it has the same interface as we do.
        # But we do have to add 'category_name' to the list of our @Accessors,
        # because it is implemented not by us directly, but by our parent class

        foreach my $accessor (CLASS->Accessors, 'category_name') {
            $self->$accessor($args{'from_record'}->$accessor());
        }
    }

    if ($args{'raw_record'}) {
        # create record from raw record data

        $self->_parse_raw_record($args{'raw_record'}{'data'});
        $self->category_id($args{'raw_record'}{'category'});
    }

}

sub raw_record {
    my $self = shift;
    return $self->_pack_raw_record;
}

# Input/Output routines

# _parse_raw_record takes the binary raw record structure and populates
# the fields of $self properly

sub _parse_raw_record {
    my ($self, $record_data) = @_;

    my (
        $level,        # ok
        $flag_group1,
        $flag_group2,
        $flag_group3,
        $priority,     # ok
        $completed,    # ok
        $date_b1,
        $date_b2,

    ) = unpack 'CCCCCCCC', $record_data;

    $self->level($level);

    # Perl won't unpack more than one ASCIIZ string at a time,
    # so we have to unpack them one at a time, skipping the
    # proper number of bytes each time:

    my $offset = 8;  #   8 bytes of flags

    my $description = unpack "x${offset}Z*", $record_data;
    $self->description($description);

    $offset += length($description) + 1;

    my $note = unpack "x${offset}Z*", $record_data;
    $self->note($note);

    if ($note) {
        $offset += length($note);
    }

    # The completed field is quite complicated and context specific:
    #   < 10 == PERCENTAGE
    #     16 == INFORMATIVE
    #     11 == ACTION
    #     12 == ACTION_OK
    #     13 == ACTION_NO
    #   > 20 == NUMERIC

    my $type = 0;
    if ($completed >= 11 and $completed <= 13) {
        $type = RECORD_TYPE_ACTION;
        $self->completed($completed == 12 ? 1 : undef);
    }
    elsif ($completed <= 10) {
        $type = RECORD_TYPE_PROGRESS;
        $self->completed($completed * 10);
    }
    elsif ($completed >= 20) {
        $type = RECORD_TYPE_NUMERIC;
        my @extra = unpack "x${offset}C*", $record_data;

        $self->completed_limit(  $extra[5] * 2**8 + $extra[6] );
        $self->completed_actual( $extra[7] * 2**8 + $extra[8] );
    }
    elsif ($completed == 16) {
        $type = RECORD_TYPE_INFO;
        $self->completed(undef);
    }
    $self->type($type);

    $self->has_next(  ($flag_group1 & 2**7) > 0 ); # ok
    $self->has_child( ($flag_group1 & 2**6) > 0 ); # ok
    $self->is_opened( ($flag_group1 & 2**5) > 0 ); # ok
    $self->has_prev(  ($flag_group1 & 2**4) > 0 ); # ok

    $self->has_todo(  ($flag_group2 & 2**3) > 0 ); # ok

    # For some reason, pri = 6 means "no priority"
    # probably because the "none" button is the 6th button
    # on the palm's screen.

    $self->priority($priority);

    if ($priority == 6) {
        $self->priority(undef);
    }

    # Date due field:
    # This field seems to be layed out like this:
    #     year  7 bits (0-128)
    #     month 4 bits (0-16)
    #     day   5 bits (0-32)

    my $day   = $date_b2 & (2**0 | 2**1 | 2**2 | 2**3 | 2**4);
    my $month = $date_b2 & (2**5 | 2**6 | 2**7);
    $month   /= (2**5);
    $month   += ($date_b1 & 1) * (2**3);

    my $year = int($date_b1 / 2); # shifts off LSB

    $year    += 1904 if $year;

    my $date_due;

    eval {
        $date_due = timelocal(0,0,0,$day,$month-1,$year) if ($day && $month && $year);
    };

    $self->date_due($date_due);
}

# _pack_raw_record creates a binary raw record structure from
# the fields of self

sub _pack_raw_record {
    my $self = shift;

    my $extra_block = '';
    my $data        = '';

    my $type = $self->type || 0;

    my $completed;
    if ($type == RECORD_TYPE_ACTION) {
        $completed = $self->completed? 12 : 13;
    }
    elsif ($type == RECORD_TYPE_PROGRESS) {
        $completed = int(($self->completed || 0) / 10);
    }
    elsif ($type == RECORD_TYPE_INFO) {
        $completed = 16;
    }
    elsif ($type == RECORD_TYPE_NUMERIC) {
        if ($self->completed_actual) {
            $completed = int($self->completed_limit / $self->completed_actual / 10);
        }
        $completed += 20;
        $extra_block .= pack 'C*', @Extra_Block_Chars_Head;
        $extra_block .= pack 'n',  $self->completed_limit;
        $extra_block .= pack 'n',  $self->completed_actual;
        $extra_block .= pack 'C*', @Extra_Block_Chars_Tail;
    }

    my $flag_group_1 = (
        ($self->has_next  ? 2**7 : 0) |
        ($self->has_child ? 2**6 : 0) |
        ($self->is_opened ? 2**5 : 0) |
        ($self->has_prev  ? 2**4 : 0)
    );

    my $note    = $self->note;

    my ($date_b1, $date_b2, $has_due_date);

    if ($self->date_due) {
        my ($day, $month, $year) = (localtime $self->date_due)[3,4,5];

        if ($day && $year) {
            my $origdate = ($year + 1900).'/'.($month+1)."/$day";
            $year = $year + 1900 - 1904;
            $month = $month + 1;
            $date_b1 = $year * 2;
            $date_b1 = $date_b1 | (($month & 2**3) ? 1 : 0);

            my $month_lowbits = $month & (2**2 | 2**1 | 2**0);

            $date_b2 = ($month_lowbits * 2**5) | $day;

            $has_due_date = 1;
        }
    }
    else {
        $has_due_date = 0;
        $date_b1      = 0;
        $date_b2      = 0;
    }

    my $flag_group_2 = (
        ($has_due_date   ? 2**4 : 0) |
        ($self->has_todo ? 2**3 : 0) |
        ($note           ? 2**2 : 0)
    );

    # No priority is represented as priority=6
    my $priority = $self->priority || 6;

    $data .= pack 'CCCxCCCC', (
        ($self->level         || 0),
        ($flag_group_1        || 0),
        ($flag_group_2        || 0),
        ($priority            || 0),
        ($completed           || 0),
        ($date_b1             || 0),
        ($date_b2             || 0),
    );

    $data .= pack 'Z*', ($self->description || '');

    # Strangely, the unpack function seems
    # to have changed from 5.005 to 5.6.x
    # We need to manually add the null
    # at the end of packed strings for
    # version 5.005

    $data .= "\0" if $Perl_Version < 5.006;

    if ($note) {
        $data .= pack 'Z*', $note;
        $data .= "\0" if $Perl_Version < 5.006;
    }
    else {
        $data .= "\0";
    }

    if ($extra_block) {
        $data .= $extra_block;
    }

    my $raw_record = {
        data       => $data,
        category   => $self->category_id,
        id         => 0,
    };

    return $raw_record;
}


1;
