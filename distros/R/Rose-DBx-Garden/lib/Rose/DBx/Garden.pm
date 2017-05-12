package Rose::DBx::Garden;

use warnings;
use strict;
use base qw( Rose::DB::Object::Loader );
use Carp;
use Data::Dump qw( dump );
use Path::Class;
use File::Slurp::Tiny;
use File::Basename;

my $MAX_FIELD_SIZE = 64;

use Rose::Object::MakeMethods::Generic (
    boolean => [
        'find_schemas'                => { default => 0 },
        'force_install'               => { default => 0 },
        'debug'                       => { default => 0 },
        'skip_map_class_forms'        => { default => 1 },
        'include_autoinc_form_fields' => { default => 1 },
    ],
    'scalar --get_set_init' => 'column_field_map',
    'scalar --get_set_init' => 'column_to_label',
    'scalar --get_set_init' => 'garden_prefix',
    'scalar --get_set_init' => 'perltidy_opts',
    'scalar --get_set_init' => 'base_code',
    'scalar --get_set_init' => 'base_form_class_code',
    'scalar --get_set_init' => 'text_field_size',
    'scalar --get_set_init' => 'limit_to_schemas',
    'scalar'                => 'use_db_name',
);

our $VERSION = '0.193';

=head1 NAME

Rose::DBx::Garden - bootstrap Rose::DB::Object and Rose::HTML::Form classes

=head1 SYNOPSIS

 use Rose::DBx::Garden;
    
 my $garden = Rose::DBx::Garden->new(
 
         garden_prefix   => 'MyRoseGarden',    # instead of class_prefix
         perltidy_opts   => '-pbp -nst -nse',  # Perl Best Practices
         db              => My::DB->new, # Rose::DB object
         find_schemas    => 0,           # set true if your db has schemas
         force_install   => 0,           # do not overwrite existing files
         debug           => 0,           # print actions on stderr
         skip_map_class_forms => 1,      # no Form classes for many2many map classes
         include_autoinc_form_fields => 1,
         # other Rose::DB::Object::Loader params here
 
 );
                        
 # $garden ISA Rose::DB::Object::Loader
                     
 $garden->plant('path/to/where/i/want/files');

=head1 DESCRIPTION

Rose::DBx::Garden bootstraps L<Rose::DB::Object> and L<Rose::HTML::Form> based projects.
The idea is that you can point the module at a database and end up with work-able
RDBO and Form classes with a single method call.

Rose::DBx::Garden creates scaffolding only. 
It creates Rose::DB::Object-based and Rose::HTML::Object-based classes, which
assume 1 table == 1 form.  There is no generation of code to handle
subforms, though it's relatively easy to add those later.

Rose::DBx::Garden inherits from L<Rose::DB::Object::Loader>, so all the magic there
is also available here.

=head1 METHODS

B<NOTE:> All the init_* methods are intended for when you subclass the Garden
class. You can pass in values to the new() constructor for normal use.
See L<Rose::Object::MakeMethods::Generic>.

=cut

=head2 include_autoinc_form_fields

The default behaviour is to include db columns flagged as
auto_increment from the generated Form class and to map
them to the 'serial' field type. Set this value
to a false value to exclude auto_increment columns as form fields.

=cut

=head2 init_column_field_map

Sets the default RDBO column type to RHTMLO field type mapping.
Should be a hash ref of 'rdbo' => 'rhtmlo' format.

=cut

# TODO better detection of the serial type on per-db basis
sub init_column_field_map {
    return {
        'varchar'          => 'text',
        'text'             => 'textarea',
        'character'        => 'text',
        'date'             => 'date',
        'datetime'         => 'datetime',
        'epoch'            => 'datetime',
        'integer'          => 'integer',
        'bigint'           => 'integer',
        'serial'           => 'serial',
        'time'             => 'time',
        'timestamp'        => 'datetime',
        'float'            => 'numeric',    # TODO nice to have ::Field::Float
        'numeric'          => 'numeric',
        'decimal'          => 'numeric',
        'double precision' => 'numeric',
        'boolean'          => 'boolean',
        'enum'             => 'menu',
    };
}

