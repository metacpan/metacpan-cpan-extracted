
package SQL::Admin::Catalog::Compare;

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################

use Data::Compare;

######################################################################

our $HIDE_DROP_TABLE     = 0;
our $HIDE_DROP_COLUMN    = 0;
our $HIDE_DROP_SEQUENCE  = 0;

######################################################################
######################################################################
sub new {                                # ;
    my ($class) = @_;

    bless [], ref $class || $class;
}


######################################################################
######################################################################
sub decompose {                          # ;
    my ($self, $decomposer) = @_;
    my @retval;

    for my $command (@$self) {
        if ('HASH' eq ref $command) {
            push @retval, $command;
        } else {
            my ($name, $catalog, $data) = @$command;

            push @retval, $decomposer->$name ($catalog, $data)
              if $decomposer->can ($name);
        }
    }

    @retval;
}


######################################################################
######################################################################
sub _diff_schema {                       # ;
    my ($self, $src, $dst) = @_;
    my ($src_map, $dst_map) = map $_->list ('schema'), $src, $dst;

    push @$self, [ 'create_schema', $dst, $_ ]
      for map $dst_map->{$_}, grep ! exists $src_map->{$_}, keys %$dst_map;
}


######################################################################
######################################################################
sub _diff_sequence {                     # ;
    my ($self, $srccat, $dstcat) = @_;

    my $sseq = $srccat->list ('sequences') || {};
    my $dseq = $dstcat->list ('sequences') || {};
    my $dsc  = $dstcat->{_schema} || {};

    # drop sequences
    ##################################################################
    unless ($HIDE_DROP_SEQUENCE) {
        push @$self, [ drop_sequence => $srccat, $_ ]
          for grep exists $dsc->{$_->{schema}},
              map  $sseq->{$_},
              grep ! exists $dseq->{$_},
              keys %$sseq;
    }

    # create sequences
    ##################################################################
    push @$self, { create_sequence => $dstcat, $dseq->{$_} }
      for grep ! exists $sseq->{$_},     # -- not in src
          keys %$dseq;                   # ++ all dst sequences

    ##################################################################

    1;
}


######################################################################
######################################################################
sub _diff_table {                        # ;
    my ($self, $srccat, $dstcat) = @_;

    my $stab = $srccat->list ('table') || {};
    my $dtab = $dstcat->list ('table') || {};
    my $dsc  = $dstcat->{_schema} || {};

    # drop tables
    ##################################################################
    unless ($HIDE_DROP_TABLE) {
        push @$self, [ 'drop_table', $srccat, $stab->{$_} ]
          for grep exists $dsc->{$_->{schema}},
              map  $stab->{$_},
              grep ! exists $dtab->{$_},
              keys %$stab;
    }

    # create tables
    ##################################################################
    push @$self, [ 'create_table', $dstcat, $dtab->{$_} ]
      for grep ! exists $stab->{$_},     # -- not in src
          keys %$dtab;                   # ++ all dst tables

    ##################################################################

    1;
}


######################################################################
######################################################################
sub _diff_column {                       # ;
    my ($self, $srccat, $dstcat) = @_;
    my $scol = $srccat->list ('column');
    my $dcol = $dstcat->list ('column');
    my $dtab = $dstcat->list ('table');
    my $stab = $srccat->list ('table');

    # drop columns
    ##################################################################
    unless ($HIDE_DROP_COLUMN) {
        push @$self, [ 'drop_column', $srccat, $scol->{$_} ]
          for grep $stab->{$_->{table}{fullname}},
              grep $dtab->{$_->{table}{fullname}},
              map  $scol->{$_},
              grep ! $dcol->{$_},
              keys %$scol;
    }

    # add columns
    ##################################################################
    while (my ($key, $value) = each %$dcol) {
        next if exists $scol->{$key};
        next unless exists $stab->{ $value->table->fullname };
        next unless exists $dtab->{ $value->table->fullname };

        push @$self, [ 'add_column', $dstcat, $value ];
    }
}


######################################################################
######################################################################
sub _diff_column_not_null {              # ;
    my ($self, $srccat, $dstcat) = @_;
    my $scol = $srccat->list ('column');
    my $dcol = $dstcat->list ('column');
    my $dtab = $dstcat->list ('table');
    my $stab = $srccat->list ('table');

    ##################################################################
    while (my ($key, $value) = each %$dcol) {
        # alter only existing columns
        next unless exists $scol->{$key};

        next if ($value->not_null || 0) == ($scol->{$key}->not_null || 0);

        push @$self, +{ alter_table => {
            table_name => { name => $value->table->name, schema => $value->table->schema },
            alter_table_actions => [ { alter_column => {
                column_name    => $value->name,
                not_null       => $value->not_null,
            } } ] } };
    }
}


######################################################################
######################################################################
sub _diff_column_default {               # ;
    my ($self, $srccat, $dstcat) = @_;
    my $scol = $srccat->list ('column');
    my $dcol = $dstcat->list ('column');
    my $dtab = $dstcat->list ('table');
    my $stab = $srccat->list ('table');

    ##################################################################
    while (my ($key, $value) = each %$dcol) {
        # alter only existing columns
        next unless exists $scol->{$key};

        next if Data::Compare::Compare ($value->default, $scol->{$key}->default);

        push @$self, +{ alter_table => {
            table_name => { name => $value->table->name, schema => $value->table->schema },
            alter_table_actions => [ { alter_column => {
                column_name   => $value->name,
                default_clause=> $value->default,
            } } ] } };
    }
}


######################################################################
######################################################################
sub compare {                            # ;
    my ($self, $src, $dest) = @_;
    $self = __PACKAGE__->new unless ref $self;

    @$self = ();

    $self->_diff_schema   ($src, $dest);
    $self->_diff_table    ($src, $dest);
#    $self->_diff_sequence ($src, $dest);
#    $self->_diff_index    ($src, $dest);
#    # $self->_diff_view     ($src, $dest);
#    # $self->_diff_trigger  ($src, $dest);
#    # $self->_diff_function ($src, $dest);
    $self->_diff_column   ($src, $dest);
#    {
        $self->_diff_column_not_null ($src, $dest);
        $self->_diff_column_default  ($src, $dest);
#        $self->_diff_constraints ($src, $dest);
#    }

    $self;
}


######################################################################
######################################################################
sub is_difference {                      # ;
    my $self=  shift;

    return @$self > 0;
}


######################################################################
######################################################################
sub save {                               # ;
    my ($self, $driver, @params) = @_;

    $driver = SQL::Admin->get_driver ($driver, @{ shift @params || [] } )
      unless ref $driver;

    my @list = $self->decompose ($driver->decomposer);

    ##################################################################

    my $fh = \*STDOUT;
    if ($driver->{file}) {
        open $fh, '>', $driver->{file}
          or die "Unable write to $driver->{file}: $!\n";
    }

    print $fh $driver->producer->produce (@list);
}


######################################################################
######################################################################

package SQL::Admin::Catalog::Compare;

1;

__END__

=pod

=head1 NAME

SQL::Admin::Catalog::Compare

=head1 SYNOPSIS

   use SQL::Admin::Catalog::Compare;

   my $diff = SQL::Admin::Catalog::Compare->compare (
       $source_catalog,
       $destination_catalog
   );

   say "There is a difference"
     if $diff->is_difference;

   $diff->save ('Pg');
   $diff->save ('Pg::DBI');


