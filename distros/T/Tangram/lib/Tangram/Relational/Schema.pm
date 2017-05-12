package Tangram::Relational::Schema;

use strict;
use Tangram::Schema;

sub _deploy_do
{
    my $output = shift;

    return ref($output) && eval { $output->isa('DBI::db') }
		? sub { print $Tangram::TRACE "Deploying with: >-\n",
			    @_, ($_[$#_]=~m/\n\Z/?"":"\n"),
				"...\n" if $Tangram::TRACE;
			$output->do( join '', @_ ); }
		: sub { print $output @_, ";\n\n" };
}

sub deploy
{
    my ($self, $output) = @_;
    my ($tables, $engine) = @$self;
	my $schema = $engine->{SCHEMA};

    $output ||= \*STDOUT;
    my $driver = $engine->{driver} || Tangram::Relational->new();

    my $do = _deploy_do($output);

    foreach my $table (sort keys %$tables)
    {
	my $def = $tables->{$table};
	my $cols = $def->{COLS};

	my @base_cols;

	my $type = $def->{TYPE} || $schema->{sql}{table_type};

	my $id_col = $schema->{sql}{id_col};
	my $class_col = $schema->{sql}{class_col} || 'type';
	my $timestamp_col = $schema->{sql}{timestamp_col} || '__ts';
	my $timestamp_type = $schema->{sql}{timestamp} || 'TIMESTAMP';
	my $timestamp = $schema->{sql}{timestamp_all_tables};

	push @base_cols,("$id_col ".
			 $driver->type("$schema->{sql}{id} NOT NULL"))
	    if exists $cols->{$id_col};
	push @base_cols, "$class_col "
	    .$driver->type("$schema->{sql}{cid} NOT NULL")
	    if exists $cols->{$class_col};

	push @base_cols, "$timestamp_col "
	    .$driver->type("$timestamp_type NOT NULL")
            if $timestamp;

	delete @$cols{$id_col};
	delete @$cols{$class_col};

	$do->("CREATE TABLE $table\n(\n  ",
	      join( ",\n  ", (@base_cols,
			      map { "$_ ".$driver->type($cols->{$_}) }
			      keys %$cols),
		    ( exists $cols->{$id_col} 
		      ? ("PRIMARY KEY( $id_col )")
		      : () ),
		  ),
	      "\n) ".($type?" ENGINE=$type":""));

    }

    my %made_sequence;

    foreach my $class ( values %{$schema->{classes}} ) {
	if ( my $sequence = $class->{oid_sequence} ) {
	    $do->($driver->mk_sequence_sql($sequence))
		unless $made_sequence{$sequence}++;
	}
    }

    my $control = $schema->{control};
    my $table_type = $schema->{sql}{table_type};

    if ( my $sequence = $schema->{sql}{oid_sequence} ) {

	$do->($driver->mk_sequence_sql($sequence))
	    unless $made_sequence{$sequence}++;

    } else {
    $do->( <<SQL . ($table_type?" ENGINE=$table_type":"") );
CREATE TABLE $control
(
layout INTEGER NOT NULL,
engine VARCHAR(255),
engine_layout INTEGER,
mark INTEGER NOT NULL
)
SQL

    my $info = $engine->get_deploy_info();
    #my ($l) = split '\.', $Tangram::VERSION;

    # Prevent additional records on redeploy.
    #  -- ks.perl@kurtstephens.com 2004/04/29
    $do->("CREATE UNIQUE INDEX ${control}_Guard ON $control (layout, engine, engine_layout)");

    $do->("INSERT INTO $control (layout, engine, engine_layout, mark)"
	  ." VALUES ($info->{LAYOUT}, '$info->{ENGINE}', "
	  ."$info->{ENGINE_LAYOUT}, 0)");

    }
}

sub retreat
{
    my ($self, $output) = @_;
    my ($tables, $engine) = @$self;
	my $schema = $engine->{SCHEMA};

    $output ||= \*STDOUT;

    my $do = _deploy_do($output);

    my %dropped_sequences;
    my $driver = $engine->{driver} || Tangram::Relational->new();

    my $oid_sequence = $schema->{sql}{oid_sequence};
    for my $table (sort keys %$tables,
		   ($oid_sequence ? () : $schema->{control}))
    {
		$do->( "DROP TABLE $table" );
    }

    for my $class ( values %{ $schema->{classes} } ) {
	if ( my $sequence = $class->{oid_sequence} ) {
	    $do->($driver->drop_sequence_sql($sequence))
		unless $dropped_sequences{$sequence}++;
	}
    }

    if ( $oid_sequence ) {
	$do->($driver->drop_sequence_sql($oid_sequence));
    }
}

# XXX - never reached in the test suite; debugging function?
sub classids
{
    my ($self) = @_;
    my ($tables, $schema) = @$self;
	my $classes = $schema->{classes};
	# use Data::Dumper;
	return { map { $_ => $classes->{$_}{id} } keys %$classes };
}

1;
