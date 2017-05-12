

package Palm::Progect::DB_23::Record;
use base Palm::Progect::Record;
use Time::Local;

use Palm::Progect::Constants;

my $Perl_Version = $];

use strict;
use 5.004;

use CLASS;
use base qw(Class::Constructor);

CLASS->mk_constructor(
    Auto_Init    => [ CLASS->Accessors ],
    Init_Methods => '_init',
);

use constant XB_TYPE_NULL            => 0;
use constant XB_TYPE_Description     => 1;
use constant XB_TYPE_Note            => 2;
use constant XB_TYPE_Link_ToDo       => 20;
use constant XB_TYPE_Link_LinkMaster => 21;
use constant XB_TYPE_Icon            => 50;
use constant XB_TYPE_Numeric         => 51;

use constant DB_RECORD_TYPE_PROGRESS => 0;  # 0
use constant DB_RECORD_TYPE_NUMERIC  => 1;  # 3
use constant DB_RECORD_TYPE_ACTION   => 2;  # 4
use constant DB_RECORD_TYPE_INFO     => 3;  # 6
use constant DB_RECORD_TYPE_EXTENDED => 4;
use constant DB_RECORD_TYPE_LINK     => 5;

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

    );

    (
        $level,        # ok
        $flag_group1,
        $flag_group2,
        $flag_group3,

    ) = unpack 'CCCC', $record_data;

    $self->level($level);

    my $offset = 4;  #   8 bytes of flags


    # Has XB: Whether the record has an extra block.
    # Should be bit 3 of flag_group3.

    my $has_xb = $flag_group3 & (2**3) ? 1 : 0;

    my ($description, $note);
    my $xb_total_size = 0;

    if ($has_xb) {

        # TaskExtendedRecordType
        # priority  b \ ExtraBlockFields.size
        # completed b /
        # dueDate   b   ExtraBlockFields.data
        # desc...   b   ExtraBlockFields.align

        # We use $xb_total_size for calculating the end of the
        # extra block (i.e. where the standard fields begin)
        # We add 2 to account for the extra block size

        $xb_total_size = unpack "x${offset}n", $record_data;
        $xb_total_size += 2;

        $offset +=2;

        # Each record can have multiple Extra Blocks.
        # Each Extra Block (XB) has a type and a size
        # and a body

        my $xb_offset  = $offset;
        my $xb_to_read = $has_xb;

        while (1) {
            my (
                $xb_type,
                $xb_subkey,
                $xb_reserve1,
                $xb_size,
            ) = unpack "x$xb_offset CCCC", $record_data;

            $xb_offset += 4;

            if ($xb_type == XB_TYPE_NULL and $xb_subkey == 0) {
                last;
            }
            if ($xb_type == XB_TYPE_Description) {   # Should not happen in db version 0.23
                $description = unpack "x$xb_offset Z$xb_size", $record_data;
                $self->description($description);
            }
            elsif ($xb_type == XB_TYPE_Note) {       # Should not happen in db version 0.23
                $note = unpack "x$xb_offset Z$xb_size", $record_data;
                $self->note($note);
            }
            elsif ($xb_type == XB_TYPE_Numeric) {
                $note = unpack "x$xb_offset Z$xb_size", $record_data;
                # completed is a reflection of the numeric/limit ratio

                my ($completed_limit, $completed_actual) = unpack "x$xb_offset nn", $record_data;

                $self->completed_actual($completed_actual);
                $self->completed_limit($completed_limit);
            }
            elsif ($xb_type == XB_TYPE_Link_ToDo) {
                # Don't handle this for now...
                # my @todo_link_data;
                # for (my $i = 0; $i < $xb_size; $i++) {
                #     push @todo_link_data, unpack "x" . ($xb_offset + $i) . "C1", $record_data;
                # }
                #
                # my @mapped_todo_link_data = map { chr $_ } @todo_link_data;
                # print "todo_link_data:\n";
                # print "[";
                # print join "|", @todo_link_data;
                # print "]\n";
                # print "mapped_todo_link_data:\n";
                # print "[";
                # print join "|", @mapped_todo_link_data;
                # print "]\n";

                # Real way
                my $todo_link_data = unpack "x$xb_offset a$xb_size", $record_data;

                print "todo_link_data:\n";
                print "[$todo_link_data]\n";

                $self->todo_link_data($todo_link_data);

            }
            elsif ($xb_type == XB_TYPE_Link_LinkMaster) {
                # Don't handle this for now...
            }
            elsif ($xb_type == XB_TYPE_Icon) {
                # Don't handle this for now...
            }
            else {
                warn "Unknown Extra Block encountered: $xb_type/$xb_subkey!\n";
            }

            # Let's just assume that if we've read in 2KB, then we've gone too far!
            if ($xb_offset > $offset + 2048) {
                warn "Extra Block is too big, and I never saw the end of it!\n";
                last;
            }

            $xb_offset += $xb_size;
        }
    }

    #
    #              size  t  s  r  z  1  2  3  4  t  s      xxtsrz1234ts
    # 01 f1 00 18 00 0c 33 00 00 04 00 14 00 05 00 00 |......3.........|
    #  r  z              B  e  t  a                    rz
    # 00 00 06 02 00 00 42 65 74 61 2d 70 72 69 6f 72 |......Beta-prior|

    # 01 f1 00 18 00 0c 33 00 00 04 00 14 00 05 00 00 |......3.........|
    # 00 00 06 02 00 00 42 65 74 61 2d 70 72 69 6f 72 |......Beta-prior|
    # 69 74 79 20 31 2c 6e 75 6d 20 35 2f 32 30 2c 63 |ity 1,num 5/20,c|
    # 61 74 20 74 77 6f 00 00                         |at two..        |


    # "Standard Fields are the following:
    #     priority
    #     completed
    #     dueDate
    #     description
    #     note
    #
    # They are stored starting at the fifth byte, or
    # (if the record has an Extra Block), they are stored after
    # the extra block

    $offset = 4 + $xb_total_size;

    ($priority,
    $completed,
    $date_b1,
    $date_b2) = unpack "x${offset}CCCC", $record_data;

    $offset += 4;

    # Type is held in 5 bits.
    # Near as I can tell, this includes the highest 4 bits of flag_group3

    my $type = $flag_group3;

    # Shift right by 4 bits
    $type = int($type / 2**4);

    if ($type == DB_RECORD_TYPE_PROGRESS ) {
        $self->type(RECORD_TYPE_PROGRESS);
        $self->completed($completed * 10);
    }
    elsif ($type == DB_RECORD_TYPE_NUMERIC ) {
        $self->type(RECORD_TYPE_NUMERIC);

        # Silently ignore divide by zero
        if ($self->completed_actual) {
            $self->completed(int($self->completed_actual / $self->completed_limit * 10));
        }
        else {
            $self->completed(0);
        }
    }
    elsif ($type == DB_RECORD_TYPE_ACTION ) {
        $self->type(RECORD_TYPE_ACTION);
        $self->completed(1) if $completed;
    }
    elsif ($type == DB_RECORD_TYPE_INFO ) {
        $self->type(RECORD_TYPE_INFO);
        $self->completed(0);
    }
    elsif ($type == DB_RECORD_TYPE_EXTENDED ) {
        $self->type(RECORD_TYPE_EXTENDED);
    }
    elsif ($type == DB_RECORD_TYPE_LINK ) {
        $self->type(RECORD_TYPE_LINK);
    }

    $description = unpack "x${offset}Z*", $record_data;
    $self->description($description);

    $offset += length($description) + 1;

    $note = unpack "x${offset}Z*", $record_data;
    $self->note($note);

    if ($note) {
        $offset += length($note);
    }

    # For some reason, pri = 6 means "no priority"
    # probably because the "none" button is the 6th button
    # on the palm's screen.

    $self->priority($priority);

    if ($priority == 6) {
        $self->priority(undef);
    }

    $self->has_next(  ($flag_group1 & 2**7) > 0 ); # ok
    $self->has_child( ($flag_group1 & 2**6) > 0 ); # ok
    $self->is_opened( ($flag_group1 & 2**5) > 0 ); # ok
    $self->has_prev(  ($flag_group1 & 2**4) > 0 ); # ok

    $self->has_todo(  ($flag_group2 & 2**3) > 0 ); # ok


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

    my $d = $self->description;

    my $db_type = 0;

    my $completed;
    if ($type == RECORD_TYPE_ACTION) {
        $db_type   = DB_RECORD_TYPE_ACTION;
        $completed = $self->completed? 10 : 0;
    }
    elsif ($type == RECORD_TYPE_PROGRESS) {
        $db_type   = DB_RECORD_TYPE_PROGRESS;
        $completed = int(($self->completed || 0) / 10);
    }
    elsif ($type == RECORD_TYPE_INFO) {
        $db_type   = DB_RECORD_TYPE_INFO;
        $completed = 0;
    }
    elsif ($type == RECORD_TYPE_NUMERIC) {
        $db_type   = DB_RECORD_TYPE_NUMERIC;
        if ($self->completed_actual) {
            $completed = int($self->completed_actual / $self->completed_limit * 10);
        }

        $extra_block .= pack 'C*', 0,
                                   12, # Total XB Size
                                   XB_TYPE_Numeric,
                                   0,  # Subkey
                                   0,  # Reserved
                                   4;  # length of block

        $extra_block .= pack 'n',  $self->completed_limit;
        $extra_block .= pack 'n',  $self->completed_actual;

        $extra_block .= pack 'C*', XB_TYPE_NULL,
                                   0,  # Subkey
                                   0,  # Reserved
                                   0;  # length of block

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

    # Shift db_type left by 4 bits, and it becomes flag_group3
    my $flag_group_3 = $db_type * 2**4;

    # Set the has_xb bit only on Numeric type records
    $flag_group_3 = $flag_group_3 | (2**3) if $type == RECORD_TYPE_NUMERIC;

    # No priority is represented as priority=6
    my $priority = $self->priority || 6;

    $data .= pack 'CCCC', (
        ($self->level         || 0),
        ($flag_group_1        || 0),
        ($flag_group_2        || 0),
        ($flag_group_3        || 0),
    );

    if ($extra_block) {
        $data .= $extra_block;
    }

    $data .= pack 'CCCC', (
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

    my $raw_record = {
        data       => $data,
        category   => $self->category_id,
        id         => 0,
    };

    return $raw_record;
}

1;
