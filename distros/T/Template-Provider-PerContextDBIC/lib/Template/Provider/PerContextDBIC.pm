package Template::Provider::PerContextDBIC;
# ABSTRACT: Load templates using DBIx::Class with per-context resultsets
$Template::Provider::PerContextDBIC::VERSION = '0.000002';

use strict;
use warnings;

use parent 'Template::Provider';

use Carp qw( croak );
use Date::Parse ();
# use Data::Printer;


sub _init {
	my ( $self, $options ) = @_;
# 	$self->debug("_init for PerContextDBIC") if $self->{ DEBUG };

	# Provide defaults as necessary.
	$self->{COLUMN_NAME}        = $options->{COLUMN_NAME}        || 'tmpl_name';
	$self->{COLUMN_MODIFIED}    = $options->{COLUMN_MODIFIED}    || 'modified';
	$self->{COLUMN_CONTENT}     = $options->{COLUMN_CONTENT}     || 'content';
	$self->{SEARCH_CRITERIA}    = $options->{SEARCH_CRITERIA}    || {};
	$self->{TEMPLATE_EXTENSION} = $options->{TEMPLATE_EXTENSION} || '';
	$self->{RESTRICTBY_NAME}    = $options->{RESTRICTBY_NAME}    || '';
	$self->{RESULTSET_METHOD}   = $options->{RESULTSET_METHOD}   || undef;
	$self->{TOLERANT_QUERY}     = $options->{TOLERANT_QUERY}     || 0;

	$self->resultset( $options->{RESULTSET}, $self->{RESTRICTBY_NAME} ) if $options->{RESULTSET};

	if ( $options->{SCHEMA} ) {
		return $self->error( __PACKAGE__ . ' does not support the SCHEMA option' );
	}

	# Use Template::Provider's ->_init() to create the COMPILE_DIR...
	$self->SUPER::_init($options);

	$self->{DEBUG} = $options->{DEBUG} || 0;

	return $self;

} ## end sub _init

sub resultset {
	my $self = shift;

	if (@_) {
		$self->{RESULTSET}  = shift;
		my $restrictby_name = shift || '';
# 		$self->debug("Setting resultset: ". p($self->{ RESULTSET })) if $self->{ DEBUG };

		my $storage      = $self->{RESULTSET}->result_source->schema->storage;
		my $connect_info = $storage->connect_info->[0];

		# The connection DSN will be used when caching templates.
		$self->{DSN} = ref $connect_info ? $connect_info->{dsn} : $connect_info;
		$self->{DSN} = ( split( ';', $self->{DSN} ) )[0];
		$self->{DSN} =~ s/[\/:]/-/g;
# 		$self->debug("Setting DSN: $self->{ DSN }") if $self->{ DEBUG };

		# The resultset could be restricted, so add name-id of restricting object to cache_name so it is guaranteed unique
		my $restricting_object =
		    $self->{RESULTSET}->result_source->schema->can('restricting_object')
		  ? $self->{RESULTSET}->result_source->schema->restricting_object
		  : undef;
		if ($restricting_object) {
			$restrictby_name =
			  $restrictby_name
			  ? sprintf( '%s-%s/%s', $restricting_object->result_source->name, $restricting_object->id, $restrictby_name )
			  : sprintf( '%s-%s',    $restricting_object->result_source->name, $restricting_object->id );
		}
		$self->{RESTRICTBY_NAME} = $restrictby_name;
		$self->debug("RESTRICTBY_NAME: $self->{RESTRICTBY_NAME} ") if $self->{DEBUG};

		# ...and add a directory for templates cached by this provider.
		if ( $self->{COMPILE_DIR} ) {
			# Adapted from Template::Provider 2.94
			require File::Spec;
			require File::Path;

			my $wdir = $self->{DSN};
			$wdir =~ s[:][]g if $^O eq 'MSWin32';
			$wdir =~ /(.*)/;    # untaint
			$wdir = "$1";                                                 # quotes work around bug in Strawberry Perl
			$wdir = File::Spec->catfile( $self->{COMPILE_DIR}, $wdir );
# 			$self->debug("Checking wdir: $wdir") if $self->{ DEBUG };
			File::Path::mkpath($wdir) unless -d $wdir;
		} ## end if ( $self->{COMPILE_DIR} )
	} ## end if (@_)

	return $self->{RESULTSET};
} ## end sub resultset


