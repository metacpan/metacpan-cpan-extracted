package SAS::Header;

use SAS::Parser;
@ISA = qw(SAS::Parser Exporter);

use vars qw($VERSION $DEBUG $width $indent $frame);

$VERSION = sprintf("%d.%02d", q$Revision: 0.91 $ =~ /(\d+)\.(\d+)/);

@EXPORT = qw(
	makeheader 
	macdescribe 
	macdesc_head 
	macdesc_arg 
	macdesc_tail 
	margs 
	box 
	get_title 
	get_author 
	get_version 
	get_doc
	date 
	unbox 
	rebox 
);  # symbols to export by default

=head1 NAME

SAS::Header - Create a documentation header comment for a SAS program

=head1 SYNOPSIS

 use SAS::Header;
 $p = new SAS::Header;
 $p->parse_file('mysas.sas');       # returns a SAS::Parser object
 $header = $p->makeheader();        # extract info and format the header

 my @macdefs = $p->macdefs();       # any macros defined?
 foreach (@macdefs) {
   $header .= $p->macdescribe($_);  # describe args, append to header
   }


=head1 DESCRIPTION

I<SAS::Header> is a sub-class of SAS::Parser which parses a SAS file
and creates a block-comment header.  It can also generate descriptions
of SAS macros found in the file.  It is designed to make a reasonably
good start on documentation, which would then be edited or extended
manually.

It overrides the parse_ccomment() and parse_mdef() methods from
SAS::Parser to extract additional information for this purpose.

=head2 Methods

The following methods are defined in the SAS:Header class.

=over 4

=item $p -> parse_file($filename)

Calls the SAS::Parser parse_file() method with the options
silent=>1, trim=>0, store=>'global|ccomment'.  

=item $header = $p -> makeheader()

Call makeheader() after the file has been parsed.  makeheader()
extracts the following information from the SAS::Header object:
name, title, doc, procs called, datasets created, macros defined, macros
called, author, created, revised, version.

Each item is formatted as a line of the form:

    Key: Information

e.g.,

   Name: filename.sas
  Title: Description of what I do

and then the collection of lines is formatted as a boxed /* ... */
comment, whose width is determined by the variable C<$SAS::Header::width>.
Any ``Information'' portion which would exceed C<$SAS::Header::width>
is wrapped so that successive lines are indented.

The keys that appear in the header are determined dynamically from
an array, C<@headitems>, whose default value is

	@headitems = qw(
		name title doc SEP
		procs macdefs macros datasets modules SEP
		author created revised version);

where C<SEP> stands for a separator line.  An application may change
this array to alter the items or their order in the header.
However, only those keys which have some content from the current
file actually appear in the header.

This boxed comment is returned as a "\n" separated string.

=item $p->parse_ccomment($statement)

This method is used to override the default parse_ccomment() method
of the SAS::Parser class, so that any information present in an
existing program header may be found during the initial parsing.

As defined here, this method ignores all C-comments contained within a
PROC or DATA step.  For other C-comments, it looks for strings with the
following keywords:

  Author:
  Created:
  Doc:
  Title:
  Version:

The keyword may be in upper, lower, or mixed case, but must be followed
by (optional whitespace) and a ':'.  When such a line is found, a
corresponding entry is added to the SAS::Header object, and later used
by makeheader().  E.g., the Author information would be stored or
accessed as C<$p-E<gt>{author}>.

=item $author = $p->get_author()

Returns an author string extracted from the parse.  If an author was found
by parse_ccomment(), that string is returned.  Otherwise, the get_author()
method assumes the current user is the author, and returns a string
composed from the USER and HOST environment variables.  On systems which
have NetInfo installed, L<nidump(8)> is called to get the user's real name.


=item $title = $p->get_title()

Returns a title string extracted from the parse.  If a title was found
by parse_ccomment(), that string is returned.  Otherwise, the get_title()
method tries harder, by examining the $p->stored() statements, 
-- either /* ... */ comments, or TITLE statements,
until something reasonable is found.

=item $version = $p->get_version()

Returns a version string extracted from the parse.  If a version was found
by parse_ccomment(), that string is returned.  Otherwise, the get_version()
method returns undef.

=item $doc = $p->get_doc()

