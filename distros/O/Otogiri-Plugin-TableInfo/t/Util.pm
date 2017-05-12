package t::Util;
use parent qw(Exporter);
use strict;
use warnings;

our @EXPORT = qw(desc_by_pg_dump);

sub desc_by_pg_dump {
    my ($db, $table_name) = @_;

    my ($dsn, $user, $pass) = @{ $db->connect_info };
    my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn($dsn);
    my %attr = _parse_driver_dsn($driver_dsn);
    $attr{user}     = $user if ( !exists $attr{user} );
    $attr{password} = $pass if ( !exists $attr{password} );
    my $cmd = _build_pg_dump_command($table_name, %attr);
    my $cmd_result = `$cmd`;
    my $result = _trim_result($cmd_result);
    _fix_unique_index_ddl(\$result, $table_name);
    return $result;
}

sub _parse_driver_dsn {
    my ($driver_dsn) = @_;

    my @statements = split(qr/;/, $driver_dsn);
    my %result = ();
    for my $statement ( @statements ) {
        my ($variable_name, $value) = map{ _trim($_) } split(qr/=/, $statement);
        $result{$variable_name} = $value;
    }
    return %result;
}

sub _build_pg_dump_command {
    my ($table_name, %args) = @_;
    my $cmd = "pg_dump ";
    $cmd .= "-h $args{host} "   if ( exists $args{host} );
    $cmd .= "-p $args{port} "   if ( exists $args{port} );
    $cmd .= "-U $args{user} "   if ( exists $args{user} );
    $cmd .= "-w --schema-only ";
    $cmd .= "-t $table_name ";
    $cmd .= "$args{dbname}";
    return $cmd;
}

sub _trim_result {
    my ($input) = @_;
    my @lines = split(qr/\n/, $input);
    my $result = "";
    for my $line ( @lines ) {
        next if ( $line =~ qr/\A--/ );
        next if ( $line =~ qr/\A\s*\z/ );
        next if ( $line =~ qr/\ASET\s+/ );
        next if ( $line =~ qr/\AREVOKE\s+/ );
        next if ( $line =~ qr/\AGRANT\s+/ );
        next if ( $line =~ qr/\AALTER TABLE\s+/ && $line =~ qr/\s+OWNER TO\s+/ );
        $result .= "$line\n";
    }
    return $result;
}

sub _trim {
    my ($string) = @_;
    $string =~ s/\A\s+//;
    $string =~ s/\s+\z//;
    return $string;
}

sub _fix_unique_index_ddl {
    my ($input_sref, $table_name) = @_;

    while ( $$input_sref =~ /ALTER TABLE ONLY $table_name\n    ADD CONSTRAINT (.+?) UNIQUE \(([^)]+)\);\n/mg ) {
        $$input_sref =~ s/ALTER TABLE ONLY $table_name\n    ADD CONSTRAINT (.+?) UNIQUE \(([^)]+)\);\n/CREATE UNIQUE INDEX $1 ON $table_name USING btree ($2);\n/m;
    }
}


1;
