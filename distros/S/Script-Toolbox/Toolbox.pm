package Script::Toolbox;

use 5.006;
use strict;
use warnings;
use Script::Toolbox::Util qw(:all);

require Exporter;

our @ISA = qw(Script::Toolbox::Util Script::Toolbox::Util::Opt Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Script::Toolbox ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(Open Log Exit Table Usage Dir File FileC
						           System Now Menue KeyMap Stat TmpFile
                                   DataMenue Menu DataMenu
                                  )]);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.56';


# Preloaded methods go here.

1;
__END__

=head1 NAME

Script::Toolbox - Framework for the daily business scripts

=head1 SYNOPSIS

  use Script::Toolbox qw(:all);

  $e = Script::Toolbox->new();

  #---------
  # Logging 
  #---------
  Log( 'log message' );           # log to STDERR
  Log( 'log message', 'STDERR' ); # log to STDERR
  Log( 'log message', 'STDOUT' ); # log to STDOUT
  Log( 'log message', '/tmp/x' ); # log to /tmp/x
  Log( 'log message', new IO::File '/tmp/XXX' ); # log to /tmp/XXX

  Script::Toolbox->new(
        { logdir'=>{'mod'=>'=s',
                   desc'=>'Log directory',
                   mand'=>1,
                   default'=>'/var/log'}
        });
  Log( 'log message' ); # log to /var/log/<scriptName>.log

  Log( 'log message','syslog','severity','tag' ); # log via syslogd


  #--------------------------
  # Formatted tables like:
  #   print join "\n", @{$t};
  #--------------------------

  $t = Table( [ '1;2;3','44;55;66','7.77;8.88;9.99' ] );
  $t = Table( [ '1|2|3','44|55|66','7.77|8.88|9.99' ], '|');
  $t = Table( [ 'This is the title',
                [ '--H1--',  '--H2--', '--H3--'],
                [ '11:11:11',  33.456, 'cc  '  ],
                [ '12:23:00', 2222222, 3       ],
                [ '11:11', 222, 3333333333333333 ]]);
  $t = Table({ 'title' => 'Hash example',
               'head'  => ['Col1', 'Col2', 'Col3'],
               'data'  => [[ '11:11:11',  33.456, 'cc  ' ],
                           [ '12:23:00', 2222222, 3 ],
                           [ '11:11', 222, 3333333333333333 ]]});
  $t = Table({'title'=>'Hash with automatic column heads (F1,F2,F3)',
              'data' =>[{'F1'=>'aaaa','F2'=>'bbb','F3'=>'c'},
                        {'F1'=>'dd  ','F2'=>'ee ','F3'=>'f'}]});
  
  # as OO version
  my $T = Script::Toolbox::TableO->new([ '1;2;3','44;55;66','7.77;8.88;9.99' ] );
  my @T = $T->asArray();
  print   $T->asString();       # table rows separated by \n
  print   $T->asString("\n\n"); # table rows separated by \n\n

  #----------------------
  # Command line options
  #----------------------
  $x    = {'file'=>{'mod'=>'=s','desc'=>'Description',    'mand'=>1, 'default'=>'/bin/cat'},
           'int' =>{'mod'=>'=i','desc'=>'Integer option', 'mand'=>1, 'default'=>'10'      },
           'flag'=>{            'desc'=>'Boolean option', 'mand'=>0                       },
          };
  $tb   = Script::Toolbox->new( $x );
  $file = $tb->{'file'};
  $old  = $tb->SetOpt('newFile');

  #--------------------------
  # Automatic usage messages
  #--------------------------
  Usage(); # print an usage message for all options
           # if available print also the POD

  Usage('This is additional text for the usage');

  #--------------------
  # Directory handling
  #--------------------
  $arrRef = Dir('/tmp' );            # all except . and ..
  $arrRef = Dir('/tmp', '.*patt' );  # all matching patt
  $arrRef = Dir('/tmp', '!.*patt' ); # all not matching patt

  $stat   = Stat('/bin');            # like Dir() with stat() for each file
  $stat   = Stat('/bin','.*grep');   # grep,egrep,fgrep

  #---------------
  # File handling
  #---------------
  # READ file
  $arrRef = File ('path/to/file');              # read file into array
  $arrRef = FileC('path/to/file');              # read file into array, chomp all lines
  $arrRef = File ('/bin/ps |');                 # read comand STDOUT into array
  $arrRef = File ('path/to/file', \&callback ); # filter with callback
  $arrRef = FileC('path/to/file', \&callback ); # filter with callback, chomp all lines

  # WRITE file
  File( '> path/to/file', 'override the old content' );
  File( 'path/to/file',   'append this to the file' );
  File( 'path/to/file',   $arrRef );           # append array elements 
  File( 'path/to/file',   $arrRef, $recSep );  # append array elements 
  File( 'path/to/file',   $hashRef, $recSep, $fieldSep); # append key <$fldSep> value <$recSep>
  File( '| /bin/cat', 'Hello world.\n' );

  $fileHandle = TmpFile();                     # open new temporary file
  $arrRef     = TmpFile($fileHandle)           # read temp whole file


  #---------------------------------------------
  # Key maps. Key maps are hashs of hashs like:
  # key => key => ... key => value
  #---------------------------------------------
  # fill key map from CSV file
  $keyMap = KeyMap('path/to/file');
  $keyMap = KeyMap('path/to/file', $fieldSep);

  # write the hash to CSV file
  KeyMap('path/to/file', $fieldSep, $hashRef); 


  #---------------
  # Miscelleanous
  #---------------
  Exit( 1, 'Exit message' ); # exit with returncode 1, 
                             # write exit message via Log()

  Exit( 1, 'Exit message', __FILE__, __LINE__ );
                             # exit with returncode 1, 
                             # with code line reference,
                             # write exit message via Log()

  $fh = Open( '> /tmp/xx' ); # return an IO::File object with
                             # /tmp/xx opened for write 
                             # die with logfile entry if failed
  $fh = Open( '/bin/ps |' ); # return an IO::File object
                             # die with logfile entry if failed
  $rc = System('/bin/ls')    # execute a system command and
                             # report it's output into the 
                             # logfile.

  #------------------------+
  # Date and time handling |
  #------------------------+
  $n   = Now();
  print  $n->{'mday'},$n->{'mon'},  $n->{'year'},$n->{'wday'}, $n->{'yday'},
         $n->{'isdst'},$n->{'sec'}, $n->{'min'}, $n->{'hour'};
  print  Now->{'epoch'};
  $now = Now({'format'=>'%A, %B %d, %Y'});      # Monday, October 10, 2005
  $now = Now({'offset'=>3600});                 # now + 1 hour
  $diff= Now({'diff'=>time()+86400+3600+60+1}); # time+1d+1h+1min+1sec
  print  $diff->{'seconds'};                    # 90061 
  print  $diff->{'minutes'};                    # 1501.016
  print  $diff->{'hours'};                      # 25.01694
  print  $diff->{'days'};                       # 1.042373
  print  $diff->{'DHMS'};                       # '1d 01:01:01'


  #----------------
  # Menu handling
  #----------------
  # using Menu to start subroutines
  my $mainMenu = [{'header'=>'This is the line on top'},
                   {'footer'=>'This is the bottom line.'},
                   {'label'=>'EXIT',          jump'=>\&_exit,     argv'=>0},
                   {'label'=>'Edit Hosts',    jump'=>\&editHosts, argv'=>$ops},
                   {'label'=>'Activate Host', jump'=>\&activate,  argv'=>$ops}, 
                   {'label'=>'Changeable Value','value'=>10},
                   {'label'=>'Read only  Value','value'=>10, 'readOnly'=>1},
                  ];
  while( 1 ) { my ($o,$mainMenu) = Menu($mainMenu); }

  # or ...
  my ($resp, $menue) = Menu([{'label'=>'One'},{'label'=>'Two'},{'label'=>'Three'}]);
  print 'Second Option' if( $resp == 2 );

  # or with header and footer
  my ($resp, $menue) = Menu([{'header'=>'This is the optional head line.'}, 
                              {'label' =>'One'},{'label'=>'Two'},{'label'=>'Three'},
                              {'footer'=>'This is the optional footer line.'}]);
  print 'Second Option' if( $resp == 2 );

  #----------------
  # Menu container 
  #----------------
  my $m = Script::Toolbox::Util::Menus->new({'SubMenu1'=>[{'label'=>'Opt1','label'=>'Opt2'}]});
  my $m = Script::Toolbox::Util::Menus->new();

     $m->addMenu({'MainMenu'=>[{'label'=>'Opt1','label'=>'Opt2'}]});
     $m->addOption('MainMenu',  {'label'=>'Opt3',     'jump'=>\&callBack });
     $m->addOption('MainMenu',  {'label'=>'Sub Menu','jump'=>'SubMenu1'}); 
     $m->addOption('MainMenu',  {'label'=>'Edit Value','value'=>10});
     $m->setAutoHeader();               # enable AutoHeader for all defined menues
     $m->setAutoHeader('MainMenu');    # enable AutoHeader for one menue
     $m->delAutoHeader();               # disable AutoHeader for all defined menues
     $m->delAutoHeader('MainMenu');    # disable AutoHeader for one menue
     $m->setHeader('MainMenu','My new header of main manue'); # override setAutoHeader()
     $m->setFooter('MainMenu','------');

  my $num = $m->run('MainMenu');        # terminate menue after first selection, return seleted option number
     $num = $m->run('MainMenu', 3);     # terminate menue after third selection, return last seleted option number
     $num = $m->run('MainMenu', 0);     # terminate never
  my $opt = $m->currNumber('MainMenu'); # return number of last seleted option
  my $lbl = $m->currLabel ('MainMenu'); # return label  of last seleted option
  my $jmp = $m->currJump  ('MainMenu'); # return callback address of last seleted option
  my $val = $m->currValue ('MainMenu'); # return data value of last seleted option
  my $lbl = $m->setCurrLabel ('MainMenu','newLabel'); # set label  of last seleted option
  my $val = $m->setCurrValue ('MainMenu','newValue'); # set data value of last seleted option
  my $jmp = $m->setCurrJump  ('MainMenu',\&newCB,$newArgv); # set callback address of last seleted option

  my $list= $m->getMatching('MainMenu','^[1]','number','label'); # return all labels where option number starts with one
  my $list= $m->getMatching('MainMenu','(min|low)','value','number'); # return all option numbers where value match min or low

  #----------------
  # Data Menus 
  #----------------
  # using Menu to display and edit some few data values
  my $dataMenu = [{'label'=>'EXIT'},
                   {'label'=>'Name',value'=>''},
                   {'label'=>'ZIP', value'=>'01468'},
                   {'label'=>'City',value'=>'Templeton'} ];

  while( 1 ) {
    my ($o,$dataMenu) = Menu($dataMenu);
    last if( $o == 0 );
  }

  # or ...
  my $dataMenu = [{'label'=>'Name','value'=>'',         'default'=>'Linus'},
                  {'label'=>'ZIP', 'value'=>'01468',    'default'=>'00000'},
                  {'label'=>'City','value'=>'Templeton','default'=>'London'} ];
  $dataMenu = DataMenu($dataMenu)
  my $data   = DataMenu('aaa bbb ccc');
  my $data   = DataMenu('aaa bbb ccc',{'header'=>'Top Line', 'footer'=>'Bottom Line'});

=head1 ABSTRACT

  This module should be a 'swiss army knife' for the daily tasks.
  The main goals are command line processing, automatic usage
  messages, signal catching (with logging), simple logging, 
  simple data formatting, simple directory and file processing.
  

=head1 DESCRIPTION

=over 3

=item Dir('/path/to/dir')

This function lists the file names in the directory into an array (without '.' and '..').
Return a reference to this array or undef if directory is not readable.

=item Dir('/path/to/dir', 'regexp')

This function lists the file names in the directory into an array (without '.' and '..').
Skip any file names not matching regexp.
Return a reference to this array or undef if the directory is not readable.

=item Dir('/path/to/dir', '!regexp')

This function lists the file names in the directory into an array (without '.' and '..').
Skip any file names matching regexp.
Return a reference to this array or undef if the directory is not readable.








=item Exit(1,'The reason for the exit.', __FILE__, __LINE__)

Exit the script with return value 1. Write the message to the log-channel
via Log().  __FILE__ and __LINE__ are optional.







=item $arrRef = File('/path/to/file')

This function read the file content into an array.
Return a reference to this array or undef if the file is not readable.

=item $arrRef = File('/path/to/file', \&callback)

Read the file into an array. Afterwards call the callback function with
a reference to that array. The return value of File() will be the return
value of the callback function. In case the callback function do not return 
anything, a reference to the input array of the callback function will be
returned. The callback function may return one scalar value.

 ...
 sub decrypt($) {...}
 $f = File('path/to/encrypted', \&decrypt);


=item File( '> path/to/file', 'overwrite the old content' )

Write the string to the file. Overwrite the old content of the file.

=item File( 'path/to/file', 'append this to the file' )

Append the string to the file.


=item File( 'path/to/file', $arrRef )

Append each array element to the end of the file as is (no automatic newline).


=item File( 'path/to/file', $arrRef, $recSep )

Concatenate each array element with the record separator and append it to the file. 


=item File( 'path/to/file', $hashRef, $recSep, $fieldSep )

Append records like  KEY$fieldSepVALUE$recSep to the file. Default record separator is 
the empty string. Default field separator is ':';


=item $arrRef = FileC('/path/to/file')

Same as File('/path/to/file') but with chomped the results.

=item $arrRef = FileC('/path/to/file', \&callback)

Same as File('/path/to/file',  \&callback) but with chomped the results.




=item KeyMap('path/to/file')

Read a CSV file with the structure 

	key1.1,key1.2,...,value1
	key2.1,key2.2,...,value2

into a hash of the same structure. The default field separator is ','.

=item KeyMap('path/to/file', $fieldSep)

Use $fieldSep as  field separator.

=item KeyMap('path/to/file', \&callback)

Same funtionality as in File().

=item KeyMap('path/to/file', $fieldSep, \&callback)

Same funtionality as in File().
Use $fieldSep as  field separator.



=item KeyMap('path/to/file', $fieldSep, $hashRef)

Write a hash with the structure 

	key1.1 => key1.2 => ... => value1
	key2.1 => key2.2 => ... => value2

into a file of the same structure. Use $fieldSep as  field separator.






=item Log('The message', [channel])

Add a timestamp and write the log message to the channel. 
The channel may be F<'STDERR'> (default), F<'STDOUT'>, F</path/to/logfile>
or an IO::File object. Without a channel and using the command
line option -logdir F</path/to/log> the log file will be created 
under F</path/to/log/<scriptName>.log>. ScriptName is the basename
of the perl script using Script::Toolbox.pm;





=item Now({'format'=><'strftime-format'>, offset'=><+-seconds>})

Return the actual date and time. If $format is undef the result is a hash
ref. The keys are: I<sec min hour mday mon year wday yday isdst epoch.> 
Month and year are corrected. Epoch is the time in seconds since 1.1.1970.
If $format is not undef it must be a strftime() format string. The result
of Now() is then the strftime() formated date string. If defined, offset will be 
added to the epoch seconds before any format convertion takes place.

=item Now({'diff'=><time>})
$diff may be a value in epoch seconds or any string parseable by Time::ParseDate.
If Now() is called with a diff argument it returns a hash ref with following keys
I<seconds minutes hours days DHMS>. Each corresponding value is the 
difference between now and the given time value.

    my $d = Now( time()- 1800 );
    print $d->{'seconds'} .'s'; 	# 1800.0s
    print $d->{'minutes'} .'min';	# 30.0min
    print $d->{'hours'}   .'h';	# 0.5h
    print $d->{'days'}    .'d';	# 0.02083d
    print $d->{'DHMS'};		# 0d 00:30:00


=item Stat('/path/to/dir', '!regexp')

Read the directory like Dir() and make a stat() call for each matching file.
Skip '.'  '..' and any entry matching regexp.
Return a reference to a hash or undef if directory not readable.

=item Stat('/path/to/dir', 'regexp')

Read the directory like Dir() and make a stat() call for each matching file.
Skip '.'  '..' and any entry not matching regexp.
Return a reference to a hash or undef if directory not readable.

	$d = Stat('/bin','echo');
	print $d->{'echo'}{'atime'};
	print $d->{'echo'}{'blksize'};
	print $d->{'echo'}{'blocks'};
	print $d->{'echo'}{'ctime'};
	print $d->{'echo'}{'dev'};
	print $d->{'echo'}{'gid'};
	print $d->{'echo'}{'ino'};
	print $d->{'echo'}{'mode'};
	print $d->{'echo'}{'mtime'};
	print $d->{'echo'}{'nlink'};
	print $d->{'echo'}{'rdev'};
	print $d->{'echo'}{'size'};
	print $d->{'echo'}{'uid'};


=item  System( 'command to execute' )

Execute a program in a new shell. The STDOUT / STDERR of the executed 
program will be logged into the logfile. System() returns 0 if the 
exit code of the program is not 0 otherwise 1;







=item Table($dataRef)

Table can be used for formatting simple data structures into equal
spaced tables. Table knows the folloing input data structures:

=over 4

=item *

Array of CSV lines. Default separator is ';'

=item *

Array of arrays. If the first array element is a SCALAR value, we assume
it is the title and the second array element has the column headers.
Otherwise default title and headers will be generated.

=item *

A hash with the keys 'title', 'head' and 'data'. 'title' points to a
SCALAR value, 'head' points to an array of scalars. 'data' points to
an array of arrays or an array of hashes. 

In case of array of hashes, the column heads will be initialized from
the keys of the hash in the first array element. The order of the columns
is the order of the sorted keys of the hash in the first array element.

=back

=item TableO($dataRef)

It's an object oriented version of Table (vers. >= 0.50). A Table-Object has 
two methods.

=over 4

=item asArray()

Return the formatted table as array of scalars.

=item asString(<sep>)

Return the formatted table as string.
Tablerows will be separated by separator <sep> or
by "\n" as default if <sep> is missing.

=back

=item Menu

There are two types of menues. Regular menues and data menues.
All menues use the madatory key 'label'. 
A data menue has the mandatory key 'value' and optional keys 'default' and
'readOnly'. The latter has some special effects within Menus containers.
See also addOption() and run().

Optional keys for both types are 'header' and 'footer'. All Entries with
these keys will be printed on top resp. below the option lines.

Regular menues may use the optional keys 'jump' and 'argv'. Jump points
to a handler subroutine. Argv points to the arguments of the handler
subroutine.

=item Menus

This is an object oriented container for regular menues. Each menue generated
by Menus->new() gets an automatic RETURN option with option number zero and 
must have an unique menue-name.

Menus-Methods:

=over 4

=item addMenu(<menueDefs>)

Add one or more complete menue definitions to the menues object.
A <menueDefs> has this layout:
{<menueName> => [<menueDef>], ...}

<menueDef> is the structure of a simple menue as decribed in item Menu.
In the context of Menus, a jump target may be also the name of a menue
in the same Menus container.

     $m->addMenu({
         'SubMenu' =>[{'label'=>'Opt2'}, {'label'=>'Opt3'}],
         'MainMenu'=>[{'label'=>'Go to submenue','jump'=>'SubMenu'}, {'label'=>'Opt1'}]
     });

=item addOption(<menueName>,<labelsDef>)

Add a new option line to the menue <menueName>.

     $m->addOption('MainMenu',  {'label'=>'Opt3',      'jump'=>\&callBack });
     $m->addOption('MainMenu',  {'label'=>'Sub Menu',  'jump'=>'SubMenu1'}); 
     $m->addOption('MainMenu',  {'label'=>'Edit 1','value'=>10});
     $m->addOption('MainMenu',  {'label'=>'Edit 2','value'=>10, 'default'=>20});
     $m->addOption('MainMenu',  {'label'=>'Toggle1', 'readOnly'=>1,
                                 'value'=>10, 'default'=>20});
     $m->addOption('MainMenu',  {'label'=>'Toggle2', 'readOnly'=>1, 'value'=>10});
     $m->addOption('MainMenu',  {'label'=>'Toggle3', 'readOnly'=>1, 'default'=>10});
     $m->addOption('MainMenu',  {'label'=>'Toggle4', 'readOnly'=>1, });

=over 4

=item Edit 1

Normal edit mode. If you enter <SPACE> the content of value is a space character.

=item Edit 2

Reset to default mode. If you enter <SPACE> the content of value is the
content of default.

=item Toggle 1

The content of value toggles between 10 and 20 (value and default content).

=item Toggle 2

The content of value toggles between 10 and '' (value and default content).

=item Toggle 3

The content of value toggles between '' and 10 (value and default content).

=item Toggle 4

The content of value toggles between 'x' and '' (value and default content).


=back



=item setHeader(<menueName>,<newHeaderStr>)

Replace the header of the menue <menueName>. This override an enabled auto header.

=item setFooter(<menueName>,<newFooterStr>)

Replace the footer of the menue <menueName>. 

=item run(<menueName>, [<maxRunCnt>])

Start the menue <menueName>. The run() method returns after 
the the user has <maxRunCnt> options selected. Default value for <maxRunCnt> is one.
If <maxRunCnt> is lower than or equal zero, the run() method will never return unless the
user selects the RETURN option (num=0). The run() method returns the number of the
last selected option.

If the menu runs in endless mode (maxRunCnt < 0), then all <readOnly> options
will take a special behavior. They are in toggle-mode. See also example at
addOption().

    while( $m->run('MainMenu') ) { ... }
    $num = $m->run('MainMenu', 3);
    $num = $m->run('MainMenu', 0);

=item currNumber(<menueName>)

Get the number of the last selected option.

  my $opt = $m->currNumber('MainMenu');

=item currLabel(<menueName>)

Get the label of the last selected option.

  my $lbl = $m->currLabel ('MainMenu');

=item currJump(<menueName>)

Get the address of the callback function of the last selected option.

  my $jmp = $m->currJump  ('MainMenu');

=item currValue(<menueName>)

Get the data field value of the last selected option.

  my $val = $m->currValue ('MainMenu'); 

=item setCurrLabel(<menueName>,<newLabel>)

Change the label string of the last selected option. Return the old label string.

  my $old = $m->setCurrLabel ('MainMenu','newLabel'); 

=item setCurrJump(<menueName>,\$newCB,$newArgv)

Change the address of the callback function and argv of the last selected option.

  my ($oldCB,$oldArgv) = $m->setCurrJump  ('MainMenu',<newCallBack>,<newArgv>); 

=item setCurrValue(<menueName>,<newValue>)

Change the data field value of the last selected option. Return the old value.

  my $old = $m->currValue ('MainMenu','newValue');

=item setCurrDefault(<menuName>,<newDefault>)

Set a new default for the current selected option of menue <nemuName>.
Return the old default.


=item setCurrReadOnly(<menuName>,<newReadOnly>)

Set the readOnly flag for the current selected option of menue <nemuName>.
Return the old readOnly state. <newReadOnly> may be 0, 'false' or undef
for logical false. Any other values means locical true.


=item getMatching(<menueName>,<pattern>,<searchIn>,<return>)

Search in the options array of menue named <menueName>. Return the reference
to an array with return values according to matches.

=over 2

=item <pattern>

A regular expression.

=item <searchIn>

The part of option to search in (label,number,value).

=item <return>

The part of option to return (label,number,value) if search match.

=back



=item setAutoHeader(), setAutoHeader(<menueName>)

Enable automatic header line generation if no regular header defined.
The header looks like 'Menu: <menueName>' 
Enable AutoHeader for all menues or only the one selected by <menueName>.

=item delAutoHeader(), delAutoHeader(<menueName>)

Disable AutoHeader for all menues or only the one selected by <menueName>.

=item getLabelValueHash()

Return a hash with all label-value pairs of the menu.

=item getRunCnt(<menuName>)

Return the current value of the running counter of the menu.


=back


=item DataMenu

This is a convenient version to edit values via Menu function. It includes
an endless loop and an automatic generated EXIT label and exit handling.
The edited values will be returned. Acceptable input are the same array with
'label', 'value' hash or a simple white space separated scalar value.
In case of simple scalar input an optional hash with 'header' and/or 'footer'
keys may be given as second parameter.
An option entry like:

 {'label'=>'Read Only Example', 'value'=>10, 'readOnly'=>1}

causes the value will be displayed only and can not be changed.

If a default is defined, like this:

 {'label'=>'Default Example', 'value'=>10, 'default'=>'99'}

and the input is a single space character, then the 'default' will be
assigned to 'value'.

=back

=head1 SIGNALS

The signals SIGINT, SIGHUP, SIGQUIT and SIGTERM will be catched
by Script::Toolbox and logged as 'program aborted by signal SIG$sig.'



=head1 EXPORT

None by default. Can export Dir, Exit, File, KeyMap, Log,
Now, Open, Table, Usage, System, Stat or :all.


=head1 DEPRECATED

Menues, Menue, DataMenue will be removed in version 1.0 ;-)

=head1 SEE ALSO

L<IO::File>, L<Fatal>, L<Script::Toolbox::Util>,
L<Script::Toolbox::Util::Open>,   L<Script::Toolbox::Util::Formatter>,
L<Script::Toolbox::Util::Menus>, L<Script::Toolbox::TableO>,
L<Time::ParseDate>


=head1 AUTHOR

Matthias Eckardt, E<lt>Matthias.Eckardt@imunixx.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2018 by Matthias Eckardt, imunixx GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