sub _rs_table_name {
	my $self = shift;
	return $self->{RESULTSET} ? $self->{RESULTSET}->result_source->name : '';
}

sub cache_name {
	my $self = shift;
	my $name = shift || '';
	$self->debug("Making cache_name from: $name") if $self->{DEBUG};

	# Determine the name of the table we're dealing with.
	my $table = $self->_rs_table_name;

	return $self->{RESTRICTBY_NAME}
	  ? "$self->{ RESTRICTBY_NAME }/$table/$name"
	  : "$table/$name";

} ## end sub cache_name

sub lookup_name {
	my $self = shift;
	my $name = shift || '';
	$self->debug("Making lookup_name from: $name") if $self->{DEBUG};

	my $restrictby_name = $self->{RESTRICTBY_NAME};
	my $table           = $self->_rs_table_name;
	my $tmpl_ext        = $self->{TEMPLATE_EXTENSION};
# 	$self->debug("Removing: $restrictby_name") if $self->{DEBUG};
# 	$self->debug("Removing: $table") if $self->{DEBUG};
# 	$self->debug("Removing: $tmpl_ext") if $self->{DEBUG};

	$name =~ s/$restrictby_name\/// if $restrictby_name; # Don't want to remove just slash by itself if $restrictby_name is empty
	$name =~ s/$table\///           if $table;
	$name =~ s/$tmpl_ext//;
# 	$self->debug("Using lookup_name: $name") if $self->{DEBUG};

	return $name;
} ## end sub lookup_name


sub fetch {
	my ( $self, $name ) = @_;
	my $stat_ttl = $self->{STAT_TTL};
	$self->debug("fetch($name)") if $self->{ DEBUG };

	# We're not interested in GLOBs or file handles.
	if ( ref $name ) {
		return ( undef, Template::Constants::STATUS_DECLINED );
	}

	if ( $self->{RESULTSET_METHOD} ) {
		if ( ref $self->{RESULTSET_METHOD} eq 'CODE' ) {
			my ( $rs, $restrict_name ) = $self->{RESULTSET_METHOD}->($name);
			$self->resultset(
				$rs,
				$restrict_name
			);
		} else {
			return $self->error("You must provide a valid coderef for RESULTSET_METHOD");
		}
	} ## end if ( $self->{RESULTSET_METHOD} )

	unless ( $self->{RESULTSET} ) {
		return $self->error("You must provide a DBIx::Class::ResultSet before calling fetch");
	}

	my $cache_name = $self->cache_name($name);
# 	$self->debug("Using cache_name: $cache_name") if $self->{DEBUG};

	# Determine the path this template would be cached to.
	my $compiled_filename = $self->_compiled_filename( $self->{DSN} . "/$cache_name" );
	$self->debug("compiled_filename: $compiled_filename") if $self->{ DEBUG };

	my ( $data, $error, $slot );

	# Is caching enabled?
	my $size = $self->{SIZE};
	my $caching = !defined $size || $size;

	# Otherwise, see if we already know the template is not found
	if ( my $last_stat_time = $self->{NOTFOUND}->{$cache_name} ) {
		$self->debug("In NOTFOUND: $cache_name") if $self->{ DEBUG };
		my $expires_in = $last_stat_time + $stat_ttl - time;
		if ( $expires_in > 0 ) {
			$self->debug(" file [$cache_name] in negative cache.  Expires in $expires_in seconds")
			  if $self->{DEBUG};
			return ( undef, Template::Constants::STATUS_DECLINED );
		} else {
			$self->debug(" remove file [$cache_name] from negative cache.")
			  if $self->{DEBUG};
			delete $self->{NOTFOUND}->{$cache_name};
		}
	} ## end if ( my $last_stat_time = $self->...)

	# If caching is enabled and an entry already exists, refresh its cache
	# slot and extract the data...
	if ( $caching && ( $slot = $self->{LOOKUP}->{$cache_name} ) && !$self->_modified( $cache_name ) ) {
		( $data, $error ) = $self->_refresh($slot);
		$data = $slot->[Template::Provider::DATA] unless $error;
		$self->debug("fetch - lookup from memory") if $self->{ DEBUG };
	}
	# ...otherwise if this template has already been compiled and cached (but
	# not by this object) try to load it from the disk, providing it hasn't
	# been modified...
	elsif ($compiled_filename
		&& -f $compiled_filename
		&& !$self->_modified( $cache_name, ( stat(_) )[9] ) ) {
		$self->debug("template modified: ".$self->_modified( $cache_name, ( stat(_) )[9] )) if $self->{ DEBUG };
		$self->debug("fetch - load from cache disk") if $self->{ DEBUG };
		$data = $self->_load_compiled($compiled_filename);
		$error = $self->error() unless $data;

		# Save the new data where caching is enabled.
		$self->store( $cache_name, $data ) if $caching && !$error;
	} ## end elsif ( $compiled_filename && -f $compiled_filename...)
	# ...else there is nothing already cached for this template so load it
	# from the database.
	else {
		$self->debug("fetch - lookup from database") if $self->{ DEBUG };
		( $data, $error ) = $self->_load("$name");

		if ($error) {
			# Template could not be fetched.  Add to the negative/notfound cache.
			$self->debug("Adding to NOTFOUND: $cache_name") if $self->{ DEBUG };
			$self->{NOTFOUND}->{$cache_name} = time;
			if ($compiled_filename && -f $compiled_filename) {
				$self->debug("Removing cache file: $compiled_filename") if $self->{ DEBUG };
				unlink $compiled_filename;
			}
		}

		if ( !$error ) {
			( $data, $error ) = $self->_compile( $data, $compiled_filename );
		}

		# Save the new data where caching is enabled.
		if ( !$error ) {
			$self->debug("Storing in cache as: $cache_name") if $self->{ DEBUG };
			$data =
			    $caching
			  ? $self->_store( $cache_name, $data )
			  : $data->{data};
		}
	} ## end else [ if ( $caching && ( $slot = $self...))]

	return ( $data, $error );
} ## end sub fetch

