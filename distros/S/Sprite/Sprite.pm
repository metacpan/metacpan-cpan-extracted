#!/usr/local/bin/perl5

##++
##    Sprite v3.21
##    Last modified: April 21, 1998
##
##    Copyright (c) 1995-98, Shishir Gundavaram
##    All Rights Reserved
##
##    E-Mail: shishir@ora.com
##
##    Permission  to  use,  copy, and distribute is hereby granted,
##    providing that the above copyright notice and this permission
##    appear in all copies and in supporting documentation.
##
##    If you use Sprite for any cool (Web) applications, I would be 
##    interested in hearing about them. So, drop me a line. Thanks!
##--

#############################################################################

=head1 NAME

Sprite - Module to manipulate text delimited databases using SQL.

=head1 SYNOPSIS

  use Sprite;

  $rdb = new Sprite;

  $rdb->set_delimiter (-Read  => '::')  ## OR: ('Read',  '::');
  $rdb->set_delimiter (-Write => '::')  ## OR: ('Write', '::');

  $rdb->set_os ('Win95');

    ## Valid arguments (case insensitive) include:
    ##
    ## Unix, Win95, Windows95, MSDOS, NT, WinNT, OS2, VMS, 
    ## MacOS or Macintosh. Default determined by $^O.

  $rdb->set_lock_file ('c:\win95\tmp\Sprite.lck', 10);

  $rdb->set_db_dir ('Mac OS:Perl 5:Data') || die "Can't access dir!\n";

  $data = $rdb->sql (<<Query);   ## OR: @data = $rdb->sql (<<Query);
      .
      . (SQL)
      .
  Query

  foreach $row (@$data) {        ## OR: foreach $row (@data) {
      @columns = @$row;          ## NO null delimited string -- v3.2
  }                              

  $rdb->close;
  $rdb->close ($database);       ## To save updated database

=head1 DESCRIPTION

Here is a simple database where the fields are delimited by commas:

  Player,Years,Points,Rebounds,Assists,Championships
  ...
  Larry Bird,13,25,11,7,3
  Michael Jordan,14,29,6,5,5
  Magic Johnson,13,22,7,11,5
  ...

I<Note:> The first line must contain the field names (case sensitive).

=head1 Supported SQL Commands

Here are a list of the SQL commands that are supported by Sprite:

=over 5

=item I<select> - retrieves records that match specified criteria:

  select col1 [,col2] from database 
         where (cond1 OPERATOR value1) 
         [and|or (cond2 OPERATOR value2) ...] 

The '*' operator can be used to select all columns.

The I<database> is simply the file that contains the data. If the file 
is not in the current directory, the path must be specified. 

Sprite does I<not> support multiple tables (or commonly knows as "joins").

Valid column names can be used where [cond1..n] and [value1..n] are expected, 
such as: 

I<Example 1>:

  select Player, Points from my_db
         where (Rebounds > Assists) 

The following SQL operators can be used: =, <, >, <=, >=, <> as well as 
Perl's special operators: =~ and !~. The =~ and !~ operators are used to 
specify regular expressions, such as: 

I<Example 2>:

  select * from my_db
         where (Name =~ /Bird$/i) 

Selects records where the Name column ends with "Bird" (case insensitive). 
For more information, look at a manual on regexps.

I<Note:> A path to a database can contain only the following characters:

  \w, \x80-\xFF, -, /, \, ., :

If you have directories with spaces or other 'invalid' characters, you 
need to use the I<set_db_dir> method.

=item I<update> - updates records that match specified criteria. 

  update database 
    set cond1 = (value1)[,cond2 = (value2) ...]
        where (cond1 OPERATOR value1)
        [and|or (cond2 OPERATOR value2) ...] 

I<Example>:

  update my_db 
	 set Championships = (Championships + 1) 
         where (Player = 'Larry Bird') 

  update my_db
         set Championships = (Championships + 1),
	     Years = (12)
         where (Player = 'Larry Bird')

=item I<delete> - removes records that match specified criteria:

  delete from database 
         where (cond1 OPERATOR value1) 
         [and|or (cond2 OPERATOR value2) ...] 

I<Example>:

  delete from my_db
         where (Player =~ /Johnson$/i) or
               (Years > 12) 

