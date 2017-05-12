package Template::Provider::DBIC;

use strict;
use warnings;

use base qw/ Template::Provider /;

use Carp qw( croak );
use Date::Parse ();

our $VERSION = '0.02';


=head1 NAME

Template::Provider::DBIC - Load templates using DBIx::Class


=head1 SYNOPSIS

    use My::DBIC::Schema;
    use Template;
    use Template::Provider::DBIC;

    my $schema = My::DBIC::Schema->connect(
        $dsn, $user, $password, \%options
    );
    my $resultset = $schema->resultset('Template');

If all of your templates are stored in a single table the most convenient
method is to pass the provider a L<DBIx::Class::ResultSet>.

    my $template = Template->new({
        LOAD_TEMPLATES => [
            Template::Provider::DBIC->new({
                RESULTSET => $resultset,
                # Other template options like COMPILE_EXT...
            }),
        ],
    });

    # Process the template 'my_template' from resultset 'Template'.
    $template->process('my_template');
    # Process the template 'other_template' from resultset 'Template'.
    $template->process('other_template');

Alternatively, where your templates are stored in several tables you can pass
a L<DBIx::Class::Schema> and specify the result set and template name in the
form C<ResultSet/template_name>.

    my $template2 = Template->new({
        LOAD_TEMPLATES => [
            Template::Provider::DBIC->new({
                SCHEMA => $schema,
                # Other template options...
            }),
        ],
    });

    # Process the template 'my_template' from resultset 'Template'.
    $template->process('Template/my_template');
    # Process the template 'my_template' from resultset 'Other'.
    $template->process('Other/my_template');

In cases where both are supplied, the more specific RESULTSET will take
precedence.


=head1 DESCRIPTION

Template::Provider::DBIC allows a L<Template> object to fetch its data using
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

Check that valid Template::Provider::DBIC-specific arguments have been
supplied and store the appropriate values. See above for the available
options.

=end comment

=cut