=head2 init_column_to_label

Returns a CODE ref for filtering a column name to its corresponding
form field label. The CODE ref should expect two arguments:
the Garden object and the column name.

The default is just to return the column name. If you wanted to return,
for example, a prettier version aligned with the naming conventions used
in Rose::DB::Object::ConventionManager, you might do something like:

    my $garden = Rose::DBx::Garden->new(
                    column_to_label => sub {
                           my ($garden_obj, $col_name) = @_;
                           return join(' ', 
                                       map { ucfirst($_) }
                                       split(m/_/, $col_name)
                                  );
                    }
                 );

=cut

sub init_column_to_label {
    sub { return $_[1] }
}

=head2 init_garden_prefix

The default base class name is C<MyRoseGarden>. This value
overrides C<class_prefix> and C<base_class> in the base Loader class.

=cut

sub init_garden_prefix {'MyRoseGarden'}

=head2 init_perltidy_opts

If set, Perl::Tidy will be called to format all generated code. The
value of perltidy_opts should be the same as the command-line options
to perltidy.

The default is 0 (no run through Perl::Tidy).

=cut

sub init_perltidy_opts {0}

=head2 init_text_field_size

Tie the size and maxlength of text input fields to the allowed length
of text columns. Should be set to an integer corresponding to the max
size of a text field. The default is 64.

=cut

sub init_text_field_size {$MAX_FIELD_SIZE}

=head2 init_base_code

The return value is inserted into the base RDBO class created.

=cut

sub init_base_code {''}

=head2 init_base_form_class_code

The return value is inserted into the base RHTMLO class created.

=cut

sub init_base_form_class_code {
    return <<EOF
use base qw( Rose::HTML::Form );

EOF
}

=head2 init_limit_to_schemas

The default return value is an empty arrayref, which is interpreted
as "all schemas" if the B<find_schemas> flag is true.

Otherwise, you may explicitly name an array of schema names to limit
the code generated to only those schemas you want. B<Must> be used
with B<find_schemas> set to true.

=cut

sub init_limit_to_schemas { [] }

=head2 use_db_name( I<name> )

Define an explicit database name to use when generating class names.
The default is taken from the Rose::DB connection information.
B<NOTE:>This does not affect the db connection, only the string used
in constructing class names.

B<NOTE:>This option is ignored if find_schemas() is true.

=head2 plant( I<path> )

I<path> will override module_dir() if set in new().

Returns a hash ref of all the class names created, in the format:

 RDBO::Class => RHTMLO::Class
 
If no RHTMLO class was created the hash value will be '1'.

=head2 make_garden

An alias for plant().

=cut

*make_garden = \&plant;

