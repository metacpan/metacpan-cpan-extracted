package Mojolicious::Plugin::Tables::Model::Row;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__-> load_components('InflateColumn::DateTime');

use overload
    '""'     => sub { shift->stringify_safely },
    'bool'   => sub { 1 },
    fallback => 1;

# errors during stringification of a db object can sometimes trigger 
# deep recursion by well-meaning error messages deep in ORM internals.

sub stringify_safely {
    my $self = shift;
    return eval { $self->stringify } // do {
        my $err = $@;
        my $class  = ref $self;
        my $fallback = "[*$class]".$self->id;
        $self->log->error("stringifying $fallback: $err");
        $fallback
    }
}

# override this for each ResultClass.

sub stringify {
    my $self  = shift;
    my $cd = $self->can('cd')
                    ? (':'.$self->cd)
                    : $self->compound_ids;
    my $ds = $self->can('description')? $self->description:
             $self->can('name'       )? $self->name:
             '';
    my $label = $self->result_source->source_name;
    sprintf '[%s] %s%s', $label, $cd, ($ds? " - $ds":'')
}

sub log { shift->result_source->schema->log }

sub compound_ids {
    my $self = shift;
    join ('-|-', map { $self->get_column($_) } $self->primary_columns);
}

sub present {
    my ($self, $column, $info, %opts) = @_;
    my $class = ref $self;
    #$self->log->debug("present $column for $class using " . Dumper($info));
    my $type = $info->{data_type} || 'varchar';

    my $val = $self->$column // return;

    for ($type) {
        /timestamp/ && return ($opts{foredit}? $val->iso8601: $val->strftime('%F %T'));
        /date/      && return ($val->ymd);
        /boolean/   && return ($val?'Yes':'No');
    }
    return $val
}

# generate the full pick-list that lets the fk $column pick from its parent,
# in a structure suitable for the 'select_field' tag.  This version gets all
# (limited by safety check) but inherited versions are expected to do more
# context-sensitive filtering.  Will work as a class method.
sub options {
   #my ($self, $column, $cinfo, $pinfo, $schema, $bytable) = @_;
    my ($xxx1, $xxxxx2, $xxxx3, $pinfo, $schema, $bytable) = @_;
    my $ptable   = $pinfo->{ptable};
    my $ptabinfo = $bytable->{$ptable};
    my $psource  = $ptabinfo->{source};
    my $prs      = $schema->resultset($psource);
    my $where    = {};
    my $attrs    = {rows=>200};
    my @options  = map { 
                        [ "$_" => $_->id ]
                    } $prs->search($where, $attrs);
    return \@options;
}

sub nuke {
    my $self   = shift;
    my $s      = $self->result_source;
    my $schema = $s->schema;

    my @collections = grep { $s->relationship_info($_)->{attrs}{accessor} eq 'multi' }
                           $s->relationships;

    my $i = 0;
    $schema->txn_do( sub {
        for my $collection (@collections) {
            $i += $_->nuke for $self->$collection->all;
        }
        $self->delete;
        ++$i
    } )
}

1;

