package Rose::HTMLx::Form::DBIC;
use strict;
use Rose::HTML::Form;
use Scalar::Util qw( blessed );
use Carp;
use Moose;


BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.08';
#    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
#    @EXPORT      = qw( );
#    @EXPORT_OK   = qw( options_from_resultset init_from_dbic dbic_from_form values_hash );
#    %EXPORT_TAGS = ();
}

has 'rs' => (
    is  => 'ro',
    isa => 'DBIx::Class::ResultSet',
);

has 'form' => (
    is  => 'ro',
    isa => 'Rose::HTML::Form',
);

sub options_from_resultset {
    my( $self ) = @_;
    _options_from_resultset( $self->form, $self->rs );
}

sub init_params {
    my( $self, $params ) = @_;
    $self->options_from_resultset();
    $self->form->params( $params );
    $self->form->init_fields();
}

sub _options_from_resultset {
    my( $form, $rs ) = @_;
    for my $field ( $form->fields ){
        if ( $field->isa( 'Rose::HTML::Form::Field::SelectBox' ) ){
            my $name = $field->local_name;
            my $related_source = _get_related_source( $rs, $name );
            if( $related_source ){
                my ( $pk ) = $related_source->primary_columns;
                my $related_rs = $related_source->resultset;
                while( my $related_row = $related_rs->next ){
                    $field->add_option( $related_row->$pk => $related_row->$pk );
                }
            }
        }
    }
    for my $sub_form ( $form->forms ){
        my $name = $sub_form->name;
        my $related_source = _get_related_source( $rs, $name );
        if( $related_source ){
            my $related_rs = $related_source->resultset;
            if( $sub_form->isa( 'Rose::HTML::Form::Repeatable' ) ){
                for my $sub_sub_form ( $sub_form->forms ){
                    _options_from_resultset( $sub_sub_form, $related_rs );
                }
            }
            else {
                _options_from_resultset( $sub_form, $related_rs );
            }
        }
    }
}

sub _get_related_source {
    my ( $rs, $name ) = @_;
    if( $rs->result_source->has_relationship( $name ) ){
        return $rs->result_source->related_source( $name );
    }
    # many to many case
    my $row = $rs->new({});
    if ( $row->can( $name ) and $row->can( 'add_to_' . $name ) and $row->can( 'set_' . $name ) ){
        return $row->$name->result_source;
    }
    return;
}

sub init_from_dbic {
    my( $self, @pks ) = @_;
    my $form = $self->form;
    my $rs = $self->rs;
    return init_with_dbic( $form, $rs->find( @pks, { key => 'primary' } ) );
}

sub init_with_dbic {
    my($form, $object) = @_;

    croak "Missing required object argument"  unless($object);

    $form->clear();

    foreach my $field ($form->local_fields) {
        my $name = $field->local_name;

        if($object->can($name)) {
            # many to many case
            if( $object->can( 'add_to_' . $name ) and $object->can( 'set_' . $name ) ){
                my ( $pk ) = _get_pk_for_related( $object, $name );
                $field->add_values( map{ $_->$pk } $object->$name());
            }
            else{
                my $value = scalar $object->$name();
                if( blessed( $value ) && $value->isa( 'DBIx::Class::Row' ) ){
                    ( $value ) = $value->id;
                }
                $field->input_value( $value );
            }
        }
    }
    foreach my $sub_form ($form->forms ) {
        my $name = $sub_form->form_name;
        my $info = $object->result_source->relationship_info( $name );
        if( $info->{attrs}{accessor} eq 'multi' and $sub_form->isa( 'Rose::HTML::Form::Repeatable' ) ){
            my @sub_objects = $object->$name;
            my $i = 1;
            for my $sub_object ( @sub_objects ){
                my $sub_sub_form = $sub_form->make_form( $i++ );
                init_with_dbic( $sub_sub_form, $sub_object );
            }
        }
        elsif( $info ){
            my $sub_object = $object->$name;
            init_with_dbic( $sub_form, $sub_object );
        }
    }
}
sub _get_pk_for_related {
    my ( $object, $relation ) = @_;

    my $rs = $object->result_source->resultset;
    my $result_source = _get_related_source( $rs, $relation );
    return $result_source->primary_columns;
}