sub plant {
    my $self = shift;
    my $path = shift or croak "path required";

    #carp "path = $path";

    my $path_obj = dir($path);

    $path_obj->mkpath( $self->debug );

    if ( !-w "$path_obj" or !-d "$path_obj" ) {
        croak("$path_obj is not a write-able directory: $!");
    }

    # make sure we can 'require' files we generate
    unshift( @INC, $path );

    # set in loader just in case
    $self->module_dir($path);

    my $garden_prefix = $self->garden_prefix;

    # setup the base RDBO class
    my $base_code  = $self->base_code;
    my $db         = $self->db or croak "db required";
    my $db_class   = $db->class;
    my $new_method = $db->can('new_or_cached') ? 'new_or_cached' : 'new';
    my $db_type    = $db->type;
    my $db_domain  = $db->domain;

    # make the base class unless it already exists
    my $base_template = <<EOF;
package $garden_prefix;
use strict;
use base qw( Rose::DB::Object );
use $db_class;

sub init_db { 
    ${db_class}->$new_method( type => '$db_type', domain => '$db_domain' ) 
}

=head2 garden_prefix

Returns the garden_prefix() value with which this class was created.

=cut

sub garden_prefix { '${garden_prefix}' }

$base_code

EOF

    # append metadata if we are using schemas
    if ( $self->find_schemas ) {

        $base_template .= <<EOF;

use ${garden_prefix}::Metadata;
sub meta_class { '${garden_prefix}::Metadata' }

EOF

    }

    # need a 1 no matter what
    $base_template .= "\n1;\n";

    $self->_make_file( $garden_prefix, $base_template )
        unless ( defined $base_code && $base_code eq '0' );

    # find all schemas if this db supports them
    my %schemas;
    if ( $self->find_schemas and !scalar @{ $self->limit_to_schemas } ) {
        my %native = ( information_schema => 1, pg_catalog => 1 );
        my $info = $db->dbh->table_info( undef, '%', undef, 'TABLE' )
            ->fetchall_arrayref;

        #carp dump $info;

        for my $row (@$info) {
            next if exists $native{ $row->[1] };
            $schemas{ $row->[1] }++;
        }

        # only need custom metadata if we are using schemas
        $self->_make_file( join( '::', $garden_prefix, 'Metadata' ),
            $self->_metadata_template );

    }

    # if we are using schemas and have explicitly named them already,
    # then use what was specified.
    elsif ( $self->find_schemas ) {

        $schemas{$_}++ for @{ $self->limit_to_schemas };

        $self->_make_file( join( '::', $garden_prefix, 'Metadata' ),
            $self->_metadata_template );

    }
    elsif ( $self->use_db_name ) {
        %schemas = ( $self->use_db_name => '' );
    }
    else {

        my $dbname = $db->database;
        $dbname =~ s!.*/!!;
        $dbname =~ s/\W/_/g;
        %schemas = ( $dbname => '' );
    }

    my (%created_classes);

    my $preamble  = $self->module_preamble;
    my $postamble = $self->module_postamble;

    $Rose::DB::Object::Loader::Debug = $self->debug || $ENV{PERL_DEBUG} || 0;

    my @classes;

    for my $schema ( keys %schemas ) {

        #carp "working on schema $schema";

        my $schema_class
            = $schema
            ? join( '::', $garden_prefix, ucfirst($schema) )
            : $garden_prefix;

        if ($schema) {
            my $schema_tmpl
                = $self->_schema_template( $garden_prefix, $schema_class,
                $schema );

            $self->_make_file( $schema_class, $schema_tmpl );
            $self->db_schema($schema) if $self->find_schemas;
        }

        #carp "schema_class: $schema_class";

        $self->class_prefix($schema_class);
        $self->base_class($schema_class);   # already wrote it, so can require

        push @classes, $self->make_classes;
    }

    #carp dump \@classes;

    for my $class (@classes) {

        #carp "class: $class";

        my $template       = '';
        my $this_preamble  = '';
        my $this_postamble = '';

        if ( $class->isa('Rose::DB::Object') ) {

            $template
                = $class->meta->perl_class_definition( indent => 4 ) . "\n";

            if ($preamble) {
                $this_preamble
                    = ref $preamble eq 'CODE'
                    ? $preamble->( $class->meta )
                    : $preamble;
            }

            if ($postamble) {
                $this_postamble
                    = ref $postamble eq 'CODE'
                    ? $postamble->( $class->meta )
                    : $postamble;
            }

            $created_classes{$class} = 1;
        }
        elsif ( $class->isa('Rose::DB::Object::Manager') ) {
            $template = $class->perl_class_definition( indent => 4 ) . "\n";

            if ($preamble) {
                $this_preamble
                    = ref $preamble eq 'CODE'
                    ? $preamble->( $class->object_class->meta )
                    : $preamble;
            }

            if ($postamble) {
                $this_postamble
                    = ref $postamble eq 'CODE'
                    ? $postamble->( $class->object_class->meta )
                    : $postamble;
            }
        }
        else {
            croak "class $class not supported";
        }

        $self->_make_file( $class,
            $this_preamble . $template . $this_postamble );
    }

    # RDBO classes all done. That was the easy part.
    # now create a RHTMLO::Form tree using the same model.

    # first create the base ::Form class.
    my $base_form_class      = join( '::', $garden_prefix, 'Form' );
    my $base_form_class_code = $self->base_form_class_code;
    my $base_form_template   = <<EOF;
package $base_form_class;
use strict;

$base_form_class_code

1;

# generated by Rose::DBx::Garden

EOF

    $self->_make_file( $base_form_class, $base_form_template );

    # second create a subclass of base ::Form for each RDBO class.
    for my $rdbo_class ( keys %created_classes ) {

        if (    $self->convention_manager->is_map_class($rdbo_class)
            and $self->skip_map_class_forms )
        {
            print " ... skipping map_class $rdbo_class\n";
            next;
        }
        my $form_class = join( '::', $rdbo_class, 'Form' );
        my $form_template = $self->_form_template( $rdbo_class, $form_class,
            $base_form_class );

        $created_classes{$rdbo_class} = $form_class;

        $self->_make_file( $form_class, $form_template );
    }

    return \%created_classes;
}