Returns a 'Doc' string (a pointer to external documentation or a web URL)
extracted from the parse.  If a doc string was found
by parse_ccomment(), that string is returned.  Otherwise, the get_doc()
method returns undef.

=item $desc = $p -> macdescribe('mymacro', ['plain'|'pod'|'html'])

Generates a description of a macro and its arguments from information
collected by the parse_mdef() method during the parse.  The (optional)
second parameter determines the style of the macro description
text.  The current version recognizes 'plain', 'pod' and 'html' styles.

It is assumed that the goal of using macdescribe() is to generate a
basic stub for documentation from the available information, which
is then edited to provide more details, as necessary.

The description distinguishes between positional and keyword
arguments, and has the following format in the 'plain' style:

  /*=
 =Description:

  The COMBOS macro ...

 =Usage:

  The COMBOS macro takes 2 positional arguments and 8 keyword arguments.
 
 ==Parameters:

 * THINGS             The N things to combine
 * SIZE               Size (K) of each combination
 * INCLUDE=           Items which must be included
 ...
 =*/

Descriptive text for each argument is taken from comments in the
%macro statement.  See parse_mdef() for details.

If no descriptive text is found for a given argument, an associative
array (C<%stdargs>) is consulted for an appropriate description.  For
example, a DATA= argument is given the description from

	'DATA' => 'The name of the input data set',

You can add to, or modify the default standard text simply by (re-)defining
an argument-name keyword (in uppercase) in %stdargs, e.g.,

	$stdargs{DATA} = "Le nom de l'ensemble de donnees d'entree";
	$stdargs{VAR} = "Le(s) nom(s) de(s) variable(s) d'analyse";

