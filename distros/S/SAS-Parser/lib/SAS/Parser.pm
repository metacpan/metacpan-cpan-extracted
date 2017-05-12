package SAS::Parser;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = "0.93";  # $Date: 15 Feb 2006 10:02:56 $

## 0.93 	Added parsing of function macros called in %let statements

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(readfile find_autoexec protect_special);  # symbols to export by default

# You can run this file through pod2man, pod2html or pod2text to produce pretty
# documentation. (These utilities are part of the Perl 5+ distribution).

=head1 NAME

SAS::Parser - Parse a SAS program file

=head1 SYNOPSIS

 use SAS::Parser;
 $p = new SAS::Parser;
 $p->parse_file('mysas.sas');         # returns a SAS::Parser object

or

 $file = shift @ARGV;
 $p->parse_file($file, {options});

After parsing, you can access the information stored in the C<SAS::Parser> object as follows:

 @procs = $p->procs();               # get list of procs called
 @datasets = $p->datasets();         # get list of datasets created
 $macros = $p->macros();             # get string of macros called

=head1 DESCRIPTION

I<SAS::Parser> is a base tool for use in writing applications which deal
with F<.sas> programs.  It can be used as a documentation tool, e.g.,
to extract lists of procedures used, data sets created, macros used,
etc., and produce a nicely formatted header in a consistent format, or to
produce standard documentation headers for SAS macros. It can also be used
as a pre-processor to a SAS code formatter, to produce WWW documents, etc.
It is I<not> likely to be useful as a SAS syntex checker without a good
deal of additional work.  It does as reasonable a job on SAS macros as
can be expected without being an actual macro processor.

I had written a large number of specialized scripts for some of these
tasks, and found that I was re-doing similar stuff each time.  I<SAS::Parser>
is an attempt to bring this to the next level, where the basic statement
parsing can be assumed, and your application can just work with the info
extracted.

It's just a beginning, and all the rest depends on writing Perl
code making use of SAS::Parser to accomplish such tasks.  See L<SAS::Header>
for one such extension.

=head2 So, what does it actually do?

Any parser works by segmenting text into 'interesting units' for the
purpose at hand.

I<SAS::Parser> parses a SAS program into I<statements> when the parse()
or parse_file() methods are called.  Each statement is classified
as a statement type, and further parsed depending on that statement
type.  Information about libnames, filenames, data sets created,
procs called, macros called, and macros defined is stored in the
SAS::Parser object.

In addition, the parsed description of each statement selected by
the B<stored> option (its type, the statement name, and statement
text) may be stored in an array for further processing.

Presently, we just collect the information from the SAS program.  To
do more interesting things, one should define sub-classes for more
specialized tasks.  See, for example, L<SAS::Header>.
These can add items to the object structure, which, like Topsy, just grows.

=head1 USAGE

The external interface to I<SAS::Parser> is:

=over 4

=item $p = new SAS::Parser;

Create a new, but empty SAS::Parser object. The object constructor takes no arguments.

=item $p->parse( $string, \%options );

Parse the $string as a SAS program.  The $string argument is
typically a series of lines (separated by \n) read from a file.
The parse() method may be called several times with different chunks
of a large file, or with lines read from different files.  The
parse() method does most of the work, but most applications directly use
the parse_file() method, which in turn calls parse() with the text
of a file.  The return value is a reference to the parser object.

=item $p->parse_file( $file, \%options );

This method can be called to parse text from a file.  The argument can
be a filename or an already opened file handle. The return value from
parse_file() is a reference to the parser object.

On Unix systems, parse_file() also attempts to locate and parse the
F<autoexec.sas> file, in order to locate pre-defined C<libname> and 
C<filename> statements which may be referenced in the SAS program.

=back 4

=head2 OPTIONS

The parse() and parse_file() methods take the following options as an
optional second argument.  All options are included as a hash of
(option_name, option_value) pairs.

=over 4

=item doincludes

Setting C<doincludes=E<gt>1> (non-zero) causes the parser to insert the
text of included files (C<%include> statements) in the input stream at
that point, if the included file can be read.  In this case, line numbers
refer to the total stream, not individual files.

=item trim

Setting C<trim=E<gt>1> (non-zero) causes each statement to be trimmed of
leading/trailing whitespace, and all internal C-style comments
(C</* ... */>) to be removed before the statement is stored or printed.

=item store

The C<store> option specifies either 'ALL', or 'NONE', or a list of 
statement types whose contents
and descriptors are stored in the C<SAS:Parser> object.
The default is store = qw(data proc).

For example, to store all C<data> and C<proc> statements, use

 $p->parse_file($file, {store=>qw(data proc)});

For each stored statement, the SAS::Parser object stores a list of
the following 5 elements:

 ($lineno, $step, $type, $stmt, $statement)

The C<parse_file()> method uses the following call to parse the F<autoexec.sas>
file silently, storing no statements (but recording filename and
libname information):

  $self -> parse($auto, {silent=>1, store=>qw(none)}) if $auto;

=item print

The C<print> option specifies either 'ALL', or 'NONE', or a list of 
statement types whose contents
and descriptors are printed as they are parsed.  The default here,
C<print = qw(data proc)> prints information about each data and proc
step.
This option is mainly
used for debugging or testing.

=item silent

Setting C<silent=E<gt>1> (non-zero) suppresses the printout of statements as they are parsed.  This is equivalent to setting the C<print> option to 'NONE'.

=back 4

=head2 Methods

The following methods are available in the SAS:Parser class.
Except for the output() method,
they all work as both constructors and accessors.  If called
with an argument, that argument is added to the corresponding
entry in the SAS:Parser object.  If called with no argument,
they return that entry.  

As a convenience, the accessors which ordinarily return lists (e.g.,
procs(), macros(), datasets(), etc.) will return a blank-separated
string if called in a scalar context, or an array if called in a
list context.  (But note that "print $p->procs();" supplies a I<list>
context.)

