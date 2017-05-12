package SPOPS::Loopback;

# $Id: Loopback.pm,v 3.11 2004/06/02 00:48:21 lachoy Exp $

use strict;
use base qw( SPOPS );
use Data::Dumper  qw( Dumper );
use Log::Log4perl qw( get_logger );
use SPOPS::Secure qw( :level );

$SPOPS::Loopback::VERSION  = sprintf("%d.%02d", q$Revision: 3.11 $ =~ /(\d+)\.(\d+)/);

my $log = get_logger();

# Save objects here, indexed by ID.

my %BY_ID = ();

sub fetch {
    my ( $class, $id, $p ) = @_;
    $log->is_info &&
        $log->info( "Trying to fetch '$class' with ID '$id'" );
    return undef unless ( $class->pre_fetch_action( $id ) );
    $log->is_info &&
        $log->info( "The 'pre_fetch_action' check ran ok" );
    my $level = SEC_LEVEL_WRITE;
    if ( ! $p->{skip_security} and $class->isa( 'SPOPS::Secure' ) ) {
        $level = $class->check_action_security({ id       => $id,
                                                 required => SEC_LEVEL_READ });
    }
    $log->is_info &&
        $log->info( "The security check ran ok" );

    my ( $object );
    if ( exists $BY_ID{ $class }->{ $id } ) {
        $log->is_info &&
            $log->info( "Object exists, creating from data" );
        $object = $class->new( $BY_ID{ $class }->{ $id } )
    }
    else {
        $log->is_info &&
            $log->info( "Object doesn't exist, creating an empty one" );
        $object = $class->new({ id => $id });
    }
    $object->{tmp_security_level} = $level;
    return undef unless ( $object->post_fetch_action );
    $log->is_info &&
        $log->info( "The 'post_fetch_action' check ran ok" );
    $object->has_save;
    $object->clear_change;
    $log->is_info &&
        $log->info( "Set object saved and changed flags ok" );
    return $object;
}


sub fetch_group {
    my ( $class, $params ) = @_;
    $params ||= {};
    my @id_list = ();
    if ( scalar keys %{ $BY_ID{ $class } } == 0 ) {
        @id_list = ( 1 .. 15 ); # make up some stuff...
    }
    elsif ( $params->{where} ) {
        $log->is_info &&
            $log->info( "Fetching objects with [$params->{where}]" );
        my @values = ( ref $params->{value} ) ? @{ $params->{value} } : ();
        my ( $field, $value ) = split /\s*=\s*/, $params->{where};
        if ( $value eq '?' ) {
            $value = shift @values;
        }
        else {
            $value =~ s/[\'\"]//g;
        }
        my $id_field = $class->id_field;
        foreach my $id ( sort keys %{ $BY_ID{ $class } } ) {
            my $data = $BY_ID{ $class }->{ $id };
            if ( exists $data->{ $field } and $data->{ $field } eq $value ) {
                push @id_list, $id;
            }
        }
    }
    else {
        @id_list = sort keys %{ $BY_ID{ $class } }
    }
    $log->is_info &&
        $log->info( "Trying to fetch objects: ", join( ', ', @id_list ) );
    return [ map { $class->fetch( $_ ) } @id_list ];
}


sub fetch_iterator {
    my ( $class, $params ) = @_;
    my $items = $class->fetch_group( $params );
    require SPOPS::Iterator::WrapList;
    return SPOPS::Iterator::WrapList->new({ object_list => $items });
}


sub save {
    my ( $self, $p ) = @_;
    $log->is_info &&
        $log->info( "Trying to save object '", $self->id, "'" );
    $p ||= {};
    unless ( $self->pre_save_action({ is_add => $self->is_saved }) ) {
        $log->error( "Failed the 'pre_save_action'" );
        return undef;
    }
    if ( $self->is_saved ) {
        if ( ! $p->{skip_security} and $self->isa( 'SPOPS::Secure' ) ) {
            $self->check_action_security({ required => SEC_LEVEL_WRITE });
        }
        $log->is_info &&
            $log->info( "Passed security check ok" );

    }
    else {
        $self->id( $self->pre_fetch_id )  unless ( $self->id );
        $self->id( $self->post_fetch_id ) unless ( $self->id );
        $log->is_info &&
            $log->info( "Assigned ID '", $self->id, "'" );
    }

    my %data = %{ $self->as_data_only };
    $BY_ID{ ref( $self ) }->{ $self->id } = \%data;
    $log->is_debug &&
        $log->debug( "Saved new object: ", Dumper( \%data ) );
    unless ( $self->is_saved or $p->{skip_security} ) {
        #warn "Calling create_initial_security()\n";
        $self->create_initial_security;
    }
    unless ( $self->post_save_action ) {
        $log->is_info &&
            $log->info( "Failed the 'post_save_action'" );
        return undef;
    }
    $self->has_save;
    $self->clear_change;
    return $self;
}

# Other items in ISA will override, otherwise we want to prevent a
# warning when doing strict field checking

sub pre_fetch_id  { return undef }
sub post_fetch_id { return undef }

sub remove {
    my ( $self ) = @_;
    return undef unless ( $self->pre_remove_action );
    delete $BY_ID{ ref( $self ) }->{ $self->id };
    return undef unless ( $self->post_remove_action );
    return 1
}


sub peek {
    my ( $class, $id, $field ) = @_;
    return undef unless ( exists $BY_ID{ $class }->{ $id } );
    return $BY_ID{ $class }->{ $id }{ $field }
}

1;

__END__

=head1 NAME

SPOPS::Loopback - Simple SPOPS class used for testing rules and other goodies

=head1 SYNOPSIS

    use SPOPS::Initialize;

    my %config = (
      test => {
         class    => 'LoopbackTest',
         isa      => [ qw( SPOPS::Loopback ) ],
         field    => [ qw( id_field field_name ) ],
         id_field => 'id_field',
      },
    );
    SPOPS::Initialize->process({ config => \%config });
    my $object = LoopbackTest->new;
    $object->save;
    $object->remove;

=head1 DESCRIPTION

This is a simple SPOPS class that returns success for all
operations. The serialization methods (C<save()>, C<fetch()>,
C<fetch_group()> and C<remove()>) all call the pre/post action methods
just like any other objects, so it is useful for testing out rules.

=head1 METHODS

B<fetch( $id )>

Returns a new object initialized with the ID C<$id>, calling the
C<pre/post_fetch_action()> methods first. If the object has been
previously saved we pull it from the in-memory storage, otherwise we
return a new object initialized with C<$id>.

B<fetch_group( \%params )>

Returns an arrayref of previously saved objects. If no objects have
been saved, it returns an arrayref of new objects initialized with
numeric IDs.

We grab the 'where' clause out of C<\%params> but do only some
rudimentary parsing to return previously stored objects. (Patches
welcome.)

B<save()>

Returns the object you called the method on. If this is an unsaved
object (if it has not been fetched or saved previously), we call
C<pre_fetch_id()> and C<post_fetch_id()> to trigger any key-generation
actions.

Saved and unsaved objects both have C<pre/post_save_action()> methods
called.

This also stores the object in-memory so you can call C<fetch()> on it
later.

B<remove()>

Calls the C<pre/post_remove_action()> and removes the object from the
in-memory storage.

B<peek( $id, $field )>

Peeks into the in-memory store for the value of C<$field> for object
C<$id>. Must be called as class method.

=head1 SEE ALSO

L<SPOPS|SPOPS>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