=item I<alter> - simplified version of SQL-92 counterpart

Removes the specified column from the database. The other standard SQL 
functions for alter table are not supported:

  alter table database 
        drop column column-name 

  alter table database
        add column column-name

I<Example>:

  alter table my_db 
        drop column Years

  alter table my_db 
        add column Legend

=item I<insert> - inserts a record into the database:

  insert into database 
         (col1, col2, ... coln) 
  values 
         (val1, val2, ... valn) 

I<Example>:

  insert into my_db 
         (Player, Years, Points, Championships) 
  values 
         ('Kareem Abdul-Jabbar', 21, 26, 6) 

You don't have to specify all of the fields in the database! Sprite also 
does not require you to specify the fields in the same order as that of 
the database. 

I<Note:> You should make it a habit to quote strings. 

=back

=head1 METHODS

Here are the available methods:

=over 5

=item I<set_delimiter>

The set_delimiter function sets the read and write delimiter for the
database. The delimiter is not limited to one character; you can have 
a string, and even a regexp (for reading only). 

I<Return Value>

None

=item I<set_os>

The set_os function can be used to notify Sprite as to the operating 
system that you're using. Default is determined by $^O.

I<Note:> If you're using Sprite on Windows 95/NT or on OS2, make sure
to use backslashes -- and NOT forward slashes -- when specifying a path 
for a database or to the I<set_db_dir> or I<set_lock_file> methods!

I<Return Value>

None

=item I<set_lock_file>

For any O/S that doesn't support flock (i.e Mac, Windows 95 and VMS), this
method allows you to set a lock file to use and the number of tries that
Sprite should try to obtain a 'fake' lock. However, this method is NOT 
fully reliable, but is better than no lock at all.

'Sprite.lck' (either in the directory specified by I<set_db_dir> or in 
the current directory) is used as the default lock file if one 
is not specified.

I<Return Value>

None

=item I<set_db_dir>

A path to a database can contain only the following characters: 

  \w, \x80-\xFF, -, /, \, ., :  

If your path contains other characters besides the ones listed above,
you can use this method to set a default directory. Here's an example:

  $rdb->set_db_dir ("Mac OS:Perl 5:Data");

  $data = $rdb->sql ("select * from phone.db");

Sprite will look for the file "Mac OS:Perl 5:Data:phone.db". Just to
note, the database filename cannot have any characters besides the one 
listed above!

I<Return Value>

  0 - Failure
  1 - Success

=item I<sql>

The sql function is used to pass a SQL command to this module. All of the 
SQL commands described above are supported. The I<select> SQL command 
returns an array containing the data, where the first element is the status. 
All of the other other SQL commands simply return a status.

I<Return Value>
  1 - Success
  0 - Error

=item I<close>

The close function closes the file, and destroys the database object. You 
can pass a filename to the function, in which case Sprite will save the 
database to that file; the directory set by I<set_db_dir> is used as
the default.

I<Return Value>

None

=back

=head1 NOTES

Sprite is not the solution to all your data manipulation needs. It's fine 
for small databases (less than 1000 records), but anything over that, and 
you'll have to sit there and twiddle your fingers while Sprite goes 
chugging away ... and returns a few *seconds* or so later.

The main advantage of Sprite is that you can use Perl's regular expressions 
to search through your data. Yippee!

=head1 SEE ALSO

Text::CSV, RDB

=head1 ACKNOWLEDGEMENTS

I would like to thank the following, especially Rod Whitby and Jim Esten, 
for finding bugs and offering suggestions:

  Rod Whitby      (rwhitby@geocities.com)
  Jim Esten       (jesten@wdynamic.com)
  Dave Moore      (dmoore@videoactv.com)
  Shane Hutchins  (hutchins@ctron.com)
  Josh Hochman    (josh@bcdinc.com)
  Barry Harrison  (barryh@topnet.net)
  Lisa Farley     (lfarley@segue.com)
  Loyd Gore       (lgore@ascd.org)
  Tanju Cataltepe (tanju@netlabs.net)
  Haakon Norheim  (hanorhei@online.no)

=head1 COPYRIGHT INFORMATION

          Copyright (c) 1995-1998, Shishir Gundavaram
                      All Rights Reserved

  Permission  to  use,  copy, and distribute is hereby granted,
  providing that the above copyright notice and this permission
  appear in all copies and in supporting documentation.

