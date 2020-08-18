package Template::Provider::CustomDBIC;

use strict;
use warnings;

use base qw/ Template::Provider /;

use Carp qw( croak );
use Date::Parse ();

our $VERSION = '0.05';

=head1 NAME

Template::Provider::CustomDBIC - Load templates using DBIx::Class


=head1 SYNOPSIS

    use My::CustomDBIC::Schema;
    use Template;
    use Template::Provider::CustomDBIC;

    my $schema = My::CustomDBIC::Schema->connect(
        $dsn, $user, $password, \%options
    );
    my $resultset = $schema->resultset('Template');

If all of your templates are stored in a single table the most convenient
method is to pass the provider a L<DBIx::Class::ResultSet>.

    my $template = Template->new({
        LOAD_TEMPLATES => [
            Template::Provider::CustomDBIC->new({
                RESULTSET => $resultset,
                # Other template options like COMPILE_EXT...
            }),
        ],
    });

    # Process the template in 'column' referred by reference from resultset 'Template'.
    $template->process('table/reference/column');


=head1 DESCRIPTION

Template::Provider::CustomDBIC allows a L<Template> object to fetch its data using
L<DBIx::Class> instead of, or in addition to, the default filesystem-based
L<Template::Provider>.


=head2 SCHEMA

This provider requires a schema containing at least the following:

=over

=item

A column containing the template name. When C<$template-E<gt>provider($name)>
is called the provider will search this column for the corresponding C<$name>.
For this reason the column must be a unique key, else an exception will be
raised.

=item

A column containing the actual template content itself. This is what will be
compiled and returned when the template is processed.

=item

A column containing the time the template was last modified. This must return
- or be inflated to - a date string recognisable by L<Date::Parse>.

=back


=head2 OPTIONS

In addition to supplying a RESULTSET or SCHEMA and the standard
L<Template::Provider> options, you may set the following preferences:

=over 4

=item COLUMN_NAME

The table column that contains the template name. This will default to 'name'.

=item COLUMN_CONTENT

The table column that contains the template data itself. This will default to
'content'.

=item COLUMN_MODIFIED

The table column that contains the date that the template was last modified.
This will default to 'modified'.

=back


=head1 METHODS

=begin comment

->_init( \%options )

Check that valid Template::Provider::CustomDBIC-specific arguments have been
supplied and store the appropriate values. See above for the available
options.

=end comment

=cut

sub _init {
    my ( $self, $options ) = @_;

    # Provide defaults as necessary.
    $self->{COLUMN_NAME}     = $options->{COLUMN_NAME}     || 'name';
    $self->{COLUMN_MODIFIED} = $options->{COLUMN_MODIFIED} || 'modified';
    $self->{COLUMN_CONTENT}  = $options->{COLUMN_CONTENT}  || 'content';

    # Ensure that a RESULTSET or SCHEMA has been specified. In the case of
    # both RESULTSET takes precedence.
    my $storage;

    if ( defined $options->{RESULTSET} ) {

        $self->{RESULTSET} = $options->{RESULTSET};
        $storage = $self->{RESULTSET}->result_source->schema->storage;

    } else {    # neither specified

        return $self->error('A valid DBIx::Class::ResultSet is required');
    }

    # The connection DSN will be used when caching templates.
    $self->{DSN} = $storage->connect_info->[0];

    # Use Template::Provider's ->_init() to create the COMPILE_DIR...
    $self->SUPER::_init($options);

    # ...and add a directory for templates cached by this provider.
    if ( $self->{COMPILE_DIR} ) {

        # Adapted from Template::Provider 2.91
        require File::Spec;
        require File::Path;

        my $wdir = $self->{DSN};
        $wdir =~ s/://g if $^O eq 'MSWin32';
        $wdir =~ /(.*)/;    # untaint
        $wdir = File::Spec->catfile( $self->{COMPILE_DIR}, $1 );
        File::Path::mkpath($wdir) unless -d $wdir;
    }

    return $self;
}

=head2 ->fetch( $name )

This method is called automatically during L<Template>'s C<-E<gt>process()>
and returns a compiled template for the given C<$name>, using the cache where
possible.

=cut

sub fetch {
    my ( $self, $name ) = @_;

    # We're not interested in GLOBs or file handles.
    if ( ref $name ) {
        return ( undef, Template::Constants::STATUS_DECLINED );
    }

    # Determine the name of the table we're dealing with.
    my ( $table, $reference, $column ) = split( "/", $name );
        
    my ( $data, $error, $slot );

    if ( $table && $reference && $column && scalar split("/", $name) == 3 ) {
   

        # Determine the path this template would be cached to.
        my $compiled_filename = $self->_compiled_filename( $self->{DSN} . "/$table/$reference/$column" );

        # Is caching enabled?
        my $size = $self->{SIZE};
        my $caching = !defined $size || $size;

        # If caching is enabled and an entry already exists, refresh its cache
        # slot and extract the data...
        if ( $caching && ( $slot = $self->{LOOKUP}->{"$table/$reference/$column"} ) ) {
            ( $data, $error ) = $self->_refresh($slot);
            $data = $slot->[Template::Provider::DATA] unless $error;
        }

        # ...otherwise if this template has already been compiled and cached (but
        # not by this object) try to load it from the disk, providing it hasn't
        # been modified...
        elsif ( $compiled_filename
            && -f $compiled_filename
            && !$self->_modified( "$table/$reference/$column", ( stat(_) )[9] ) )
        {
            $data = $self->_load_compiled($compiled_filename);
            $error = $self->error() unless $data;

            # Save the new data where caching is enabled.
            $self->store( "$table/$reference/$column", $data ) if $caching && !$error;
        }

            # ...else there is nothing already cached for this template so load it
            # from the database.
        else {

            ( $data, $error ) = $self->_load("$table/$reference/$column");

            if ( !$error ) {
            
                ( $data, $error ) = $self->_compile( $data, $compiled_filename );
            }

            # Save the new data where caching is enabled.
            if ( !$error ) {

                $data = $caching  ? $self->_store( "$table/$reference/$column", $data ) : $data->{data};
            }
        }
    
        return ( $data, $error );
        
    } else {

        return ( undef, Template::Constants::STATUS_DECLINED );
 
    }
}

