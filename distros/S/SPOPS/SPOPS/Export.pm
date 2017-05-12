package SPOPS::Export;

# $Id: Export.pm,v 3.4 2004/06/02 00:48:21 lachoy Exp $

use strict;
use base qw( Class::Accessor Class::Factory );
use SPOPS::Exception qw( spops_error );

$SPOPS::Export::VERSION  = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);

use constant AKEY => '_attrib';

my @FIELDS = qw( object_class where value include_id skip_fields DEBUG );
SPOPS::Export->mk_accessors( @FIELDS );

sub new {
    my ( $pkg, $type, $params ) = @_;
    my $class = eval { $pkg->get_factory_class( $type ) };
    spops_error $@ if ( $@ );
    my $self = bless( {}, $class );;
    foreach my $field ( $self->get_fields ) {
        $self->$field( $params->{ $field } );
    }
    return $self->initialize( $params );
}


sub initialize { return $_[0] }

sub get_fields { return @FIELDS }


# Class::Accessor stuff

sub get { return $_[0]->{ AKEY() }{ $_[1] } }
sub set { return $_[0]->{ AKEY() }{ $_[1] } = $_[2] }


# Main event

sub run {
    my ( $self ) = @_;
    my $object_class = $self->object_class;
    unless ( $object_class ) {
        spops_error "Cannot export objects without an object class! ",
                    "Please set using\n",
                    "\$exporter->object_class( \$object_class )";
    }
    my @export_fields = $self->_find_export_fields;
    my @output = ();
    push @output, $self->create_header( \@export_fields );

    my $iter = $object_class->fetch_iterator({ where => $self->where,
                                               value => $self->value,
                                               DEBUG => $self->DEBUG });
    while ( my $o = $iter->get_next ) {
        push @output, $self->create_record( $o, \@export_fields );
    }
    push @output, $self->create_footer;
    return join( "", @output );
}

# Subclasses should override these actions as necessary -- note that
# if you remove the 'return' you'll get a nasty surprise, since the
# exporter object is returned :-)

sub create_header { return }
sub create_record { return }
sub create_footer { return }


# Private

sub _find_export_fields {
    my ( $self ) = @_;
    my %skip_fields = ();
    my $object_class = $self->object_class;
    if ( $self->skip_fields ) {
        map { $skip_fields{ $_ }++ } @{ $self->skip_fields };
    }
    unless ( $self->include_id ) {
        $skip_fields{ $object_class->CONFIG->{id_field} }++;
    }
    return grep { ! $skip_fields{ $_ } } @{ $object_class->field_list };
}


########################################
# INITIALIZE

__PACKAGE__->register_factory_type( object => 'SPOPS::Export::Object' );
__PACKAGE__->register_factory_type( xml    => 'SPOPS::Export::XML' );
__PACKAGE__->register_factory_type( perl   => 'SPOPS::Export::Perl' );
__PACKAGE__->register_factory_type( sql    => 'SPOPS::Export::SQL' );
__PACKAGE__->register_factory_type( dbdata => 'SPOPS::Export::DBI::Data' );

1;

__END__

=head1 NAME

SPOPS::Export - Export SPOPS objects to various formats

=head1 SYNOPSIS

 use SPOPS::Export;

 # Export to internal SPOPS format

 my $exporter = SPOPS::Export->new( 'object',
                                    { object_class => 'My::Object' });

 # Export all objects

 print $exporter->run;

 # Export only certain objects

 $exporter->where( "user_id = 5" );
 print $exporter->run;

 $exporter->where( "last_name = ?" );
 $exporter->value( [ "O'Reilly" ] );
 print $exporter->run;

 my $exporter2 = SPOPS::Export->new( 'xml',
                                    { object_class => 'My::Object' } );

 # Export all objects

 print $exporter2->run;

 # Export only certain objects

 $exporter2->where( "user_id = 5" );
 print $exporter2->run;

 $exporter2->where( "last_name = ?" );
 $exporter2->value( [ "O'Reilly" ] );
 print $exporter2->run;


=head1 DESCRIPTION

This is a simple module to export SPOPS objects into a portable
format. The format depends on the type of exporting you are
doing. Currently we support five formats, each of which has a unique
identifier (in parens) that you pass to the C<new()> method:

=over 4

=item 1.

L<SPOPS::Export::Object|SPOPS::Export::Object> (object) An internal
format based on serialized perl.

=item 2.

L<SPOPS::Export::XML|SPOPS::Export::XML> (xml) Basic XML

=item 3.

L<SPOPS::Export::Perl|SPOPS::Export::Perl> (perl) Standard serialized
Perl format using L<Data::Dumper|Data::Dumper>.

=item 4.

L<SPOPS::Export::SQL|SPOPS::Export::SQL> (sql) A series of SQL
statements, one for each record.

=item 5.

L<SPOPS::Export::DBI::Data|SPOPS::Export::DBI::Data> (dbdata) Almost
exactly like 'object' but it can be put directly into a DBI table
without using objects.

=back

=head1 PROPERTIES

You can set the following properties in the exporter object. Only one
is mandatory.

B<object_class> ($)

Class of the object for which you want to export the data. This should
already be created via the normal means (see
L<SPOPS::Initialize|SPOPS::Initialize>).

B<include_id> (bool) (optional)

Whether to include the ID field its values in the exported data.

Default: false

B<skip_fields> (\@) (optional)

Fields for which you do not want to include data.

Default: none

B<where> ($) (optional)

A WHERE clause (or whatever the datasource supports) to export only
certain data.

B<value> (\@) (optional)

If you use placeholders in the C<where> property, replace them with
values here.

=head1 METHODS

B<new( $export_type, \%params )>

Create a new instance of an exporter. Since this is a factory class,
we use C<$export_type> to determine the class used to create the
exporter object. (The export types and classes are listed above.)

B<run()>

Runs the configured export, returning a string with the exported data.

=head1 SUBCLASS METHODS

If you want to write your own exporter, you just need to create a
class with the following methods. (Technically, all are optional, but
you will not get too far if you do not implement at least
C<create_record()>.)

Also: if you are writing your own exporter, be sure to look at the
C<add_type()> method defined above.

B<initialize( \%params )>

Perform any necessary initialization for an instance of your exporter
object. Return the object.

B<create_header( \@object_fields )>

Return a string with the export header.

B<create_record( $object, \@object_fields )>

Return a string representing the object in the export format you are
implementing.

B<create_footer()>

Return a string with the export footer.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Manual::ImportExport|SPOPS::Manual::ImportExport>

L<Class::Accessor|Class::Accessor>

L<Class::Factory|Class::Factory>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
