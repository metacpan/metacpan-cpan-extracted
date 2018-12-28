package MySQL::Workbench::DBIC;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use File::Spec;
use JSON;
use List::Util qw(first);
use Moo;
use MySQL::Workbench::Parser;

# ABSTRACT: create DBIC scheme for MySQL workbench .mwb files

our $VERSION = '1.13';

has output_path              => ( is => 'ro', required => 1, default => sub { '.' } );
has file                     => ( is => 'ro', required => 1 );
has uppercase                => ( is => 'ro' );
has inherit_from_core        => ( is => 'ro' );
has namespace                => ( is => 'ro', isa => \&_check_namespace, required => 1, default => sub { '' } );
has result_namespace         => ( is => 'ro', isa => \&_check_namespace, required => 1, default => sub { '' } );
has resultset_namespace      => ( is => 'ro', isa => \&_check_namespace, required => 1, default => sub { '' } );
has load_result_namespace    => ( is => 'ro', isa => \&_check_namespace_array, default => sub { '' } );
has load_resultset_namespace => ( is => 'ro', isa => \&_check_namespace_array, default => sub { '' } );
has schema_name              => ( is => 'rwp', isa => sub { $_[0] =~ m{ \A [A-Za-z0-9_]+ \z }xms } );
has parser                   => ( is => 'rwp' );
has version_add              => ( is => 'ro', required => 1, default => sub { 0.01 } );
has column_details           => ( is => 'ro', required => 1, default => sub { 0 } );
has use_fake_dbic            => ( is => 'ro', required => 1, default => sub { 0 } );
has skip_indexes             => ( is => 'ro', required => 1, default => sub { 0 } );
has belongs_to_prefix        => ( is => 'ro', required => 1, default => sub { '' } );
has has_many_prefix          => ( is => 'ro', required => 1, default => sub { '' } );
has has_one_prefix           => ( is => 'ro', required => 1, default => sub { '' } );
has many_to_many_prefix      => ( is => 'ro', required => 1, default => sub { '' } );
has utf8                     => ( is => 'ro', required => 1, default => sub { 0 } );

has version => ( is => 'rwp' );
has classes => ( is => 'rwp', isa => sub { ref $_[0] && ref $_[0] eq 'ARRAY' }, default => sub { [] } );

sub _check_namespace {
    my ($namespace) = @_;

    return $namespace =~ m{ \A [A-Z]\w*(::\w+)* \z }xms;
}

sub _check_namespace_array {
    my ($namespaces) = @_;

    if ( !ref $namespaces ) {
        return _check_namespace( $namespaces );
    }

    for my $namespace ( @{ $namespaces || [] } ) {
        return if !_check_namespace( $namespace );
    }

    return 1;
}

around new => sub {
    my ($next, $class, %args) = @_;

    if ( $args{use_fake_dbic} || !eval{ require DBIx::Class } ) {
        require MySQL::Workbench::DBIC::FakeDBIC;
    }

    my $self = $class->$next( %args );

    my $parser = MySQL::Workbench::Parser->new( file => $self->file );
    $self->_set_parser( $parser );

    return $self;
};

sub create_schema{
    my $self = shift;

    my $parser = $self->parser;
    my @tables = @{ $parser->tables };

    my @classes;
    my %relations;
    for my $table ( @tables ){
        my $name = $table->name;

        push @classes, $name;

        my $rels = $table->foreign_keys;
        for my $to_table ( keys %$rels ){
            $relations{$to_table}->{to}->{$name}   = $rels->{$to_table};
            $relations{$name}->{from}->{$to_table} = $rels->{$to_table};
        }
    }

    $self->_set_classes( \@classes );

    my @scheme = $self->_main_template;

    my @files;
    for my $table ( @tables ){
        my $custom_code = $self->_custom_code_table( $table );
        push @files, $self->_class_template( $table, $relations{$table->name}, $custom_code );
    }

    push @files, @scheme;

    $self->_write_files( @files );
}