(there's no support for accents yet).

You can also modify the names of the sections of the macro description,
and the text used therein, but for now you'll have to read through the
code to find out how.


=item parse_mdef($statement)

The parse_mdef method parses a %macro statement to determine
arguments, defaults, and brief descriptions.  It stores in the
parser object a list-of-lists, each item of which contains 

  [$arg, $argtype, $default, $desc]

for one argument.

parse_mdef() assumes that the %macro statement has the following
format, where each keyword argument is followed by and '=' sign
and optional default value.  Each argument is followed by a ',',
and may be followed by one or more comments, which are combined as
the argument description.

 %macro combos(
	things,         /* the N things to combine           */
	/* more descriptive text */
	/* and one more */
	size,           /* size (K) of each combination      */
	include=,		 /* items which must be included      */
	out=out,        /* output data set containing combos */
	sep=%str( ),    /* separator within each combo       */
	join=%str(, ),  /* separator to join all combos      */
	result=combos,  /* name of macro result variable with all
	                   combinations */
	);

=item $self->margs('name') 

Accessor for the list of macro arguments.  If called with
one argument, it returns the list of macro arguments for the given
macro.
   
=item $self->margs('name', 'arg', 'type', 'default', 'desc')

Constructor for the list of macro arguments.
It pushes the remaining (list) argument on the
list of macro arguments.


=back 4

=head2 Formatting C-comments

The following subroutines are used to process /* ... */ comments:

=over 4

=item $boxed = &box($text)

Creates a boxed multi-line /* ... */ comment where each line is of
width C<$SAS::Header::width>, and preceeded by C<$SAS::Header::indent>
spaces.  The default indent is 1, because some systems (MVS) have
difficulty with '/*' starting in column 1.  

The default frame
characters used are '--||', corresponding to top, bottom, left,
and right, and may be changed by re-assigning to the variable
C<$SAS::Header::frame>.  Note that any trailing frame characters
which are unassigned are simply empty, so the string '--' omits
the left and right frame characters, and the string ' ' omits
them all.

box() assumes that all lines have been previously folded if necessary
to fit given width.  Any longer lines are silently truncated.

=item $unboxed = &unbox($text)

Takes a string containing a boxed multi-line /* ... */ comment and
removes the left and right frame characters and leading and trailing
spaces from each line, and an initial and trailing line of decorators.
The set '*-=|#' are treated as frame characters.

=item $boxed = &rebox($text)

Takes a string containing a boxed multi-line /* ... */ comment and
reformats it as a new boxed comment with the current width, indent,
and frame variables.

=back 4

=head1 BUGS

There are no bugs, except those inherited from SAS::Parser.

=cut


BEGIN	{
	$width = 70;  				# header width
	$indent = 1;				# header indent
	$frame = '--||';			# header frame chars: top, bot, left, right
	$DEBUG = 0;
}

sub new
{
    my($class) = @_;

    my $self = $class->SUPER::new;
    $self;
}

sub parse_file {
	my $self = shift;
	my $file = shift;
	my %options = # defined $_[0] ? %{$_[0]} :
		(
		silent => 1,
		trim   => 0,
		store  => 'global|ccomment',
		);
	$self->SUPER::parse_file($file, \%options);
	$self;
}

#  Items in the header

my @headitems = qw(
	name title doc SEP
	procs macdefs macros datasets modules SEP
	author created revised version);
	
sub makeheader {
	my $self = shift;
	my $head;

	# standard information
	my $name = $self->{file};
	   $name =~ s|.*[\/]||;			# strip any leading path
	my $procs = $self->procs();
	my $macros = $self->macros();
	my $macdefs = $self->macdefs();
	my $datasets = $self->datasets();
   my $modules = $self->modules();
	
	# additional info, for SAS::Header
	my $date = (stat $file)[9];
	my $created = (defined($self->{created}))  
					? $self->{created} : date($date);
	my $title   = $self->get_title();
	my $author  = $self->get_author();
	my $version = $self->get_version();
	my $doc     = $self->get_doc();
		
	my $SEP = '-' x $width . "\n";

	my @headlines = ();
	my $headcode = '';
	foreach (@headitems) {
		$headcode .= "push(\@headlines, "  
			. "&fmt('$_', \${$_})) if \${$_}"
			. ";\n"
	}
#	print "HEADCODE:\n$headcode";
	eval $headcode || print $@;
	$head = join('', @headlines);
#	print "HD:\n$hd";
	
	## top section - always
#	$head  = &fmt('name', $file)
#			 . &fmt('title', $title);
#	$head .= &fmt('doc', $doc)           if $doc;
#	$head .= $SEP;

	## middle section - maybe
#	$head .= &fmt('procs', $procs)       if $procs;
#	$head .= &fmt('macdefs', $macdefs)   if $macdefs;
#	$head .= &fmt('macros', $macros)     if $macros;
#	$head .= &fmt('datasets', $datasets) if $datasets;
#	$head .= &fmt('modules', $modules)   if $modules;
#	$head .= $SEP if ($procs||$macdefs||$macros||$datasets||$modules);

	## bottom section - always
#	$head .= &fmt('author', $author)     if $author;
#	$head .= &fmt('created', $created);
#	$head .= &fmt('revised', date($date));
#	$head .= &fmt('version', $version) if $version;

	return &box($head);
}

# Format one header item

sub fmt {
	my ($tag, $text) = @_;
	
	return $text if $tag eq 'SEP';
	
	$text =~ s/\s*\n?$//;
	
	my $t = sprintf("%8s: %s\n", ucfirst($tag), $text);
	local $columns = $width - 5;
	$t = &wrap("", " " x 10, $t);
	return $t;
}

# We use Text::Wrap to fold long lines, but suppress the transformation
# of tabs back to spaces by re-defining unexpand as a no-op.

# Not sure why, but it doesn't work if I just import from Text::Wrap
#use Text::Wrap;

use Text::Tabs qw(expand);
sub unexpand {return shift;};

## from Text::Wrap, but without tab re-expansion
sub wrap
{
	my ($ip, $xp, @t) = @_;

	my $r = "";
	my $t = expand(join(" ",@t));
	my $lead = $ip;
	my $ll = $columns - length(expand($lead)) - 1;
	my $nl = "";

	# remove up to a line length of things that aren't
	# new lines and tabs.

	if ($t =~ s/^([^\n]{0,$ll})(\s|\Z(?!\n))//xm) {

		# accept it.
		$r .= unexpand($lead . $1);

		# recompute the leader
		$lead = $xp;
		$ll = $columns - length(expand($lead)) - 1;
		$nl = $2;

		# repeat the above until there's none left
		while ($t) {
			if ( $t =~ s/^([^\n]{0,$ll})(\s|\Z(?!\n))//xm ) {
				print "\$2 is '$2'\n" if $debug;
				$nl = $2;
				$r .= unexpand("\n" . $lead . $1);
			} elsif ($t =~ s/^([^\n]{$ll})//) {
				$nl = "\n";
				$r .= unexpand("\n" . $lead . $1);
			}
		}
		$r .= $nl;
	} 

	die "couldn't wrap '$t'" 
		if length($t) > $ll;

	print "-----------$r---------\n" if $debug;

	print "Finish up with '$lead', '$t'\n" if $debug;

	$r .= $lead . $t if $t ne "";

	print "-----------$r---------\n" if $debug;
	return $r;
}

## Override the parse_comment method to extract information from an
## existing header: Author, Title, Created, Version, Doc.

#  For efficiency, we stop trying inside a DATA or PROC step.
#  Dont call eof() because we want to find all the procs, etc.

sub parse_ccomment {		# $self->parse_ccomment($statement);
   my($self, $stmt) = @_;
	
	return unless $step eq '';

	$stmt = &unbox($stmt);
	my @lines = split(/\n/, $stmt);
	foreach (@lines) {
		if (/(author|title|created|version|doc)\s*:\s*/i) {
			my $info = lc($1);
			my $rest = $';
			$rest =~ s/\s*$//;
			$rest =~ s/\s+/ /g;
			#print "$info :: $rest\n";
			$self->{$info} = $rest;
		};
	}
}

my %stdargs = (
	'DATA' => 'The name of the input data set',
	'VAR'	 => 'The name(s) of the variable(s) to be analyzed',
	'ID'   => 'The name of an observation ID variable',
	'BY'   => 'The name(s) of one or more BY variables',
	'OUT'  => 'The name of the output data set',
	'NAME' => 'The name of the graph in the graphic catalog',
	'GOUT' => 'The name of the graphics catalog',
);

## Generate a description of a macro and its arguments

my $macdesc_default_style = 'plain';

sub macdescribe {
   my($self, $mac) = @_;
	my $self = shift;
	my $mac  = shift;
	my $desc;
	local $macdesc_style = shift || $macdesc_default_style;
	
	#avoid boo-boos
	$macdesc_style =  $macdesc_default_style
#		unless $macdesc_style =~ join('|',qw(plain pod));
		unless defined(&{('macdesc_head_' . $macdesc_style)});
	
	my @args = $self->margs($mac);
	my $name = uc($mac);

	my $nargs = scalar @args;    # number of macro arguments
	my $pargs;                   # number of positional arguments
	my $kargs;                   # number of keyword arguments
	foreach (@args) {
		my ($arg, $argtype, $def, $des) = @{$_};
		$pargs++ if $argtype eq 'P';
		$line = &macdesc_arg(@{$_});
		$desc .= $line;
		}
	$pargs = $pargs ? "$pargs positional arguments" : undef;
	$kargs = $nargs - $pargs;
	$kargs = $kargs ? "$kargs keyword arguments" : undef;
	$args = $pargs . (($pargs && $kargs) ? " and " : "") . $kargs;
	
	my $desc_head = &macdesc_head($name, $args);
	$desc = " /*=\n" . $desc_head . $desc;	
	$desc .= &macdesc_tail;
	$desc .= " =*/\n\n";
	return $desc;
}

# Schema for macro description -- single quotes so not interpolated now
#  sections = string of level:section_name
#  section_name = string of title:text

my %macdesc_text = (
	sections =>  q(1:Description 1:Usage 2:Parameters),
	description => q{Description:\n\n The $name macro ...\n\n},
	usage => q{Usage:\n\n The $name macro takes $args.\n\n},
	parameters => q{Parameters:\n\n},
	example => q{Example:\n\n},
	);

sub macdesc_head {
	my ($name, $args) =@_;
	my $formatter = 'macdesc_head_' . $macdesc_style;
	return &$formatter($name, $args);
}

sub macdesc_head_plain {
	my ($name, $args) =@_;
	my ($desc_head, $level, $sec);
	
	foreach (split ' ', $macdesc_text{sections}) {
		my ($level, $sec) = split(/:/);
		$sec = lc($sec);
	 	$desc_head .= '=' x $level 
		. eval("qq[$macdesc_text{$sec}]");  # double-nasty-qq-interpolate
		}
	return $desc_head;
}

sub macdesc_head_pod {
	my ($name, $args) =@_;
	my ($desc_head, $level, $sec, $text);

	$desc_head = "=pod\n\n";
	foreach (split ' ', $macdesc_text{sections}) {
		my ($level, $sec) = split(/:/);
		$sec = lc($sec);
		#print "$sec:: $macdesc_text{$sec}\n";
		$text = eval("qq[$macdesc_text{$sec}]");  # double-nasty-qq-interpolate
		$text =~ s/(\w+):/\U$1\E/;
	 	$desc_head .= "=head$level " . $text
		}
	$desc_head .= "=over 4\n\n";
	#print "DESCHEAD\n$desc_head----\n";
	return $desc_head;
}

sub macdesc_head_html {
	my ($name, $args) =@_;
	my ($desc_head, $level, $sec, $text);
	
	foreach (split ' ', $macdesc_text{sections}) {
		my ($level, $sec) = split(/:/);
		$sec = lc($sec);
		$text = eval("qq[$macdesc_text{$sec}]");  # double-nasty-qq-interpolate
		$text =~ s|(\w+):|<H$level><a name="$name:$1">$1</a></H$level>|;
	 	$desc_head .=  $text ;
		}
	$desc_head .= "<DL>\n";
	return $desc_head;
}

sub macdesc_head_latex {
	my ($name, $args) =@_;
	my ($desc_head, $level, $sec, $text);
	
	foreach (split ' ', $macdesc_text{sections}) {
		my ($level, $sec) = split(/:/);
		$sec = lc($sec);
		$text = eval("qq[$macdesc_text{$sec}]");  # double-nasty-qq-interpolate
		my $sublev = '\\' . ('sub' x $level) . 'section';
#		$text =~ s|(\w+):|<H$level><a name="$name:$1">$1</a></H$level>|;
		$text =~ s|(\w+):|$sublev\{$1\}\\label{$name:$1}|;
	 	$desc_head .=  $text ;
		}
	$desc_head .= "\\begin{description}\n";
	return $desc_head;
}

# Format one macro argument

sub macdesc_arg {
		my ($arg, $argtype, $def, $des) = @_;
		$arg = uc($arg);

		if ($des) {
			$des =~ s/^\s*//;
			$des = ucfirst($des);
		}
		elsif (defined($stdargs{$arg})) {
			$des = $stdargs{$arg};
		}
		my $formatter = 'macdesc_arg_' . $macdesc_style;
		return &$formatter($arg, $argtype, $def, $des);
}

sub macdesc_arg_plain {
		my ($arg, $argtype, $def, $des) = @_;
		my $line;

		$line = "* " . $arg;
		$line .= "=$def" if $argtype eq 'K';
		$line .= ' ' x (20-length($line));
		$line .= ' ' if substr(reverse($line),0,1);
		$line .= $des if $des;

#		$line = wrap("", " " x 10, $line);
		#print "$arg\t:$def\t:$des\n";
		$line .= "\n\n";
		return $line;
}

sub macdesc_arg_pod {
		my ($arg, $argtype, $def, $des) = @_;
		my $line;

		$line = "=item B<$arg>";
		$line .= "\t[Default: $def]" if $argtype eq 'K';
		$line .= "\n\n$des" if $des;
		$line .= "\n\n";
		return $line;
}

sub macdesc_arg_html {
		my ($arg, $argtype, $def, $des) = @_;
		my $line;

		$line = qq{<DT><a name="arg_$arg">$arg</a>};
		$line .= "\n<DD>$des" if $des;
		$line .= "\t[<em>Default</em>: $def]" if $argtype eq 'K' && $def;
		$line .= "\n";
		return $line;
}

sub macdesc_arg_latex {
		my ($arg, $argtype, $def, $des) = @_;
		my $line;
		$def =~ s/^\s+//;
		$arg .= "=" if $argtype eq 'K';

		$line = qq{ \\item[$arg]};
		$line .= "\n  $des" if $des;
		$line .= "\n  \\default{$arg" . uc($def)."}" if $argtype eq 'K' && $def;
		$line .= "\n";
		return $line;
}

sub macdesc_tail {
	my $formatter = 'macdesc_tail_' . $macdesc_style;
	return &$formatter;
}

sub macdesc_tail_plain {};

sub macdesc_tail_pod {
	return "=back 4\n\n=cut\n";
}

sub macdesc_tail_html {
	return "</DL>\n";
}

sub macdesc_tail_latex {
	return "\\end{description}\n";
}

# Parse a %macro statement to determine arguments, defaults, and
# brief descriptions.  Stores a list-of-lists, each item of which
# contains [$arg, $argtype, $default, $desc]

sub parse_mdef {		# $self->parse_mdef($statement);
   my($self, $stmt) = @_;
	
	my $sasname = '\w+\b';
	my $comment =
         '/\*'                   # comment opener, then...
       . '(?:[^*]+|\*(?!/))*'    # anything except */ ...
       . '\*/'                   # comment closer
			;
	
	my ($args, $mac, $arg, $default, $desc);
	my @args;

	$stmt =~ m/%macro\s+($sasname)/;
	$mac = lc($1);                     # macro name
	($args = $stmt) =~ s/^.*\(\s*//;   # remove %macro name(		# bal )) (
	$args =~ s/\s*\)\s*;\s*$/,/s;		  # replace closing paren by , 
	$args =~ s/\n\s*/ /smg;
	$args =~ s/\s+/ /g;
	$args = &protect_special($args, ',', '#COMMA#');
	
	#print "$mac ::$args\n\n";

	# split the args string into chunks, each of which is either an arg
	# (or arg=default), or a comment.  Comments first, in case they
	# include ','.
	my @list = split(/($comment|[,])/, $args);

	# comments usually come after the arg and default
	
	foreach $item (@list) {
		$item =~ s/^\s*(.*)\s*$/$1/;
		next unless $item;
		next if $item eq ',';
		if ($item =~ m/^($sasname)\s*(=?)/) {

			if (defined($arg)) {
		#		print "[$type] $arg, $argtype, $default, $desc\n";
		#		push @args, [$arg, $argtype, $default, $desc];
				$self->margs($mac, $arg, $argtype, $default, $desc);
			}
			undef $desc;
			undef $default;
			$arg = $1;
			$argtype = $2 ? 'K' : 'P';
			$default = $';
			$default =~ s/#COMMA#/,/g;
			$type = 'ARG';
			#next;		
		}
		# Accumulate a description from one or more comments.
		elsif ($item =~ m{/\*}) {
			$des = $item;
			$des =~ s|\s*/\*\s*||g;
			$des =~ s|\s*\*/||g;
			$desc = join(' ', $desc, $des);
			$type = 'DESC';
		}
	}
	# do the last one
	$default =~ s/#COMMA#/,/g;
#	print "[$type] $arg, $argtype, $default, $desc\n";
#	push @args, [$arg, $argtype, $default, $desc];
	$self->margs($mac, $arg, $argtype, $default, $desc);
	
}

# Parse IML start() statement to determine arguments, defaults, and
# brief descriptions.  Stores a list-of-lists, each item of which
# contains [$arg, $desc]

sub parse_module {		# $self->parse_module($statement);
   my($self, $stmt) = @_;
	
	my $sasname = '\w+\b';
	my $comment =
         '/\*'                   # comment opener, then...
       . '(?:[^*]+|\*(?!/))*'    # anything except */ ...
       . '\*/'                   # comment closer
			;
	$stmt =~ m/start\s+($sasname)\s*\(?/;
	my $mod = lc($1) || 'MAIN';                   # module name
	my $args = $';
	if ($args =~ s/global\s*\(([^)]+)\)//) {
		my $globals = $1;
		$globals =~ s/\s+//smg;
		my @globals = split(/,/, $globals);
	}
	$args =~ s/\s*;\s*$//s;		  # remove ; 
	$args =~ s/\s*\)$//s;		  # remove closing paren 
	$args =~ s/\s+//smg;
	
	my @args = split(/,/, $args);
	#print "$mod ::$args\n   $globals\n";
}

