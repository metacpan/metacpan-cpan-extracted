package Peta::NN::Data;
# ABSTRACT: records with named fields, to train models on and measure them by

# What models are trained on and measured by: records with named fields.
#
# A record is one thing a model is to learn something about: a noun with its
# gender and its plural, a word with its language. A model is told which
# field it reads, which it answers and which it is given beside (from, to,
# given), and takes its training pairs from here.
#
# Two things about a record are not fields but its place in the work:
#
#   held out   it is not trained on, so that there is something left to
#              measure a model by. Which records are held out is decided by
#              a field's value (by default the first field), not by chance:
#              the same record is on the same side on every run and on every
#              machine, and records that share the value stay together.
#   marked     it belongs to a named group, such as the `core` a model has
#              to get right without exception.
#
# A Data object is a view: where(), shown(), held() and marked() give a
# narrower view of the same records, and nothing is copied.

use v5.36;
use utf8;

our $VERSION = '0.2610090';

my $WORD = 0xFFFFFFFF;        # the hash below is in 32 bits, the same on every perl

# records   a list of tables, one per record
# fields    the names of their fields, in the order they are thought of
sub new ($class, %arg) {
    my $records = $arg{records} // die "records => [ { field => value, ... }, ... ] is required\n";
    my $fields  = $arg{fields}  // [ sort keys %{ $records->[0] // {} } ];
    return bless { records => $records, fields => [@$fields], held => {}, mark => {} }, $class;
}