sub _custom_code_table {
    my ($self, $table) = @_;

    my $name = $table->name;
    if ( $self->uppercase ) {
        $name = join '', map{ ucfirst } split /[_-]/, $table->name;
    }

    my @base_path;
    push @base_path, $self->output_path if $self->output_path;

    my $path = File::Spec->catfile(
        @base_path,
        (split /::/, $self->namespace),
        $self->schema_name,
        $self->result_namespace,
        'Result',
        $name . '.pm'
    );

    return '' if !-f $path;

    return $self->_custom_code( $path );
}

sub _custom_code {
    my ($self, $path) = @_;

    my $content = do { local (@ARGV, $/) = $path; <> };

    my ($code) = $content =~ m{
        ^[#] \s+ --- \s*
        ^[#] \s+ Put \s+ your \s+ own \s+ code \s+ below \s+ this \s+ comment \s*
        ^[#] \s+ --- \s*
        (.*?)
        ^[#] \s+ --- \s*
    }xms;

    return $code;
}

sub _write_files{
    my ($self, %files) = @_;

    for my $package ( keys %files ){
        my @path;
        push @path, $self->output_path if $self->output_path;
        push @path, split /::/, $package;
        my $file = pop @path;
        my $dir  = File::Spec->catdir( @path );

        unless( -e $dir ){
            $self->_mkpath( $dir );
        }

        if( open my $fh, '>', $dir . '/' . $file . '.pm' ){
            if ( $self->utf8 ) {
                binmode $fh, ':encoding(utf-8)';
            }

            print $fh $files{$package};
            close $fh;
        }
        else{
            croak "Couldn't create $file.pm: $!";
        }
    }
}

sub _mkpath{
    my ($self, $path) = @_;

    my @parts = split /[\\\/]/, $path;

    for my $i ( 0..$#parts ){
        my $dir = File::Spec->catdir( @parts[ 0..$i ] );
        unless ( -e $dir ) {
            mkdir $dir or die "$dir: $!";
        }
    }
}

sub _has_many_template{
    my ($self, $to, $rels) = @_;

    my $to_class = $to;
    if ( $self->uppercase ) {
        $to_class = join '', map{ ucfirst $_ }split /[_-]/, $to;
    }

    my $package = join '::', (
       ( $self->namespace ? $self->namespace : () ),
       $self->schema_name,
       ( length $self->result_namespace ? $self->result_namespace : () ),
       'Result',
       $to_class,
    );

    my $name = $to;

    my %has_many_rels;
    my $counter = 1;

    my $string = '';
    for my $field ( @{ $rels || [] } ) {
        my $me_field      = $field->{foreign};
        my $foreign_field = $field->{me};

        my $temp_field = $self->has_many_prefix . $name;
        while ( $has_many_rels{$temp_field} ) {
            $temp_field = $self->has_many_prefix . $name . $counter++;
        }

        $has_many_rels{$temp_field}++;

        $string .= qq~
__PACKAGE__->has_many($temp_field => '$package',
             { 'foreign.$foreign_field' => 'self.$me_field' });
~;
    }

    return $string;
}

sub _belongs_to_template{
    my ($self, $from, $rels) = @_;

    my $from_class = $from;
    if ( $self->uppercase ) {
        $from_class = join '', map{ ucfirst $_ }split /[_-]/, $from;
    }

    my $package = join '::', (
       ( $self->namespace ? $self->namespace : () ),
       $self->schema_name,
       ( length $self->result_namespace ? $self->result_namespace : () ),
       'Result',
       $from_class,
    );

    my $name = $from;

    my %belongs_to_rels;
    my $counter = 1;

    my $string = '';
    for my $field ( @{ $rels || [] } ) {
        my $me_field      = $field->{me};
        my $foreign_field = $field->{foreign};

        my $temp_field = $self->belongs_to_prefix . $name;
        while ( $belongs_to_rels{$temp_field} ) {
            $temp_field = $self->belongs_to_prefix . $name . $counter++;
        }

        $belongs_to_rels{$temp_field}++;

        $string .= qq~
__PACKAGE__->belongs_to($temp_field => '$package',
             { 'foreign.$foreign_field' => 'self.$me_field' });
~;
    }

    return $string;
}

sub _class_template{
    my ($self, $table, $relations, $custom_code) = @_;

    my $name    = $table->name;
    my $class   = $name;
    if ( $self->uppercase ) {
        $class = join '', map{ ucfirst $_ }split /[_-]/, $name;
    }

    my $package = join '::', (
       ( $self->namespace ? $self->namespace : () ),
       $self->schema_name,
       ( length $self->result_namespace ? $self->result_namespace : () ),
       'Result',
       $class,
    );

    my ($has_many, $belongs_to) = ('','');

    my $comment = $table->comment // '{}';
    utf8::upgrade( $comment );

    my $data;
    my $table_comment_perl = '';
    eval {
        $data = JSON->new->decode( $comment );
    };

    if ( !ref $data || 'HASH' ne ref $data ) {
        $data               = {};
        $table_comment_perl = $comment if $comment;
    }
    elsif ( $data->{comment} ) {
        $table_comment_perl = $data->{comment};
    }

    if ( $table_comment_perl ) {
        $table_comment_perl = sprintf "\n\n=head1 DESCRIPTION\n\n%s\n\n=cut", $table_comment_perl;
    }

    my @core_components = $self->inherit_from_core ? () : qw(PK::Auto Core);
    my $components      = join( ' ', @core_components, @{ $data->{components} || [] } );
    my $load_components = $components ? "__PACKAGE__->load_components( qw/$components/ );" : '';

    my %foreign_keys;

    for my $to_table ( sort keys %{ $relations->{to} } ){
        $has_many .= $self->_has_many_template( $to_table, $relations->{to}->{$to_table} );
    }

    for my $from_table ( sort keys %{ $relations->{from} } ){
        $belongs_to .= $self->_belongs_to_template( $from_table, $relations->{from}->{$from_table} );

        my @foreign_key_names = map{ $_->{me} }@{ $relations->{from}->{$from_table} };
        @foreign_keys{ @foreign_key_names } = (1) x @foreign_key_names;
    }

    my @columns = map{ $_->name }@{ $table->columns };
    my $column_string = '';

    if ( !$self->column_details ) {
        $column_string = "qw/\n" . join "\n", map{ "    " . $_ }@columns, "    /";
    }
    else {
        my @columns = @{ $table->columns };

        for my $column ( @columns ) {
            my $default_value = $column->default_value || '';
            $default_value =~ s/'/\\'/g;

            my $size = $column->length;

            if ( $column->datatype =~ /char/i && $column->length <= 0 ) {
                $size = 255;
            }

            my @options;

            my $name        = $column->name;
            my $col_comment = $column->comment;

            push @options, "data_type          => '" . $column->datatype . "',";
            push @options, "is_auto_increment  => 1,"                            if $column->autoincrement;
            push @options, "is_nullable        => 1,"                            if !$column->not_null;
            push @options, "size               => " . $size . ","                if $size > 0;
            push @options, "default_value      => '" . $default_value . "',"     if $default_value;

            if ( first { $column->datatype eq $_ }qw/SMALLINT INT INTEGER BIGINT MEDIUMINT NUMERIC DECIMAL/ ) {
                push @options, "is_numeric         => 1,";
            }

            push @options, "retrieve_on_insert => 1," if first{ $name eq $_ }@{ $table->primary_key };
            push @options, "is_foreign_key     => 1," if $foreign_keys{$name};

            my $column_comment_perl_raw = '';

            if ( ( $data && $data->{column_info}->{$name} ) || $col_comment ) {
                local $Data::Dumper::Sortkeys = 1;
                local $Data::Dumper::Indent   = 1;
                local $Data::Dumper::Pad      = '      ';

                utf8::upgrade( $col_comment );

                my $comment_data;
                eval {
                    $comment_data = JSON->new->decode( $col_comment );
                    1;
                } or do {
                    if ( $col_comment =~ /\{/ ) {
                    print STDERR $col_comment, ": ", $@;
                    }
                };

                if ( !$comment_data || 'HASH' ne ref $comment_data ) {
                    $column_comment_perl_raw = $col_comment;
                    $comment_data            = {};
                }
                else {
                    $column_comment_perl_raw = delete $comment_data->{comment} // '';
                }

                my %hash = (
                    %{ $data->{column_info}->{$name} || {} },
                    %{ $comment_data || {} },
                );

                if ( %hash ) {
                    my $dump = Dumper( \%hash );
                    $dump    =~ s{\$VAR1 \s+ = \s* \{ \s*? $}{}xms;
                    $dump    =~ s{\A\s+\n\s{8}}{}xms;
                    $dump    =~ s{\n[ ]+\};\s*\z}{}xms;

                    push @options, $dump;
                }
            }

            my $option_string = join "\n        ", @options;

            my @column_comment_lines = split /\r?\n/, $column_comment_perl_raw;
            my $column_comment_perl  = '';
            if ( @column_comment_lines ) {
                my $sep = sprintf "\n%s%s%s# ", ' ' x 4, ' ' x length $name, ' ' x 6;
                $column_comment_perl = ' # ' . join ( $sep, @column_comment_lines );
            }

            $column_string .= <<"            COLUMN";
    $name => {$column_comment_perl
        $option_string
    },
            COLUMN
        }
    }

    my @indexes      = @{ $table->indexes };
    my $indexes_hook = $self->_indexes_template( @indexes );

    my $primary_key   = join " ", @{ $table->primary_key };
    my $version       = $self->version;
    my $inherit_from  = $self->inherit_from_core ? '::Core' : '';
    my $use_utf8      = $self->utf8 ? "\nuse utf8;" : '';

    my $template = qq~package $package;

# ABSTRACT: Result class for $name$table_comment_perl

use strict;
use warnings;$use_utf8
use base qw(DBIx::Class$inherit_from);

our \$VERSION = $version;

$load_components
__PACKAGE__->table( '$name' );
__PACKAGE__->add_columns(
$column_string
);
__PACKAGE__->set_primary_key( qw/ $primary_key / );

$has_many
$belongs_to

$indexes_hook

# ---
# Put your own code below this comment
# ---
$custom_code
# ---

1;~;

    return $package, $template;
}

sub _indexes_template {
    my ($self, @indexes) = @_;

    return '' if !@indexes;
    return '' if $self->skip_indexes;

    my $hooks     = '';
    my $indexlist = '';

    INDEX:
    for my $index ( @indexes ) {
        my $type = lc $index->type || 'normal';

        next INDEX if $type eq 'primary';

        $type = 'normal' if $type eq 'index';

        $hooks .= sprintf '    $table->add_index(
        type   => "%s",
        name   => "%s",
        fields => [%s],
    );

', $type, $index->name, join ', ', map{ "'$_'" }@{ $index->columns };

        $indexlist.= sprintf "=item * %s\n\n", $index->name;
    }

    return '' if !$hooks;

    my $sub_string = qq~
=head1 DEPLOYMENT

=head2 sqlt_deploy_hook

These indexes are added to the table during deployment

=over 4

$indexlist

=back

=cut

sub sqlt_deploy_hook {
    my (\$self, \$table) = \@_;

$hooks
    return 1;
}
~;

    return $sub_string;
}

sub _main_template{
    my ($self) = @_;

    my @class_names  = @{ $self->classes };
    my $classes      = join "\n", map{ "    " . $_ }@class_names;

    my $schema_name  = $self->schema_name;

    unless ($schema_name) {
        my @schema_names = qw(DBIC_Schema Database DBIC MySchema MyDatabase DBIxClass_Schema);

        for my $schema ( @schema_names ){
            unless( grep{ $_ eq $schema }@class_names ){
                $schema_name = $schema;
                last;
            }
        }
    }

    croak "couldn't determine a package name for the schema" unless $schema_name;


    $self->_set_schema_name( $schema_name );

    my $namespace  = $self->namespace . '::' . $schema_name;
       $namespace  =~ s/^:://;

    my $version;
    eval {
        my $lib_path = $self->output_path;
        my @paths    = @INC;
        unshift @INC, $lib_path;

        eval "require $namespace";
        $version = $namespace->VERSION();
        1;
    } or warn $@;

    my $custom_code;
    if ( $version ) {
        (my $path       = $namespace) =~ s{::}{/}g;
        my $schema_file = $self->output_path . '/' . $path . '.pm';
        $custom_code    = $self->_custom_code( $schema_file );
    }

    $custom_code //= '';

    my %all_namespaces_to_load;
    if ( $self->resultset_namespace ) {
        push @{ $all_namespaces_to_load{resultset_namespace} }, sprintf "'%s'", $self->resultset_namespace;
    }

    if ( $self->load_resultset_namespace ) {
        push @{ $all_namespaces_to_load{resultset_namespace} }, map { "'$_'" }
            ref $self->load_resultset_namespace ?
                @{ $self->load_resultset_namespace } :
                $self->load_resultset_namespace;
    }

    if ( $self->load_result_namespace ) {
        push @{ $all_namespaces_to_load{result_namespace} }, map { "'$_'" }
            ref $self->load_result_namespace ?
                @{ $self->load_result_namespace } :
                $self->load_result_namespace;
    }

    if ( $self->result_namespace ) {
        my $namespace = sprintf "'%s::Result'", $self->result_namespace;
        my $found     = grep { $namespace eq $_ }@{ $all_namespaces_to_load{result_namespace} };
        unshift @{ $all_namespaces_to_load{result_namespace} }, $namespace if !$found;
    }

    if ( $version ) {
        $version += $self->version_add || 0.01;
    }

    $version ||= ($self->version_add || 0.01);

    $self->_set_version( $version );

    my @namespace_types;
    for my $namespace_type ( sort keys %all_namespaces_to_load ) {
        my @namespaces = @{ $all_namespaces_to_load{$namespace_type} };

        push @namespace_types, sprintf "\n    %s => %s,",
            $namespace_type,
            ( @namespaces == 1 ? $namespaces[0] : '[' . (join ', ', @namespaces ) . ']' );
    }

    my $namespaces_to_load = '';
    $namespaces_to_load    = "(" . (join '', @namespace_types) . "\n)" if @namespace_types;

    my $use_utf8 = $self->utf8 ? "\nuse utf8;" : '';

    my $template = qq~package $namespace;

# ABSTRACT: Schema class

use strict;
use warnings;$use_utf8

use base qw/DBIx::Class::Schema/;

our \$VERSION = $version;

__PACKAGE__->load_namespaces$namespaces_to_load;

# ---
# Put your own code below this comment
# ---
$custom_code
# ---

1;~;

    return $namespace, $template;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MySQL::Workbench::DBIC - create DBIC scheme for MySQL workbench .mwb files

=head1 VERSION

version 1.13

=head1 SYNOPSIS

    use MySQL::Workbench::DBIC;

    my $foo = MySQL::Workbench::DBIC->new(
        file           => '/path/to/file.mwb',
        output_path    => $some_path,
        namespace      => 'MyApp::DB',
        version_add    => 0.01,
        column_details => 1, # default 1
        use_fake_dbic  => 1, # default 0
    );

    $foo->create_schema;

=head1 METHODS

=head2 new

creates a new object of MySQL::Workbench::DBIC. You can pass some parameters
to new:

  my $foo = MySQL::Workbench::DBIC->new(
    output_path       => '/path/to/dir',
    input_file        => '/path/to/dbdesigner.file',
    namespace         => 'MyApp::Database',
    result_namespace  => 'Core',
    version_add       => 0.001,
    schema_name       => 'MySchema',
    column_details    => 1,
    use_fake_dbic     => 1, # default 0.
    belongs_to_prefix => 'fk_',
    has_many_prefix   => 'has_',
    uppercase         => 1,
  );

C<use_fake_dbic> is helpful when C<DBIx::Class> is not installed on the
machine where you use this module.

=head2 create_schema

creates all the files that are needed to work with DBIx::Class schema:

The main module that loads all classes and one class per table. If you haven't
specified an input file, the module will croak.

=head1 ATTRIBUTES

=head2 output_path

sets / gets the output path for the scheme

  print $foo->output_path;

=head2 input_file

sets / gets the name of the Workbench file

  print $foo->input_file;

=head2 column_details

If enabled, the column definitions are more detailed. Default: disabled.

Standard (excerpt from Result classes):

  __PACKAGE__->add_columns( qw/
    cert_id
    register_nr
    state
  );

With enabled column details:

  __PACKAGE__->add_columns(
    cert_id => {
      data_type         => 'integer',
      is_nullable       => 0,
      is_auto_increment => 1,
    },
    register_nr => {
      data_type   => 'integer',
      is_nullable => 0,
    },
    state => {
      data_type     => 'varchar',
      size          => 1,
      is_nullable   => 0,
      default_value => 'done',
    },
  );

This is useful when you use L<DBIx::Class::DeploymentHandler> to deploy the columns
correctly.

=head2 version_add

The files should be versioned (e.g. to deploy the DB via C<DBIx::Class::DeploymentHandler>). On the first run
the version is set to "0.01". When the schema file already exists, the version is increased by the value
of C<version_add> (default: 0.01)

=head2 schema_name

sets a new name for the schema. By default on of these names is used:

  DBIC_Scheme Database DBIC MyScheme MyDatabase DBIxClass_Scheme

=head2 namespace

sets / gets the name of the namespace. If you set the namespace to 'Test' and you
have a table named 'MyTable', the main module is named 'Test::DBIC_Scheme' and
the class for 'MyTable' is named 'Test::DBIC_Scheme::Result::MyTable'

=head2 result_namespace

sets / gets the name of an optional result namespace. If you set the result_namespace to 'Core' and you
have a table named 'MyTable', the class for 'MyTable' is named 'Test::DBIC_Scheme::Core::Result::MyTable'

=head2 resultset_namespace

sets / gets the name of an optional resultset namespace. If you set the resultset_namespace to 'Core' and you
have a table named 'MyTable', the resultset class for 'MyTable' is named 'Test::DBIC_Scheme::Core::ResultSet::MyTable'

=head2 load_result_namespace

Additional namespaces to be loaded from the main schema class:

  my $foo = MySQL::Workbench::DBIC->new(
    output_path       => '/path/to/dir',
    input_file        => '/path/to/dbdesigner.file',
    result_namespace  => 'Core',
    load_result_namespace  => 'Virtual', # can be an arrayref, too
  );

The schema class loads all namespaces:

  __PACKAGE__->load_namespaces(
    result_namespace => ['Core', 'Virtual'],
  );

=head2 load_resultset_namespace

Additional namespaces to be loaded from the main schema class:

  my $foo = MySQL::Workbench::DBIC->new(
    output_path       => '/path/to/dir',
    input_file        => '/path/to/dbdesigner.file',
    result_namespace  => 'Core',
    load_resultset_namespace => [ 'Test', 'Virtual' ], # can be a string, too
  );

The schema class loads all namespaces:

  __PACKAGE__->load_namespaces(
    resultset_namespace => ['Test', 'Virtual'],
    result_namespace    => 'Core';
  );

=head2 prefix

In relationships the accessor for the objects of the "other" table shouldn't have the name of the column.
Otherwise it is very clumsy to get the orginial value of this table.

  'belongs_to' => 'fk_'
  'has_many' => 'has_'

creates (col1 is the column name of the foreign key)

  __PACKAGE__->belongs_to( 'fk_col1' => 'OtherTable', {'foreign.col1' => 'self.col1' } );

=head2 uppercase

When C<uppercase> is set to true the package names are CamelCase. Given the table names I<user>, I<user_groups> and
I<groups>, the package names would be I<*::User>, I<*::UserGroups> and I<*::Groups>.

=head2 skip_indexes

When C<skip_indexes> is true, the sub C<sqlt_deploy_hook> that adds the indexes to the table is not created

=head2 utf8

If you use non-ASCII characters in table or column comments, you should set the C<utf8> attribute to a true value.
Then every generated class has a C<use utf8;> in it.

=head2 belongs_to_prefix

=head2 has_many_prefix

=head2 has_one_prefix

=head2 many_to_many_prefix

=head2 version

=head2 use_fake_dbic

=head2 classes

=head2 file

=head2 inherit_from_core

By default, the classes inherit from C<DBIx::Class> and they load the components
C<PK::Auto> and C<Core>. If you set I<inherit_from_core>, the classes inherit
from C<DBIx::Class::Core>. and no extra components are loaded.

=head2 parser

The C<MySQL::Workbench::Parser> object.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
