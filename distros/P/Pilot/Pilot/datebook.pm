# DateBook
#
# This module is useful for processing the contents of Pilot Date Book
# databases.

require 5.001;

package Pilot::DateBook;

use Pilot::DB;
@ISA = qw(Pilot::DB);

@QuantityTypes =
    ("Minutes",
     "Hours",
     "Days");

sub new {
    my $self = new Pilot::DB @_;
    bless $self;
    return $self;
}

sub before_records {
    # jww: skip some unknown data; length is given

    $self->{"MiscLength"} = Pilot::DB::read_dword;
    $self->{"MiscData"}   = Pilot::DB::read_db $self->{"MiscLength"};

    # jww: what do these mean?

    $self->{"MiscDWORD1"} = Pilot::DB::read_dword;
    $self->{"MiscDWORD2"} = Pilot::DB::read_dword;
}

sub read_record {
    my ($self, $descriptors) = @_;

    my $ref = $self->start_record();

    $ref->{"Start"}       = Pilot::DB::read_field;
    $ref->{"End"}         = Pilot::DB::read_field;
    $ref->{"Description"} = Pilot::DB::read_note;
    $ref->{"Number?"}     = Pilot::DB::read_field;
    $ref->{"Note"}        = Pilot::DB::read_note;
    $ref->{"Untimed"}     = Pilot::DB::read_field;
    $ref->{"Private"}     = Pilot::DB::read_field;
    $ref->{"Number?2"}    = Pilot::DB::read_field;
    $ref->{"Alarm"}       = Pilot::DB::read_field;
    $ref->{"Before"}      = Pilot::DB::read_field;
    $ref->{"Quantity"}    = $QuantityTypes[Pilot::DB::read_field];
    $ref->{"Repeat"}      = Pilot::DB::read_field;

    # private and category

    $ref->{"Private"} = read_field;

    my $descriptor    = $self->read_category($descriptors, $ref);

    # finish up the record

    return $self->finish_record($descriptor, $ref);
}

1;