sub get_template {
	my $self = shift;
	my $lookup_name = shift;
	my @columns = @_;

	my $find_crit = {
		$self->{COLUMN_NAME} => $lookup_name,
		%{ $self->{SEARCH_CRITERIA} }
	};
	my $find_attr = { columns => [map { $self->{$_} } @columns] };
# 	$self->debug("find_crit: " . p($find_crit)) if $self->{ DEBUG };
# 	$self->debug("find_attr: " . p($find_attr)) if $self->{ DEBUG };

	## I prefer to use `find`, but that means user is responsible for 
	## passing a $resultset that will only match *one* template name.
	## And we should return error (STATUS_ERROR?? STATUS_DECLINED??)
	## if more than one template is found
# 	my $template = $self->{RESULTSET}->find(
# 		$find_crit,
# 		$find_attr,
# 	);	
	my $template_rs = $self->{RESULTSET}->search(
		$find_crit,
		$find_attr,
	); 
	
	if ($template_rs->count > 1) {
		$self->debug("get_template for $lookup_name has more than one record") if $self->{ DEBUG };
		return (undef, "More then one template matching '$lookup_name' was found in the resultset");
	} elsif($template_rs->count == 1) {
		$self->debug("get_template for $lookup_name found one record") if $self->{ DEBUG };
		return ($template_rs->first, 0)
	} else {
		$self->debug("get_template for $lookup_name didn't find any records") if $self->{ DEBUG };
		return (undef, 0)
	}
}


sub _load {
	my ( $self, $name ) = @_;
	my ( $data, $error );
# 	$self->debug("_load($name)") if $self->{DEBUG};

	my $lookup_name = $self->lookup_name($name);
# 	$self->debug("_load for $lookup_name") if $self->{ DEBUG };

	# Try to retrieve the template from the database.
	my ( $template, $tmpl_error ) = $self->get_template($lookup_name, qw/COLUMN_CONTENT COLUMN_MODIFIED/);

	if ($tmpl_error) {
		( $data, $error ) = $self->{TOLERANT_QUERY}
		  ? (
			undef,
			Template::Constants::STATUS_DECLINED
		  )
		  : (
			$tmpl_error,
			Template::Constants::STATUS_ERROR
		  );

	} elsif ($template) {
		$data = {
			name => $lookup_name,
			text => $template->get_column( $self->{COLUMN_CONTENT} ),
			time => Date::Parse::str2time(
				$template->get_column( $self->{COLUMN_MODIFIED} )
			),
			load => time,
		};
		$self->debug("LOADED $lookup_name") if $self->{ DEBUG };

	} elsif ( $self->{TOLERANT} ) {
		( $data, $error ) = ( undef, Template::Constants::STATUS_DECLINED );

	} else {
		( $data, $error ) = (
			"Could not retrieve '$lookup_name' from the resultset '" . $self->_rs_table_name . "'",
			Template::Constants::STATUS_ERROR
		);
	}

	return ( $data, $error );
} ## end sub _load