=cut

###############################################################################

package Sprite;

require 5.002;

use Cwd;
use Fcntl; 

##++
##  Global Variables. Declare lock constants manually, instead of 
##  importing them from Fcntl.
##
##  use vars qw ($VERSION $LOCK_SH $LOCK_EX);
##--

$Sprite::VERSION = '3.21';
$Sprite::LOCK_SH = 1;
$Sprite::LOCK_EX = 2;

##++
##  Public Methods and Constructor
##--

sub new
{
    my $class = shift;
    my $self;

    $self = {
                commands     => 'select|update|delete|alter|insert',
                column       => '[A-Za-z\x80-\xFF][\w\x80-\xFF]+',
		_select      => '[\w\x80-\xFF\*,\s]+',
		path         => '[\w\x80-\xFF\-\/\.\:\\\\]+',
		table        => '',
		file         => '',
		directory    => '',
		_read        => ',',
		_write       => ',',
		fields       => {},
		order        => [],
		records      => [],
		platform     => 'Unix',
		fake_lock    => 0,
		default_lock => 'Sprite.lck',
		lock_file    => '',
		lock_handle  => '',
		default_try  => 10,
		lock_try     => '',
                lock_sleep   => 1,
		errors       => {}
	    };

    $self->{separator} = { Unix  => '/',    Mac => ':', 
			   PC    => '\\\\', VMS => '/' };

    bless $self, $class;

    $self->initialize;

    return $self;
}

sub initialize
{
    my $self = shift;

    $self->define_errors;

    $self->set_os ($^O) if (defined $^O);
}

sub set_delimiter
{
    my ($self, $type, $delimiter) = @_;

    $type      ||= 'other';
    $delimiter ||= $self->{_read} || $self->{_write};

    $type =~ s/^-//;
    $type = lc $type;

    if ($type eq 'read') {
	$self->{_read} = $delimiter;
    } elsif ($type eq 'write') {
	$self->{_write} = $delimiter;
    } else {
	$self->{_read} = $self->{_write} = $delimiter;
    }

    return (1);
}

sub set_os
{
    my ($self, $platform) = @_;

    $platform = 'Unix', return unless ($platform);

    $platform =~ s/\s//g;

    if ($platform =~ /^(?:OS2|(?:Win)?NT|Win(?:dows)?95|(?:MS)?DOS)$/i) {
	$self->{platform} = 'PC';
    } elsif ($platform =~ /^Mac(?:OS|intosh)?$/i) {
	$self->{platform} = 'Mac';
    } elsif ($platform =~ /^VMS$/i) {
	$self->{platform} = 'VMS';
    } else {
	$self->{platform} = 'Unix';
    }

    return (1);
}

sub set_db_dir
{
    my ($self, $directory) = @_;

    return (0) unless ($directory);

    stat ($directory);

    if ( (-d _) && (-e _) && (-r _) && (-w _) ) {
	$self->{directory} = $directory;
	return (1);
    } else {
	return (0);
    }
}

sub get_path_info
{
    my ($self, $file) = @_;
    my ($separator, $path, $name, $full);

    $separator = $self->{separator}->{ $self->{platform} };

    ($path, $name) = $file =~ m|(.*?)([^$separator]+)$|o;

    if ($path) {
	$full  = $file;
    } else {
	$path  = $self->{directory} || fastcwd;
	$path .= $separator;
	$full  = $path . $name;
    }

    return wantarray ? ($path, $name) : $full;
}

sub set_lock_file
{
    my ($self, $file, $lock_try) = @_;

    if (!$file || !$lock_try) {
	return (0);
    } else {
	$self->{lock_file} = $file;
	$self->{lock_try}  = $lock_try;
    
	return (1);
    }
}

sub lock
{
    my $self = shift;
    my $count;

    $self->{lock_file} ||= $self->{default_lock}; 
    $self->{lock_file}   = $self->get_path_info ($self->{lock_file});
    $self->{lock_try}  ||= $self->{default_try};

    local *FILE;

    $count = 0;

    while (++$count <= $self->{lock_try}) {	
	if (sysopen (FILE, $self->{lock_file}, 
		           O_WRONLY|O_EXCL|O_CREAT, 0644)) {

	    $self->{fake_lock}   = 1;
	    $self->{lock_handle} = *FILE;

	    last;
	} else {
	    select (undef, undef, undef, $self->{lock_sleep});
	}
    }

    return $self->{fake_lock};
}