sub _metadata_template {
    my $self            = shift;
    my $base_rdbo_class = $self->garden_prefix;

    return <<EOF;
package ${base_rdbo_class}::Metadata;

use strict;
use warnings;

use base qw( Rose::DB::Object::Metadata );

sub setup {
    my \$self   = shift;
    my \$schema = \$self->class->schema;
    \$self->SUPER::setup( \@_, schema => \$schema );
}

1;

EOF
}

sub _form_template {
    my ( $self, $rdbo_class, $form_class, $base_form_class ) = @_;

    # load the rdbo class and examine its metadata.

    # make sure rdbo_class is loaded
    eval "require $rdbo_class";
    croak "can't load $rdbo_class: $@" if $@;

    my $object_name
        = $self->convention_manager->class_to_table_singular($rdbo_class);

    # create a form template using the column definitions
    # as seed for the form field definitions
    # use the convention manager to assign default field labels

    my $form = <<EOF;
package $form_class;
use strict;
use base qw( $base_form_class );

sub object_class { '$rdbo_class' }

sub init_with_${object_name} {
    my \$self = shift;
    \$self->init_with_object(\@_);
}

sub ${object_name}_from_form {
    my \$self = shift;
    \$self->object_from_form(\@_);
}

sub build_form {
    my \$self = shift;
    
    \$self->add_fields(
    
EOF

    my @fields;
    my $count = 0;
    for my $column ( sort __by_position $rdbo_class->meta->columns ) {
        push( @fields, $self->_column_to_field( $column, ++$count ) );
    }

    $form .= join( "\n", @fields );
    $form .= <<EOF;
    );
    
    return \$self->SUPER::build_form(\@_);
}

1;

EOF

    return $form;
}

# keep columns in same order they appear in db
sub __by_position {
    my $pos1 = $a->ordinal_position;
    my $pos2 = $b->ordinal_position;

    if ( defined $pos1 && defined $pos2 ) {
        return $pos1 <=> $pos2 || lc( $a->name ) cmp lc( $b->name );
    }

    return lc( $a->name ) cmp lc( $b->name );
}

sub _column_to_field {
    my ( $self, $column, $tabindex ) = @_;
    my $col_type    = $column->type;
    my $type        = $self->column_field_map->{$col_type} || 'text';
    my $field_maker = 'garden_' . $type . '_field';
    my $label_maker = $self->column_to_label;
    my $label       = $label_maker->( $self, $column->name );

    unless ( $self->can($field_maker) ) {
        $field_maker = 'garden_default_field';
    }

    if ( $col_type eq 'serial' and !$self->include_autoinc_form_fields ) {
        return '';
    }

    return $self->$field_maker( $column, $label, $tabindex );
}