sub _modified {
	my ( $self, $name, $time ) = @_;
# 	$self->debug("_modified($name)") if $self->{DEBUG};

	my $lookup_name = $self->lookup_name($name);
# 	$self->debug("Check modified for $lookup_name") if $self->{DEBUG};

	# Try to retrieve the template from the database.
	my ( $template, $tmpl_error ) = $self->get_template($lookup_name, qw/COLUMN_MODIFIED/);

	# return true to say template is modified (must be true if template doesn't exist)
	return 1 if $tmpl_error;
	return 1 unless $template;

	my $modified = Date::Parse::str2time( $template->get_column( $self->{COLUMN_MODIFIED} ) )
	  || return $time ? 1 : 0;
# 	$self->debug("Modified $lookup_name at $modified") if $self->{DEBUG};

	return $time ? $modified > $time : $modified;
} ## end sub _modified


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Provider::PerContextDBIC - Load templates using DBIx::Class with per-context resultsets

=head1 VERSION

version 0.000002

=head1 SYNOPSIS

    use My::DBIC::Schema;
    use Template;
    use Template::Provider::PerContextDBIC;

    my $schema = My::DBIC::Schema->connect(
        $dsn, $user, $password, \%options
    );
    my $resultset = $schema->resultset('Template');
    
    my $dbic_provider = Template::Provider::PerContextDBIC->new({
                RESULTSET => $resultset,
                TOLERANT => 1,
                # Other template options like COMPILE_EXT...
            });

    my $template = Template->new({
        LOAD_TEMPLATES => [ $dbic_provider ],
    });

    # Process the template 'my_template' from resultset 'Template'.
    $template->process('my_template');
    # Process the template 'other_template' from resultset 'Template'.
    $template->process('other_template');

If you have a resultset that changes based on context, update C<resultset> 
between calls to C<process>.

    # Process the template 'my_template' for site 'foo' from resultset 'Template'.
    $dbic_provider->resultset(
        $schema->resultset('Template')->search({site=>'foo'})
    );
    $template->process('my_template');

    # Process the template 'other_template' for site 'bar' from resultset 'Template'.
    $dbic_provider->resultset(
        $schema->resultset('Template')->search({site=>'bar'})
    );
    $template->process('other_template');

=head1 DESCRIPTION

Template::Provider::PerContextDBIC allows a L<Template> object to fetch
its data using L<DBIx::Class> instead of, or in addition to, the default
filesystem-based L<Template::Provider>. The PerContextDBIC provider also
allows changing the C<resultset> between calls to $template->process.

This module was inspired by both L<Template::Provider::DBIC> and
L<Template::Provider::PrefixDBIC>. It uses ideas from both of the other
excellent modules.

=head1 ATTRIBUTES

=head2 COLUMN_NAME

The table column that contains the template name. This will default to
'tmpl_name'.

=head2 COLUMN_CONTENT

The table column that contains the template data itself. This will
default to 'content'.

=head2 COLUMN_MODIFIED

The table column that contains the date that the template was last
modified. This will default to 'modified'.

=head2 RESULTSET

The resultset to be used to C<find> templates. It can be left blank as
long as C<$provider->resultset(...)> is called prior to template
processing.

=head2 RESTRICTBY_NAME

The unique value identifying the C<$resultset> to use for creating cache
directories and lookups. Can be left blank if C<$resultset> has a
C<restricting_object> method (eg. using
L<DBIx::Class::Schema::RestrictWithObject>).

=head2 RESULTSET_METHOD

The sub reference to be called during C<fetch> which will return a two
item list with C<$resultset> and C<$restrictby_name>.

=head2 TOLERANT_QUERY