sub _delete_empty_auto_increment {
    my ( $object ) = @_;
    for my $col ( keys %{$object->{_column_data}}){
        if( $object->result_source->column_info( $col )->{is_auto_increment} 
                and 
            ( ! defined $object->{_column_data}{$col} or $object->{_column_data}{$col} eq '' )
        ){
            delete $object->{_column_data}{$col}
        }
    }
}

sub values_hash {
    my( $form ) = @_;
    
    my %hash; 
    foreach my $field ($form->local_fields) {
        $hash{$field->local_name} = $field->internal_value;
    }
    foreach my $sub_form ($form->forms ) {
        if( $sub_form->isa( 'Rose::HTML::Form::Repeatable' ) ){
            for my $sub_sub_form ( $sub_form->forms ) {
                push @{$hash{$sub_form->form_name}}, values_hash( $sub_sub_form );
            }
        }
        else{
            $hash{$sub_form->form_name} = values_hash( $sub_form );
        }
    }
    return \%hash;
}

sub dbic_from_form { 
    my( $self, @pks ) = @_;
    my $form = $self->form;
    my $rs = $self->rs;
    if ( $form->validate ){
        my $updates = values_hash( $form );
        my @primary_columns = $rs->result_source->primary_columns;
        for my $value ( @pks ){
            $updates->{shift @primary_columns} = $value;
        }
        for my $key ( @primary_columns ){
            $updates->{$key} = undef if not length( $updates->{$key} );
        }
        return $rs->recursive_update( $updates );
    }
    else {
        return;
    }
}

sub _master_relation_cond {
    my ( $object, $cond, @foreign_ids ) = @_;
    my $foreign_ids_re = join '|', @foreign_ids;
    if ( ref $cond eq 'HASH' ){
        for my $f_key ( keys %{$cond} ) {
            # might_have is not master
            my $col = $cond->{$f_key};
            $col =~ s/self\.//;
            if( $object->column_info( $col )->{is_auto_increment} ){
                return 0;
            }
            if( $f_key =~ /^foreign\.$foreign_ids_re/ ){
                return 1;
            }
        }
    }elsif ( ref $cond eq 'ARRAY' ){
        for my $new_cond ( @$cond ) {
            return 1 if _master_relation_cond( $object, $new_cond, @foreign_ids );
        }
    }
    return;
}



#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

Rose::HTMLx::Form::DBIC - Filling Forms with data from DBIC and saving data from Forms 
to DBIC records.

=head1 SYNOPSIS

  use Rose::HTML::Form::DBIC qw(options_from_resultset init_with_dbic dbic_from_form );
  use DvdForm;
  use DBSchema;
.
.
.
  $form = DvdForm->new;
  options_from_resultset( $form, $schema->resultset( 'Dvd' ) );
  $form->params( { ... } );
  $form->init_fields();
  if( $form->was_submitted ){
    if ( $form->validate ){ 
      dbic_from_form($form, $schema->resultset( 'Dvd' )->find(1));
    }
  }
  else {
    init_with_dbic($form, $schema->resultset( 'Dvd' )->find(1));
  }

=head1 DESCRIPTION

This module exports functions integrating Rose::HTML::Form with DBIx::Class.

=head1 USAGE

=head2 options_from_resultset

 Usage     : options_from_resultset( $form, $result_set )
 Purpose   : loads options for SELECT boxes from database tables
 Returns   :
 Argument  : $form - Rose::HTML::Form, $result_set - DBIx::Class::ResultSet
 Throws    : 
 Comment   : 
           : 


=head1 BUGS


=head1 SUPPORT
#rdbo at irc.perl.org


=head1 AUTHOR

    Zbigniew Lukasiak
    CPAN ID: ZBY
    http://perlalchemy.blogspot.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