=head2 garden_default_field( I<column>, I<label>, I<tabindex> )

Returns the Perl code text for creating a generic Form field.

=cut

sub garden_default_field {
    my ( $self, $column, $label, $tabindex ) = @_;
    my $col_type = $column->type;
    my $type     = $self->column_field_map->{$col_type} || 'text';
    my $name     = $column->name;
    my $desc     = $column->can('remarks') ? ( $column->remarks || '' ) : '';
    my $length   = $column->can('length') ? $column->length() : 0;
    my $maxlen   = $self->text_field_size;
    if ( defined $length ) {
        $maxlen = $length;
    }
    $length = 24 unless defined $length;    # 24 holds a timestamp

    if ( $length > $MAX_FIELD_SIZE ) {
        $length = $MAX_FIELD_SIZE;
    }

    return <<EOF;
    $name => {
        id          => '$name',
        type        => '$type',
        class       => '$col_type',
        label       => '$label',
        tabindex    => $tabindex,
        rank        => $tabindex,
        size        => $length,
        maxlength   => $maxlen,
        description => q{$desc},
        },
EOF
}

=head2 garden_numeric_field( I<column>, I<label>, I<tabindex> )

Returns the Perl code text for creating a numeric Form field.

=cut

sub garden_numeric_field {
    my ( $self, $column, $label, $tabindex ) = @_;
    my $col_type = $column->type;
    my $type     = $self->column_field_map->{$col_type} || 'text';
    my $name     = $column->name;
    my $desc     = $column->can('remarks') ? ( $column->remarks || '' ) : '';

    return <<EOF;
    $name => {
        id          => '$name',
        type        => '$type',
        class       => '$col_type',
        label       => '$label',
        tabindex    => $tabindex,
        rank        => $tabindex,
        size        => 16,
        maxlength   => 32,
        description => q{$desc},
        },
EOF
}

=head2 garden_boolean_field( I<column>, I<label>, I<tabindex> )

Returns the Perl code text for creating a boolean Form field.

=cut

sub garden_boolean_field {
    my ( $self, $column, $label, $tabindex ) = @_;
    my $col_type = $column->type;
    my $name     = $column->name;
    my $desc     = $column->can('remarks') ? ( $column->remarks || '' ) : '';

    return <<EOF;
    $name => {
        id          => '$name',
        type        => 'boolean',
        label       => '$label',
        tabindex    => $tabindex,
        rank        => $tabindex,
        class       => '$col_type',
        description => q{$desc},
        },
EOF
}

=head2 garden_text_field( I<column>, I<label>, I<tabindex> )

Returns the Perl code text for creating a text Form field.

=cut

sub garden_text_field {
    my ( $self, $column, $label, $tabindex ) = @_;
    my $col_type = $column->type;
    my $name     = $column->name;
    my $length   = $column->can('length') ? $column->length() : 0;
    $length = 0 unless defined $length;
    my $maxlen = $self->text_field_size;
    if ( defined $length ) {
        $maxlen = $length;
    }
    if ( $length > $MAX_FIELD_SIZE ) {
        $length = $MAX_FIELD_SIZE;
    }
    my $desc = $column->can('remarks') ? ( $column->remarks || '' ) : '';

    return <<EOF;
    $name => {
        id          => '$name',
        type        => 'text',
        class       => '$col_type',
        label       => '$label',
        tabindex    => $tabindex,
        rank        => $tabindex,
        size        => $length,
        maxlength   => $maxlen,
        description => q{$desc},
        },
EOF
}

=head2 garden_menu_field( I<column>, I<label>, I<tabindex> )

Returns the Perl code text for creating a menu Form field.

=cut