The items for all these lists are stored and returned in the order found
in the file(s) parsed.  To use or print these in a sorted order, use
the sort() function (which also supplies a list context).

=over 4

=item $p->procs('means')

Appends the named procedure to the list of procedures called.  The 
constructor use of these methods is used internally during parsing.

=item $p->procs();

Returns a list of the unique names of procedures called in C<PROC> statements
or a blank-separated string in a scalar context.
The list accessor functions such as this are used as follows:

   my @procs = $p->procs();		# list context
   print "procs called: ", join(', ', @procs), "\n" if scalar @procs;

or

   my $procs = $p->procs();		# scalar context
   print "procs called: $procs\n" if $procs;

=item $p->macros();

Returns a list of the unique names of macros invoked explicitly in the
form C<%macname [(args);]> or a blank-separated string in a scalar context.
This does include macros invoked as part
of C<%let> other statements, e.g., C<%let nv = %nvar(&vars);>,
but not other macro statements.


=item $p->macdefs();

Returns a list of the unique names of macros defined
or a blank-separated string in a scalar context.

=item $p->datasets();

Returns a list of the unique names of datasets created in C<DATA> statements
or a blank-separated string in a scalar context.
Output datasets created by procedures are not tracked.

=item $p->includes();

Returns a list of the unique names of included files from C<%include> statements or a blank-separated string in a scalar context.

=item $p->modules();

Returns a list of the unique names of IML modules defined
or a blank-separated string in a scalar context.

=item $p->libnames();

Returns a hash of the names of SAS libraries defined.
The key for each element of the hash is the libref, and the corresponding
value is a string containing the folder or directory name.

The libnames and corresponding directory names (if any) may be printed as follows:

 my %libnames = $p->libnames();
 while (($libref,$value) = each %libnames) {
	print "  libname: $libref=$value\n";
 }

=item $p->filenames();

Returns a hash of the names of SAS filenames defined.
Non-disk filenames (C<pipe>, C<printer>, C<tape>, etc) are ignored.
The key for each element of the hash is the fileref, and the corresponding
value is a string containing the filename, or
a folder or directory name, or a blank-separated list of folder/directory names (for a filename aggregate).

=item $p->stored();

Returns a list-of-lists of the SAS statements stored, which consists of
all statements whose type matches the C<store> option.

=item $p->eof(1)

Sets an end-of-file condition which terminates parsing after the current
statement has been processed.  The eof() method may be used by a sub-class
of SAS::Parser to end the parsing after the required information has
been extracted.

=item $p->output($lineno, $step, $type, $stmt, $statement)

This method is used to produce output from the parser as each statement
is parsed.  The default method provided in SAS::Parser simply prints
the values of $step, $type, $stmt, and $statement.  It uses a negative
value of $lineno as a flag for initial processing.
Sub-classes of SAS::Parser may override this method for other purposes.

For example, the following lines define a short SAS program as
a here document, and parses it with SAS::Parser.

  use SAS::Parser;
  my $sascode = <<END;
  data test;
	  do x=1 to 20;
		  y=x + normal(0);
		  output;
		  end;
  proc reg data=test;
	  model y=x;
  proc means data=test;
	  var y x;
  END
  ;

  my $p = new SAS::Parser;
  $p -> parse($sascode);

When run, this produces the following printed output:

 data data     test     data test;
 proc proc     reg      proc reg data=test;
 proc proc     means    proc means data=test;


=back 4

=head2 Statement types

The parsing of each statement returns the variables $lineno, $step,
$type, $stmt, and $statement, which may be printed by parser()
and/or stored in the SAS::Parser object (depending on the options:
B<silent>, B<print>, B<store>).

