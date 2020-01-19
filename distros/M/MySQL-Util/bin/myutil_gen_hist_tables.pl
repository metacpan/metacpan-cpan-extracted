#!/usr/bin/perl

###### PACKAGES ######

use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
use MySQL::Util::Lite;
use Data::Dumper;
use Method::Signatures;

###### CONSTANTS ######

###### GLOBAL VARIABLES ######

use vars qw($Host $DbName $User $Pass $Util @IgnoreRegex $DbmaintainCompat $Append);

###### MAIN PROGRAM ######

parse_cmd_line();
init();

my $sql = generate_hist_table_ddl(
    util => $Util,
    table_ignore_regexs => \@IgnoreRegex
);

print $sql;

###### END MAIN #######

func generate_hist_table_ddl(
    MySQL::Util::Lite :$util!,
    ArrayRef :$table_ignore_regexs = []
){
    my $schema = $util->get_schema;
    my @tables = $schema->get_tables;
    
    my $ret_sql = "";
    
    foreach my $t ( @tables ){
        next if ignore_table( table => $t, ignore_regexs => $table_ignore_regexs );
        
        my $t_sql = "";
        $t_sql .= create_history_table_ddl(    table => $t, util => $util );
        $t_sql .= get_alter_history_table_ddl( table => $t, util => $util );
        
        if( $t_sql ){
            # Only regenerate triggers if create table or alter table statements found
            $t_sql .= get_trigger_ddl( table => $t, util => $util);
        }
        
        $ret_sql .= $t_sql;
    }
    
    return $ret_sql;
}

func ignore_table(
    MySQL::Util::Lite::Table :$table!,
    ArrayRef :$ignore_regexs
){
    my $table_name = $table->name;
    
    foreach my $regex ( @$ignore_regexs ){
        if( $table_name =~ m/$regex/ ){
            return 1;
        }
    }
    
    return 0
}