sub unlock
{
    my $self = shift;

    if ($self->{fake_lock}) {

	close ($self->{lock_handle}) || return (0);
	unlink ($self->{lock_file})  || return (0);
	
	$self->{fake_lock}   = 0;
	$self->{lock_handle} = '';

    }

    return (1);
}

sub sql
{
    my ($self, $query) = @_;
    my ($command, $status);

    $self->display_error (-514) unless ($query);

    $query   =~ s/\n/ /gs;
    $query   =~ s/^\s*(.*?)\s*$/$1/;
    $command = '';

    if ($query =~ /^($self->{commands})/io) {
	$command = lc $1;
	$status  = $self->$command ($query);

	if (ref ($status) eq 'ARRAY') {
	    unshift (@$status, 1);

	    return wantarray ? @$status : $status;
	} else {
	    if ($status <= 0) {
		$self->display_error ($status);
		return (0);
	    } else {
		return (1);
	    }
	}
    } else {
	return (0);
    }
}

sub display_error
{	
    my ($self, $status, @error) = @_;
    my ($error, $other);

    $error = (scalar @error) ? "\n>> " . join ("\n>> ", @error) : '';
    $other = ($@) ? "\n>> $@" : "\n";

    warn <<Error_Message;
Sprite Error:

>> $self->{errors}->{$status} $error $other
Error_Message
	
    return (1);
}

sub close
{
    my ($self, $file) = @_;
    my ($status, $full_path);

    $status = 1;

    if ($file) {
	$full_path = $self->get_path_info ($file);
	$status    = $self->write_file ($full_path);

	$self->display_error ($status) if ($status <= 0);
    }

    ##++
    ##  Destroy object!
    ##--

    undef $self;

    return $status;
}

##++
##  Private Methods
##--

sub define_errors
{
    my $self = shift;
    my $errors;

    $errors = {};

    $errors->{'-501'} = 'Could not open specified database.';
    $errors->{'-502'} = 'Specified column(s) not found.';
    $errors->{'-503'} = 'Incorrect format in select.';
    $errors->{'-504'} = 'Incorrect format in update.';
    $errors->{'-505'} = 'Incorrect format in delete.';
    $errors->{'-506'} = 'Incorrect format in add/drop column.';
    $errors->{'-507'} = 'Incorrect format in alter table.';
    $errors->{'-508'} = 'Incorrect format in insert command.';
    $errors->{'-509'} = 'The no. of columns does not match no. of values.';
    $errors->{'-510'} = 'A severe error! Check your query carefully.';
    $errors->{'-511'} = 'Cannot write the database to output file.';
    $errors->{'-512'} = 'Unmatched quote in expression.';
    $errors->{'-513'} = 'Need to open the database first.';
    $errors->{'-514'} = 'Please specify a valid query.';
    $errors->{'-515'} = 'Cannot get lock on database file.';
    $errors->{'-516'} = 'Cannot delete temp. lock file.';

    $self->{errors} = $errors;

    return (1);
}

