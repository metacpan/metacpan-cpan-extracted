# MemoPad
#
# This module is useful for processing the contents of Pilot memopad
# databases directly.

require 5.001;

package Pilot::MemoPad;

use Pilot::DB;
@ISA = qw(Pilot::DB);

sub new {
    my $self = new Pilot::DB @_;
    bless $self;
    return $self;
}

sub before_records {
    for (1 .. 10) {
        $self->{"MiscData$_"} = Pilot::DB::read_dword;
    }
}

sub read_record {
    my ($self, $descriptors) = @_;

    my $ref = $self->start_record();

    # details about the memo

    $ref->{"Note"}    = Pilot::DB::read_note;
    $ref->{"Private"} = Pilot::DB::read_field;

    my $descriptor = $self->read_category($descriptors, $ref);

    # finish up the record

    return $self->finish_record($descriptor, $ref);
}

1;