$lineno is the source line number of the first line of the statement.
$step is one of 'data', 'proc', or '' (for global statements outside
of PROC or DATA steps.  $type is a general statement type, $stmt
sometimes gives a further keyword or name associated with the
statement, and $statement is the actual text of the statement
(possibly trimmed of whitespace and embedded /* comments */,
depending on the B<trim> option).

The statement $types currently used are:

=over 4

=item ?          

parser() could not classify this statement.

=item assign     

an assignment statement.  $stmt contains the name of the variable assigned.

=item cards      

cards; datalines;, etc.

=item ccomment   

a C-style comment:  C</* ... */>


=item data       

a DATA statement. $stmt contains the name of the first data set mentionted

=item global     

a SAS global statement: options, title, run, axis, etc.  $stmt contains
the statement keyword.

=item include    

%include statement.  The parser handles the forms C<%include 'path/filename';>,
C<%include fileref;>,
and C<%include fileref(file);>
where C<fileref> was defined in a filename statement, possibly in the
F<autoexec.sas> file.  If the fileref was defined, the name of the actual
file is found, if the file exists.

=item lines      

actual data lines following C<cards;>


=item mcall      

a macro call statement. $stmt contains the macro name.

=item mcomment   

a macro comment statement: C<%* ... ;>

=item mdef       

a macro definition statement: C<%macro()>.  $stmt contains the macro name.
$statement contains the text of the macro definition statement, including
all arguments and default values.

=item mend       

%mend statement

=item mstmt      

some other macro statement: C<%display>, C<%do>, C<%else>, C<%end>, etc.
$stmt contains the statement keyword.

=item null       

null statement

=item proc       

a PROC statement.  $stmt contains the name of the procedure called.

=item scomment   

a statement comment: C<* ... ;>

=item stmt       

some other SAS statement: all DATA step statements, and PROC step
statements. $stmt contains the statement keyword.

=back 4

=head2 Specialized parser methods

The following methods are available in the SAS:Parser class
for specialized parsing of particular statement types, to extract
or operate on additional information in a statement.  They are designed
so that they may be overridden for particular applications.  

Those
listed as NOOP do nothing here, except reserve a place for such additional
processing.  For example, you can override parse_mdef() to do further
parsing of macro arguments.

=over 4

=item $self->parse_assign($statement);

NOOP

=item $self->parse_ccomment($statement);

NOOP

=item $self->parse_data($statement);

Parse a data statement, finding all dataset names created, and
storing these in $self->{datasets}.  We don't bother distinguishing
between permanent and temporary datasets, or store information about
the SAS libraries referred to.  We handle (implicit)
_data_, as in C<data;>, but don't resolve these to DATA1, DATA2, etc.


=item $self->parse_filename($statement);

Parse a filename statement to determine fileref and corresponding folder(s).

=item $self->parse_global($statement);

NOOP

=item C$file = $self->parse_include($statement);

Parse a %include statement to determine pathname of included file(s).
For this to work, we must have seen and parsed the filename statements
for any C<%include fileref;> or C<%include fileref(file);>.
We don't actually include the file, but leave that to the higher-ups.

Returns:  the resolved pathname of the included file, if it exists.

=item $self->parse_libname($statement);

Parse a libname statement to determine libref and corresponding folder

=item $self->parse_mcall($statement);

NOOP

=item $self->parse_mdef($statement);

NOOP

=item $self->parse_mend($statement);

NOOP

=item $self->parse_module($statement);

NOOP

=item $self->parse_mstmt($statement);

Parse a macro statement. As implemented here, this just looks
for user-defined macro functions invoked in a C<%let> statement,
e.g.,

  %let nv = %words(&vars);

This will add C<%words> to the list of macros called.

=item $self->parse_proc($statement);

NOOP

=item $self->parse_stmt($statement);

NOOP

=back 4

=head2 Other routines

The following subroutines are exported by default.

=over 4

=item &find_autoexec()

Find the F<autoexec.sas> file, and return its pathname if found,
else return C<undef>.
If the environment variable SAS_OPTIONS defines C<-autoexec>, we
look there first.  Otherwise, we search the current directory,
the user's HOME directory, or a directory specified by the
environment variable SASROOT, in that order.

=item $new = &protect_special($text, ['char'] ['replace']);

Protect special characters from the parser by remapping them into
some other string.

=item $text = &readfile($file)

Read a file, given filename (complete path) or filehandle (assumed
open).  Returns the file contents or undef if not found.

=back 4

=head1 ENVIRONMENT

Uses C<SAS_OPTIONS> and C<SASROOT> to locate F<autoexec.sas>.

=head1 BUGS and LIMITATIONS

=over 4

=item * 

parse() does not handle certain types of complex macros particularly
well.  When  C<%do...;  stuff %end;> is used inside another statement
to generate conditional code, that text, up to the next ';' is
appended appropriately to the current statement.  In other cases,
it may fail, returning '?' as the statement type, because
it's a static parser, not a true macro interpreter.  In these cases,
the parser swallows text up to the next ';' as the current statement,
and soldiers on.  Following statements are parsed correctly.

=item * 

The logic used to handle ';' inside quoted strings is fooled by
unmatched quotes, even those inside comments. For example, 

	*--don't expect this comment to parse correctly;

=item *

There are still some problems with parsing line labels that look
like statement types or keywords.  For example, the macro statement

 %done: options notes;

gets classified as a C<%do> statement.

=back 4


=head1 SEE ALSO

L<C<SAS::Header>>, L<C<SAS::Index>>

=head1 AUTHOR

Michael Friendly, friendly@yorku.ca

=head1 COPYRIGHT

Copyright 1999-  Michael Friendly. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# see CPAN/authors/id/DCONWAY/Parse-RecDescent.tar.gz
use Text::Balanced qw ( extract_bracketed );
use Carp;

# $OS = 'UNIX';

# FIGURE OUT THE OS WE'RE RUNNING UNDER
# Some systems support the $^O variable.  If not
# available then require() the Config library
unless ($OS) {
    unless ($OS = $^O) {
	require Config;
	$OS = $Config::Config{'osname'};
    }
}
if ($OS=~/Win/i)    { $OS = 'WINDOWS';} 
elsif ($OS=~/vms/i) { $OS = 'VMS';} 
elsif ($OS=~/Mac/i) { $OS = 'MACINTOSH';}
elsif ($OS=~/os2/i) { $OS = 'OS2';}
else                { $OS = 'UNIX';}

# newline character(s) used in parsing

my $NL = {
    UNIX     => "\n",
    OS2      => "\r\n",
    WINDOWS  => "\r\n",
    MACINTOSH=> "\r",
    VMS      => "\r\n"
    }->{$OS};

# The path separator is a slash, backslash or semicolon, depending
# on the paltform.
my $SL = {
    UNIX      => '/',
    OS2       => '\\',
    WINDOWS   => '\\',
    MACINTOSH => ':',
    VMS       => '\\'
    }->{$OS};

# for copious debugging
sub _trace(@) {}
# sub _trace(@) { print STDERR join(' ', @_), "\n"; }

# At the moment, we just collect the information from the SAS program
# in a SAS:Parser object.  To do more interesting things, we should
# define sub-classes for more specialized tasks.  These can add items
# to the object structure.

sub new
{
    my $class = shift;
    my $self = bless { 
         file       => '',    # name of the file being parsed
         libnames   => {},    # hash of librefs and corresponding dir
         filenames  => {},    # hash of filenames and corresponding dir(s)
         procs      => [],    # array of procs called
         macros     => [],    # array of macros called
         macdefs    => [],    # array of macros defined
         datasets   => [],    # array of data sets created
			includes   => [],    # array of included filenames
         stored     => [],    # list-of-lists of stored statements
           }, $class;
    $self;
}

# Someday, we will make a dispatch table for special parsing of particular
# statements.

my %parsers = (
    libname  => \&parse_libname,
    filename => \&parse_filename,
    include  => \&parse_include,
    data     => \&parse_data,
);

sub parse_file {# ($text, \%options)
   my($self, $file) = @_;
	croak("Provide a filename to parse") unless defined($file);
   my $text;
   
   # Handle options, but just pass them to parse().
   my %options = defined $_[2] ? %{$_[2]} : ();
   my $silent = defined $options{silent} ? $options{silent} : 0;


   # find the autoexec.sas file to get pre-defined filename/libname(s)
   my $autoexec = &find_autoexec();
   _trace("autoexec: $autoexec");
   my $auto = &readfile($autoexec) if $autoexec;
   
   $file = (-e $file) ? $file : "$file.sas";
   croak "Cannot find $file" unless -e $file;
	
   $text = &readfile($file);
   $self->{file} = $file;

	$self -> output(-1) unless $silent;		# print header
   $self -> parse($auto, {silent=>1, store=>qw()}) if $auto;
   $self -> parse($text, \%options);
}

sub parse {# ($text, \%options)
   my $self = $_[0];
   my $text = $_[1];

   # Handle options to the parser.
   my %options = defined $_[2] ? %{$_[2]} : ();

   my $doincludes = defined $options{doincludes} ? $options{doincludes} : 0;
   my $silent = defined $options{silent} ? $options{silent} : 0;

   my $trim = defined $options{trim} ? $options{trim} : 1;

   # store => qw ( list_of_types_to_store )
   #   Default: data proc
   my $store  = ref($options{store}) eq 'ARRAY' ?
      join('|', @{$options{store}})
          : defined($options{store})          ? $options{store}
          :                join('|', qw(data proc))
          ;
	#print "Storing: $store\n";
   
	# print => qw ( types_to_print )
   my $print  = ref($options{'print'}) eq 'ARRAY' ? 
      join('|', @{$options{print}})
          : defined($options{print})          ? $options{print}
          :                join('|', qw(data proc))
          ;
   my $noprint  = ref($options{noprint}) eq 'ARRAY' ? 
      join('|', @{$options{noprint}})
          : defined($options{noprint})          ? $options{noprint}
          :                join('|', qw(comment null assign))
          ;

   my $stmtno = 0;
   my ($statement, $type, $stmt, $lines);
   
   # local variables-- accessible in called subs
   local $lineno = 1;      # source line number
   local $step = '';       # current step: data/proc
   local $lasttype = '';   # last value of $stmt -- for better cards handling
   local $laststmt = '';   # last value of $stmt -- for better cards handling
   local $proc = '';       # name of current proc

   # We use the seen hash to keep track of *all* names we're recording
   # uniquely.  Do this by prefixing the name by a type string.
   local %seen;
   $seen{'DATA_null_'}++;     # ignore data _null_ steps
   $seen{'MCALLeval'}++;      # ignore %eval as macro call
   $seen{'MCALLstr'}++;       # ignore %str as macro call

   
   # protect ';' inside %str(), %nstr() and quoted strings.
   $text = &protect_special($text);
   
   while (length $text) {
      ($statement, $type, $stmt, $text) =
         $self->extract_statement($text);   # get next statement

      $statement =~ s/#SEMI#/;/;            # put back escaped ;s
      $lines = $statement =~ s/$NL/$NL/g;   # count lines

		
		if ($trim) {            # trim whitespace and embedded comments?
			$statement =~ s/\A\s*//;
			$statement =~ s/\s+/ /sg;
			$statement = &remove_comments($statement) if $type ne 'ccomment';
		}
   
      $stmtno++;

      if ($store !~ /none/i && ($store =~/^all/i || $type =~ /$store/)) {
         ## How to construct this list dynamically from $items??
         my @item = ($lineno, $step, $type, $stmt, $statement);
#was:    push (@{$self->{stored}}, [@item]);
			$self->stored(@item);
      }

		unless ($silent || $print =~/none/) {
			if ($print =~ /^all/i || $type =~ /$print/) {
				$self->output ($lineno, $step, $type, $stmt, $statement);
			}
		}

      $lineno += $lines;
      $lasttype = $type;
      $laststmt = $stmt;
      last if $stmt eq 'endsas';
		last if $self->eof();
   }
}

# Extract and classify the next SAS statement in $text
#    At present, we will fail for certain types of complex macros
#    e.g., where a %if ... %then %do;  stuff %end; is used inside
#    another statement to generate conditional code.

# Each statement is assigned a $type:

#   ?          parser could not classify
#   assign     assignment statement
#   cards      cards; datalines;, etc.
#   ccomment   C-style comment:  /* ... */
#   data       data statement
#   global     SAS global statement: options, title, run, axis, etc.
#   include    %include
#   lines      actual data lines following cards;
#   mcall      macro call
#   mcomment   macro comment statement: %* ... ;
#   mdef       macro definition statement: %macro
#   mend       %mend statement
#   mstmt      other macro statement: %display, %do, %else, %end, etc
#   null       null statement
#   proc       proc statement
#   scomment   statement comment: * ... ;
#   stmt       some other SAS statement

#   $stmt - gives the actual statement keyword, or proc, or dsn
#   $step - keeps track of what kind of step we're in: data/proc

## we include the trailing \n in $statement

sub extract_statement {
   my($self, $text) = @_;

   my ($statement, $type, $rest, $stmt, $name, $next);
   my $args;
   undef $statement;
   undef $rest;
   
   my @global_statements =
      qw(options goptions run quit
         libname filename
         missing
         title\d* footnote\d* page skip
         x dm endsas
         axis\d* symbol\d* legend\d* pattern\d* 
         );
         # omitted: %list %run 
			# %include is handled separately

   my @datastep_data =
      qw(cards cards4 datalines datalines4);

   my @macro_stmts = 
      qw(abort display do else end global goto if input 
         keydef let local put return symdel syscall syslput sysrput window sysexec);

   # patterns
   my $label = '(%?\w+\s*:)?';
   my $globals = join('|', @global_statements);
   my $dlines  = join('|', @datastep_data);
   my $mstmts = '(%' . join('|%', @macro_stmts) . ')';
   
   # Check for general forms of statements, signalled by '##'
   
	if ($lasttype eq 'cards' && $laststmt =~  /^($dlines)$/i) {		## datalines
		$type = 'lines';

		if ($& =~ /4/) {		# cards4; -- match up to ;;;;
			$text =~ /^(.*$NL);;;;\s*/s;
			$statement = $1;
			$rest = $';
		}
		else {					# just cards
			$text =~ /^([^;]+$NL)([^;]*;)(\s*)/s;
			$statement = "$1";
			$next = $2 . $3;
			$rest = $';
			#print "lines: $lineno LINES\n$statement\nNEXT\n$next\n";

			# was data followed by a non-null SAS statement?
			if ($next =~ /\S+;/) {
				$rest = $next . $rest;		# put it back
			}
			# we've swallowed a null ; statement
		}
	}

   elsif ($text =~                         ## null statement
         /\A\s*$label\s*;\s*/s
         ) {
      $statement = $&;
      $rest = $';
      $type = 'null';
      $stmt = '';
   }

   elsif ($text =~                      ## SAS statement
         /\A\s*$label(&?\w+)\s*[^;]*;\s*/s     # $label gets $1
         ) {
      $stmt = lc($2);
      $statement = $&;
      $rest = $';
      
		# Check here for embedded %do ... %end;
		if ($statement =~ m/%do\s*[^;]*;\s*/s) {
			$rest =~ s/.*?%end\s*;.*(%str\(#SEMI#\))|;//s &&   # remove from $rest 
				do{$statement .= $&;			# swallow up to nearest '%end;'
				};
		}
		
      # Assignment statement, $stmt gets the variable assigned
      if ($statement =~   /$stmt\s*=/i) {
         $type = 'assign';
			$self->parse_assign($statement);
      }

      # Global statement, $stmt gets the actual statement name
      elsif ($stmt =~   /^($globals)$/i) {
         $type = 'global';
         $stmt =~ s/\d+$//;      # delete trailing digits on title1, etc.
         
         $step = '' if $stmt eq 'run'  && $proc ne 'iml';
         $step = '' if $stmt eq 'quit' && $proc eq 'iml';

			if    ($stmt eq 'libname') {$self -> parse_libname($statement);}
			elsif ($stmt eq 'filename') {$self->parse_filename($statement);}
			else                       {$self -> parse_global($statement);}
      }
      elsif ($stmt =~   /^($dlines)$/i) {
         $type = 'cards';
         $stmt = $&;
      }
      # DATA statement.  We parse the name of the data set(s) and store
      # them in $self->{datasets}.
      elsif ($stmt =~ /^data/i) {
         $type = 'data';
         $step = 'data';
			# this should take place in parse_data, but $stmt must be global
         $statement =~ m/data\s+(&?\w+)\b/i;
         $stmt = lc($1) || '_data_';
         $self -> parse_data($statement);
      }

      # PROC statement.  We parse the name of the procedure and store
      # it in $self->{procs}.  Also, set the running $proc variable
		# so we know which procedure is current.
      elsif ($stmt =~ /^proc/i) {
         $type = 'proc';
         $step = 'proc';
         $statement =~ m/proc\s+(\w+)\b/i;
         $proc = $stmt = lc($1);
         $self->procs($proc) unless $seen{'PROC' . $proc}++;
         $self -> parse_proc($statement);
      }

		# IML module.  Just keep track of the names.  Don't require
		# $proc='iml' because we may just have a file of modules.
      elsif ($stmt =~ /^start\b/i) {
         $type = 'stmt';      # should it be a new type??
         $statement =~ m/start\s+(\w+)\b/i;
         $module = lc($1);
         $self->modules($module) unless $seen{'MODULE' . $module}++;
         $self -> parse_module($statement);
		}

      else {
         $type = 'stmt';      # some other statement
      }   
   }   ## End of SAS statement

   elsif ($text =~                      ## some sort of macro statement
         /\A\s*(%\w+)\s*[^;]*;\s*/s
         ) {
      $stmt = lc($1);
      $statement = $&;
      $rest = $';

      if ($stmt =~ /%inc(lude)?/) {
         $type = 'include';
         my $file = $self -> parse_include($statement);
			# to insert the %included file:
			if ($file && $doincludes) {
				print "Including: $file\n";
				$rest = &readfile($file) . $rest;
			}
      }
      elsif ($stmt eq '%macro') {
         $type = 'mdef';
         $statement =~ m/%macro\s+(\w+)\b/;
         $name = $stmt = lc($1);
         $self->macdefs($name) unless $seen{'MACDEF' . $name}++;
         $self -> parse_mdef($statement);
      }
      elsif ($stmt eq '%mend') {
         $type = 'mend';
         $self -> parse_mend($statement);
      }

      # Any of the macro statements defined in @macro_stmts?
      elsif ($stmt =~ /$mstmts/) {
         $type = 'mstmt';
         $stmt = $&;
         $self -> parse_mstmt($statement);
      }
      else {                           # macro call, $stmt is macro name
         $type = 'mcall';
			$stmt =~ s/^%//;
# was:   push (@{$self->{macros}}, $stmt) unless $seen{$stmt}++;
         $self->macros($stmt) unless $seen{'MCALL' . $stmt}++;

         # If macro call had no ';', we have swallowed the next statement
         # If there's an argument list, find its boundaries and push
         # any additional text back on $rest
         if ($statement =~ /\(/) {      # bal )
         my ($test, $rem);
         ($test = $statement) =~ s/[^(]+//;  # bal )
         ($args, $rem) = 
            &extract_bracketed($test, '()');
         # print "mcall: in $test leaves $rem\n";
         unless ($rem =~ /^\s*;/s) {
            $rest = $rem . $rest;
            $statement = substr($statement, 0, index($statement, $rem));
            # print "mcall: $rem put back\n";
            }
         }
         else {      # we should still check if there is extra stuff
         }
			$self -> parse_mcall($statement);
      }   
   }  ## End of macro statement

   elsif ($text =~                     ## C-style comment
         m{\A\s*/\*            # opt. white space comment opener, then...
         (?:[^*]+|\*(?!/))*   # anything except */ ...
         \*/                    # comment closer
         (\s*)?               # trailing blanks or tabs
         }sx) {
      $statement = $&;
      $type = 'ccomment';
      $rest = $';
		$self -> parse_ccomment($statement);
   }
   
   elsif ($text =~ /\A\s*%\*[^;]*;\s*/s) {      ## macro comment statement
      $statement = $&;
      $rest = $';
      $type = 'mcomment';
   }

   elsif ($text =~ /\A\s*(\*|comment\b)[^;]*;\s*/is) {      ## comment statement
#   elsif ($text =~ /\A\s*\*[^;]*;\s*/ms) {      ## comment statement
      $statement = $&;
      $rest = $';
      $type = 'scomment';
   }
   elsif ($text =~ /\A\s+\Z/s) {
      $type = 'null';
   }

   else {
      my $near = substr($text,0,45);
      $near =~ s/^\s*//s;
      print "$self->{file}($lineno): Could not classify near '$near'\n";
      # try to recover -- get up to the next ;
      ($statement, $rest) = split(/;/, $text);
		$statement .= ';';
      $type = '?';
   }

#  Dispatch to special handling:
#	if (ref($parsers{$type}) eq 'CODE') {
#		$self->&{$parsers{$type}}($statement);
#	}

   #Whew!
   return 
      $statement,    # the text of the statement we parsed
      $type,         # its type
      $stmt,         # actual statement name, proc, or macro
      $rest;         # unparsed text

}

# Get or set eof flag to terminate parsing

sub eof {
   my $self = $_[0];
   
   if (defined($_[1])) {
      $self->{eof} = $_[1];
   }
   else {
      return $self->{eof};
   }
	
}

# Output method - simply print the info.  Meant to be overridden

sub output {
   my $self = shift;
	my ($lineno, $step, $type, $stmt, $statement) = @_;

	if ($lineno < 0) {
	   printf "%4s %-8s %-8s %s\n", qw(STEP TYPE STMT STATEMENT) unless $silent;
	}
	else {
#		printf "%3d ", $lineno;
		printf "%4s %-8s %-8s ", $step, $type, $stmt;
		print substr($statement, 0, &min(50,length($statement)));
		print " ..." if length($statement)>50;
		print "\n";
	}

}

###### Special parse-processing for some types of statements #####

# Parse a libname statement to determine libref and corresponding folder

sub parse_libname {		# $self->parse_libname($statement);
   my($self, $stmt) = @_;
   my ($libref, $dirname);
   $stmt =~ s/\A\s+//s;
   if ($stmt =~ 
      m|libname\s+         # statement start
        (\w+)              # the libref
        .+                 # maybe, an engine, ignored
        ['"]([^'"]+)['"]   # 'directory path'
        |soix)
          {
      $libref = $1;
      $dirname = $2;
      $dirname =~ s/\s*~/$ENV{HOME}/;
      # print "libref=$libref dirname=$dirname\n";
      $self->{libnames}{$libref} = $dirname;
   }
   else {
      print "$self->{file}($lineno): Failed to parse libname in $stmt\n";
   }
}

# Parse a filename statement to determine fileref and corresponding folder(s)
# We don't check that the path exists.

sub parse_filename {		# $self->parse_filename($statement);
   my($self, $stmt) = @_;
   my ($filename, $fileref, $pathlist, $rest, $devtype);
   my @paths;
   $stmt =~ s/\A\s+//s;
   if ($stmt =~
      m|filename\s+        # statement start
        (\w+)              # the fileref
        \s+                # eat whitespace
        (\w*)\s*           # optional devtype
        |soix)
      {
         $fileref= $1;  $devtype= $2;
         $rest = $';

			# We don't handle pipes or other non-disk filename statements
			if ($devtype =~ /dummy|pipe|printer|tape|terminal|ftp/i) {
				return;
			}
         _trace("fileref:1: $fileref $rest");
         if ($rest =~ /^\(/)   #aggregate, balance )
            {
            my $pathlist = extract_bracketed($rest,'()');
            $pathlist =~ s/^\(//;   # balance ) (
            $pathlist =~ s/\)$//;
            #print "fileref:2a: $fileref $pathlist\n";
            @paths = split(',\s*', $pathlist);
            }
         elsif ($rest =~ /["']([^"']+)["']/) 
            {
            _trace("fileref:2b: $fileref $1");
            push (@paths, $1);
            }
         
         foreach (@paths) {
            s/^\s*["']//;
            s/\s*['"]//;
            s/\s*~/$ENV{HOME}/;
         }
         $pathlist = join(' ', @paths);
         #print "fileref:3 : $fileref -> $pathlist\n";
         $self->{filenames}{$fileref} = $pathlist;
      }
   else {
      print "$self->{file}($lineno): Failed to parse filename in $stmt\n";
   }
}

# Parse %include statement to determine pathname of include file(s).
# For this to work, we must have seen and parsed the filename statements
# for any %include fileref or %include fileref(file).

# Returns:  the resolved pathname of the included file, if it exists.

# We don't actually include the file.  Leave that to the higher-ups.

sub parse_include {		# $file = $self->parse_include($statement);
   my($self, $stmt) = @_;

   my @files;
   
   $stmt =~ s/\A\s*%include\s+//s;
   $stmt =~ s/\s*;\s*//s;
   $stmt =~ s|/.*$||;      # remove options

   @files = split(/\s+/, $stmt);
   foreach $this (@files) {
      undef $file;
      _trace("include: $this");
      if ($this =~ m/(['"])([^"']+)\1/) {      #   physical 'file.sas'
         $file = $2 if -e $2;
      }
      elsif ($this =~ m/\w+$/) {               # fileref or ./file.sas
         # which takes precedence -- we try './file.sas' first
         if (-e "$this.sas") {
            $file = $this . ".sas";
         }
         else {      # check filerefs that we know
            if (defined ($self->{filenames}{$this})) {
               _trace("include: found fileref");
               $file = $self->{filenames}{$this};
            }
         }
      }
      elsif ($this =~ m/(\w+)\((\w+)\)/) {   # fileref aggregate ?
         $fileref = $1;
         $file = $2;
         if (defined ($self->{filenames}{$fileref})) {
            $fileref = $self->{filenames}{$fileref};
            # may be a \s separated list of paths to search
            foreach $dir (split(' ', $fileref)) {
               if (-e $dir . $SL . "$file" . '.sas') {
                  $file = $dir . $SL . "$file" . '.sas';
                  last;
               }
            }
         }
         _trace("include:: $fileref -> $file");
      }
      else {
         print "$self->{file}($lineno): Failed to recognize %included file $this\n";
      }
      if ($file) {
         _trace("include::: $file");
			$self->includes($file);
			return $file;
      }
      else {
         print "$self->{file}($lineno): Failed to find %included file $this\n";
			return undef;
      }
   }
}

# Parse a data statement, finding all dataset names created, and storing
#	these in $self->{datasets}.
#	We don't bother distinguishing between permanent and temporary datasets.
#	We handle (implicit) _data_, but don't resolve to DATA1, DATA2, etc.
#  (because we're not parsing other statements which may use _data_)

sub parse_data {		# $self->parse_data($statement);
   my($self, $text) = @_;

   my @datasets;
	my ($dsn, $opts);

	my $dsn_pat = '[A-Za-z]\w{0,7}'			# libname or dsn
					. '\.?[A-Za-z]?\w{0,7}';	# followed by dsn
	$dsn_pat = '[\w.]+';

   $text =~ s/\A\s*data\s*//is;
   $text =~ s/\s*;\s*$//s;
	
	if (length($text)==0) {	
		push (@datasets, '_data_');
	}
	else {
		while ($text) {
			last if $text =~ /^\s*$/s;
			if ($text =~ m/^\s*&($dsn_pat)\s*/s) {		# ignore macro dsns
				 $text = $'; next;
			}
			if ($text =~ m/^\s*($dsn_pat)\s*/s) {
				$dsn = lc($1); $text = $';
				_trace("parse_data: dsn=$dsn");
				push (@datasets, $dsn);
			}
			elsif ($text =~ /^\(/s) {		# bal )
				# ignore dataset options
				($opts, $text) = &extract_bracketed($text, '()');
			}
			else {
				print "$self->{file}($lineno): "
					. "Failed to parse data set name or option at $text\n";
				return;
			}
		}
	}

	_trace("parse_data: found ", join(' ', @datasets));
	foreach $dsn (@datasets) {
		$self->datasets($dsn) unless $seen{'DATA' . $dsn}++;
	}
}

sub parse_mstmt {		# $self->parse_mstmt($statement);
   my($self, $stmt) = @_;

   #  handle %let statement separately to find function macro calls
	# SAS system macro functions to ignore
	my @macro_funcs =
    	qw(str nstr quote nrquote bquote nrbquote superq
			q?cmpres index q?left length q?lowcase q?scan q?substr trim q?upcase verify
			datatyp eval sysevalf q?sysfunc);
   my $mfuncs = '(%' . join('|%', @macro_funcs) . ')';
   
   if ($stmt =~
      m|%let\s+        # statement start
        (\w+)              # the macro variable
        \s*=                # eat whitespace
        %(\w*)\s*           # macro function
        |soix)
      {
	  my $mfunc = $2;
	  if (! $mfunc =~ m/$mfuncs/) {
         $self->macros($mfunc) unless $seen{'MCALL' . $mfunc}++;
	  	}
	  }
}

##########################
# Stubs for other specialized statement parsers.  Can override.

sub parse_assign {		# $self->parse_assign($statement);
   my($self, $stmt) = @_;
}

sub parse_ccomment {		# $self->parse_ccomment($statement);
   my($self, $stmt) = @_;
}

sub parse_global {		# $self->parse_global($statement);
   my($self, $stmt) = @_;
}

sub parse_mcall {		# $self->parse_mcall($statement);
   my($self, $stmt) = @_;
}

sub parse_mdef {		# $self->parse_mdef($statement);
   my($self, $stmt) = @_;
}

sub parse_mend {		# $self->parse_mend($statement);
   my($self, $stmt) = @_;
}

sub parse_module {		# $self->parse_module($statement);
   my($self, $stmt) = @_;
}

sub parse_proc {		# $self->parse_proc($statement);
   my($self, $stmt) = @_;
}

sub parse_stmt {		# $self->parse_stmt($statement);
   my($self, $stmt) = @_;
}

########################
# Constructor / accessor for list of macros called.  If called with
# a (scalar) argument, that is pushed on the list. Otherwise, it returns
# the list of macros, as a list, if called in a list context, or as a
# string, if called in a scalar context.

my $sep = ' ';			# Separator used to join items in a scalar context

sub macros {
   my $self = $_[0];
   
   if (defined($_[1])) {
      push (@{$self->{macros}}, $_[1]);
   }
   else {
      return wantarray ? @{$self->{macros}} : join($sep, @{$self->{macros}});
   }
}

########################
# Constructor / accessor for list of macros defined.  If called with
# a (scalar) argument, that is pushed on the list. Otherwise, it returns
# the list of macros, as a list, if called in a list context, or as a
# string, if called in a scalar context.

sub macdefs {
   my $self = $_[0];
   
   if (defined($_[1])) {
      push (@{$self->{macdefs}}, $_[1]);
   }
   else {
      return wantarray ? @{$self->{macdefs}} : join($sep, @{$self->{macdefs}});
   }
}

########################
# Constructor / accessor for list of procs called.  If called with
# a (scalar) argument, that is pushed on the list. Otherwise, it returns
# the list of procs, as a list, if called in a list context, or as a
# string, if called in a scalar context.

sub procs {
   my $self = $_[0];
   
   if (defined($_[1])) {
      push (@{$self->{procs}}, $_[1]);
   }
   else {
      return wantarray ? @{$self->{procs}} : join($sep, @{$self->{procs}});
   }
}

########################
# Constructor / accessor for list of datasets defined.  If called with
# a (scalar) argument, that is pushed on the list; otherwise, it returns
# the list of datasets.

sub datasets {
   my $self = $_[0];
   
   if (defined($_[1])) {
      push (@{$self->{datasets}}, $_[1]);
   }
   else {
      return wantarray ? @{$self->{datasets}} : join($sep, @{$self->{datasets}});
   }
}

########################
# Constructor / accessor for list of includes defined.  If called with
# a (scalar) argument, that is pushed on the list; otherwise, it returns
# the list of includes.

sub includes {
   my $self = $_[0];
   
   if (defined($_[1])) {
      push (@{$self->{includes}}, $_[1]);
   }
   else {
      return wantarray ? @{$self->{includes}} : join($sep, @{$self->{includes}});
   }
}

########################
# Constructor / accessor for list of modules defined.  If called with
# a (scalar) argument, that is pushed on the list; otherwise, it returns
# the list of modules.

sub modules {
   my $self = $_[0];
   
   if (defined($_[1])) {
      push (@{$self->{modules}}, $_[1]);
   }
   else {
      return wantarray ? @{$self->{modules}} : join($sep, @{$self->{modules}});
   }
}

########################
# Constructor / accessor for hash of libnames defined.  If called with
# a (scalar) argument, that is pushed on the list; otherwise, it returns
# the hash of libnames.

sub libnames {
   my $self = $_[0];
   
   if (defined($_[1]) && defined($_[2])) {
      ${$self->{libnames}}{$_[1]} = $_[2];
   }
   else {
      return %{$self->{libnames}};
   }
}

########################
# Constructor / accessor for hash of filenames defined.  If called with
# a (scalar) argument, that is pushed on the list; otherwise, it returns
# the hash of filenames.

sub filenames {
   my $self = $_[0];
   
   if (defined($_[1]) && defined($_[2])) {
      ${$self->{filenames}}{$_[1]} = $_[2];
   }
   else {
      return %{$self->{filenames}};
   }
}


########################
# Constructor / accessor for list of stored statements.  If called with
# a (list) argument, that is pushed on the list; otherwise, it returns
# the list of stored statements.

sub stored {
   my $self = shift;
   
   if (scalar(@_)) {
      push (@{$self->{stored}}, [@_]);
   }
   else {
      return @{$self->{stored}};
   }
}

sub min { 
   local($a, $b) = @_; ($a > $b ? $b : $a); 
}

# Read a file, given filename (complete path) or filehandle (assumed
# open).  Returns the file contents or undef if not found.

sub readfile($)
{
   local $/;
   undef $/;
   my $file =$_[0];
	
	no strict 'refs';  # so that a symbol ref as $file works
   local(*FILE);
   unless (ref($file) || $file =~ /^\*[\w:]+$/) {
		# Assume $file is a filename
		$file =~ s/^~/$ENV{HOME}/;
	   $file = (-e $file) ? $file : "$file.sas";
		open(FILE, $file) || return undef;
		$file = \*FILE;
   }

	my $contents = <FILE>;
	close FILE;
	return $contents;
}

sub find_autoexec {
   # Find autoexec.sas file
   #
   my ($autoexec, $dir);
   my @dirs;
   # if $ENV{SAS_OPTIONS} defines -autoexec, look there first
   if ($ENV{SAS_OPTIONS} && $ENV{SAS_OPTIONS} =~ /-autoexec\s+(\S+)/) {
      $autoexec = $1;
      return $autoexec if -e $autoexec;
      }

   # otherwise, check current dir, ~, and SASROOT
   @dirs = ( '.', "$ENV{HOME}", "$ENV{SASROOT}" );
   foreach $dir (@dirs) {
      $autoexec = $dir . $SL . 'autoexec.sas';
      return $autoexec if -e $autoexec;
   } 
   return undef;
}

sub remove_comments {
   my $text = shift;
   $text =~
         s{/\*                 # comment opener, then...
         (?:[^*]+|\*(?!/))*    # anything except */ ...
         \*/                   # comment closer
         }
         { }gsx;               # replace by one space
   $text =~ s/\s+/ /g;         # compress multiple
   return $text;
}

# Protect special characters (; or ,) inside:
#    %str( ), %nstr( ), call execute(' ')
#    'quoted strings' like: vv = 'String can''t have a ; but it does';
#    "quoted strings" like: vv = "String with a quoted ';'";
#    Unfortunately, this is fooled by unmatched quotes.
#    (Thanks to Damian Conway for assistance)

sub protect_special {
   my $rest = shift;
	my $char = (defined $_[0]) ? $_[0] : ';';
	my $repl = $char eq ';' ? '#SEMI#' :
					(defined $_[1]) ? $_[1] : '#SPEC#';
   my ($out, $extracted, $pre, $match);
   $out = undef;

	my $quoting = 
			q{(?:%n?str|execute)\s*(?!\(\s*\))}    # more than just %str()
		.  q{|(?:'(?:[^']*(?:''[^']*)*)')}	      # or 'quoted' string
		.  q{|(?:"(?:[^"]*(?:""[^"]*)*)")};	      # or "quoted" string

   while ($rest =~ s/(.*?)($quoting)//sm) {

      ($pre, $match) = ($1, $2);

      if ($match =~ /^['"]/) {
         $match =~ s/$char/$repl/g;
         $out .= $pre . $match;
      }
      else {
         ($extracted, $rest) = extract_bracketed($rest, q{('")});	#"'
         $extracted =~ s/$char/$repl/g;
         $out .= $pre . $match . $extracted;
      }
   }
   $out .= $rest;
   return $out;
}

# dont forget to return the
1;

__END__