########################
# Constructor / accessor for list of macro arguments.  If called with
# one argument, it returns the list of macro arguments for the given
# macro.  Otherwise, it pushes the remaining (list) argument on the
# list of macro arguments.

sub margs {
   my $self = shift;
	my $mac  = shift;
   
   if (scalar(@_)) {
      push (@{$self->{'MDEF' . $mac}}, [@_]);
   }
   else {
      return @{$self->{'MDEF' . $mac}};
   }
}



# Create a C-style boxed comment. Assumes all lines have been previously
# folded if necessary to fit given width.
# Uses global:  $width, $indent, $frame

sub box {
	my ($text) = shift;
	my @lines = split ("\n", $text);
	my ($line, $boxed);
	
	my $boxed;
	my $win = $width-$indent-4;
	my @f = split(/ */, $frame);
	$boxed  = ' ' x $indent . '/*' . $f[0] x $win . "*\n";
	foreach $line (@lines) {
		$line = ' ' . $line . ' ' x $width;
		$line = substr($line,0, $win);
		$boxed .= ' ' x ($indent+1) . $f[2] . $line   . $f[3] . "\n";
	}
	$boxed .= ' ' x ($indent+1) . '*' . $f[1] x $win . "*/\n";
	return $boxed;
}

# Format a filemod time, as 17-Jan-97 12:34.  Uses current time() if 
# no arg.
sub date {

    local($time) = shift || time();
    local($[) = 0;
    local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
    local(@MoY) = ('Jan','Feb','Mar','Apr','May','Jun',
	    'Jul','Aug','Sep','Oct','Nov','Dec');
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($time);
	 $year = $year+1900;     # Y2K !!
    sprintf("%02d %3s %4d %02d:%02d:%02d", 
	 	$mday, $MoY[$mon], $year, $hour, $min, $sec);
}

# Find something reasonable to use for a title from the stored statements
# -- either in a leading /* ... */ comment, or in a title statement,
# unless a title has already been defined.
# First one wins.  Assumes that global and ccomment statements were
# stored.

sub get_title {
	my $self = shift;
	my $title;

	return $self->{title} if defined($self->{title});	

	my @stored = $self->stored();
	foreach $s (@stored) {
		my ($lineno, $step, $type, $stmt, $statement) = @$s;

		# find first line in a C-comment containing 'Title:'
		if ($type eq 'ccomment' && $statement =~ /title\s*:/i) {
			$title = $';
			($title) = (split(/\n/, $title))[0];
			$title =~ s/^\s*//;
			$title =~ s{\s*[|*/]?\s*$}{};
			last;
		}
		# or, the first title statement
		elsif ($stmt eq 'title') {
		#  remove h=, f=, etc;
			$title = $statement;
			$title =~ s/((h|height)\s*=\s*[\d.]*\s)|((f|font)\s*=\s*[\w]*)//i;
			$title =~ s/title\d?\s+['"]?//;
			$title =~ s/['"]?\s*;.*$//;
			last;
		}
	}
#	chomp($title);
	return $title;
}

sub get_author {
	my $self = shift;
	# if we have already seen an Author:, return that.
	return $self->{author}  if defined($self->{author});
	
	# otherwise, get information from environment, assuming current user
	# is the author.
	my $user = $ENV{USER};
	my $host = $ENV{HOST} || `hostname`;
	my $author ="<$user\@$host>";
	my $name;

	# Try to use nidump to get name from netinfo database
	# On AIX there's the lsuser command, but with different format
	if (-x '/usr/bin/nidump') {
		my $ninfo = `nidump passwd .`;
		#print "Trying nidump for $author\n";
		foreach (split(/\n/, $ninfo)) {
			($u, $name) = (split(':'))[0, 4];
			if ($u eq $user) {
				$author = $name . " $author";
				last;
			}
		}
	}
	return $author;	
}

sub get_version {
	my $self = shift;

	return $self->{version}  if defined($self->{version});
	return undef;
}	

sub get_doc {
	my $self = shift;

	return $self->{doc}  if defined($self->{doc});
	return undef;
}	

# Remove frame characters around a boxed comment

sub unbox {
	my $text = shift;
	my @lines = split ("\n", $text);
	
	unshift @lines if $lines[0] =~ m{(#|/\*)[\s*-=#]{2,}$};
	pop @lines if $lines[-1] =~ m{[\s*-=#]{2,}\*/};
	
	foreach (@lines) {
		s|^\s*/*\s*||;
		s|\s*\*/\s*$||;
		s/^\s*[*-=|#]+\s*//;
		s/\s*[*-=|#]+\s*$//
	}
	return join("\n",@lines) . "\n";
}

# Reformat a boxed comment.  Might want to fold paragraphs, but not now.

sub rebox {
	my $text = shift;

	$text = &unbox($text);
	my @para = split(/\n\n/, $text);
	foreach (@para) {
	}
	$text = &box($text);
}

1;
