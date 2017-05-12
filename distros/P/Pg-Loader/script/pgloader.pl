#!/usr/bin/env  perl

use 5.010000;
use lib qw( ../blib/lib ) ;
use Pg::Loader::Options qw/ get_options /;
use Pg::Loader          qw/ copy_loader  update_loader  /;
use Pg::Loader::Query   qw/ connect_db  /;
use Pg::Loader::Log     qw/ l4p_config    /;
use Pg::Loader::Misc_2  qw/ sample_config show_sections add_defaults/;
use Pg::Loader::Misc    qw/ error_check_pgsql print_results ini_conf/;
use Data::Dumper;
use Log::Log4perl  	qw/ :easy /;
use strict;
use warnings;

our $VERSION = '0.19';

my $o    = get_options;
my $conf = $o->opts;

############################# Options Processing
$conf->{version} 	and 	say $VERSION 		and exit;
$conf->{sample} 	and 	say sample_config 	and exit;

############################# M A I N
my $ini  = ini_conf    $conf->{config} ;
error_check_pgsql( $conf, $ini );
l4p_config( $conf);
my $l = get_logger('Pg::Loader');
$l->info( 'Configuration from ' . ($conf->{config}//='pgloader.conf') );

my $dh   = connect_db  $ini->{pgsql};
show_sections($conf, $ini)  unless @ARGV;

## MAIN
my @stats;

for  ( @ARGV ) {
        add_defaults( $ini, $_ )  ;
        # setup per-section logging
	
        # update, or load table
        $ini->{$_}{mode} eq 'update'
                ? (push @stats,    update_loader( $conf, $ini, $dh , $_))
                : (push @stats,    copy_loader(   $conf, $ini, $dh , $_))  ;

};

print_results( @stats)  if $conf->{summary};

END { $dh and $dh->disconnect }




__END__
=head1 NAME

pgloader.pl - loads and updates data to Postgres tables

=head1 SYNOPSIS

  pgloader.pl  -siTV  person
  pgloader.pl  --help


=head1 DESCRIPTION

I<pgloader.pl> loads tables to a Postgres database. It is an enhanced
version of the pgloader(1) python program, written by other authors. Data
are read from the file specified in the configuration file (defaults
to pgloader.dat).

This version of pgloader exhibits the -i option which 
drops all table indexes and recreates them again after COPY.  Loading
is performed inside transactions, supports updates, and the libpq "service"
connection method. It is meant to be a drop-in replacement to the 
python pgloader(1), numerous additional CLI options, though some 
non-core functionalities are not implemented .

=head1 OPTIONS

 -q                         quiet  mode     (same as loglevel=1)
 -v                         verbose mode    (same as loglevel=3)
 -d                         debug  mode     (same as loglevel=4)
 -l,  --loglevel            set loglevel 1 to 4  . Defaults to 2
 -c,  --config              configuration file; defaults to "pgloader.conf"
 -g,  --generate            generate a sample configuration file
 -i,  --indexes             disable indexes during COPY
 -n,  --dry_run             dry_run
 -s,  --summary             show summary
 -D,  --disable_triggers    disable triggers during loading
 -T,  --truncate            truncate table before loading
 -V,  --vacuum              vacuum analyze table after loading
 -C,  --count               number of lines to process
      --version             show version and exit
 -F,  --from                process from this line number

=head1 CONFIGURATION FILE


The configuration file follows the ini configuration format 
and is divided into these sections:

=over

=item [pgslq]

This is the only mandatory section and defines
database connection parameters.

 base           [required]  name of database
 host           [optional]  hostname to connect. (Defaults to localhost)
 port           [optional]  port number. (Defaults to 5432)
 user           [optional]  name of login user. (Defaults to user's epid) 
 pass           [optional]  user password. Not needed if using libpq defaults.
 pgsysconfdir   [optional]  dir for PGSYSCONFDIR
 service        mandatory only when pgsysconfdir ( or when the enviromental
                variable PGSYSCONFDIR ) is defined .

=item [template1]

This section defines a I<template>. In this example, the name  B<template1> 
was chosen as the name for the template. Templates are 
optional and hold default values for I<table sections> (defined bellow).  
You may define zero or unlimited number of templates. A template must
contain the entry 'template', plus any entry allowed in table sections.

 template   when defined to any true value, the template as enabled; 
            leave it blank to ignore all entries of the template 


=item [person]

A I<table section> controls all aspects of data loading.
When invoking pgloader.pl
from the command line, you must specify which section 
pgloader should read 
so the corresponding table section can take effect.
Here, The name B<person> was arbitrary chosen.
In a table section you can control loading with the following parameters:

 table                [ MANDATORY ]  Tablename or schema.tablename .
                      Defaults to section name.

 filename             [ OPTIONAL ]  Filename containing data for the table
                      If unspecified, or set to 'STDIN', input data should
                      arrive from standard input.

 use_template         [ OPTIONAL ]   Template to use for default values.

 field_sep            Delimiter that separates fields. The default for
                      text formats is TAB, and for csv formats is ','

 format               [ OPTIONAL ]   Must be either 'text' or 'csv' (without
                      the quotes). Default is text.

 copy                 [ OPTIONAL ]   Names of columns found in data file.
                      The names must match those in the database table.
                      Defauls to * . If you don't wish to list the names
                      in there proper order, you must append a number next
                      to their name; useful when the data file contains data
                      data in different order.
                      Example:  copy = age, last, first
                                copy = first:3, age:1, last:2

copy_columns          [ OPTIONAL ]    Which columns to copy.
                      The char '*' (the default) means all columns specified 
                      using the "copy" parameter; careful, it does not mean
                      all columns defined for the table in database table, 
                      pertains only to columns in the file and whose names
                      were specified earlier with parameter copy.
		      Again, it is about column names in data file.
                      Names need not obey a particular order.
                      Example:  copy_columns = first, last, age
                                copy_columns = *

update                [ OPTIONAL ]   Names of columns found in data file.
                      By including this tag, you are switching to the UPDATE
                      mode for the purpose to change some (or all) fields
                      of an existing row. Updates are allowed only if the
                      the table contains primary keys.
                      The format and semantics are identical to "copy".

update_copy           [ OPTIONAL ]    Names of columns for the update mode.
                      The format and semantics are identical to "copy_columns".

reject_data           [ OPTIONAL ]    Specifies the pathname for the file
                      to record rejected data. 

reject_log            [ OPTIONAL ]    Specifies the pathname for the file
                      to record diagnostics.

only_cols             [ OPTIONAL ]    Same purpose as "copy_columns", but here
                      we use numbers (instead of names), to specify the
                      columns. Numbers start from 1, ranges are also allowed.
                      The char '*' means all columns, and is the default.
                      Example: only_cols = 1-2, 3, 5
                               only_cols = 3

 quotechar            [ OPTIONAL ]    Usefull only for csv formats. Default is "

 null                 [ OPTIONAL ]    String that indicates the  NULL value ;
                      usefull only for text mode. Default is string '\NA'

skipinitialspace      [ OPTIONAL ]    Ignore leading and trailing whitespace

udc_COLUMNAME         [ OPTIONAL ]    Assign this value for all rows whose name
                      is column COLUMNAME
                      Examples: udc_title = Sir
                                udc_age   = 99
                                udc_race  = white

reformat              [ OPTIONAL ]    reformat values of the age column by
                      passing it to function upper(), in the John::Util
                      module reformat = age:John::Util::upper

copy_every            [ OPTIONAL ]    How many tuples to copy per transaction.
                      More transactions are automatically created to
                      insert the rest of the date, each inserting
                      upto that many tuples. Defaults is 10_000
                      TIP: set this parameter to 1 if you wish
                      to avoid the case where one bad tuple
                      cause other tuples to also fail.
datestyle             [ OPTIONAL ]   Set datestyle parameter, omit all quotes.
                      Example:  datestyle=euro
                                datestyle=us

client_encoding       [ OPTIONAL ]   Set client encoding, omit all quotes.
lc_messages           [ OPTIONAL ]   Set lc messages parameter, omit all quotes.
lc_numeric            [ OPTIONAL ]   Set lc numeric parameter, omit all quotes.
lc_monetary           [ OPTIONAL ]   Set lc monetary, omit all quotes.
lc_time               [ OPTIONAL ]   Set lc time, omit all quotes.


NOTE: Because of how the ini format is defined as a value separator,
if you need to include the ',' char, you must escape it with \ . For
example:
 field_sep = \,          sets field_sep to char ','

=back


=head1 SEE ALSO

http://pgfoundry.org/projects/pgloader/  hosts the official python
project. This project has nothing to do with this Perl program.


=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut


