
package SQL::Admin;

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################

use Module::Load qw();
use SQL::Admin::Utils qw( refarray );

######################################################################

our %CATALOG_MAP;

######################################################################
######################################################################
sub new {                                # ;
    my $class = shift;
    $class = ref $class if ref $class;

    bless {
        -sql_admin_search => [ $class, $class ne __PACKAGE__ ? __PACKAGE__ : () ],
    }, $class;
}


######################################################################
######################################################################
sub _load_and_new {                      # ;
    my ($self, $class, @args) = @_;

    Module::Load::load ($class);
    $class->new (@args);
}


######################################################################
######################################################################
sub get_driver {                         # ;
    my ($self, $name, @args) = @_;
    my $retval;

    $retval ||= eval { $self->_load_and_new ($_ . '::Driver::' . $name, @args) }
      for @{ $self->{-sql_admin_search} };

    ##################################################################

    $retval;
}


######################################################################
######################################################################
sub get_catalog {                        # ;
    my ($self, $name, @args) = @_;

    my $cat;
    $cat = $CATALOG_MAP{$name}
      if ( (defined $name) and ($CATALOG_MAP{$name}));

    $cat ||= $self->_load_and_new ('SQL::Admin::Catalog', @args);

    $CATALOG_MAP{$name} = $cat if defined $name;

    ##################################################################

    $cat;
}


######################################################################
######################################################################
sub compare {                            # ;
    my $self = shift;
    my $args = shift if @_ > 2;

    my ($src, $dst) = map refarray ($_) ? $self->get_catalog->load (@$_) : $_, @_;

    $self
      ->_load_and_new ('SQL::Admin::Catalog::Compare', %$args)
      ->compare ($src, $dst)
      ;
}


######################################################################
######################################################################

package SQL::Admin;

1;

__END__

=pod

=head1 NAME

SQL::Admin - Maintain database schemas

=head1 SYNOPSIS

   use SQL::Admin;

   # Merge multiple SQL files
   my $catalog = SQL::Admin
      ->get_catalog
      ->load ('DB2', { file => [ 'create-schema.sql', 'update-001.sql' ] })
      ->save ('Pg', { file  => [ 'output.sql' ] });

   # ... deploy catalog
   $catalog->save ('Pg::DBI', { dbdsn  => ... });


   # Sync SQL files and db
   my $src = SQL::Admin->get_catalog;
      ->load ('Pg::DBI', { dbdsn => ... });

   my $dst = SQL::Admin->get_catalog;
      ->load ('Pg', { file => [ 'create-schema.sql' ] });

   my $diff = SQL::Admin->compare ($src, $dst);

   if ($diff->is_difference) {
       $diff->save ('Pg');
       $diff->save ('Pg::DBI', { dbdsn => ... });
   }

=head1 DESCRIPTION