sub garden_menu_field {
    my ( $self, $column, $label, $tabindex ) = @_;
    my $col_type = $column->type;
    my $name     = $column->name;
    my $options  = dump $column->values;
    my $desc     = $column->can('remarks') ? ( $column->remarks || '' ) : '';

    #dump $column;

    return <<EOF;
    $name => {
        id          => '$name',
        type        => 'menu',
        class       => '$col_type',
        label       => '$label',
        tabindex    => $tabindex,
        rank        => $tabindex,
        options     => $options,
        description => q{$desc},
        },
EOF
}

=head2 garden_textarea_field( I<column>, I<label>, I<tabindex> )

Returns Perl code for textarea field.

=cut

sub garden_textarea_field {
    my ( $self, $column, $label, $tabindex ) = @_;
    my $col_type = $column->type;
    my $name     = $column->name;
    my $desc     = $column->can('remarks') ? ( $column->remarks || '' ) : '';

    return <<EOF;
    $name => {
        id          => '$name',
        type        => 'textarea',
        class       => '$col_type',
        label       => '$label',
        tabindex    => $tabindex,
        rank        => $tabindex,
        size        => $MAX_FIELD_SIZE . 'x8',
        description => q{$desc},
        },
EOF
}

=head2 garden_hidden_field( I<column>, I<label>, I<tabindex> )

Returns the Perl code text for creating a hidden Form field.

=cut

sub garden_hidden_field {
    my ( $self, $column, $label, $tabindex ) = @_;
    my $col_type = $column->type;
    my $name     = $column->name;
    my $desc     = $column->can('remarks') ? ( $column->remarks || '' ) : '';
    return <<EOF;
    $name => {
        id      => '$name',
        type    => 'hidden',
        class   => '$col_type',
        label   => '$label',
        rank    => $tabindex,
        description => q{$desc},
        },
EOF
}

=head2 garden_serial_field( I<column>, I<label>, I<tabindex> )

Returns the Perl code text for creating a serial Form field.

=cut

sub garden_serial_field {
    my ( $self, $column, $label, $tabindex ) = @_;
    my $col_type = $column->type;
    my $name     = $column->name;
    my $desc     = $column->can('remarks') ? ( $column->remarks || '' ) : '';

    return <<EOF;
    $name => {
        id      => '$name',
        type    => 'serial',
        class   => '$col_type',
        label   => '$label',
        rank    => $tabindex,
        description => q{$desc},
        },
EOF
}

sub _schema_template {
    my ( $self, $base, $package, $schema ) = @_;

    my @other_base = grep { !m/LoaderGenerated/ } @{ $self->base_classes };
    if (@other_base) {
        $base .= ' ' . join( ' ', @other_base );
    }

    return <<EOF;
package $package;
use strict;
use base qw( $base );

sub schema { '$schema' }

1;
EOF
}

sub _make_file {
    my ( $self, $class, $buffer ) = @_;
    ( my $file = $class ) =~ s,::,/,g;
    $file .= '.pm';

    my ( $name, $path, $suffix ) = fileparse( $file, qr{\.pm} );

    my $fullpath = dir( $self->module_dir, $path );

    unless ( $self->force_install ) {
        if ( -s $file ) {
            print " ... skipping $class ($file)\n";
            return;
        }
    }

    $fullpath->mkpath( $self->debug ) if $path;

    if ( $self->perltidy_opts ) {
        require Perl::Tidy;
        my $newbuf;
        Perl::Tidy::perltidy(
            source      => \$buffer,
            destination => \$newbuf,
            argv        => $self->perltidy_opts
        );
        $buffer = $newbuf;
    }

    my $file_to_write = file( $self->module_dir, $file )->stringify;

    File::Slurp::Tiny::write_file( $file_to_write, $buffer );

    print "$class written to $file\n";
}

=head1 AUTHORS

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-dbx-garden at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-DBx-Garden>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::DBx::Garden

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-DBx-Garden>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-DBx-Garden>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DBx-Garden>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-DBx-Garden>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Adam Prime, C<< adam.prime at utoronto.ca >>
for patches and feedback on the design.

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2007 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Rose::DBx::Garden