If set to a true value, then a query with more than one row will cause
the provider to return C<STATUS_DECLINED> rather than C<STATUS_ERROR>.

=head1 METHODS

=head2 ->_init( \%options )

Check that valid Template::Provider::PerContextDBIC-specific arguments
have been supplied and store the appropriate values. See above for the
available options.

=head2 ->lookup_name( $name )

This method returns the name of the template that will be looked up in
the database. The C<TEMPLATE_EXTENSION> will be removed as well as the
leading table name and restricting object.

=head2 ->cache_name( $name )

This method returns the name of the cache entry. It will have the
leading table name and restricting object as part of the name.

=head2 ->fetch( $name )

This method is called automatically during L<Template>'s
C<-E<gt>process()> and returns a compiled template for the given
C<$name>, using the cache where possible.

=head2 ->_load( $name )

Load the template from the database and return a hash containing its
name, content, the time it was last modified, and the time it was loaded
(now).

=head2 ->_modified( $name, $time )

When called with a single argument, returns the modification time of the
given template. When called with a second argument it returns true if
$name has been modified since $time.

=head2 ->resultset($rs, [$restrict_by])

Pass a resultset to use for subsequent template processing. Optionally
pass a string to use for making unique cache directory.

If C<$restrict_by> is not set, and the C<$rs> has a
C<restricting_object> method (eg. using
L<DBIx::Class::Schema::RestrictWithObject>), then C<$restrict_by> will
be set to a string containing the
C<$restricting_object->result_source->name> and
C<$restricting_object->id>.

If both C<$restrict_by> is set, and the C<$rs> has a
C<restricting_object> method, then both values are used to create a
unique cache directory.

=head2 ->get_template($lookup_name, @columns)

Pass a template name to retrieve from the database, as well as list of
columuns to be included. The column names are specified as the keys
C<COLUMN_CONTENT> and C<COLUMN_MODIFIED>. A C<$row> will be returned if
lookup_name matches a record.

The database query is done using C<search> rather than C<find> to avoid
warnings when query returns more than one record. The author feels that
C<find> is the correct method, but puts too much burden to ensure unique
queries.

The default behaviour is to return a C<STATUS_ERROR> if more than one
row is returned. You can change that behaviour with the
C<TOLERANT_QUERY> option.

=head1 USE WITH OTHER PROVIDERS

By default Template::Provider::PerContextDBIC will raise an exception
when it cannot find the named template. When TOLERANT is set to true it
will defer processing to the next provider specified in LOAD_TEMPLATES
where available. For example:

    my $template = Template->new({
        LOAD_TEMPLATES => [
            Template::Provider::PerContextDBIC->new({
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
Template::Provider::PerContextDBIC will create a directory consisting of
the database DSN and table name, and restrict_by name. This should
prevent conflicts with other databases and providers.

In addition, if the result set has been restricted using
L<DBIx::Class::Schema::RestrictWithObject>, the cache directory will
also be prefixed with the name and id of the restricting object. This
should prevent conflicts with other resultsets for the same table. 

=head1 SEE ALSO

=over 4

=item *

L<Template::Provider>

=item *

L<Template::Provider::DBIC>

=item *

L<Template::Provider::PrefixDBIC>

=item *

L<DBIx::Class::Schema>

=back

=head1 DIAGNOSTICS

In addition to errors raised by L<Template::Provider> and L<DBIx::Class>,
Template::Provider::DBIC may generate the following error messages:

=over

=item C<< does not support the SCHEMA option >>

The SCHEMA configuration option should not be provided.

=item C<< You must provide a DBIx::Class::ResultSet before calling fetch >>

Couldn't find a valid resultset when $provider->fetch runs.

=item C<< More then one template matching '%s' was found in the resultset >>

The template %s was found more than once when querying the resultet. 

=item C<< Could not retrieve '%s' from the result set '%s' >>

Unless TOLERANT is set to true failure to find a template with the given name
will raise an exception.

=back

=head1 DEPENDENCIES

=over 4

=item *

L<Carp>

=item *

L<Date::Parse>

=item *

L<File::Path>

=item *

L<File::Spec>

=item *

L<Template::Provider>

=back

Additionally, use of this module requires an object of the class
 L<DBIx::Class::ResultSet>.

=head1 AUTHOR

Charlie Garrison <garrison@zeta.org.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Charlie Garrison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