=begin comment

->_load( $name )

Load the template from the database and return a hash containing its name,
content, the time it was last modified, and the time it was loaded (now).

=end comment

=cut

sub _load {
    my ( $self, $name ) = @_;
    my ( $data, $error );

    my ( $table, $reference, $column ) = split( "/", $name );

    if ( $table && $reference && $column ) { 

        my $resultset = $self->{RESULTSET};

        # Try to retrieve the template from the database.
        my $template = $resultset->find( $reference, { key => $self->{COLUMN_NAME} } );

        if ($template) {

            $data = {
                name => "$table/$reference/$column",
                text => $template->get_column($column),
                time => Date::Parse::str2time( $template->get_column( $self->{COLUMN_MODIFIED} ) ),
                load => time,
            };

        } else {

            # Not found in RESULTSET 
            ( $data, $error ) = ( "Could not retrieve '$reference' from the result set '$table'", Template::Constants::STATUS_ERROR );
        }

    } else { 

        ( $data, $error ) = ( undef, Template::Constants::STATUS_DECLINED );

    }

    return ( $data, $error );
}

=begin comment

->_modified( $name, $time )

When called with a single argument, returns the modification time of the
given template. When called with a second argument it returns true if $name
has been modified since $time.

=end comment

=cut

sub _modified {
    my ( $self, $name, $time ) = @_;

    my ( $table, $reference, $column ) = split( "/", $name );

    my $resultset = $self->{RESULTSET};

    # Try to retrieve the template from the database...
    my $template = $resultset->find( $reference, { key => $self->{COLUMN_NAME} } );

    require Date::Parse;

    my $modified = $template && Date::Parse::str2time( $template->{COLUMN_MODIFIED} ) || return $time ? 1 : 0;

    return $time ? $modified > $time : $modified;
}

1;    # End of the module code; everything from here is documentation...
__END__

=head1 USE WITH OTHER PROVIDERS

By default Template::Provider::CustomDBIC will raise an exception when it cannot
find the named template 

    my $template = Template->new({
        LOAD_TEMPLATES => [
            Template::Provider::CustomDBIC->new({
                RESULTSET => $resultset,
            }),
            Template::Provider->new({
                INCLUDE_PATH => $path_to_templates,
            }),
        ],
    });


=head1 CACHING

When caching is enabled, by setting COMPILE_DIR and/or COMPILE_EXT,
Template::Provider::CustomDBIC will create a directory consisting of the database
DSN and table name. This should prevent conflicts with other databases and
providers.


=head1 SEE ALSO

L<Template>, L<Template::Provider>, L<DBIx::Class::Schema>


=head1 DIAGNOSTICS

In addition to errors raised by L<Template::Provider> and L<DBIx::Class>,
Template::Provider::CustomDBIC may generate the following error messages:

=over

=item C<< A valid DBIx::Class::Schema or ::ResultSet is required >>

One of the SCHEMA or RESULTSET configuration options I<must> be provided.

=item C<< %s not valid: must be of the form $table/$template >>

When using Template::Provider::CustomDBIC with a L<DBIx::Class::Schema> object, the
template name passed to C<-E<gt>process()> must start with the name of the
result set to search in.

=item C<< '%s' is not a valid result set for the given schema >>

Couldn't find the result set %s in the given L<DBIx::Class::Schema> object.

=item C<< Could not retrieve '%s' from the result set '%s' >>

=back


=head1 DEPENDENCIES

=over

=item

L<Carp>

=item

L<Date::Parse>

=item

L<File::Path>

=item

L<File::Spec>

=item

L<Template::Provider>

=back

Additionally, use of this module requires an object of the class
L<DBIx::Class::Schema> or L<DBIx::Class::ResultSet>.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/itnode/Template-Provider-CustomDBIC/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Provider::CustomDBIC

You may also look for information at:

=over 4

=item * Template::Provider::CustomDBIC

=item * AnnoCPAN: Annotated CPAN documentation

=item * RT: CPAN's request tracker

L<https://github.com/itnode/Template-Provider-CustomDBIC/issues>

=item * Search CPAN

=back

=head1 AUTHOR

Jens Gassmann <jegade@cpan.org>

Based on work from Dave Cardwell <dcardwell@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015 Jens Gassmann. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=cut