func create_history_table_ddl(
    MySQL::Util::Lite::Table :$table!,
    MySQL::Util::Lite :$util!
){
    
    my $hist_table_name = $table->name . "$Append";
    my $schema_name     = $table->schema_name;
    
    if( $util->table_exists($hist_table_name) ){
        # Table already exists
        return "";
    } 
    
    my $sql = qq{create table if not exists `$schema_name`.`$hist_table_name` (
    
     `${hist_table_name}_id` bigint(20) unsigned AUTO_INCREMENT,
     `_hist_modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
     `_hist_action` ENUM ('INSERT', 'UPDATE', 'DELETE'),

};
        
    foreach my $col ( $table->get_columns ){
        $col->is_autoinc(0);
        $sql .= "\t" . $col->get_ddl . ",\n";
    }
    $sql .= qq{
        PRIMARY KEY (`${hist_table_name}_id`),
        INDEX `${hist_table_name}_idx` ( _hist_modified_date )
    ) ENGINE = INNODB;
    };
    
    
    return $sql;
    
}

func get_alter_history_table_ddl(
    MySQL::Util::Lite::Table :$table!,
    MySQL::Util::Lite :$util!
){
    my $schema_name     = $table->schema_name;
    my $schema          = $util->get_schema;
    
    my $hist_table      = $schema->get_table( $table->name . "$Append");
    
    if( !$hist_table ){
        return "";
    }
    
    my $sql = "";
    
    my %checked_cols;
    my $prev_column;
    my $alter_table = "ALTER TABLE `" . $table->schema_name . "`.`" . $table->name . "$Append` ";
    foreach my $col ( $table->get_columns ){
        my $hist_col = $hist_table->get_column(name => $col->name);
        if( !$hist_col ){
            $sql .= "$alter_table ADD COLUMN " . $col->get_ddl;
            if( defined $prev_column){
                $sql .= " after $prev_column ";
            }
            $sql .= ";\n";
        }
        else{
            # Need to check if columns are equal
            $col->is_autoinc(0); # We want to ignore primary tables autoinc setting
            if( $col->get_ddl ne $hist_col->get_ddl ){
                print $col->get_ddl . "\n";
                print $hist_col->get_ddl . "\n";
                $sql .= "$alter_table MODIFY COLUMN " . $col->get_ddl . ";\n";
            }
        }
        $checked_cols{$col->name} = 1;
        $prev_column = $col->name;
    }
    
    foreach my $col ( $hist_table->get_columns ){
        my $hist_table_name = $hist_table->name;
        if( !$checked_cols{$col->name} && (
            $col->name ne "_hist_action" &&
            $col->name ne "_hist_modified_date" &&
            $col->name ne "${hist_table_name}_id" )
        ){
            # This columns was removed from original table
            $sql .= "$alter_table DROP COLUMN " . $col->name . ";\n";
        }
    }
    
    return $sql;
        
}

func get_trigger_ddl(
    MySQL::Util::Lite::Table :$table!,
    MySQL::Util::Lite :$util!,
    Str :$trigger_delimiter = ";"
){
    my $schema_name     = $table->schema_name;
    my $table_name      = $table->name;
    my $hist_table_name = "${table_name}$Append";
    
    my $set_delimiter = "delimiter $trigger_delimiter";
    if( $DbmaintainCompat ){
        $trigger_delimiter = "/";
        $set_delimiter = "";
    }
    
    my @column_names = ();
    my @values_new = ();
    my @values_old = ();
    foreach my $col ( $table->get_columns){
        push @column_names, $col->name;
        push @values_new, "NEW." . $col->name;
        push @values_old, "OLD." . $col->name; 
    }
    
    my $columns_name_str = join(",", @column_names);
    my $values_new_str   = join(",", @values_new);
    my $values_old_str   = join(",", @values_old);
        
    my $sql = qq{
drop trigger if exists `$schema_name`.`${table_name}_insert`;
drop trigger if exists `$schema_name`.`${table_name}_update`;
drop trigger if exists `$schema_name`.`${table_name}_delete`;

$set_delimiter
CREATE TRIGGER `$schema_name`.`${table_name}_insert`
    AFTER INSERT on `$schema_name`.`$table_name`
    FOR EACH ROW 
    BEGIN
    INSERT INTO `$schema_name`.`$hist_table_name` ( _hist_action,
        $columns_name_str )
    VALUES ( 'INSERT', $values_new_str );
END
$trigger_delimiter

CREATE TRIGGER `$schema_name`.`${table_name}_update`
    AFTER UPDATE on `$schema_name`.`$table_name`
    FOR EACH ROW 
    BEGIN
    INSERT INTO `$schema_name`.`$hist_table_name` ( _hist_action,
        $columns_name_str )
    VALUES ( 'UPDATE', $values_new_str);
END
$trigger_delimiter

CREATE TRIGGER `$schema_name`.`${table_name}_delete`
    AFTER DELETE on `$schema_name`.`$table_name`
    FOR EACH ROW 
    BEGIN
    INSERT INTO `$schema_name`.`$hist_table_name` ( _hist_action,
        $columns_name_str )
    VALUES ( 'DELETE', $values_old_str);
END
$trigger_delimiter

};

    if( !$DbmaintainCompat ){
        $sql .= "delimiter ;\n";
    }
    
    return $sql;
}

sub init {
    my $dsn = "dbi:mysql:host=$Host;dbname=$DbName";

    $Util = MySQL::Util::Lite->new(
        dsn  => $dsn,
        user => $User,
        pass => $Pass
    );
}

sub check_required {
    my $opt = shift;
    my $arg = shift;

    print_usage("missing arg $opt") if !$arg;
}

sub parse_cmd_line {
    my @tmp = @ARGV;
    my $help;

    my $rc = GetOptions(
        "h=s"    => \$Host,
        "d=s"    => \$DbName,
        "u=s"    => \$User,
        "p=s"    => \$Pass,
        "i=s"    => \@IgnoreRegex,
        "dbmaintain" => \$DbmaintainCompat,
        "a=s"        => \$Append,
        "help|?" => \$help
    );

    print_usage("usage:") if $help;

    check_required( '-u', $User );
    check_required( '-h', $Host );
    check_required( '-d', $DbName );

    if ( !($rc) || ( @ARGV != 0 ) ) {
        ## if rc is false or args are left on line
        print_usage("parse_cmd_line failed");
    }
    
    if( !defined $Append ){
        $Append = "_hist";
    }
    
    push @IgnoreRegex, "${Append}\$";

    @ARGV = @tmp;
}

sub print_usage {
    print STDERR "@_\n";

    print "\n$0\n"
      . "\t-u <user>\n"
      . "\t-h <host>\n"
      . "\t-d <dbname>\n"
      . "\t[-p <pass>]\n"
      . "\t[-i <regex>] (ignore tables matching regex, can specify multiple times)\n"
      . "\t[-a <append>] (default: '_hist')\n"
      . "\t[--dbmaintain] (output sql in dbmaintain compatible mode)\n"
      . "\t[-?] (usage)\n" . "\n";

    print "\nExamples:\n"
      . "\t$0 -u myself -p secret -h myhost -d mydb -i '^t1$' -i '_example$'";

    print "\n";

    exit 1;
}
