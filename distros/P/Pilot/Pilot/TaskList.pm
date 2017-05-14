# TaskLisk
#
# This module is useful for processing the contents of Pilot "todo"
# databases directly.

require 5.001;

package Pilot::TaskList;

use Pilot::DB;
@ISA = qw(Pilot::DB);

sub new {
    my $self = new Pilot::DB @_;
    bless $self;
    return $self;
}

sub CompareRecord {
    my $diff = $a->{"Priority"} <=> $b->{"Priority"};
    if ($diff == 0) {
        $diff = $a->{"Done"} <=> $b->{"Done"};
    }
    if ($diff == 0) {
        $diff = $a->{"Due"} <=> $b->{"Due"};
    }
    return $diff;
}

sub ReadTaskList {
    my ($pilot, $cat) = @_;

    my @tasks = ();
    my $db    = new Pilot::TaskList;

    $db->Read($pilot->{"Path"} . '\todo\todo.dat',
              $cat => { "Object" => \@tasks });

    return sort CompareRecord @tasks;
}

sub before_records {
    # jww: skip some unknown data; length is given

    $self->{"MiscLength"} = Pilot::DB::read_word;
    $self->{"MiscData"}   = Pilot::DB::read_db $self->{"MiscLength"};
}

sub read_record {
    my ($self, $descriptors) = @_;

    my $ref = $self->start_record();
    
    # details about the task
    
    $ref->{"Description"} = Pilot::DB::read_field;
    $ref->{"Date"}        = Pilot::DB::read_field;
    $ref->{"Done"}        = Pilot::DB::read_field;
    $ref->{"Priority"}    = Pilot::DB::read_field;
    $ref->{"Private"}     = Pilot::DB::read_field;

    my $descriptor = $self->read_category($descriptors, $ref);
    
    $ref->{"Note"}        = Pilot::DB::read_note;

    # finish up the record

    return $self->finish_record($descriptor, $ref);
}

1;