sub parse_expression
{
    my ($self, $query) = @_;
    my ($column, @strings, %numopmap, %stropmap, $numops, $strops, $special);

    return unless ($query);

    $column    = $self->{column};
    @strings   = ();

    %numopmap  = ( '=' => 'eq', '==' => 'eq', '>=' => 'ge', '<=' => 'le',
                   '>' => 'gt', '<'  => 'lt', '!=' => 'ne', '<>' => 'ne' );
    %stropmap  = ( 'eq' => '==', 'ge' => '>=', 'le' => '<=', 
	           'gt' => '>',  'lt' => '<',  'ne' => '!=');

    $numops    = join '|', keys %numopmap;
    $strops    = join '|', keys %stropmap;

    $special   = "$strops|and|or";

    ##++
    ##  A big thanks to the King of Regex, Jeffrey Friedl, for helping
    ##  me craft up this beauty: (...)((?:\\\1|(?!\1).)*)\1 - Thanks!
    ##--

    $query =~ s{([!=]~)\s*(m?)([^\w;\s])((?:\\\3|(?!\3).)*)\3(i?)}{
                   push (@strings, "$2$3$4$3$5"); "$1 *$#strings";
               }ge;

    $query =~ s{(['"])((?:\\\1|(?!\1).)*)\1}{
                   push (@strings, "$1$2$1"); "*$#strings";
 	       }ge;

    $query =~ s|\b($column)\s*($numops)\s*\*|$1 $numopmap{$2} \*|go;

    $query =~ s|\b($column)\s*=\s*(\d+)|$1 == $2|go;

    $query =~ s|\b($column)\s+($strops)\s+(\d+)|$1 $stropmap{$2} $3|go;

    $query =~ s|($column)|
                   my $match = $1;
                   ($match =~ /\b(?:$special)/io) ? "\L$match\E"    : 
                                                    "\$_->{$match}"
               |geo;

    $query =~ s|[;`]||g;
    $query =~ s#\|\|#or#g;
    $query =~ s#&&#and#g;

    $query =~ s|\*(\d+)|$strings[$1]|g;

    return $query;
}

sub check_columns
{
    my ($self, $column_string) = @_;
    my ($status, @columns, $column);

    $status  = 1;
    @columns = split (/,/, $column_string);

    foreach $column (@columns) {
	$status = 0 unless ($self->{fields}->{$column});
    }

    return $status;
}

sub parse_columns
{
    my ($self, $command, $column_string, $condition, $values) = @_;
    my ($status, $results, @columns, $single, $loop, $code, $column);

    local $SIG{'__WARN__'} = sub { $status = -510 };
    local $^W = 0;

    $status  = 1;
    $results = [];
    @columns = split (/,/, $column_string);
    $single  = ($#columns) ? $columns[$[] : $column_string;

    for ($loop=0; $loop < scalar @{ $self->{records} }; $loop++) {
	$_ = $self->{records}->[$loop];

	if ( !$condition || (eval $condition) ) {
	    if ($command eq 'select') {
		push (@$results, [ @$_{@columns} ]);
	    } elsif ($command eq 'update') {

		$code = '';

		map { $code .= qq|\$_->{'$_'} = $values->{$_};| } @columns;

                eval $code;

	    } elsif ($command eq 'add') {
		$_->{$single} = '';

	    } elsif ($command eq 'drop') {
		delete $_->{$single};
	    }
	}
    }

    if ( ($status <= 0) || ($command ne 'select') ) {
	return $status;
    } else {
	return $results;
    }
}

sub check_for_reload
{
    my ($self, $file) = @_;
    my ($table, $path, $status);

    return unless ($file);

    ($path, $table) = $self->get_path_info ($file);

    $file   = $path . $table if ($table eq $file);
    $status = 1;

    if ( ($self->{table} ne $table) || ($self->{file} ne $file) ) {
	stat ($file);

	if ( (-e _) && (-T _) && (-s _) && (-r _) ) {

	    $self->{table} = $table;
	    $self->{file}  = $file;
	    $status        = $self->load_database ($file);

	} else {
	    $status = 0;
	}
    }

    return $status;
}

sub select
{
    my ($self, $query) = @_;
    my ($regex, $path, $columns, $table, $extra, $condition, $values_or_error);

    $regex = $self->{_select};
    $path  = $self->{path};

    if ($query =~ /^select\s+                         # Keyword
                    ($regex)\s+                       # Columns
                    from\s+                           # 'from'
                    ($path)(.*)$/iox) {           

	($columns, $table, $extra) = ($1, $2, $3);

	if ($extra =~ /^\s+where\s+(.+)$/i) {
	    $condition = $self->parse_expression ($1);
	}

	$self->check_for_reload ($table) || return (-501);

	$columns = join (',', @{ $self->{order} }) if ($columns eq '*');
	$columns =~ s/\s//g;

	$self->check_columns ($columns) || return (-502);

	$values_or_error = $self->parse_columns ('select', $columns,
    			    			           $condition);

	return $values_or_error;
    } else {
	return (-503);
    }
}

sub update
{
    my ($self, $query) = @_;
    my ($path, $regex, $table, $extra, $condition, $all_columns, 
	$columns, $status);

    ##++
    ##  Hack to allow parenthesis to be escaped!
    ##--

    $query =~ s/\\([()])/sprintf ("%%\0%d: ", ord ($1))/ge;
    $path  =  $self->{path};
    $regex =  $self->{column};

    if ($query =~ /^update\s+($path)\s+set\s+(.+)$/io) {
	($table, $extra) = ($1, $2);

	$all_columns = {};
	$columns     = '';

        $extra =~ s|($regex)\s*=\s*(\(.+?\))(?:\s*,\s*)?|
	               my ($key, $value) = ($1, $2);

	               $value =~ s/%\0(\d+): /pack ("C", $1)/ge;
	               $value = $self->parse_expression ($value);

	               $all_columns->{$key} = $value;

	               '';
	           |goe;

        $columns   = join (',', keys %$all_columns);
	$condition = ($extra =~ /^\s*where\s+(.+)$/i) ? $1 : '';

	$self->check_for_reload ($table) || return (-501);
	$self->check_columns ($columns)  || return (-502);

	$condition = $self->parse_expression ($condition);

	$status    = $self->parse_columns ('update', $columns, 
 			    		             $condition, 
					             $all_columns);

	return ($status);
    } else {
	return (-504);
    }
}

sub delete 
{
    my ($self, $query) = @_;
    my ($path, $table, $condition, $status);

    $path = $self->{path};

    if ($query =~ /^delete\s+from\s+($path)\s+where\s+(.+)$/io) {
	$table     = $1;
	$condition = $self->parse_expression ($2);

	$self->check_for_reload ($table) || return (-501);

	$status = $self->delete_rows ($condition);

	return $status;
    } else {
	return (-505);
    }
}

sub delete_rows
{
    my ($self, $condition) = @_;
    my ($status, $loop);

    local $SIG{'__WARN__'} = sub { $status = -510 };
    local $^W = 0;

    $status = 1;

    for ($loop=0; $loop < scalar @{ $self->{records} }; $loop++) {
	$_ = $self->{records}->[$loop];

	$self->{records}->[$loop] = undef if (eval $condition);
    }

    return $status;
}

sub alter
{
    my ($self, $query) = @_;
    my ($path, $regex, $table, $extra, $type, $column, $count, $status);

    $path  = $self->{path};
    $regex = $self->{column};

    if ($query =~ /^alter\s+table\s+($path)\s+(.+)$/io) {
	($table, $extra) = ($1, $2);

	if ($extra =~ /^(add|drop)\s+column\s+($regex)$/io) {
	    ($type, $column) = ($1, $2);

	    $self->check_for_reload ($table) || return (-501);

	    if ($type eq 'add') {
		$self->{fields}->{$column} = 1;
		push (@{ $self->{order} }, $column);

	    } else {
	        $self->check_columns ($column) || return (-502);

		$count = -1;

		foreach (@{ $self->{order} }) {
		    ++$count;
		    last if ($_ eq $column);
		}

		splice (@{ $self->{order} }, $count, 1);
		delete $self->{fields}->{$column};
	   }
					
	    $status = $self->parse_columns ("\L$type\E", $column);

	    return $status;
	} else {
	    return (-506);
	}
    } else {
	return (-507);
    }
}

sub insert
{
    my ($self, $query) = @_;
    my ($path, $table, $columns, $values, $status);

    $path = $self->{path};

    if ($query =~ /^insert\s+into\s+                            # Keyword
                   ($path)\s+                                   # Table
                   \((.+?)\)\s+                                 # Keys
                   values\s+                                    # 'values'
                   \((.+)\)$/ixo) {

	($table, $columns, $values) = ($1, $2, $3);

	$columns =~ s/\s//g;

	$self->check_for_reload ($table) || return (-501);
	$self->check_columns ($columns)  || return (-502);

	$status = $self->insert_data ($columns, $values);
					      
	return $status;
    } else {
	return (-508);
    }
}

sub insert_data
{
    my ($self, $column_string, $value_string) = @_;
    my (@columns, @values, $hash, $loop, $column);

    @columns = split (/,/, $column_string);
    @values  = $self->quotewords (',\s*', $value_string);

    if ($#columns == $#values) {
	$hash = {};

	for ($loop=0; $loop <= $#columns; $loop++) {
	    $column = $columns[$loop];

	    if ($self->{fields}->{$column}) {
		$hash->{$column} = $values[$loop];
	    }
	}

	push @{ $self->{records} }, $hash;

	return (1);
    } else {
	return (-509);
    }
}						    

sub write_file
{
    my ($self, $new_file) = @_;
    my ($status, $write, $fields, $loop, $record, $record_string, 
	$column, $value);

    local (*FILE, $^W);

    $^W     = 0;
    $status = (scalar @{ $self->{records} }) ? 1 : -513;

    if ( ($status >= 1) && (open (FILE, ">$new_file")) ) {
	eval { flock (FILE, $Sprite::LOCK_EX) || die };

	if ($@) {
	    $self->lock || $self->display_error (-515);
	}

	$write  = $self->{_write}; 
	$fields = join ($write, @{ $self->{order} });

	print FILE "$fields\n";

	for ($loop=0; $loop < scalar @{ $self->{records} }; $loop++) {
	    $record = $self->{records}->[$loop];

	    next unless (defined $record);

            $record_string = '';

 	    foreach $column (@{ $self->{order} }) {
		$value = $record->{$column};

                if ($value =~ /(?:\Q$write\E)|(?:['"\\])/o) {
		    $value =~ s/(["\\])/\\$1/g;
		    $value =  qq|"$value"|;
		}
			
                $record_string .= "$write$value";
	    }

	    $record_string =~ s/^\Q$write\E//o;

	    print FILE "$record_string\n";
	}

	close (FILE);

        $self->unlock || $self->display_error (-516);
    } else {
	$status = ($status < 1) ? $status : -511;
    }

    return $status;
}

sub load_database 
{
    my ($self, $file) = @_;
    my ($header, @fields, $no_fields, @record, $hash, $loop);

    local (*FILE);

    open (FILE, $file) || return (-501);

    eval { flock (FILE, $Sprite::LOCK_SH) || die };

    if ($@) {
	$self->lock || $self->display_error (-515);
    }

    $_ = <FILE>;

    ($header)  = /^ *(.*?) *$/;
    @fields    = split (/$self->{_read}/o, $header);
    $no_fields = $#fields;

    undef %{ $self->{fields} };
    undef @{ $self->{order}  };

    $self->{order} = [ @fields ];

    map    { $self->{fields}->{$_} = 1 } @fields;
    undef @{ $self->{records} } if (scalar @{ $self->{records} });

    while (<FILE>) {
	chomp;

	if (/['"\\]/) {
	    s/((?!\\).)""/$1\\"/g;

            @record = $self->quotewords ($self->{_read}, $_);
        } else {
            @record = split (/$self->{_read}/o, $_);
        }

        next unless (scalar @record);

	$hash = {};

	for ($loop=0; $loop <= $no_fields; $loop++) {
	    $hash->{ $fields[$loop] } = $record[$loop];
	}

	push @{ $self->{records} }, $hash;
    }
	
    close (FILE);

    $self->unlock || $self->display_error (-516);

    return (1);
}

##++
##  NOTE: Derived from lib/Text/ParseWords.pm. Thanks Hal!
##--

sub quotewords 
{
    my ($self, $delim, $line) = @_;
    my (@words, $snippet, $field);

    $_ = $line;

    while (length) {
	$field = '';

	for (;;) {

            $snippet = '';

	    if (s/^"([^"\\]*(?:\\.[^"\\]*)*)"//) {
		$snippet = $1;
	    } elsif (s/^'([^'\\]*(?:\\.[^'\\]*)*)'//) {
		$snippet = $1;
	    } elsif (/^["']/) {              # Don't bail out!
                $self->display_error (-512, $line);
                return;
	    } elsif (s/^\\(.)//) {
                $snippet = $1;
            } elsif (!length || s/^$delim//) {
	        last;
	    } else {
                while (length && !(/^$delim/ || /^['"\\]/)) {
		   $snippet .= substr ($_, 0, 1);
		   s/^.//s;
                }
	    }

	    $field .= $snippet;
	}
        
        $field =~ s/\\(.)/$1/g;

	push (@words, $field);
    }

    return (@words);
}

1;