# From a file of tab-separated lines, one record a line. Lines that start
# with # are comments, and a missing last field is empty.
#   fields   the names of the columns
sub read ($class, $file, %arg) {
    my $fields = $arg{fields} // die "fields => [ names of the columns ] is required\n";
    open my $in, '<:encoding(UTF-8)', $file or die "cannot read $file: $!\n";
    my @records;
    while (my $line = <$in>) {
        next if $line =~ /\A#/;
        chomp $line;
        my @values = split /\t/, $line, -1;
        die "$file line $.: " . scalar(@values) . " fields where there are " . scalar(@$fields) . " names\n" if @values > @$fields;
        push @records, { map { $fields->[$_] => $values[$_] // '' } 0 .. $#$fields };
    }
    close $in;
    return $class->new(records => \@records, fields => $fields);
}

# A view of some of these records, with what is known about them.
sub _view ($self, $records) {
    return bless { %$self, records => $records }, ref $self;
}

sub records ($self) { return @{ $self->{records} } }
sub count   ($self) { return scalar @{ $self->{records} } }
sub fields  ($self) { return @{ $self->{fields} } }

# The values of one field, record by record.
sub values_of ($self, $field) {
    $self->_known($field);
    return map { $_->{$field} } @{ $self->{records} };
}

sub _known ($self, @fields) {
    my %have = map { $_ => 1 } @{ $self->{fields} };
    $have{$_} or die "there is no field '$_' (there are: @{ $self->{fields} })\n" for @fields;
    return;
}

# A new field, worked out from each record: derive(name => sub ($record) { ... }).
sub derive ($self, %new) {
    for my $field (sort keys %new) {
        $_->{$field} = $new{$field}->($_) for @{ $self->{records} };
        push @{ $self->{fields} }, $field if !grep { $_ eq $field } @{ $self->{fields} };
    }
    return $self;
}

# The records a sub accepts.
sub where ($self, $accept) {
    return $self->_view([ grep { $accept->($_) } @{ $self->{records} } ]);
}

# A number from 0 up to 1 for a value: the same wherever the value occurs,
# and nothing like that of a value that differs by a letter (FNV-1a, stirred).
sub _place ($value) {
    my $hash = 2166136261;
    $hash = (($hash ^ ord) * 16777619) & $WORD for split //, $value;
    $hash ^= $hash >> 15;
    $hash  = ($hash * 2246822519) & $WORD;
    $hash ^= $hash >> 13;
    return $hash / ($WORD + 1);
}

# Hold a share of the records out of training. Which ones follows from the
# value of a field (by => name, default the first field), so records that
# share it are held out together or not at all; `by` may also be a sub that
# gives the value for a record. The records of a mark can be exempted
# (never => name): what has to be right without exception is trained on.
sub hold_out ($self, $share, %arg) {
    die "the share to hold out is a number above 0 and below 1, not '$share'\n" if !($share > 0 && $share < 1);
    my $by = $arg{by} // $self->{fields}[0];
    $self->_known($by) if !ref $by;
    my $never = defined $arg{never} ? $self->{mark}{ $arg{never} } // die "no records are marked '$arg{never}'; mark them before holding out\n" : {};
    %{ $self->{held} } = ();
    for my $record (@{ $self->{records} }) {
        next if $never->{$record};
        my $value = ref $by ? $by->($record) : $record->{$by};
        $self->{held}{$record} = 1 if _place($value) < $share;
    }
    return $self;
}

# Hold out the records a sub accepts, and no others: for data that has to be
# on the same sides as other data.
sub hold_out_if ($self, $accept) {
    %{ $self->{held} } = map { $_ => 1 } grep { $accept->($_) } @{ $self->{records} };
    return $self;
}

# The records that are trained on, and those that are held out.
sub shown ($self) { return $self->_view([ grep { !$self->{held}{$_} } @{ $self->{records} } ]) }
sub held  ($self) { return $self->_view([ grep { $self->{held}{$_} } @{ $self->{records} } ]) }

# Name a group of records: mark(core => sub ($record) { ... }). A record that
# is marked is not thereby trained on or held out; that is another question.
sub mark ($self, %group) {
    for my $name (sort keys %group) {
        $self->{mark}{$name} = { map { $_ => 1 } grep { $group{$name}->($_) } @{ $self->{records} } };
    }
    return $self;
}

sub marks ($self) { return sort keys %{ $self->{mark} } }

# The records of a named group.
sub marked ($self, $name) {
    my $group = $self->{mark}{$name} // die "no records are marked '$name' (marked are: @{[ $self->marks ]})\n";
    return $self->_view([ grep { $group->{$_} } @{ $self->{records} } ]);
}

sub is_marked ($self, $name, $record) { return ($self->{mark}{$name} // {})->{$record} ? 1 : 0 }
sub is_held   ($self, $record)        { return $self->{held}{$record} ? 1 : 0 }

# Some of the records, the same ones every time: at most $count of them,
# spread evenly over the whole.
sub sample ($self, $count) {
    my $records = $self->{records};
    return $self->_view([@$records]) if $count >= @$records;
    return $self->_view([ map { $records->[ int($_ * @$records / $count) ] } 0 .. $count - 1 ]);
}

# What a model learns from: for each record [input, answer, parameters ...].
#   from    the field a model reads
#   to      the field it answers
#   given   the fields it is told beside, in order
sub pairs ($self, %arg) {
    my $from  = $arg{from} // die "from => the field a model reads is required\n";
    my $to    = $arg{to}   // die "to => the field a model answers is required\n";
    my @given = @{ $arg{given} // [] };
    $self->_known($from, $to, @given);
    return [ map { [ @$_{ $from, $to, @given } ] } @{ $self->{records} } ];
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Data - records with named fields, to train models on and measure them by

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    use Peta::NN::Data;

    my $nouns = Peta::NN::Data->read('nouns.tsv', fields => [qw(singular gender plural listed)])
        ->derive(length => sub ($noun) { length $noun->{singular} })
        ->hold_out(0.1)
        ->mark(core => sub ($noun) { length $noun->{listed} });

    printf "%d nouns, %d of them held out, %d the core\n",
        $nouns->count, $nouns->held->count, $nouns->marked('core')->count;

    my $pairs = $nouns->shown->pairs(from => 'singular', to => 'plural', given => ['gender']);

=head1 DESCRIPTION

A record is one thing a model is to learn something about, as a table of
named fields. A model is told which field it reads, which it answers and
which it is given beside, and takes its training pairs from the data.

Whether a record is I<held out> of training follows from a field's value,
not from chance: the same record is on the same side on every run and every
machine, and records that share the value stay together. A record can also
be I<marked> as belonging to a named group, such as a C<core> a model has to
get right without exception.

C<where>, C<shown>, C<held>, C<marked> and C<sample> give views of the same
records; nothing is copied.

=head1 METHODS

=head2 new

C<< Peta::NN::Data->new(records => [ { ... }, ... ], fields => [ names ]) >>.

=head2 read

C<< Peta::NN::Data->read($file, fields => [ names ]) >>: one record per
tab-separated line; lines that start with C<#> are comments.

=head2 records

The records, as a list of tables.

=head2 count

How many records there are.

=head2 fields

The names of the fields.

=head2 values_of

C<values_of($field)>: that field's value of every record.

=head2 derive

C<< derive(name => sub ($record) { ... }) >>: a new field, worked out from
each record. Returns the data.

=head2 where

C<where(sub ($record) { ... })>: a view of the records the sub accepts.

=head2 hold_out

C<< hold_out($share, by => $field, never => $mark) >>: holds that share of
the records out of training, decided by the value of a field (the first one
unless named, or what a sub gives for a record). The records of the mark
C<never> names are not held out. Returns the data. Data made with
C<new> without C<fields> has its fields in alphabetical order, so name the
field there.

=head2 hold_out_if

C<hold_out_if(sub ($record) { ... })>: holds out the records the sub
accepts, and no others. Returns the data.

=head2 shown

A view of the records that are trained on.

=head2 held

A view of the records that are held out.

=head2 mark

C<< mark(name => sub ($record) { ... }) >>: names the group of records the
sub accepts. Returns the data.

=head2 marks

The names of the groups.

=head2 marked

C<marked($name)>: a view of that group.

=head2 is_marked

C<is_marked($name, $record)>: whether the record is in that group.

=head2 is_held

C<is_held($record)>: whether the record is held out.

=head2 sample

C<sample($count)>: a view of at most that many records, the same ones every
time, spread evenly over the whole.

=head2 pairs

C<< pairs(from => $field, to => $field, given => [ fields ]) >>: for each
record C<[input, answer, parameters ...]>, as a model is trained on.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