sub _init {
    my ( $self, $options ) = @_;
    
    # Provide defaults as necessary.
    $self->{ COLUMN_NAME }     = $options->{ COLUMN_NAME }     || 'name';
    $self->{ COLUMN_MODIFIED } = $options->{ COLUMN_MODIFIED } || 'modified';
    $self->{ COLUMN_CONTENT }  = $options->{ COLUMN_CONTENT }  || 'content';
    
    # Ensure that a RESULTSET or SCHEMA has been specified. In the case of
    # both RESULTSET takes precedence.
    my $storage;
    if ( defined $options->{ RESULTSET } ) {
        $self->{ RESULTSET } = $options->{ RESULTSET };
        $storage = $self->{ RESULTSET }->result_source->schema->storage;
    }
    elsif ( defined $options->{ SCHEMA } ) {
        $self->{ SCHEMA } = $options->{ SCHEMA };
        $storage = $self->{ SCHEMA }->storage;
    }
    else { # neither specified
        return $self->error(
            'A valid DBIx::Class::Schema or ::ResultSet is required'
        );
    }
    
    # The connection DSN will be used when caching templates.
    $self->{ DSN } = $storage->connect_info->[0];
    
    # Use Template::Provider's ->_init() to create the COMPILE_DIR...
    $self->SUPER::_init($options);
    
    # ...and add a directory for templates cached by this provider.
    if ( $self->{ COMPILE_DIR } ) {
        # Adapted from Template::Provider 2.91
        require File::Spec;
        require File::Path;
        
        my $wdir = $self->{ DSN };
        $wdir =~ s/://g if $^O eq 'MSWin32';
        $wdir =~ /(.*)/; # untaint
        $wdir =  File::Spec->catfile( $self->{ COMPILE_DIR }, $1 );
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
    my $table;
    if ( $self->{ RESULTSET } ) {
        # We can extract the table name from a DBIx::Class::ResultSet.
        $table = $self->{ RESULTSET }->result_source->name;
    }
    else {
        # For DBIx::Class::Schema, however, we have to extract the table name
        # from the given template name if it is of the form
        # "$table/$template".
        if ( $name =~ m#^([^/]+)/(.+)$# ) {
            ( $table, $name ) = ( $1, $2 );
        }
        else {
            # In tolerant mode decline to handle the template, otherwise raise
            # an error.
            return $self->{ TOLERANT }
                ? ( undef, Template::Constants::STATUS_DECLINED )
                : ( "$name not valid: must be of the form "
                                     . '"$table/$template"',
                    Template::Constants::STATUS_ERROR )
            ;
        }
        
        # Make sure this is a valid resultset.
        eval { $self->{ SCHEMA }->resultset($table); };
        if ( $@ ) {
            return $self->{ TOLERANT }
                ? ( undef, Template::Constants::STATUS_DECLINED )
                : ( "'$table' is not a valid result set for the given schema",
                    Template::Constants::STATUS_ERROR )
            ;
        }
    }
    
    
    # Determine the path this template would be cached to.
    my $compiled_filename = $self->_compiled_filename(
        $self->{ DSN } . "/$table/$name"
    );
    
    my ( $data, $error, $slot );
    
    # Is caching enabled?
    my $size    = $self->{ SIZE };
    my $caching = !defined $size || $size;
    
    
    # If caching is enabled and an entry already exists, refresh its cache
    # slot and extract the data...
    if ( $caching && ($slot = $self->{ LOOKUP }->{ "$table/$name" }) ) {
        ( $data, $error ) = $self->_refresh($slot);
        $data = $slot->[ Template::Provider::DATA ] unless $error;
    }
    # ...otherwise if this template has already been compiled and cached (but
    # not by this object) try to load it from the disk, providing it hasn't
    # been modified...
    elsif ( $compiled_filename && -f $compiled_filename
         && !$self->_modified( "$table/$name", (stat(_))[9] ) ) {
        $data  = $self->_load_compiled($compiled_filename);
        $error = $self->error() unless $data;
        
        # Save the new data where caching is enabled.
        $self->store( "$table/$name", $data ) if $caching && !$error;
    }
    # ...else there is nothing already cached for this template so load it
    # from the database.
    else {
        ( $data, $error ) = $self->_load("$table/$name");
        if ( !$error ) {
            ( $data, $error ) = $self->_compile( $data, $compiled_filename );
        }
        
        # Save the new data where caching is enabled.
        if ( !$error ) {
            $data = $caching ? $self->_store( "$table/$name", $data )
                             : $data->{ data }
            ;
        }
    }
    
    return ( $data, $error );
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
    
    my $table;
    if ( $name =~ m#^([^/]+)/(.+)$# ) {
        ( $table, $name ) = ( $1, $2 );
    }
    
    my $resultset = $self->{ RESULTSET }
                 || $self->{ SCHEMA }->resultset($table);
    
    # Try to retrieve the template from the database.
    my $template = $resultset->find(
        $name, { key => $self->{ COLUMN_NAME } }
    );
    if ( $template ) {
        $data = {
            name => "$table/$name",
            text => $template->get_column( $self->{ COLUMN_CONTENT } ),
            time => Date::Parse::str2time(
                        $template->get_column( $self->{ COLUMN_MODIFIED } )
                    ),
            load => time,
        };
    }
    elsif ( $self->{ TOLERANT } ) {
        ( $data, $error ) = ( undef, Template::Constants::STATUS_DECLINED );
    } else {
        ( $data, $error ) = (
            "Could not retrieve '$name' from the result set '$table'",
            Template::Constants::STATUS_ERROR
        );
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
    
    my $table;
    if ( $name =~ m#^([^/]+)/(.+)$# ) {
        ( $table, $name ) = ( $1, $2 );
    }
    
    my $resultset = $self->{ RESULTSET }
                 || $self->{ SCHEMA }->resultset($table);
                 
    # Try to retrieve the template from the database...
    my $template = $resultset->find(
        $name, { key => $self->{ COLUMN_NAME } }
    );
    
    require Date::Parse;
    my $modified = $template && Date::Parse::str2time(
                                    $template->{ COLUMN_MODIFIED }
                                )
                || return $time ? 1 : 0;
    
    return $time ? $modified > $time : $modified;
}


1; # End of the module code; everything from here is documentation...
__END__

=head1 USE WITH OTHER PROVIDERS

By default Template::Provider::DBIC will raise an exception when it cannot
find the named template. When TOLERANT is set to true it will defer processing
to the next provider specified in LOAD_TEMPLATES where available. For example:

    my $template = Template->new({
        LOAD_TEMPLATES => [
            Template::Provider::DBIC->new({
                RESULTSET => $resultset,
                TOLERANT  => 1,
            }),
            Template::Provider->new({
                INCLUDE_PATH => $path_to_templates,
            }),
        ],
    });


=head1 CACHING

When caching is enabled, by setting COMPILE_DIR and/or COMPILE_EXT,
Template::Provider::DBIC will create a directory consisting of the database
DSN and table name. This should prevent conflicts with other databases and
providers.


=head1 SEE ALSO

L<Template>, L<Template::Provider>, L<DBIx::Class::Schema>


=head1 DIAGNOSTICS

In addition to errors raised by L<Template::Provider> and L<DBIx::Class>,
Template::Provider::DBIC may generate the following error messages:

=over

=item C<< A valid DBIx::Class::Schema or ::ResultSet is required >>

One of the SCHEMA or RESULTSET configuration options I<must> be provided.

=item C<< %s not valid: must be of the form $table/$template >>

When using Template::Provider::DBIC with a L<DBIx::Class::Schema> object, the
template name passed to C<-E<gt>process()> must start with the name of the
result set to search in.

=item C<< '%s' is not a valid result set for the given schema >>

Couldn't find the result set %s in the given L<DBIx::Class::Schema> object.

=item C<< Could not retrieve '%s' from the result set '%s' >>

Unless TOLERANT is set to true failure to find a template with the given name
will raise an exception.

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

Please report any bugs or feature requests to
C<bug-template-provider-dbic at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Provider-DBIC>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Provider::DBIC

You may also look for information at:

=over 4

=item * Template::Provider::DBIC

L<http://perlprogrammer.co.uk/modules/Template::Provider::DBIC/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Provider-DBIC/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Provider-DBIC>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Provider-DBIC/>

=back


=head1 AUTHOR

Dave Cardwell <dcardwell@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Dave Cardwell. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=cut
