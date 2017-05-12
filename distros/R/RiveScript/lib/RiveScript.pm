package RiveScript;

use strict;
use warnings;

# Version of the Perl RiveScript interpreter. This must be on a single line!
# See `perldoc version`
use version; our $VERSION = version->declare('v2.0.3');

our $SUPPORT = '2.0';  # Which RS standard we support.
our $basedir = (__FILE__ =~ /^(.+?)\.pm$/i ? $1 : '.');

# Constants.
use constant RS_ERR_MATCH => "ERR: No Reply Matched";
use constant RS_ERR_REPLY => "ERR: No Reply Found";

# Exports
require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(RS_ERR_MATCH RS_ERR_REPLY);
our %EXPORT_TAGS = (
	standard => \@EXPORT_OK,
);

=head1 NAME

RiveScript - Rendering Intelligence Very Easily

=head1 SYNOPSIS

  use RiveScript;

  # Create a new RiveScript interpreter.
  my $rs = new RiveScript;

  # Load a directory of replies.
  $rs->loadDirectory ("./replies");

  # Load another file.
  $rs->loadFile ("./more_replies.rive");

  # Stream in some RiveScript code.
  $rs->stream (q~
    + hello bot
    - Hello, human.
  ~);

  # Sort all the loaded replies.
  $rs->sortReplies;

  # Chat with the bot.
  while (1) {
    print "You> ";
    chomp (my $msg = <STDIN>);
    my $reply = $rs->reply ('localuser',$msg);
    print "Bot> $reply\n";
  }

=head1 DESCRIPTION

RiveScript is a simple trigger/response language primarily used for the creation
of chatting robots. It's designed to have an easy-to-learn syntax but provide a
lot of power and flexibility. For more information, visit
http://www.rivescript.com/

=head1 METHODS

=head2 GENERAL

=over 4

=cut

################################################################################
## Constructor and Debug Methods                                              ##
################################################################################

=item RiveScript new (hash %ARGS)

Create a new instance of a RiveScript interpreter. The instance will become its
own "chatterbot," with its own set of responses and user variables. You can pass
in any global variables here. The two standard variables are:

  debug     - Turns on debug mode (a LOT of information will be printed to the
              terminal!). Default is 0 (disabled).
  verbose   - When debug mode is on, all debug output will be printed to the
              terminal if 'verbose' is also true. The default value is 1.
  debugfile - Optional: paired with debug mode, all debug output is also written
              to this file name. Since debug mode prints such a large amount of
              data, it is often more practical to have the output go to an
              external file for later review. Default is '' (no file).
  utf8      - Enable UTF-8 support for the RiveScript code. See the section on
              UTF-8 support for details.
  depth     - Determines the recursion depth limit when following a trail of replies
              that point to other replies. Default is 50.
  strict    - If this has a true value, any syntax errors detected while parsing
              a RiveScript document will result in a fatal error. Set it to a
              false value and only a warning will result. Default is 1.

It's recommended that if you set any other global variables that you do so by
calling C<setGlobal> or defining it within the RiveScript code. This will avoid
the possibility of overriding reserved globals. Currently, these variable names
are reserved:

  topics   sorted  sortsthat  sortedthat  thats
  arrays   subs    person     client      bot
  objects  syntax  sortlist   reserved    debugopts
  frozen   globals handlers   objlangs

Note: the options "verbose" and "debugfile", when provided, are noted and then
deleted from the root object space, so that if your RiveScript code uses variables
by the same values it won't conflict with the values that you passed here.

=back

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto || 'RiveScript';

	my $self = {
		###
		# User configurable fields.
		###

		# Debugging
		debug     => 0,
		debugopts => {
			verbose => 1,  # Print to the terminal
			file    => '', # Print to a filename
		},

		# Unicode stuff
		utf8                => 0,  # UTF-8 support
		unicode_punctuation => qr/[.,!?;:]/,

		# Misc.
		depth  => 50, # Recursion depth allowed.
		strict => 1,  # Strict syntax checking (causes a die)

		###
		# Internal fields.
		###
		topics     => {}, # Loaded replies under topics
		lineage    => {}, # Keep track of topics that inherit other topics
		includes   => {}, # Keep track of topics that include other topics
		sorted     => {}, # Sorted triggers
		sortsthat  => {}, # Sorted %previous's.
		sortedthat => {}, # Sorted triggers that go with %previous's
		thats      => {}, # Reverse mapping for %previous, under topics
		arrays     => {}, # Arrays
		subs       => {}, # Substitutions
		person     => {}, # Person substitutions
		client     => {}, # User variables
		frozen     => {}, # Frozen (backed-up) user variables
		bot        => {}, # Bot variables
		objects    => {}, # Subroutines
		syntax     => {}, # Syntax tracking
		sortlist   => {}, # Sorted lists (i.e. person subs)
		handlers   => {}, # Object handlers
		globals    => {}, # Globals that conflict with reserved names go here
		objlangs   => {}, # Map object names to their programming languages
		reserved   => [   # Reserved global variable names.
			qw(topics sorted sortsthat sortedthat thats arrays subs person
			client bot objects syntax sortlist reserved debugopts frozen
			handlers globals objlangs current_user)
		],
		current_user => undef, # The user ID of the current chatter
		@_,
	};
	bless ($self,$class);

	# Set the default object handler for Perl objects.
	$self->setHandler (perl => sub {
		my ($rs,$action,$name,$data) = @_;

		# $action will be "load" during the parsing phase, or "call"
		# when called via <call>.

		# Loading
		if ($action eq "load") {
			# Create a dynamic Perl subroutine.
			my $code = "sub RSOBJ_$name {\n"
				. $data
				. "}";

			# Evaluate it.
			eval ($code);
			if ($@) {
				$rs->issue("Perl object $name creation failed: $@");
			}
			else {
				# Load it.
				$rs->setSubroutine($name => \&{"RSOBJ_$name"});
			}
		}

		# Calling
		elsif ($action eq "call") {
			# Make sure the object exists.
			if (exists $rs->{objects}->{$name}) {
				# Call it.
				my @args = @{$data};
				my $return = &{ $rs->{objects}->{$name} } ($rs,@args);
				return $return;
			}
			else {
				return "[ERR: Object Not Found]";
			}
		}
	});

	# See if any additional debug options were provided.
	if (exists $self->{verbose}) {
		$self->{debugopts}->{verbose} = delete $self->{verbose};
	}
	if (exists $self->{debugfile}) {
		$self->{debugopts}->{file} = delete $self->{debugfile};
	}

	$self->debug ("RiveScript $VERSION Initialized");

	return $self;
}

sub debug {
	my ($self,$msg) = @_;
	if ($self->{debug}) {
		# Verbose debugging?
		if ($self->{debugopts}->{verbose}) {
			print "RiveScript: $msg\n";
		}

		# Debugging to a file?
		if (length $self->{debugopts}->{file}) {
			# Get a real quick timestamp.
			my @time = localtime(time());
			my $stamp = join(":",$time[2],$time[1],$time[0]);
			open (WRITE, ">>$self->{debugopts}->{file}");
			print WRITE "[$stamp] RiveScript: $msg\n";
			close (WRITE);
		}
	}
}

sub issue {
	my ($self,$msg) = @_;
	if ($self->{debug}) {
		print "# RiveScript::Warning: $msg\n";
	}
	else {
		warn "RiveScript::Warning: $msg\n";
	}
}

################################################################################
## Parsing Methods                                                            ##
################################################################################

=head2 LOADING AND PARSING

=over 4

=item bool loadDirectory (string $PATH[, string @EXTS])

Load a directory full of RiveScript documents. C<$PATH> must be a path to a
directory. C<@EXTS> is optionally an array containing file extensions, including
the dot. By default C<@EXTS> is C<('.rive', '.rs')>.

Returns true on success, false on failure.

=cut

sub loadDirectory {
	my $self = shift;
	my $dir = shift || '.';
	my (@exts) = @_ || ('.rive', '.rs');

	if (!-d $dir) {
		$self->issue ("loadDirectory failed: $dir is not a directory!");
		return 0;
	}

	$self->debug ("loadDirectory: Open $dir - extensions: @exts");


	opendir (my $dh, $dir);
	foreach my $file (sort { $a cmp $b } readdir($dh)) {
		next if $file eq '.';
		next if $file eq '..';
		next if $file =~ /\~$/i; # Skip backup files
		my $goodExt = 0;
		foreach (@exts) {
			my $re = quotemeta($_);
			$goodExt = 1 if $file =~ /$re$/;
		}
		next unless $goodExt;

		$self->debug ("loadDirectory: Read $file");

		$self->loadFile ("$dir/$file");
	}
	closedir ($dh);

	return 1;
}


=item bool loadFile (string $PATH)

Load a single RiveScript document. C<$PATH> should be the path to a valid
RiveScript file. Returns true on success; false otherwise.

=cut

sub loadFile {
	my ($self,$file) = @_;

	if (not defined $file) {
		$self->issue ("loadFile requires a file path.");
		return 0;
	}

	if (!-f $file) {
		$self->issue ("loadFile failed: $file is not a file!");
		return 0;
	}

	open (my $fh, "<:utf8", $file);
	my @code = <$fh>;
	close ($fh);
	chomp @code;

	# Parse the file.
	$self->debug ("loadFile: Parsing " . (scalar @code) . " lines from $file.");
	$self->parse ($file,join("\n",@code));

	return 1;
}



=item bool stream (arrayref $CODE)

Stream RiveScript code directly into the module. This is for providing RS code
from within the Perl script instead of from an external file. Returns true on
success.

=cut

sub stream {
	my ($self,$code) = @_;

	if (not defined $code) {
		$self->issue ("stream requires RiveScript code.");
		return 0;
	}

	# Stream the code.
	$self->debug ("stream: Streaming code.");
	$self->parse ("stream()",$code);

	return 1;
}

sub parse {
	my ($self,$fname,$code) = @_;

	# Track temporary variables.
	my $topic   = 'random'; # Default topic=random
	my $lineno  = 0;        # Keep track of line numbers
	my $comment = 0;        # In a multi-line comment.
	my $inobj   = 0;        # Trying to parse an object.
	my $objname = '';       # Object name.
	my $objlang = '';       # Object programming language.
	my $objbuf  = '';       # Object contents buffer.
	my $ontrig  = '';       # Current trigger.
	my $repcnt  = 0;        # Reply counter.
	my $concnt  = 0;        # Condition counter.
	my $lastcmd = '';       # Last command code.
	my $isThat  = '';       # Is a %Previous trigger.

	# Local (file scoped) parser options.
	my %local_options = (
		concat => "none", # Concat mode for ^Continue command.
	);

	# Concat mode characters.
	my %concat_mode = (
		none    => "",
		space   => " ",
		newline => "\n",
	);

	# Split the RS code into lines.
	$code =~ s/([\x0d\x0a])+/\x0a/ig;
	my @lines = split(/\x0a/, $code);

	# Read each line.
	$self->debug ("Parsing file data from $fname");
	my $lp = 0; # line number index
	for ($lp = 0; $lp < scalar(@lines); $lp++) {
		$lineno++;
		my $line = $lines[$lp];

		# Chomp the line further.
		chomp $line;
		$line =~ s/^(\t|\x0a|\x0d|\s)+//ig;
		$line =~ s/(\t|\x0a|\x0d|\s)+$//ig;

		$self->debug ("Line: $line (topic: $topic)");

		# In an object?
		if ($inobj) {
			if ($line =~ /^<\s*object/i) {
				# End the object.
				if (length $objname) {
					# Call this object's handler.
					if (exists $self->{handlers}->{$objlang}) {
						$self->{objlangs}->{$objname} = $objlang;
						&{ $self->{handlers}->{$objlang} } ($self,"load",$objname,$objbuf);
					}
					else {
						$self->issue ("Object creation failed: no handler for $objlang!");
					}
				}
				$objname = '';
				$objlang = '';
				$objbuf = '';
			}
			else {
				$objbuf .= "$line\n";
				next;
			}
		}

		# Look for comments.
		if ($line =~ /^(\/\/|#)/i) {
			# The "#" format for comments is deprecated.
			if ($line =~ /^#/) {
				$self->issue ("Using the # symbol for comments is deprecated at $fname line $lineno (near $line)");
			}
			next;
		}
		elsif ($line =~ /^\/\*/) {
			if ($line =~ /\*\//) {
				# Well this was a short comment.
				next;
			}

			# Start of a multi-line comment.
			$comment = 1;
			next;
		}
		elsif ($line =~ /\*\//) {
			$comment = 0;
			next;
		}
		if ($comment) {
			next;
		}

		# Skip blank lines.
		next if length $line == 0;

		# Separate the command from the data.
		my ($cmd) = $line =~ /^(.)/i;
		$line =~ s/^.//i;
		$line =~ s/^\s+?//ig;

		# Ignore inline comments if there's a space before and after
		# the // or # symbols.
		my $inline_comment_regexp = qr/(\s+#\s+|\s+\/\/)/;
		$line =~ s/\\\/\//\\\/\\\//g; # Turn \// into \/\/
		if ($cmd eq '+') {
			$inline_comment_regexp = qr/(\s\s#|\s+\/\/)/;
			if ($line =~ /\s\s#\s/) {
				# Deprecated.
				$self->issue ("Using the # symbol for comments is deprecated at $fname line $lineno (near: $line).");
			}
		}
		else {
			if ($line =~ /\s#\s/) {
				# Deprecated.
				$self->issue ("Using the # symbol for comments is deprecated at $fname line $lineno (near: $line).");
			}
		}
		if ($line =~ /$inline_comment_regexp/) {
			my ($left,$comment) = split(/$inline_comment_regexp/, $line, 2);
			$left =~ s/\s+$//g;
			$line = $left;
		}

		$self->debug ("\tCmd: $cmd");

		# Run a syntax check on this line. We put this into a separate function so that
		# we can have all the syntax logic all in one place.
		my $syntax_error = $self->checkSyntax($cmd,$line);
		if ($syntax_error) {
			# There was a syntax error! Are we enforcing "strict"?
			$syntax_error = "Syntax error in $fname line $lineno: $syntax_error (near: $cmd $line)";
			if ($self->{strict}) {
				# This is fatal then!
				die $syntax_error;
			}
			else {
				# This is a warning; warn it, and then abort processing this file!
				warn $syntax_error;
				return;
			}
		}

		# Reset the %previous state if this is a new +Trigger.
		if ($cmd eq '+') {
			$isThat = '';
		}

		# Do a lookahead for ^Continue and %Previous commands.
		for (my $i = ($lp + 1); $i < scalar(@lines); $i++) {
			my $lookahead = $lines[$i];
			$lookahead =~ s/^(\t|\x0a|\x0d|\s)+//g;
			my ($lookCmd) = $lookahead =~ /^(.)/i;
			$lookahead =~ s/^([^\s]+)\s+//i;

			# Only continue if the lookahead line has any data.
			if (defined $lookahead && length $lookahead > 0) {
				# The lookahead command has to be either a % or a ^.
				if ($lookCmd ne '^' && $lookCmd ne '%') {
					#$isThat = '';
					last;
				}

				# If the current command is a +, see if the following command
				# is a % (previous)
				if ($cmd eq '+') {
					# Look for %Previous.
					if ($lookCmd eq '%') {
						$self->debug ("\tIs a %previous ($lookahead)");
						$isThat = $lookahead;
						last;
					}
					else {
						$isThat = '';
					}
				}

				# If the current command is a ! and the next command(s) are
				# ^, we'll tack each extension on as a line break (which is
				# useful information for arrays; everything else is gonna ditch
				# this info).
				if ($cmd eq '!') {
					if ($lookCmd eq '^') {
						$self->debug ("\t^ [$lp;$i] $lookahead");
						$line .= "<crlf>$lookahead";
						$self->debug ("\tLine: $line");
					}
					next;
				}

				# If the current command is not a ^ and the line after is
				# not a %, but the line after IS a ^, then tack it onto the
				# end of the current line (this is fine for every other type
				# of command that doesn't require special treatment).
				if ($cmd ne '^' && $lookCmd ne '%') {
					if ($lookCmd eq '^') {
						$self->debug ("\t^ [$lp;$i] $lookahead");
						my $concat = exists $concat_mode{$local_options{"concat"}}
							? $concat_mode{$local_options{"concat"}}
							: "";
						$line .= $concat . $lookahead;
					}
					else {
						last;
					}
				}
			}
		}

		if ($cmd eq '!') {
			# ! DEFINE
			my ($left,$value) = split(/\s*=\s*/, $line, 2);
			my ($type,$var) = split(/\s+/, $left, 2);
			$ontrig = '';
			$self->debug ("\t! DEFINE");

			# Remove line breaks unless this is an array.
			if ($type ne 'array') {
				$value =~ s/<crlf>//ig;
			}

			if ($type eq 'version') {
				$self->debug ("\tUsing RiveScript version $value");
				if ($value > $SUPPORT) {
					$self->issue ("Unsupported RiveScript Version. Skipping file $fname.");
					return;
				}
			}
			elsif ($type eq 'local') {
				$self->debug ("\tSet local parser option $var = $value");
				$local_options{$var} = $value;
			}
			elsif ($type eq 'global') {
				if (not defined $var) {
					$self->issue ("Undefined global variable at $fname line $lineno.");
					next;
				}
				if (not defined $value) {
					$self->issue ("Undefined global value at $fname line $lineno.");
					next;
				}

				$self->debug ("\tSet global $var = $value");

				# Don't allow the overriding of a reserved global.
				my $ok = 1;
				foreach my $res (@{$self->{reserved}}) {
					if ($var eq $res) {
						$ok = 0;
						last;
					}
				}

				if ($ok) {
					# Allow in the global name space.
					if ($value eq '<undef>') {
						delete $self->{$var};
					}
					else {
						$self->{$var} = $value;
					}
				}
				else {
					# Allow in the protected name space.
					if ($value eq '<undef>') {
						delete $self->{globals}->{$var};
					}
					else {
						$self->{globals}->{$var} = $value;
					}
				}
			}
			elsif ($type eq 'var') {
				$self->debug ("\tSet bot variable $var = $value");
				if (not defined $var) {
					$self->issue ("Undefined bot variable at $fname line $lineno.");
					next;
				}
				if (not defined $value) {
					$self->issue ("Undefined bot value at $fname line $lineno.");
					next;
				}

				if ($value eq '<undef>') {
					delete $self->{bot}->{$var};
				}
				else {
					$self->{bot}->{$var} = $value;
				}
			}
			elsif ($type eq 'array') {
				$self->debug ("\tSet array $var");
				if (not defined $var) {
					$self->issue ("Undefined array variable at $fname line $lineno.");
					next;
				}
				if (not defined $value) {
					$self->issue ("Undefined array value at $fname line $lineno.");
					next;
				}

				if ($value eq '<undef>') {
					delete $self->{arrays}->{$var};
					next;
				}

				# Did this have multiple lines?
				my @parts = split(/<crlf>/i, $value);
				$self->debug("Array lines: " . join(";",@parts));

				# Process each line of array data.
				my @fields = ();
				foreach my $val (@parts) {
					# Split at pipes or spaces?
					if ($val =~ /\|/) {
						push (@fields,split(/\|/, $val));
					}
					else {
						push (@fields,split(/\s+/, $val));
					}
				}

				# Convert any remaining \s escape codes into spaces.
				foreach my $f (@fields) {
					$f =~ s/\\s/ /ig;
				}

				$self->{arrays}->{$var} = [ @fields ];
			}
			elsif ($type eq 'sub') {
				$self->debug ("\tSubstitution $var => $value");
				if (not defined $var) {
					$self->issue ("Undefined sub pattern at $fname line $lineno.");
					next;
				}
				if (not defined $value) {
					$self->issue ("Undefined sub replacement at $fname line $lineno.");
					next;
				}

				if ($value eq '<undef>') {
					delete $self->{subs}->{$var};
					next;
				}
				$self->{subs}->{$var} = $value;
			}
			elsif ($type eq 'person') {
				$self->debug ("\tPerson substitution $var => $value");
				if (not defined $var) {
					$self->issue ("Undefined person sub pattern at $fname line $lineno.");
					next;
				}
				if (not defined $value) {
					$self->issue ("Undefined person sub replacement at $fname line $lineno.");
					next;
				}
				if ($value eq '<undef>') {
					delete $self->{person}->{$var};
					next;
				}
				$self->{person}->{$var} = $value;
			}
			else {
				$self->issue ("Unknown definition type \"$type\" at $fname line $lineno.");
				next;
			}
		}
		elsif ($cmd eq '>') {
			# > LABEL
			my ($type,$name,@fields) = split(/\s+/, $line);
			$type = lc($type);

			# Handle the label types.
			if ($type eq 'begin') {
				# The BEGIN statement.
				$self->debug ("Found the BEGIN Statement.");
				$type  = 'topic';
				$name = '__begin__';
			}
			if ($type eq 'topic') {
				# Starting a new topic.
				$self->debug ("Set topic to $name.");
				$ontrig = '';
				$topic = $name;

				# Does this topic include or inherit another one?
				my $mode = ''; # or 'inherits' || 'includes'
				if (scalar(@fields) >= 2) {
					foreach my $field (@fields) {
						if ($field eq 'includes') {
							$mode = 'includes';
						}
						elsif ($field eq 'inherits') {
							$mode = 'inherits';
						}
						elsif ($mode ne '') {
							# This topic is either inherited or included.
							if ($mode eq 'includes') {
								$self->{includes}->{$name}->{$field} = 1;
							}
							else {
								$self->{lineage}->{$name}->{$field} = 1;
							}
						}
					}
				}
			}
			if ($type eq 'object') {
				# If a field was provided, it should be the programming language.
				my $lang = (scalar(@fields) ? $fields[0] : '');
				$lang = lc($lang); $lang =~ s/\s+//g;

				# Only try to parse a language we support.
				$ontrig = '';
				if (not length $lang) {
					$self->issue ("Trying to parse unknown programming language at $fname line $lineno.");
					$lang = "perl"; # Assume it's Perl.
				}

				# See if we have a defined handler for this language.
				if (exists $self->{handlers}->{$lang}) {
					# We have a handler, so load this object's code.
					$objname = $name;
					$objlang = $lang;
					$objbuf  = '';
					$inobj = 1;
				}
				else {
					# We don't have a handler, just ignore this code.
					$objname = '';
					$objlang = '';
					$objbuf  = '';
					$inobj   = 1;
				}
			}
		}
		elsif ($cmd eq '<') {
			# < LABEL
			my $type = $line;

			if ($type eq 'begin' || $type eq 'topic') {
				$self->debug ("End topic label.");
				$topic = 'random';
			}
			elsif ($type eq 'object') {
				$self->debug ("End object label.");
				$inobj = 0;
			}
		}
		elsif ($cmd eq '+') {
			# + TRIGGER
			$self->debug ("\tTrigger pattern: $line");
			if (length $isThat) {
				$self->debug ("\t\tInitializing the \%previous structure.");
				$self->{thats}->{$topic}->{$isThat}->{$line} = {};
			}
			else {
				$self->{topics}->{$topic}->{$line} = {};
				$self->{syntax}->{$topic}->{$line}->{ref} = "$fname line $lineno";
				$self->debug ("\t\tSaved to \$self->{topics}->{$topic}->{$line}: "
					. "$self->{topics}->{$topic}->{$line}");
			}
			$ontrig = $line;
			$repcnt = 0;
			$concnt = 0;
		}
		elsif ($cmd eq '-') {
			# - REPLY
			if ($ontrig eq '') {
				$self->issue ("Response found before trigger at $fname line $lineno.");
				next;
			}
			$self->debug ("\tResponse: $line");
			if (length $isThat) {
				$self->{thats}->{$topic}->{$isThat}->{$ontrig}->{reply}->{$repcnt} = $line;
			}
			else {
				$self->{topics}->{$topic}->{$ontrig}->{reply}->{$repcnt} = $line;
				$self->{syntax}->{$topic}->{$ontrig}->{reply}->{$repcnt}->{ref} = "$fname line $lineno";
				$self->debug ("\t\tSaved to \$self->{topics}->{$topic}->{$ontrig}->{reply}->{$repcnt}: "
					. "$self->{topics}->{$topic}->{$ontrig}->{reply}->{$repcnt}");
			}
			$repcnt++;
		}
		elsif ($cmd eq '%') {
			# % PREVIOUS
			$self->debug ("\t% Previous pattern: $line");

			# This was handled above.
		}
		elsif ($cmd eq '^') {
			# ^ CONTINUE
			# This should've been handled above...
		}
		elsif ($cmd eq '@') {
			# @ REDIRECT
			$self->debug ("\tRedirect the response to $line");
			if (length $isThat) {
				$self->{thats}->{$topic}->{$isThat}->{$ontrig}->{redirect} = $line;
			}
			else {
				$self->{topics}->{$topic}->{$ontrig}->{redirect} = $line;
			}
		}
		elsif ($cmd eq '*') {
			# * CONDITION
			$self->debug ("\tAdding condition.");
			if (length $isThat) {
				$self->{thats}->{$topic}->{$isThat}->{$ontrig}->{condition}->{$concnt} = $line;
			}
			else {
				$self->{topics}->{$topic}->{$ontrig}->{condition}->{$concnt} = $line;
			}
			$concnt++;
		}
		else {
			$self->issue ("Unrecognized command \"$cmd\" at $fname line $lineno.");
			next;
		}
	}
}

=item string checkSyntax (char $COMMAND, string $LINE)

Check the syntax of a line of RiveScript code. This is called automatically
for each line parsed by the module. C<$COMMAND> is the command part of the
line, and C<$LINE> is the rest of the line following the command (and
excluding inline comments).

If there is no problem with the line, this method returns C<undef>. Otherwise
it returns the text of the syntax error.

If C<strict> mode is enabled in the constructor (which is on by default), a
syntax error will result in a fatal error. If it's not enabled, the error is
only sent via C<warn> and the file currently being processed is aborted.

=cut

sub checkSyntax {
	my ($self,$cmd,$line) = @_;

	# This function returns undef when no syntax errors are present, otherwise
	# returns the text of the syntax error.

	# Run syntax checks based on the type of command.
	if ($cmd eq '!') {
		# ! Definition
		#   - Must be formatted like this:
		#     ! type name = value
		#     OR
		#     ! type = value
		#   - Type options are NOT enforceable, for future compatibility; if RiveScript
		#     encounters a new type that it can't handle, it can safely warn and skip it.
		if ($line !~ /^.+(?:\s+.+|)\s*=\s*.+?$/) {
			return "Invalid format for !Definition line: must be '! type name = value' OR '! type = value'";
		}
	}
	elsif ($cmd eq '>') {
		# > Label
		#   - The "begin" label must have only one argument ("begin")
		#   - "topic" labels must be lowercase but can inherit other topics ([A-Za-z0-9_\s])
		#   - "object" labels follow the same rules as "topic" labels, but don't need be lowercase
		if ($line =~ /^begin/ && $line =~ /\s+/) {
			return "The 'begin' label takes no additional arguments, should be verbatim '> begin'";
		}
		elsif ($line =~ /^topic/i && $line =~ /[^a-z0-9_\-\s]/) {
			return "Topics should be lowercased and contain only numbers and letters!";
		}
		elsif ($line =~ /[^A-Za-z0-9_\-\s]/) {
			return "Objects can only contain numbers and letters!";
		}
	}
	elsif ($cmd eq '+' || $cmd eq '%' || $cmd eq '@') {
		# + Trigger, % Previous, @ Redirect
		#   This one is strict. The triggers are to be run through Perl's regular expression
		#   engine. Therefore it should be acceptable by the regexp engine.
		#   - Entirely lowercase
		#   - No symbols except: ( | ) [ ] * _ # @ { } < > =
		#   - All brackets should be matched
		my $parens  = 0; # Open parenthesis
		my $square  = 0; # Open square brackets
		my $curly   = 0; # Open curly brackets
		my $chevron = 0; # Open angled brackets

		# Look for obvious errors.
		if ($self->{utf8}) {
			# UTF-8 only restricts certain meta characters.
			if ($line =~ /[A-Z\\.]/) {
				return "Triggers can't contain uppercase letters, backslashes or dots in UTF-8 mode.";
			}
		} else {
			# Only simple ASCIIs allowed.
			if ($line =~ /[^a-z0-9(\|)\[\]*_#\@{}<>=\s]/) {
				return "Triggers may only contain lowercase letters, numbers, and these symbols: ( | ) [ ] * _ # @ { } < > =";
			}
		}

		# Count brackets.
		my @chr = split(//, $line);
		for (my $i = 0; $i < scalar(@chr); $i++) {
			my $char = $chr[$i];

			# Count brackets.
			$parens++  if $char eq '('; $parens--  if $char eq ')';
			$square++  if $char eq '['; $square--  if $char eq ']';
			$curly++   if $char eq '{'; $curly--   if $char eq '}';
			$chevron++ if $char eq '<'; $chevron-- if $char eq '>';
		}

		# Any mismatches?
		if ($parens) {
			return "Unmatched " . ($parens > 0 ? "left" : "right") . " parenthesis bracket ()";
		}
		if ($square) {
			return "Unmatched " . ($square > 0 ? "left" : "right") . " square bracket []";
		}
		if ($curly) {
			return "Unmatched " . ($curly > 0 ? "left" : "right") . " curly bracket {}";
		}
		if ($chevron) {
			return "Unmatched " . ($chevron > 0 ? "left" : "right" ) . " angled bracket <>";
		}
	}
	elsif ($cmd eq '-' || $cmd eq '^' || $cmd eq '/') {
		# - Trigger, ^ Continue, / Comment
		# These commands take verbatim arguments, so their syntax is loose.
	}
	elsif ($cmd eq '*') {
		# * Condition
		#   Syntax for a conditional is as follows:
		#   * value symbol value => response
		if ($line !~ /^.+?\s*(==|eq|!=|ne|<>|<|<=|>|>=)\s*.+?=>.+?$/) {
			return "Invalid format for !Condition: should be like `* value symbol value => response`";
		}
	}

	# All good? Return undef.
	return undef;
}

=item void sortReplies ()

Call this method after loading replies to create an internal sort buffer. This
is necessary for trigger matching purposes. If you fail to call this method
yourself, RiveScript will call it once when you request a reply. However, it
will complain loudly about it.

=cut

sub sortReplies {
	my $self = shift;
	my $thats = shift || 'no';

	# Make this method dynamic: allow it to sort both triggers and %previous.
	# To that end we need to make some more references.
	my $triglvl = {};
	my $sortlvl = 'sorted';
	if ($thats eq 'thats') {
		$triglvl = $self->{thats};
		$sortlvl = 'sortsthat';
	}
	else {
		$triglvl = $self->{topics};
	}

	$self->debug ("Sorting triggers...");

	# Loop through all the topics.
	foreach my $topic (keys %{$triglvl}) {
		$self->debug ("Analyzing topic $topic");

		# Create a priority map.
		my $prior = {
			0 => [], # Default
		};

		# Collect a list of all the triggers we're going to need to
		# worry about. If this topic inherits another topic, we need to
		# recursively add those to the list.
		my @alltrig = $self->_topicTriggers($topic,$triglvl,0,0,0);
		#foreach my $trig (keys %{$triglvl->{$topic}}) {
		foreach my $trig (@alltrig) {
			if ($trig =~ /\{weight=(\d+)\}/i) {
				my $weight = $1;

				if (!exists $prior->{$weight}) {
					$prior->{$weight} = [];
				}

				push (@{$prior->{$weight}}, $trig);
			}
			else {
				push (@{$prior->{0}}, $trig);
			}
		}

		# Keep in mind here that there is a difference between 'includes'
		# and 'inherits' -- topics that inherit other topics are able to
		# OVERRIDE triggers that appear in the inherited topic. This means
		# that if the top topic has a trigger of simply '*', then *NO* triggers
		# are capable of matching in ANY inherited topic, because even though
		# * has the lowest sorting priority, it has an automatic priority over
		# all inherited topics.
		#
		# The _topicTriggers method takes this into account. All topics that
		# inherit other topics will have their triggers prefixed with a fictional
		# {inherits} tag, which would start at {inherits=0} and increment if the
		# topic tree has other inheriting topics. So we can use this tag to
		# make sure topics that inherit things will have their triggers always
		# be on the top of the stack, from inherits=0 to inherits=n.

		# Keep a running list of sorted triggers for this topic.
		my @running = ();

		# Sort them by priority.
		foreach my $p (sort { $b <=> $a } keys %{$prior}) {
			$self->debug ("\tSorting triggers with priority $p.");

			# So, some of these triggers may include {inherits} tags, if they
			# came from a topic which inherits another topic. Lower inherits
			# values mean higher priority on the stack. Keep this in mind when
			# keeping track of how to sort these things.
			my $inherits = -1; # -1 means no {inherits} tag, for flexibility
			my $highest_inherits = -1; # highest inheritence # we've seen

			# Loop through and categorize these triggers.
			my $track = {
				$inherits => {
					atomic => {}, # Sort by # of whole words
					option => {}, # Sort optionals by # of words
					alpha  => {}, # Sort alpha wildcards by # of words
					number => {}, # Sort numeric wildcards by # of words
					wild   => {}, # Sort wildcards by # of words
					pound  => [], # Triggers of just #
					under  => [], # Triggers of just _
					star   => [], # Triggers of just *
				},
			};

			foreach my $trig (@{$prior->{$p}}) {
				$self->debug("\t\tLooking at trigger: $trig");

				# See if this trigger has an inherits number.
				if ($trig =~ /{inherits=(\d+)}/) {
					$inherits = $1;
					if ($inherits > $highest_inherits) {
						$highest_inherits = $inherits;
					}
					$self->debug("\t\t\tTrigger belongs to a topic which inherits other topics: level=$inherits");
					$trig =~ s/{inherits=\d+}//g;
				}
				else {
					$inherits = -1;
				}

				# If this is the first time we've seen this inheritence priority
				# level, initialize its structure.
				if (!exists $track->{$inherits}) {
					$track->{$inherits} = {
						atomic => {},
						option => {},
						alpha  => {},
						number => {},
						wild   => {},
						pound  => [],
						under  => [],
						star   => [],
					};
				}

				if ($trig =~ /\_/) {
					# Alphabetic wildcard included.
					my @words = split(/[\s\*\#\_]+/, $trig);
					my $cnt = scalar(@words);
					$self->debug("\t\tHas a _ wildcard with $cnt words.");
					if ($cnt > 1) {
						if (!exists $track->{$inherits}->{alpha}->{$cnt}) {
							$track->{$inherits}->{alpha}->{$cnt} = [];
						}
						push (@{$track->{$inherits}->{alpha}->{$cnt}}, $trig);
					}
					else {
						push (@{$track->{$inherits}->{under}}, $trig);
					}
				}
				elsif ($trig =~ /\#/) {
					# Numeric wildcard included.
					my @words = split(/[\s\*\#\_]+/, $trig);
					my $cnt = scalar(@words);
					$self->debug("\t\tHas a # wildcard with $cnt words.");
					if ($cnt > 1) {
						if (!exists $track->{$inherits}->{number}->{$cnt}) {
							$track->{$inherits}->{number}->{$cnt} = [];
						}
						push (@{$track->{$inherits}->{number}->{$cnt}}, $trig);
					}
					else {
						push (@{$track->{$inherits}->{pound}}, $trig);
					}
				}
				elsif ($trig =~ /\*/) {
					# Wildcards included.
					my @words = split(/[\s\*\#\_]+/, $trig);
					my $cnt = scalar(@words);
					$self->debug("Has a * wildcard with $cnt words.");
					if ($cnt > 1) {
						if (!exists $track->{$inherits}->{wild}->{$cnt}) {
							$track->{$inherits}->{wild}->{$cnt} = [];
						}
						push (@{$track->{$inherits}->{wild}->{$cnt}}, $trig);
					}
					else {
						push (@{$track->{$inherits}->{star}}, $trig);
					}
				}
				elsif ($trig =~ /\[(.+?)\]/) {
					# Optionals included.
					my @words = split(/[\s\*\#\_]+/, $trig);
					my $cnt = scalar(@words);
					$self->debug("Has optionals and $cnt words.");
					if (!exists $track->{$inherits}->{option}->{$cnt}) {
						$track->{$inherits}->{option}->{$cnt} = [];
					}
					push (@{$track->{$inherits}->{option}->{$cnt}}, $trig);
				}
				else {
					# Totally atomic.
					my @words = split(/[\s\*\#\_]+/, $trig);
					my $cnt = scalar(@words);
					$self->debug("Totally atomic and $cnt words.");
					if (!exists $track->{$inherits}->{atomic}->{$cnt}) {
						$track->{$inherits}->{atomic}->{$cnt} = [];
					}
					push (@{$track->{$inherits}->{atomic}->{$cnt}}, $trig);
				}
			}

			# Add this group to the sort list.
			$track->{ ($highest_inherits + 1) } = delete $track->{'-1'}; # Move the no-{inherits} group away for a sec
			foreach my $ip (sort { $a <=> $b } keys %{$track}) {
				$self->debug("ip=$ip");
				foreach my $kind (qw(atomic option alpha number wild)) {
					foreach my $wordcnt (sort { $b <=> $a } keys %{$track->{$ip}->{$kind}}) {
						# Triggers with a matching word count should be sorted
						# by length, descending.
						push (@running, sort { length($b) <=> length($a) } @{$track->{$ip}->{$kind}->{$wordcnt}});
					}
				}
				push (@running, sort { length($b) <=> length($a) } @{$track->{$ip}->{under}});
				push (@running, sort { length($b) <=> length($a) } @{$track->{$ip}->{pound}});
				push (@running, sort { length($b) <=> length($a) } @{$track->{$ip}->{star}});
			}
		}

		# Save this topic's sorted list.
		$self->{$sortlvl}->{$topic} = [ @running ];
	}

	# Also sort that's.
	if ($thats ne 'thats') {
		# This will sort the %previous lines to best match the bot's last reply.
		$self->sortReplies ('thats');

		# If any of those %previous's had more than one +trigger for them, this
		# will sort all those +trigger's to pair back the best human interaction.
		$self->sortThatTriggers;

		# Also sort both kinds of substitutions.
		$self->sortList ('subs', keys %{$self->{subs}});
		$self->sortList ('person', keys %{$self->{person}});
	}
}

sub sortThatTriggers {
	my ($self) = @_;

	# Usage case: if you have more than one +trigger with the same %previous,
	# this will create a sort buffer for all those +trigger's.
	# Ex:
	#
	# + how [are] you [doing]
	# - I'm doing great, how are you?
	# - Good -- how are you?
	# - Fine, how are you?
	#
	# + [*] @good [*]
	# % * how are you
	# - That's good. :-)
	#
	# 	# // TODO: why isn't this ever called?
	# + [*] @bad [*]
	# % * how are you
	# - Aww. :-( What's the matter?
	#
	# + *
	# % * how are you
	# - I see...

	# The sort buffer for this.
	$self->{sortedthat} = {};
	# Eventual structure:
	# $self->{sortedthat} = {
	#	random => {
	#		'* how are you' => [
	#			'[*] @good [*]',
	#			'[*] @bad [*]',
	#			'*',
	#		],
	#	},
	# };

	$self->debug ("Sorting reverse triggers for %previous groups...");

	foreach my $topic (keys %{$self->{thats}}) {
		# Create a running list of the sort buffer for this topic.
		my @running = ();

		$self->debug ("Sorting the 'that' triggers for topic $topic");
		foreach my $that (keys %{$self->{thats}->{$topic}}) {
			$self->debug ("Sorting triggers that go with the 'that' of \"$that\"");
			# Loop through and categorize these triggers.
			my $track = {
				atomic => {}, # Sort by # of whole words
				option => {}, # Sort optionals by # of words
				alpha  => {}, # Sort letters by # of words
				number => {}, # Sort numbers by # of words
				wild   => {}, # Sort wildcards by # of words
				pound  => [], # Triggers of just #
				under  => [], # Triggers of just _
				star   => [], # Triggers of just *
			};

			# Loop through all the triggers for this %previous.
			foreach my $trig (keys %{$self->{thats}->{$topic}->{$that}}) {
				if ($trig =~ /\_/) {
					# Alphabetic wildcard included.
					my @words = split(/[\s\*\#\_]+/, $trig);
					my $cnt = scalar(@words);
					if ($cnt > 1) {
						if (!exists $track->{alpha}->{$cnt}) {
							$track->{alpha}->{$cnt} = [];
						}
						push (@{$track->{alpha}->{$cnt}}, $trig);
					}
					else {
						push (@{$track->{under}}, $trig);
					}
				}
				elsif ($trig =~ /\#/) {
					# Numeric wildcard included.
					my @words = split(/[\s\*\#\_]+/, $trig);
					my $cnt = scalar(@words);
					if ($cnt > 1) {
						if (!exists $track->{number}->{$cnt}) {
							$track->{number}->{$cnt} = [];
						}
						push (@{$track->{number}->{$cnt}}, $trig);
					}
					else {
						push (@{$track->{pound}}, $trig);
					}
				}
				elsif ($trig =~ /\*/) {
					# Wildcards included.
					my @words = split(/[\s\*\#\_]+/, $trig);
					my $cnt = scalar(@words);
					if ($cnt > 1) {
						if (!exists $track->{wild}->{$cnt}) {
							$track->{wild}->{$cnt} = [];
						}
						push (@{$track->{wild}->{$cnt}}, $trig);
					}
					else {
						push (@{$track->{star}}, $trig);
					}
				}
				elsif ($trig =~ /\[(.+?)\]/) {
					# Optionals included.
					my @words = split(/[\s\*\#\_]+/, $trig);
					my $cnt = scalar(@words);
					if (!exists $track->{option}->{$cnt}) {
						$track->{option}->{$cnt} = [];
					}
					push (@{$track->{option}->{$cnt}}, $trig);
				}
				else {
					# Totally atomic.
					my @words = split(/[\s\*\#\_]+/, $trig);
					my $cnt = scalar(@words);
					if (!exists $track->{atomic}->{$cnt}) {
						$track->{atomic}->{$cnt} = [];
					}
					push (@{$track->{atomic}->{$cnt}}, $trig);
				}
			}

			# Add this group to the sort list.
			my @running = ();
			foreach my $i (sort { $b <=> $a } keys %{$track->{atomic}}) {
				push (@running,@{$track->{atomic}->{$i}});
			}
			foreach my $i (sort { $b <=> $a } keys %{$track->{option}}) {
				push (@running,@{$track->{option}->{$i}});
			}
			foreach my $i (sort { $b <=> $a } keys %{$track->{alpha}}) {
				push (@running,@{$track->{alpha}->{$i}});
			}
			foreach my $i (sort { $b <=> $a } keys %{$track->{number}}) {
				push (@running,@{$track->{number}->{$i}});
			}
			foreach my $i (sort { $b <=> $a } keys %{$track->{wild}}) {
				push (@running,@{$track->{wild}->{$i}});
			}
			push (@running, sort { length($b) <=> length($a) } @{$track->{under}});
			push (@running, sort { length($b) <=> length($a) } @{$track->{pound}});
			push (@running, sort { length($b) <=> length($a) } @{$track->{star}});

			# Keep this buffer.
			$self->{sortedthat}->{$topic}->{$that} = [ @running ];
		}
	}
}

sub sortList {
	my ($self,$name,@list) = @_;

	# If a sorted list by this name already exists, delete it.
	if (exists $self->{sortlist}->{$name}) {
		delete $self->{sortlist}->{$name};
	}

	# Initialize the sorted list.
	$self->{sortlist}->{$name} = [];

	# Track by number of words.
	my $track = {};

	# Loop through each item in the list.
	foreach my $item (@list) {
		# Count the words.
		my @words = split(/\s+/, $item);
		my $cword = scalar(@words);

		# Store this by group of word counts.
		if (!exists $track->{$cword}) {
			$track->{$cword} = [];
		}
		push (@{$track->{$cword}}, $item);
	}

	# Sort them.
	my @sorted = ();
	foreach my $count (sort { $b <=> $a } keys %{$track}) {
		my @items = sort { length $b <=> length $a } @{$track->{$count}};
		push (@sorted,@items);
	}

	# Store this list.
	$self->{sortlist}->{$name} = [ @sorted ];
	return 1;
}

# Given one topic, walk the inheritence tree and return an array of all topics.
sub _getTopicTree {
	my ($self,$topic,$depth) = @_;

	# Break if we're in too deep.
	if ($depth > $self->{depth}) {
		$self->issue ("Deep recursion while scanning topic inheritance (topic $topic was involved)");
		return ();
	}

	# Collect an array of topics.
	my @topics = ($topic);

	$self->debug ("_getTopicTree depth $depth; topics: @topics");

	# Does this topic include others?
	if (exists $self->{includes}->{$topic}) {
		# Try each of these.
		foreach my $includes (sort { $a cmp $b } keys %{$self->{includes}->{$topic}}) {
			$self->debug ("Topic $topic includes $includes");
			push (@topics, $self->_getTopicTree($includes,($depth + 1)));
		}
		$self->debug ("_getTopicTree depth $depth (b); topics: @topics");
	}

	# Does the topic inherit others?
	if (exists $self->{lineage}->{$topic}) {
		# Try each of these.
		foreach my $inherits (sort { $a cmp $b } keys %{$self->{lineage}->{$topic}}) {
			$self->debug ("Topic $topic inherits $inherits");
			push (@topics, $self->_getTopicTree($inherits,($depth + 1)));
		}
		$self->debug ("_getTopicTree depth $depth (b); topics: @topics");
	}

	# Return them.
	return (@topics);
}

# Gather an array of all triggers in a topic. If the topic inherits other
# topics, recursively collect those triggers too. Take care about recursion.
sub _topicTriggers {
	my ($self,$topic,$triglvl,$depth,$inheritence,$inherited) = @_;

	# Break if we're in too deep.
	if ($depth > $self->{depth}) {
		$self->issue ("Deep recursion while scanning topic inheritance (topic $topic was involved)");
		return ();
	}

	# Important info about the depth vs inheritence params to this function:
	# depth increments by 1 every time this function recursively calls itself.
	# inheritence increments by 1 only when this topic inherits another topic.
	#
	# This way, `> topic alpha includes beta inherits gamma` will have this effect:
	#   alpha and beta's triggers are combined together into one matching pool, and then
	#   these triggers have higher matching priority than gamma's.
	#
	# The $inherited option is 1 if this is a recursive call, from a topic that
	# inherits other topics. This forces the {inherits} tag to be added to the
	# triggers. This only applies when the top topic "includes" another topic.

	$self->debug ("\tCollecting trigger list for topic $topic (depth=$depth; inheritence=$inheritence; inherited=$inherited)");

	# topic:   the name of the topic
	# triglvl: either $self->{topics} or $self->{thats}
	# depth:   starts at 0 and ++'s with each recursion

	# Collect an array of triggers to return.
	my @triggers = ();

	# Does this topic include others?
	if (exists $self->{includes}->{$topic}) {
		# Check every included topic.
		foreach my $includes (sort { $a cmp $b } keys %{$self->{includes}->{$topic}}) {
			$self->debug ("\t\tTopic $topic includes $includes");
			push (@triggers, $self->_topicTriggers($includes,$triglvl,($depth + 1), $inheritence, 1));
		}
	}

	# Does this topic inherit others?
	if (exists $self->{lineage}->{$topic}) {
		# Check every inherited topic.
		foreach my $inherits (sort { $a cmp $b } keys %{$self->{lineage}->{$topic}}) {
			$self->debug ("\t\tTopic $topic inherits $inherits");
			push (@triggers, $self->_topicTriggers($inherits,$triglvl,($depth + 1), ($inheritence + 1), 0));
		}
	}

	# Collect the triggers for *this* topic. If this topic inherits any other
	# topics, it means that this topic's triggers have higher priority than those
	# in any inherited topics. Enforce this with an {inherits} tag.
	if (exists $self->{lineage}->{$topic} || $inherited) {
		my @inThisTopic = keys %{$triglvl->{$topic}};
		foreach my $trigger (@inThisTopic) {
			$self->debug ("\t\tPrefixing trigger with {inherits=$inheritence}$trigger");
			push (@triggers, "{inherits=$inheritence}$trigger");
		}
	}
	else {
		push (@triggers, keys %{$triglvl->{$topic}});
	}

	# Return them.
	return (@triggers);
}

=item data deparse ()

Translate the in-memory representation of the loaded RiveScript documents into
a Perl data structure. This would be useful for developing a user interface to
facilitate editing of RiveScript replies without having to edit the RiveScript
code manually.

The data structure returned from this will follow this format:

  {
    "begin" => { # Contains begin block and config settings
      "global" => { # ! global (global variables)
        "depth" => 50,
        ...
      },
      "var" => {    # ! var (bot variables)
        "name" => "Aiden",
        ...
      },
      "sub" => {    # ! sub (substitutions)
        "what's" => "what is",
        ...
      },
      "person" => { # ! person (person substitutions)
        "you" => "I",
        ...
      },
      "array" => {  # ! array (arrays)
        "colors" => [ "red", "green", "light green", "blue" ],
        ...
      },
      "triggers" => {  # triggers in your > begin block
        "request" => { # trigger "+ request"
          "reply" => [ "{ok}" ],
        },
      },
    },
    "topic" => { # all topics under here
      "random" => { # topic names (default is random)
        "hello bot" => { # trigger labels
          "reply"     => [ "Hello human!" ], # Array of -Replies
          "redirect"  => "hello",            # Only if @Redirect exists
          "previous"  => "hello human",      # Only if %Previous exists
          "condition" => [                   # Only if *Conditions exist
            "<get name> != undefined => Hello <get name>!",
            ...
          ],
        },
      },
    },
    "include" => { # topic inclusion
      "alpha" => [ "beta", "gamma" ], # > topic alpha includes beta gamma
    },
    "inherit" => { # topic inheritence
      "alpha" => [ "delta" ], # > topic alpha inherits delta
    }
  }

Note that inline object macros can't be deparsed this way. This is probably for
the best (for security, etc). The global variables "debug" and "depth" are only
provided if the values differ from the defaults (true and 50, respectively).

=cut

sub deparse {
	my ($self) = @_;

	# Can we clone?
	eval {
		require Clone;
		$self->{_can_clone} = 1;
	};
	if ($@) {
		warn "You don't have the Clone module installed. Output from "
			. "RiveScript->deparse will remain referenced to internal data "
			. "structures. Be careful!";
		$self->{_can_clone} = 0;
	}

	# Data to return.
	my $deparse = {
		begin   => {
			global   => {},
			var      => {},
			sub      => {},
			person   => {},
			array    => {},
			triggers => {},
			that     => {},
		},
		topic   => {},
		that    => {},
		inherit => {},
		include => {},
	};

	# Populate the config fields.
	if ($self->{debug}) {
		$deparse->{begin}->{global}->{debug} = $self->{debug};
	}
	if ($self->{depth} != 50) {
		$deparse->{begin}->{global}->{depth} = $self->{depth};
	}
	$deparse->{begin}->{var}    = $self->_clone($self->{bot});
	$deparse->{begin}->{sub}    = $self->_clone($self->{subs});
	$deparse->{begin}->{person} = $self->_clone($self->{person});
	$deparse->{begin}->{array}  = $self->_clone($self->{arrays});
	foreach my $global (keys %{$self->{globals}}) {
		$deparse->{begin}->{global}->{$global} = $self->{globals}->{$global};
	}

	# Triggers.
	foreach my $topic (keys %{$self->{topics}}) {
		my $dest; # Where to place the topic info.

		if ($topic eq "__begin__") {
			# Begin block.
			$dest = $deparse->{begin}->{triggers};
		}
		else {
			# Normal topic.
			if (!exists $deparse->{topic}->{$topic}) {
				$deparse->{topic}->{$topic} = {};
			}
			$dest = $deparse->{topic}->{$topic};
		}

		foreach my $trig (keys %{$self->{topics}->{$topic}}) {
			my $src = $self->{topics}->{$topic}->{$trig};
			$dest->{$trig} = {};
			$self->_copy_trigger($trig, $src, $dest);
		}
	}

	# %Previous's.
	foreach my $topic (keys %{$self->{thats}}) {
		my $dest; # Where to place the topic info.

		if ($topic eq "__begin__") {
			# Begin block.
			$dest = $deparse->{begin}->{that};
		}
		else {
			# Normal topic.
			if (!exists $deparse->{that}->{$topic}) {
				$deparse->{that}->{$topic} = {};
			}
			$dest = $deparse->{that}->{$topic};
		}

		# The "that" structure is backwards: bot reply, then trigger, then info.
		foreach my $previous (keys %{$self->{thats}->{$topic}}) {
			foreach my $trig (keys %{$self->{thats}->{$topic}->{$previous}}) {
				my $src = $self->{thats}->{$topic}->{$previous}->{$trig};
				$dest->{$trig}->{previous} = $previous;
				$self->_copy_trigger($trig, $src, $dest);
			}
		}
	}

	# Inherits/Includes.
	foreach my $topic (keys %{$self->{lineage}}) {
		$deparse->{inherit}->{$topic} = [];
		foreach my $inherit (keys %{$self->{lineage}->{$topic}}) {
			push @{$deparse->{inherit}->{$topic}}, $inherit;
		}
	}
	foreach my $topic (keys %{$self->{includes}}) {
		$deparse->{include}->{$topic} = [];
		foreach my $include (keys %{$self->{includes}->{$topic}}) {
			push @{$deparse->{include}->{$topic}}, $include;
		}
	}

	return $deparse;
}

sub _copy_trigger {
	my ($self, $trig, $src, $dest) = @_;

	if (exists $src->{redirect}) { # @Redirect
		$dest->{$trig}->{redirect} = $src->{redirect};
	}
	if (exists $src->{condition}) { # *Condition
		$dest->{$trig}->{condition} = [];
		foreach my $i (sort { $a <=> $b } keys %{$src->{condition}}) {
			push @{$dest->{$trig}->{condition}}, $src->{condition}->{$i};
		}
	}
	if (exists $src->{reply}) {     # -Reply
		$dest->{$trig}->{reply} = [];
		foreach my $i (sort { $a <=> $b } keys %{$src->{reply}}) {
			push @{$dest->{$trig}->{reply}}, $src->{reply}->{$i};
		}
	}
}

sub _clone {
	my ($self,$data) = @_;

	# Can clone?
	if ($self->{_can_clone}) {
		return Clone::clone($data);
	}

	return $data;
}

=item void write (glob $fh || string $file[, data $deparsed])

Write the currently parsed RiveScript data into a RiveScript file. This uses
C<deparse()> to dump a representation of the loaded data and writes it to the
destination file. Pass either a filehandle or a file name.

If you provide C<$deparsed>, it should be a data structure matching the format
of C<deparse()>. This way you can deparse your RiveScript brain, add/edit
replies and then pass in the new version to this method to save the changes
back to disk. Otherwise, C<deparse()> will be called to get the current
snapshot of the brain.

=back

=cut

sub write {
	my ($self, $file, $deparsed) = @_;

	my $fh;
	if (ref($file) eq "GLOB") {
		$fh = $file;
	}
	elsif (ref($file)) {
		die "Must pass either a filehandle or file name to write()";
	}
	else {
		open ($fh, ">", $file) or die "Can't write to $file: $!";
	}

	my $deparse = ref($deparsed) ? $deparsed : $self->deparse();

	# Start at the beginning.
	print {$fh} "// Written by RiveScript::deparse()\n";
	print {$fh} "! version = 2.0\n\n";

	# Variables of all sorts!
	foreach my $sort (qw/global var sub person array/) {
		next unless scalar keys %{$deparse->{begin}->{$sort}} > 0;
		foreach my $var (sort keys %{$deparse->{begin}->{$sort}}) {
			# Array types need to be separated by either spaces or pipes.
			my $data = $deparse->{begin}->{$sort}->{$var};
			if (ref($data) eq "ARRAY") {
				my $needs_pipes = 0;
				foreach my $test (@{$data}) {
					if ($test =~ /\s+/) {
						$needs_pipes = 1;
						last;
					}
				}

				# Word-wrap the result, target width is 78 chars minus the
				# sort, var, and spaces and equals sign.
				my $width = 78 - length($sort) - length($var) - 4;

				if ($needs_pipes) {
					$data = $self->_write_wrapped(join("|", @{$data}), "|", undef, $width);
				} else {
					$data = join(" ", @{$data});
				}
			}

			print {$fh} "! $sort $var = $data\n";
		}
		print {$fh} "\n";
	}

	if (scalar keys %{$deparse->{begin}->{triggers}}) {
		print {$fh} "> begin\n\n";

		$self->_write_triggers($fh, $deparse->{begin}->{triggers}, "indent");

		print {$fh} "< begin\n\n";
	}

	# The topics. Random first!
	my $doneRandom = 0;
	foreach my $topic ("random", sort keys %{$deparse->{topic}}) {
		next unless exists $deparse->{topic}->{$topic};
		next if $topic eq "random" && $doneRandom;
		$doneRandom = 1 if $topic eq "random";

		my $tagged = 0; # Used > topic tag

		if ($topic ne "random" || exists $deparse->{include}->{$topic} || exists $deparse->{inherit}->{$topic}) {
			$tagged = 1;
			print {$fh} "> topic $topic";

			if (exists $deparse->{inherit}->{$topic}) {
				print {$fh} " inherits " . join(" ", @{$deparse->{inherit}->{$topic}});
			}
			if (exists $deparse->{include}->{$topic}) {
				print {$fh} " includes " . join(" ", @{$deparse->{include}->{$topic}});
			}

			print {$fh} "\n\n";
		}

		$self->_write_triggers($fh, $deparse->{topic}->{$topic}, $tagged ? "indent" : 0);

		# Any %Previous's?
		if (exists $deparse->{that}->{$topic}) {
			$self->_write_triggers($fh, $deparse->{that}->{$topic}, $tagged ? "indent" : 0);
		}

		if ($tagged) {
			print {$fh} "< topic\n\n";
		}
	}

	return 1;
}

sub _write_triggers {
	my ($self, $fh, $trigs, $id) = @_;

	$id = $id ? "\t" : "";

	foreach my $trig (sort keys %{$trigs}) {
		print {$fh} $id . "+ " . $self->_write_wrapped($trig," ",$id) . "\n";
		my $d = $trigs->{$trig};

		if (exists $d->{previous}) {
			print {$fh} $id . "% " . $self->_write_wrapped($d->{previous}," ",$id) . "\n";
		}

		if (exists $d->{condition}) {
			foreach my $cond (@{$d->{condition}}) {
				print {$fh} $id . "* " . $self->_write_wrapped($cond," ",$id) . "\n";
			}
		}

		if (exists $d->{redirect}) {
			print {$fh} $id . "@ " . $self->_write_wrapped($d->{redirect}," ",$id) . "\n";
		}

		if (exists $d->{reply}) {
			foreach my $reply (@{$d->{reply}}) {
				print {$fh} $id . "- " . $self->_write_wrapped($reply," ",$id) . "\n";
			}
		}

		print {$fh} "\n";
	}
}

sub _write_wrapped {
	my ($self, $line, $sep, $indent, $width) = @_;
	$width ||= 78;

	my $id = $indent ? "\t" : "";

	my @words;
	if ($sep eq " ") {
		@words = split(/\s+/, $line);
	}
	elsif ($sep eq "|") {
		@words = split(/\|/, $line);
	}

	my @lines = ();
	$line     = "";
	my @buf   = ();
	while (scalar(@words)) {
		push (@buf, shift(@words));
		$line = join($sep, @buf);
		if (length $line > $width) {
			# Need to word wrap.
			unshift(@words, pop(@buf)); # Undo
			push (@lines, join($sep,@buf));
			@buf = ();
			$line = "";
		}
	}

	# Straggler?
	if ($line) {
		push @lines, $line;
	}

	my $return = shift(@lines);
	if (scalar(@lines)) {
		my $eol = ($sep eq " " ? '\s' : "");
		foreach my $ln (@lines) {
			$return .= "$eol\n$id^ $ln";
		}
	}

	return $return;
}

################################################################################
## Configuration Methods                                                      ##
################################################################################

=head2 CONFIGURATION

=over 4

=item bool setHandler (string $LANGUAGE => code $CODEREF, ...)

Define some code to handle objects of a particular programming language. If the
coderef is C<undef>, it will delete the handler.

The code receives the variables C<$rs, $action, $name,> and C<$data>. These
variables are described here:

  $rs     = Reference to Perl RiveScript object.
  $action = "load" during the parsing phase when an >object is found.
            "call" when provoked via a <call> tag for a reply
  $name   = The name of the object.
  $data   = The source of the object during the parsing phase, or an array
            reference of arguments when provoked via a <call> tag.

There is a default handler set up that handles Perl objects.

If you want to block Perl objects from being loaded, you can just set it to be
undef, and its handler will be deleted and Perl objects will be skipped over:

  $rs->setHandler (perl => undef);

The rationale behind this "pluggable" object interface is that it makes
RiveScript more flexible given certain environments. For instance, if you use
RiveScript on the web where the user chats with your bot using CGI, you might
define a handler so that JavaScript objects can be loaded and called. Perl
itself can't execute JavaScript, but the user's web browser can.

See the JavaScript example in the C<docs> directory in this distribution.

=cut

sub setHandler {
	my ($self,%info) = @_;

	foreach my $lang (keys %info) {
		my $code = $info{$lang};
		$lang = lc($lang);
		$lang =~ s/\s+//g;

		# If the coderef is undef, delete the handler.
		if (!defined $code) {
			delete $self->{handlers}->{$lang};
		}
		else {
			# Otherwise it must be a coderef.
			if (ref($code) eq "CODE") {
				$self->{handlers}->{$lang} = $code;
			}
			else {
				$self->issue("Handler for language $lang must be a code reference!");
			}
		}
	}

	return 1;
}

=item bool setSubroutine (string $NAME, code $CODEREF)

Manually create a RiveScript object (a dynamic bit of Perl code that can be
provoked in a RiveScript response). C<$NAME> should be a single-word,
alphanumeric string. C<$CODEREF> should be a pointer to a subroutine or an
anonymous sub.

=cut

sub setSubroutine {
	my ($self,$name,$sub) = @_;

	$self->{objects}->{$name} = $sub;
	$self->{objlangs}->{$name} = "perl";
	return 1;
}

=item bool setGlobal (hash %DATA)

Set one or more global variables, in hash form, where the keys are the variable
names and the values are their value. This subroutine will make sure that you
don't override any reserved global variables, and warn if that happens.

This is equivalent to C<! global> in RiveScript code.

To delete a global, set its value to C<undef> or "C<E<lt>undefE<gt>>". This
is true for variables, substitutions, person, and uservars.

=cut

sub setGlobal {
	my ($self,%data) = @_;

	foreach my $key (keys %data) {
		if (!defined $data{$key}) {
			$data{$key} = "<undef>";
		}

		my $reserved = 0;
		foreach my $res (@{$self->{reserved}}) {
			if ($res eq $key) {
				$reserved = 1;
				last;
			}
		}

		if ($reserved) {
			if ($data{$key} eq "<undef>") {
				delete $self->{globals}->{$key};
			}
			else {
				$self->{globals}->{$key} = $data{$key};
			}
		}
		else {
			if ($data{$key} eq "<undef>") {
				delete $self->{$key};
			}
			else {
				$self->{$key} = $data{$key};
			}
		}
	}

	return 1;
}

=item bool setVariable (hash %DATA)

Set one or more bot variables (things that describe your bot's personality).

This is equivalent to C<! var> in RiveScript code.

=cut

sub setVariable {
	my ($self,%data) = @_;

	foreach my $key (keys %data) {
		if (!defined $data{$key}) {
			$data{$key} = "<undef>";
		}

		if ($data{$key} eq "<undef>") {
			delete $self->{bot}->{$key};
		}
		else {
			$self->{bot}->{$key} = $data{$key};
		}
	}

	return 1;
}

=item bool setSubstitution (hash %DATA)

Set one or more substitution patterns. The keys should be the original word, and
the value should be the word to substitute with it.

  $rs->setSubstitution (
    q{what's}  => 'what is',
    q{what're} => 'what are',
  );

This is equivalent to C<! sub> in RiveScript code.

=cut

sub setSubstitution {
	my ($self,%data) = @_;

	foreach my $key (keys %data) {
		if (!defined $data{$key}) {
			$data{$key} = "<undef>";
		}

		if ($data{$key} eq "<undef>") {
			delete $self->{subs}->{$key};
		}
		else {
			$self->{subs}->{$key} = $data{$key};
		}
	}

	return 1;
}

=item bool setPerson (hash %DATA)

Set a person substitution. This is equivalent to C<! person> in RiveScript code.

=cut

sub setPerson {
	my ($self,%data) = @_;

	foreach my $key (keys %data) {
		if (!defined $data{$key}) {
			$data{$key} = "<undef>";
		}

		if ($data{$key} eq "<undef>") {
			delete $self->{person}->{$key};
		}
		else {
			$self->{person}->{$key} = $data{$key};
		}
	}

	return 1;
}

=item bool setUservar (string $USER, hash %DATA)

Set a variable for a user. C<$USER> should be their User ID, and C<%DATA> is a
hash containing variable/value pairs.

This is like C<E<lt>setE<gt>> for a specific user.

=cut

sub setUservar {
	my ($self,$user,%data) = @_;

	foreach my $key (keys %data) {
		if (!defined $data{$key}) {
			$data{$key} = "<undef>";
		}

		if ($data{$key} eq "<undef>") {
			delete $self->{client}->{$user}->{$key};
		}
		else {
			$self->{client}->{$user}->{$key} = $data{$key};
		}
	}

	return 1;
}

=item string getUservar (string $USER, string $VAR)

This is an alias for getUservars, and is here because it makes more grammatical
sense.

=cut

sub getUservar {
	# Alias for getUservars.
	my $self = shift;
	return $self->getUservars (@_);
}

=item data getUservars ([string $USER][, string $VAR])

Get all the variables about a user. If a username is provided, returns a hash
B<reference> containing that user's information. Else, a hash reference of all
the users and their information is returned.

You can optionally pass a second argument, C<$VAR>, to get a specific variable
that belongs to the user. For instance, C<getUservars ("soandso", "age")>.

This is like C<E<lt>getE<gt>> for a specific user or for all users.

=cut

sub getUservars {
	my ($self,$user,$var) = @_;
	$user = '' unless defined $user;
	$var  = '' unless defined $var;

	# Did they want a specific variable?
	if (length $user && length $var) {
		if (exists $self->{client}->{$user}->{$var}) {
			return $self->{client}->{$user}->{$var};
		}
		else {
			return undef;
		}
	}

	if (length $user) {
		return $self->{client}->{$user};
	}
	else {
		return $self->{client};
	}
}

=item bool clearUservars ([string $USER])

Clears all variables about C<$USER>. If no C<$USER> is provided, clears all
variables about all users.

=cut

sub clearUservars {
	my $self = shift;
	my $user = shift || '';

	if (length $user) {
		foreach my $var (keys %{$self->{client}->{$user}}) {
			delete $self->{client}->{$user}->{$var};
		}
		delete $self->{client}->{$user};
	}
	else {
		foreach my $client (keys %{$self->{client}}) {
			foreach my $var (keys %{$self->{client}->{$client}}) {
				delete $self->{client}->{$client}->{$var};
			}
			delete $self->{client}->{$client};
		}
	}

	return 1;
}

=item bool freezeUservars (string $USER)

Freeze the current state of variables for user C<$USER>. This will back up the
user's current state (their variables and reply history). This won't statically
prevent the user's state from changing; it merely saves its current state. Then
use thawUservars() to revert back to this previous state.

=cut

sub freezeUservars {
	my ($self,$user) = @_;
	$user = '' unless defined $user;

	if (length $user && exists $self->{client}->{$user}) {
		# Freeze their variables. First unfreeze the last copy if they
		# exist.
		if (exists $self->{frozen}->{$user}) {
			$self->thawUservars ($user, discard => 1);
		}

		# Back up all our variables.
		foreach my $var (keys %{$self->{client}->{$user}}) {
			next if $var eq "__history__";
			my $value = $self->{client}->{$user}->{$var};
			$self->{frozen}->{$user}->{$var} = $value;
		}

		# Back up the history.
		$self->{frozen}->{$user}->{__history__}->{input} = [
			@{$self->{client}->{$user}->{__history__}->{input}},
		];
		$self->{frozen}->{$user}->{__history__}->{reply} = [
			@{$self->{client}->{$user}->{__history__}->{reply}},
		];

		return 1;
	}

	return undef;
}

=item bool thawUservars (string $USER[, hash %OPTIONS])

If the variables for C<$USER> were previously frozen, this method will restore
them to the state they were in when they were last frozen. It will then delete
the stored cache by default. The following options are accepted as an additional
hash of parameters (these options are mutually exclusive and you shouldn't use
both of them at the same time. If you do, "discard" will win.):

  discard: Don't restore the user's state from the frozen copy, just delete the
           frozen copy.
  keep:    Keep the frozen copy even after restoring the user's state. With this
           you can repeatedly thawUservars on the same user to revert their state
           without having to keep freezing them again. On the next freeze, the
           last frozen state will be replaced with the new current state.

Examples:

  # Delete the frozen cache but don't modify the user's variables.
  $rs->thawUservars ("soandso", discard => 1);

  # Restore the user's state from cache, but don't delete the cache.
  $rs->thawUservars ("soandso", keep => 1);

=cut

sub thawUservars {
	my ($self,$user,%args) = @_;
	$user = '' unless defined $user;

	if (length $user && exists $self->{frozen}->{$user}) {
		# What are we doing?
		my $restore = 1;
		my $discard = 1;
		if (exists $args{discard}) {
			# Just discard the variables.
			$restore = 0;
			$discard = 1;
		}
		elsif (exists $args{keep}) {
			# Keep the cache afterwards.
			$restore = 1;
			$discard = 0;
		}

		# Restore the state?
		if ($restore) {
			# Clear the client's current information.
			$self->clearUservars ($user);

			# Restore all our variables.
			foreach my $var (keys %{$self->{frozen}->{$user}}) {
				next if $var eq "__history__";
				my $value = $self->{frozen}->{$user}->{$var};
				$self->{client}->{$user}->{$var} = $value;
			}

			# Restore the history.
			$self->{client}->{$user}->{__history__}->{input} = [
				@{$self->{frozen}->{$user}->{__history__}->{input}},
			];
			$self->{client}->{$user}->{__history__}->{reply} = [
				@{$self->{frozen}->{$user}->{__history__}->{reply}},
			];
		}

		# Discard the cache?
		if ($discard) {
			foreach my $var (keys %{$self->{frozen}->{$user}}) {
				delete $self->{frozen}->{$user}->{$var};
			}
		}
		return 1;
	}

	return undef;
}

=item string lastMatch (string $USER)

After fetching a reply for user C<$USER>, the C<lastMatch> method will return the
raw text of the trigger that the user has matched with their reply. This function
may return undef in the event that the user B<did not> match any trigger at all
(likely the last reply was "C<ERR: No Reply Matched>" as well).

=cut

sub lastMatch {
	my ($self,$user) = @_;
	$user = '' unless defined $user;

	# Get this user's last matched trigger.
	if (length $user && exists $self->{client}->{$user}->{__lastmatch__}) {
		return $self->{client}->{$user}->{__lastmatch__};
	}

	return undef;
}

=item string currentUser ()

Get the user ID of the current user chatting with the bot. This is mostly useful
inside of a Perl object macro in RiveScript to get the user ID of the person who
invoked the object macro (e.g., to get/set variables for them using the
C<$rs> instance).

This will return C<undef> if used outside the context of a reply (the value is
unset at the end of the C<reply()> method).

=back

=cut

sub currentUser {
	my $self = shift;

	if (!defined $self->{current_user}) {
		$self->issue("currentUser() is meant to be used from within a Perl object macro!");
	}

	return $self->{current_user};
}

################################################################################
## Interaction Methods                                                        ##
################################################################################

=head2 INTERACTION

=over 4

=item string reply (string $USER, string $MESSAGE)

Fetch a response to C<$MESSAGE> from user C<$USER>. RiveScript will take care of
lowercasing, running substitutions, and removing punctuation from the message.

Returns a response from the RiveScript brain.

=back

=cut

sub reply {
	my ($self,$user,$msg) = @_;

	$self->debug ("Get reply to [$user] $msg");

	# Store the current user's ID.
	$self->{current_user} = $user;

	# Format their message.
	$msg = $self->_formatMessage ($msg);

	my $reply = '';

	# If the BEGIN statement exists, consult it first.
	if (exists $self->{topics}->{__begin__}->{request}) {
		# Get a response.
		my $begin = $self->_getreply ($user,'request',
			context => 'begin',
			step    => 0, # Recursion redundancy counter
		);

		# Okay to continue?
		if ($begin =~ /\{ok\}/i) {
			$reply = $self->_getreply ($user,$msg,
				context => 'normal',
				step    => 0,
			);
			$begin =~ s/\{ok\}/$reply/ig;
		}

		$reply = $begin;

		# Run more tag substitutions.
		$reply = $self->processTags ($user,$msg,$reply,[],[],0);
	}
	else {
		# Just continue then.
		$reply = $self->_getreply ($user,$msg,
			context => 'normal',
			step    => 0,
		);
	}

	# Save their reply history.
	unshift (@{$self->{client}->{$user}->{__history__}->{input}}, $msg);
	while (scalar @{$self->{client}->{$user}->{__history__}->{input}} > 9) {
		pop (@{$self->{client}->{$user}->{__history__}->{input}});
	}

	unshift (@{$self->{client}->{$user}->{__history__}->{reply}}, $reply);
	while (scalar @{$self->{client}->{$user}->{__history__}->{reply}} > 9) {
		pop (@{$self->{client}->{$user}->{__history__}->{reply}});
	}

	# Unset the current user's ID.
	$self->{current_user} = undef;

	return $reply;
}

sub _getreply {
	my ($self,$user,$msg,%tags) = @_;

	# Need to sort replies?
	if (scalar keys %{$self->{sorted}} == 0) {
		$self->issue ("ERR: You never called sortReplies()! Start doing that from now on!");
		$self->sortReplies();
	}

	# Collect info on this user if we have it.
	my $topic = 'random';
	my @stars = ();
	my @thatstars = (); # For %previous's.
	my $reply = '';
	if (exists $self->{client}->{$user}) {
		$topic = $self->{client}->{$user}->{topic};
	}
	else {
		$self->{client}->{$user}->{topic} = 'random';
	}

	# Avoid letting the user fall into a missing topic.
	if (!exists $self->{topics}->{$topic}) {
		$self->issue ("User $user was in an empty topic named '$topic'!");
		$topic = 'random';
		$self->{client}->{$user}->{topic} = 'random';
	}

	# Avoid deep recursion.
	if ($tags{step} > $self->{depth}) {
		my $ref = '';
		if (exists $self->{syntax}->{$topic}->{$msg}->{ref}) {
			$ref = " at $self->{syntax}->{$topic}->{$msg}->{ref}";
		}
		$self->issue ("ERR: Deep Recursion Detected$ref!");
		return "ERR: Deep Recursion Detected$ref!";
	}

	# Are we in the BEGIN Statement?
	if ($tags{context} eq 'begin') {
		# Imply some defaults.
		$topic = '__begin__';
	}

	# Track this user's history.
	if (!exists $self->{client}->{$user}->{__history__}) {
		$self->{client}->{$user}->{__history__}->{input} = [
			'undefined', 'undefined', 'undefined', 'undefined',
			'undefined', 'undefined', 'undefined', 'undefined',
			'undefined',
		];
		$self->{client}->{$user}->{__history__}->{reply} = [
			'undefined', 'undefined', 'undefined', 'undefined',
			'undefined', 'undefined', 'undefined', 'undefined',
			'undefined',
		];
	}

	# Create a pointer for the matched data (be it %previous or +trigger).
	my $matched = {};
	my $matchedTrigger = undef;
	my $foundMatch = 0;

	# See if there are any %previous's in this topic, or any topic related to it. This
	# should only be done the first time -- not during a recursive @/{@} redirection.
	# This is because in a redirection, "lastreply" is still gonna be the same as it was
	# the first time, causing an infinite loop.
	if ($tags{step} == 0) {
		my @allTopics = ($topic);
		if (exists $self->{includes}->{$topic} || exists $self->{lineage}->{$topic}) {
			(@allTopics) = $self->_getTopicTree ($topic,0);
		}
		foreach my $top (@allTopics) {
			$self->debug ("Checking topic $top for any %previous's.");
			if (exists $self->{sortsthat}->{$top}) {
				$self->debug ("There's a %previous in this topic");

				# Do we have history yet?
				if (scalar @{$self->{client}->{$user}->{__history__}->{reply}} > 0) {
					my $lastReply = $self->{client}->{$user}->{__history__}->{reply}->[0];

					# Format the bot's last reply the same as the human's.
					$lastReply = $self->_formatMessage ($lastReply, "lastReply");

					$self->debug ("lastReply: $lastReply");

					# See if we find a match.
					foreach my $trig (@{$self->{sortsthat}->{$top}}) {
						my $botside = $self->_reply_regexp ($user,$trig);

						$self->debug ("Try to match lastReply ($lastReply) to $botside");

						# Look for a match.
						if ($lastReply =~ /^$botside$/i) {
							# Found a match! See if our message is correct too.
							(@thatstars) = ($lastReply =~ /^$botside$/i);
							foreach my $subtrig (@{$self->{sortedthat}->{$top}->{$trig}}) {
								my $humanside = $self->_reply_regexp ($user,$subtrig);

								$self->debug ("Now try to match $msg to $humanside");

								if ($msg =~ /^$humanside$/i) {
									$self->debug ("Found a match!");
									$matched = $self->{thats}->{$top}->{$trig}->{$subtrig};
									$matchedTrigger = $top;
									$foundMatch = 1;

									# Get the stars.
									(@stars) = ($msg =~ /^$humanside$/i);
									last;
								}
							}
						}

						# Break if we've found a match.
						last if $foundMatch;
					}
				}
			}

			# Break if we've found a match.
			last if $foundMatch;
		}
	}

	# Search their topic for a match to their trigger.
	if (not $foundMatch) {
		foreach my $trig (@{$self->{sorted}->{$topic}}) {
			# Process the triggers.
			my $regexp = $self->_reply_regexp ($user,$trig);

			$self->debug ("Trying to match \"$msg\" against $trig ($regexp)");

			if ($msg =~ /^$regexp$/i) {
				$self->debug ("Found a match!");

				# We found a match, but what if the trigger we matched belongs to
				# an inherited topic? Check for that.
				if (exists $self->{topics}->{$topic}->{$trig}) {
					# No, the trigger does belong to our own topic.
					$matched = $self->{topics}->{$topic}->{$trig};
				}
				else {
					# Our topic doesn't have this trigger. Check inheritence.
					$matched = $self->_findTriggerByInheritence ($topic,$trig,0);
				}

				$foundMatch = 1;
				$matchedTrigger = $trig;

				# Get the stars.
				(@stars) = ($msg =~ /^$regexp$/i);
				last;
			}
		}
	}

	# Store what trigger they matched on (if $matched is undef, this will be
	# too, which is great).
	$self->{client}->{$user}->{__lastmatch__} = $matchedTrigger;

	for (defined $matched) {
		# See if there are any hard redirects.
		if (exists $matched->{redirect}) {
			$self->debug ("Redirecting us to $matched->{redirect}");
			my $redirect = $matched->{redirect};
			$redirect = $self->processTags ($user,$msg,$redirect,[@stars],[@thatstars],$tags{step});
			$self->debug ("Pretend user asked: $redirect");
			$reply = $self->_getreply ($user,$redirect,
				context => $tags{context},
				step    => ($tags{step} + 1),
			);
			last;
		}

		# Check the conditionals.
		if (exists $matched->{condition}) {
			$self->debug ("Checking conditionals");
			for (my $i = 0; exists $matched->{condition}->{$i}; $i++) {
				my ($cond,$potreply) = split(/\s*=>\s*/, $matched->{condition}->{$i}, 2);
				my ($left,$eq,$right) = ($cond =~ /^(.+?)\s+(==|eq|\!=|ne|\<\>|\<|\<=|\>|\>=)\s+(.+?)$/i);

				$self->debug ("\tLeft: $left; EQ: $eq; Right: $right");

				# Process tags on all of these.
				$left = $self->processTags ($user,$msg,$left,[@stars],[@thatstars],$tags{step});
				$right = $self->processTags ($user,$msg,$right,[@stars],[@thatstars],$tags{step});

				# Revert them to undefined values.
				$left = 'undefined' if $left eq '';
				$right = 'undefined' if $right eq '';

				$self->debug ("\t\tCheck if \"$left\" $eq \"$right\"");

				# Validate the expression.
				my $match = 0;
				if ($eq eq 'eq' || $eq eq '==') {
					if ($left eq $right) {
						$match = 1;
					}
				}
				elsif ($eq eq 'ne' || $eq eq '!=' || $eq eq '<>') {
					if ($left ne $right) {
						$match = 1;
					}
				}
				elsif ($eq eq '<') {
					if ($left < $right) {
						$match = 1;
					}
				}
				elsif ($eq eq '<=') {
					if ($left <= $right) {
						$match = 1;
					}
				}
				elsif ($eq eq '>') {
					if ($left > $right) {
						$match = 1;
					}
				}
				elsif ($eq eq '>=') {
					if ($left >= $right) {
						$match = 1;
					}
				}

				if ($match) {
					# Condition is true.
					$reply = $potreply;
					last;
				}
			}
		}
		last if length $reply > 0;

		# Process weights in the replies.
		my @bucket = ();
		$self->debug ("Processing responses to this trigger.");
		for (my $rep = 0; exists $matched->{reply}->{$rep}; $rep++) {
			my $text = $matched->{reply}->{$rep};
			my $weight = 1;
			if ($text =~ /{weight=(\d+)\}/i) {
				$weight = $1;
				if ($weight <= 0) {
					$weight = 1;
					$self->issue ("Can't have a weight < 0!");
				}
			}
			for (my $i = 0; $i < $weight; $i++) {
				push (@bucket,$text);
			}
		}

		# Get a random reply.
		$reply = $bucket [ int(rand(scalar(@bucket))) ];
		last;
	}

	# Still no reply?
	if ($foundMatch == 0) {
		$reply = RS_ERR_MATCH;
	}
	elsif (!defined $reply || length $reply == 0) {
		$reply = RS_ERR_REPLY;
	}

	$self->debug ("Reply: $reply");

	# Process tags for the BEGIN Statement.
	if ($tags{context} eq 'begin') {
		if ($reply =~ /\{topic=(.+?)\}/i) {
			# Set the user's topic.
			$self->debug ("Topic set to $1");
			$self->{client}->{$user}->{topic} = $1;
			$reply =~ s/\{topic=(.+?)\}//ig;
		}
		while ($reply =~ /<set (.+?)=(.+?)>/i) {
			# Set a user variable.
			$self->debug ("Set uservar $1 => $2");
			$self->{client}->{$user}->{$1} = $2;
			$reply =~ s/<set (.+?)=(.+?)>//i;
		}
	}
	else {
		# Process more tags if not in BEGIN.
		$reply = $self->processTags($user,$msg,$reply,[@stars],[@thatstars],$tags{step});
	}

	return $reply;
}

sub _findTriggerByInheritence {
	my ($self,$topic,$trig,$depth) = @_;

	# This sub was called because the user matched a trigger from the
	# sorted array, but the trigger doesn't exist under the topic of
	# which the user currently belongs. It probably was a trigger
	# inherited/included from another topic. This subroutine finds that out,
	# recursively, following the inheritence trail.

	# Take care to prevent infinite recursion.
	if ($depth > $self->{depth}) {
		$self->issue("Deep recursion detected while following an inheritence trail (involving topic $topic and trigger $trig)");
		return undef;
	}

	# Inheritence is more important than inclusion: triggers in one topic
	# can override those in an inherited topic.
	if (exists $self->{lineage}->{$topic}) {
		foreach my $inherits (sort { $a cmp $b } keys %{$self->{lineage}->{$topic}}) {
			# See if this inherited topic has our trigger.
			if (exists $self->{topics}->{$inherits}->{$trig}) {
				# Great!
				return $self->{topics}->{$inherits}->{$trig};
			}
			else {
				# Check what this topic inherits from.
				my $match = $self->_findTriggerByInheritence (
					$inherits, $trig, ($depth + 1),
				);
				if (defined $match) {
					# Finally got a match.
					return $match;
				}
			}
		}
	}

	# See if this topic has an "includes".
	if (exists $self->{includes}->{$topic}) {
		foreach my $includes (sort { $a cmp $b } keys %{$self->{includes}->{$topic}}) {

			# See if this included topic has our trigger.
			if (exists $self->{topics}->{$includes}->{$trig}) {
				# Great!
				return $self->{topics}->{$includes}->{$trig};
			}
			else {
				# Check what this topic includes from.
				my $match = $self->_findTriggerByInheritence (
					$includes, $trig, ($depth + 1),
				);
				if (defined $match) {
					# Finally got a match.
					return $match;
				}
			}
		}
	}

	# Don't know what else we can do.
	return undef;
}

sub _reply_regexp {
	my ($self,$user,$regexp) = @_;

	# If the trigger is simply /^\*$/ (+ *) then the * there needs to
	# become (.*?) to match the blank string too.
	$regexp =~ s/^\*$/<zerowidthstar>/i;

	$regexp =~ s/\*/(.+?)/ig;        # Convert * into (.+?)
	$regexp =~ s/\#/(\\d+)/ig;    # Convert # into ([0-9]+?)
	$regexp =~ s/\_/(\\w+)/ig; # Convert _ into ([A-Za-z]+?)
	$regexp =~ s/\{weight=\d+\}//ig; # Remove {weight} tags.
	$regexp =~ s/<zerowidthstar>/(.*?)/i;
	while ($regexp =~ /\[(.+?)\]/i) { # Optionals
		my @parts = split(/\|/, $1);
		my @new = ();
		foreach my $p (@parts) {
			$p = '(?:\s|\b)+' . $p . '(?:\s|\b)+';
			push (@new,$p);
		}

		# If this optional had a star or anything in it, e.g. [*],
		# make that non-matching.
		my $pipes = join("|",@new);
		$pipes =~ s/\(\.\+\?\)/(?:.+?)/ig; # (.+?) --> (?:.+?)
		$pipes =~ s/\(\\d\+\)/(?:\\d+)/ig; # (\d+) --> (?:\d+)
		$pipes =~ s/\(\\w\+\)/(?:\\w+)/ig; # (\w+) --> (?:\w+)

		my $rep = "(?:$pipes|(?:\\s|\\b)+)";
		$regexp =~ s/\s*\[(.+?)\]\s*/$rep/i;
	}

    # _ wildcards can't match numbers!
    $regexp =~ s/\\w/[A-Za-z]/g;

	# Filter in arrays.
	while ($regexp =~ /\@(.+?)\b/) {
		my $name = $1;
		my $rep = '';
		if (exists $self->{arrays}->{$name}) {
			$rep = '(?:' . join ("|",@{$self->{arrays}->{$name}}) . ')';
		}
		$regexp =~ s/\@(.+?)\b/$rep/i;
	}

	# Filter in bot variables.
	while ($regexp =~ /<bot (.+?)>/i) {
		my $var = $1;
		my $rep = '';
		if (exists $self->{bot}->{$var}) {
			$rep = $self->{bot}->{$var};
			$rep =~ s/[^A-Za-z0-9 ]//ig;
			$rep = lc($rep);
		}
		$regexp =~ s/<bot (.+?)>/$rep/i;
	}

	# Filter in user variables.
	while ($regexp =~ /<get (.+?)>/i) {
		my $var = $1;
		my $rep = '';
		if (exists $self->{client}->{$user}->{$var}) {
			$rep = $self->{client}->{$user}->{$var};
			$rep =~ s/[^A-Za-z0-9 ]//ig;
			$rep = lc($rep);
		}
		$regexp =~ s/<get (.+?)>/$rep/i;
	}

	# Filter input tags.
	if ($regexp =~ /<input/i) {
		my $firstInput = $self->_formatMessage($self->{client}->{$user}->{__history__}->{input}->[0] || "undefined", "botReply");
		$regexp =~ s/<input>/$firstInput/ig;
		while ($regexp =~ /<input([1-9])>/i) {
			my $index = $1;
			my (@arrInput) = @{$self->{client}->{$user}->{__history__}->{input}};
			unshift (@arrInput,'');
			my $line = $arrInput[$index];
			$line = $self->_formatMessage ($line, "botReply");
			$regexp =~ s/<input$index>/$line/ig;
		}
	}
	if ($regexp =~ /<reply/i) {
		my $firstReply = $self->_formatMessage($self->{client}->{$user}->{__history__}->{reply}->[0] || "undefined", "botReply");
		$regexp =~ s/<reply>/$firstReply/ig;
		while ($regexp =~ /<reply([1-9])>/i) {
			my $index = $1;
			my (@arrReply) = @{$self->{client}->{$user}->{__history__}->{reply}};
			unshift (@arrReply,'');
			my $line = $arrReply[$index];
			$line = $self->_formatMessage ($line, "botReply");
			$regexp =~ s/<reply$index>/$line/ig;
		}
	}

	return $regexp;
}

sub processTags {
	my ($self,$user,$msg,$reply,$st,$bst,$depth) = @_;
	my (@stars) = (@{$st});
	my (@botstars) = (@{$bst});
	unshift (@stars,"");
	unshift (@botstars,"");
	if (scalar(@stars) == 1) {
		push (@stars,'undefined');
	}
	if (scalar(@botstars) == 1) {
		push (@botstars,'undefined');
	}

	my (@arrInput) = @{$self->{client}->{$user}->{__history__}->{input}};
	my (@arrReply) = @{$self->{client}->{$user}->{__history__}->{reply}};

	my $lastInput = $arrInput[0] || 'undefined';
	my $lastReply = $arrReply[0] || 'undefined';
	unshift(@arrInput,'');
	unshift(@arrReply,'');

	# Tag Shortcuts.
	$reply =~ s/<person>/{person}<star>{\/person}/ig;
	$reply =~ s/<\@>/{\@<star>}/ig;
	$reply =~ s/<formal>/{formal}<star>{\/formal}/ig;
	$reply =~ s/<sentence>/{sentence}<star>{\/sentence}/ig;
	$reply =~ s/<uppercase>/{uppercase}<star>{\/uppercase}/ig;
	$reply =~ s/<lowercase>/{lowercase}<star>{\/lowercase}/ig;

	# Quick tags.
	$reply =~ s/\{weight=(\d+)\}//ig; # Remove leftover {weight}s
	if (scalar(@stars) > 0) {
		$reply =~ s/<star>/$stars[1]/ig if defined $stars[1];
		$reply =~ s/<star(\d+)>/(defined $stars[$1] ? $stars[$1] : '')/ieg;
	}
	if (scalar(@botstars) > 0) {
		$reply =~ s/<botstar>/$botstars[1]/ig;
		$reply =~ s/<botstar(\d+)>/(defined $botstars[$1] ? $botstars[$1] : '')/ieg;
	}
	$reply =~ s/<input>/$lastInput/ig;
	$reply =~ s/<reply>/$lastReply/ig;
	$reply =~ s/<input([1-9])>/$arrInput[$1]/ig;
	$reply =~ s/<reply([1-9])>/$arrReply[$1]/ig;
	$reply =~ s/<id>/$user/ig;
	$reply =~ s/\\s/ /ig;
	$reply =~ s/\\n/\n/ig;
	$reply =~ s/\\/\\/ig;
	$reply =~ s/\\#/#/ig;

	while ($reply =~ /\{random\}(.+?)\{\/random\}/i) {
		my $rand = $1;
		my $output = '';
		if ($rand =~ /\|/) {
			my @tmp = split(/\|/, $rand);
			$output = $tmp [ int(rand(scalar(@tmp))) ];
		}
		else {
			my @tmp = split(/\s+/, $rand);
			$output = $tmp [ int(rand(scalar(@tmp))) ];
		}
		$reply =~ s/\{random\}(.+?)\{\/random\}/$output/i;
	}
	while ($reply =~ /\{\!(.+?)\}/i) {
		# Just stream this back through.
		$self->stream ("! $1");
		$reply =~ s/\{\!(.+?)\}//i;
	}
	while ($reply =~ /\{person\}(.+?)\{\/person\}/i) {
		my $person = $1;
		$person = $self->_personSub ($person);
		$reply =~ s/\{person\}(.+?)\{\/person\}/$person/i;
	}
	while ($reply =~ /\{formal\}(.+?)\{\/formal\}/i) {
		my $formal = $1;
		$formal = $self->_stringUtil ('formal',$formal);
		$reply =~ s/\{formal\}(.+?)\{\/formal\}/$formal/i;
	}
	while ($reply =~ /\{sentence\}(.+?)\{\/sentence\}/i) {
		my $sentence = $1;
		$sentence = $self->_stringUtil ('sentence',$sentence);
		$reply =~ s/\{sentence\}(.+?)\{\/sentence\}/$sentence/i;
	}
	while ($reply =~ /\{uppercase\}(.+?)\{\/uppercase\}/i) {
		my $upper = $1;
		$upper = $self->_stringUtil ('upper',$upper);
		$reply =~ s/\{uppercase\}(.+?)\{\/uppercase\}/$upper/i;
	}
	while ($reply =~ /\{lowercase\}(.+?)\{\/lowercase\}/i) {
		my $lower = $1;
		$lower = $self->_stringUtil ('lower',$lower);
		$reply =~ s/\{lowercase\}(.+?)\{\/lowercase\}/$lower/i;
	}

	# Handle all variable-related tags with an iterative regexp approach,
	# to allow for nesting of tags in arbitrary ways (think <set a=<get b>>)
	# Dummy out the <call> tags first, because we don't handle them right here.
	$reply =~ s/<call>/{__call__}/og;
	$reply =~ s/<\/call>/{\/__call__}/og;
	while (1) {
		# This regexp will match a <tag> which contains no other tag inside it,
		# i.e. in the case of <set a=<get b>> it will match <get b> but not the
		# <set> tag, on the first pass. The second pass will get the <set> tag,
		# and so on.
		if ($reply =~ /<([^<]+?)>/) {
			my $match  = $1;
			my @parts  = split(/\s+/, $match, 2);
			my $tag    = lc($parts[0]);
			my $data   = $parts[1] || "";
			my $insert = ""; # Result of the tag evaluation.

			# Handle the tags.
			if ($tag eq "bot" or $tag eq "env") {
				# <bot> and <env> tags are similar.
				my ($what, $is) = split(/=/, $data, 2);
				my $target = $self->{bot};
				if ($tag eq "env") {
					# Reserved?
					my $reserved = 0;
					foreach my $res (@{$self->{reserved}}) {
						if ($res eq $what) {
							$reserved = 1;
							last;
						}
					}
					if ($reserved) {
						$target = $self->{globals};
					}
					else {
						$target = $self;
					}
				}

				# Updating?
				if ($data =~ /=/) {
					$self->debug("Set $tag variable $what => $is");
					$target->{$what} = $is;
				}
				else {
					$insert = exists $target->{$what} ? $target->{$what} : "undefined";
				}
			}
			elsif ($tag eq "set") {
				# <set> user vars.
				my ($what, $is) = split(/=/, $data, 2);
				$self->debug("Set uservar $what => $is");
				$self->{client}->{$user}->{$what} = $is;
			}
			elsif ($tag =~ /^(?:add|sub|mult|div)$/) {
				my ($var, $value) = split(/=/, $data, 2);

				# Initialize the value?
				if (!exists $self->{client}->{$user}->{$var}) {
					$self->{client}->{$user}->{$var} = 0;
				}

				# Sanity checks.
				if ($self->{client}->{$user}->{$var} !~ /^[0-9\-\.]+$/) {
					$insert = "[ERR: Can't Modify Non-Numeric Variable $var]";
				}
				elsif ($value =~ /^[^0-9\-\.]$/) {
					$insert = "[ERR: Math Can't '$tag' Non-Numeric Value $value]";
				}
				else {
					# Modify the variable.
					if ($tag eq "add") {
						$self->{client}->{$user}->{$var} += $value;
					}
					elsif ($tag eq "sub") {
						$self->{client}->{$user}->{$var} -= $value;
					}
					elsif ($tag eq "mult") {
						$self->{client}->{$user}->{$var} *= $value;
					}
					elsif ($tag eq "div") {
						# Don't divide by zero.
						if ($value == 0) {
							$insert = "[ERR: Can't Divide By Zero]";
						}
						else {
							$self->{client}->{$user}->{$var} /= $value;
						}
					}
				}
			}
			elsif ($tag eq "get") {
				$insert = (exists $self->{client}->{$user}->{$data} ? $self->{client}->{$user}->{$data} : "undefined");
			}
			else {
				# Might be HTML tag, it's unrecognized. Preserve it.
				$insert = "\x00$match\x01";
			}

			$reply =~ s/<$match>/$insert/i;
		}
		else {
			last; # No more tags remaining.
		}
	}

	# Recover mangled HTML-like tag parts.
	$reply =~ s/\x00/</g;
	$reply =~ s/\x01/>/g;

	if ($reply =~ /\{topic=(.+?)\}/i) {
		# Set the user's topic.
		$self->debug ("Topic set to $1");
		$self->{client}->{$user}->{topic} = $1;
		$reply =~ s/\{topic=(.+?)\}//ig;
	}
	while ($reply =~ /\{\@(.+?)\}/i) {
		my $at = $1;
		$at =~ s/^\s+//ig;
		$at =~ s/\s+$//ig;
		my $subreply = $self->_getreply ($user,$at,
			context => 'normal',
			step    => ($depth + 1),
		);
		$reply =~ s/\{\@(.+?)\}/$subreply/i;
	}
	$reply =~ s/\{__call__\}/<call>/g;
	$reply =~ s/\{\/__call__\}/<\/call>/g;
	while ($reply =~ /<call>(.+?)<\/call>/i) {
		my ($obj,@args) = split(/\s+/, $1);
		my $output = '';

		# What language handles this object?
		my $lang = exists $self->{objlangs}->{$obj} ? $self->{objlangs}->{$obj} : '';
		if (length $lang) {
			# Do we handle this?
			if (exists $self->{handlers}->{$lang}) {
				# Ok.
				$output = &{ $self->{handlers}->{$lang} } ($self,"call",$obj,[@args]);
			}
			else {
				$output = '[ERR: No Object Handler]';
			}
		}
		else {
			$output = '[ERR: Object Not Found]';
		}

		$reply =~ s/<call>(.+?)<\/call>/$output/i;
	}

	return $reply;
}

sub _formatMessage {
	my ($self,$string, $botReply) = @_;

	# Lowercase it.
	$string = lc($string);

	# Make placeholders each time we substitute something.
	my @ph = ();
	my $i = 0;

	# Run substitutions on it.
	foreach my $pattern (@{$self->{sortlist}->{subs}}) {
		my $result = $self->{subs}->{$pattern};

		# Make a placeholder.
		push (@ph, $result);
		my $placeholder = "\x00$i\x00";
		$i++;

		my $qm = quotemeta($pattern);
		$string =~ s/^$qm$/$placeholder/ig;
		$string =~ s/^$qm(\W+)/$placeholder$1/ig;
		$string =~ s/(\W+)$qm(\W+)/$1$placeholder$2/ig;
		$string =~ s/(\W+)$qm$/$1$placeholder/ig;
	}
	while ($string =~ /\x00(\d+)\x00/i) {
		my $id = $1;
		my $result = $ph[$id];
		$string =~ s/\x00$id\x00/$result/i;
	}

	# In UTF-8 mode, only strip meta characters.
	if ($self->{utf8}) {
		# Backslashes and HTML tags
		$string =~ s/[\\<>]//g;
		$string =~ s/$self->{unicode_punctuation}//g;

		# If formatting the bot's last reply for %Previous, also remove punctuation.
		if ($botReply) {
			$string =~ s/[.?,!;:@#$%^&*()\-+]//g;
		}
	} else {
		$string =~ s/[^A-Za-z0-9 ]//g;
	}

	# In UTF-8 mode, only strip meta characters.
	if ($self->{utf8}) {
		# Backslashes and HTML tags
		$string =~ s/[\\<>]//g;
	} else {
		$string =~ s/[^A-Za-z0-9 ]//g;
	}

	# Remove excess whitespace and consolidate multiple spaces down to one.
	$string =~ s/^\s+//g;
	$string =~ s/\s+$//g;
	$string =~ s/\s+/ /g;

	return $string;
}

sub _stringUtil {
	my ($self,$type,$string) = @_;

	if ($type eq 'formal') {
		$string =~ s/\b(\w+)\b/\L\u$1\E/ig;
	}
	elsif ($type eq 'sentence') {
		$string =~ s/\b(\w)(.*?)(\.|\?|\!|$)/\u$1\L$2$3\E/ig;
	}
	elsif ($type eq 'upper') {
		$string = uc($string);
	}
	elsif ($type eq 'lower') {
		$string = lc($string);
	}

	return $string;
}

sub _personSub {
	my ($self,$string) = @_;

	# Make placeholders each time we substitute something.
	my @ph = ();
	my $i = 0;

	# Substitute each of the sorted person sub arrays in order,
	# using a one-way substitution algorithm (read: base13).
	foreach my $pattern (@{$self->{sortlist}->{person}}) {
		my $result = $self->{person}->{$pattern};

		# Make a placeholder.
		push (@ph, $result);
		my $placeholder = "\x00$i\x00";
		$i++;

		my $qm = quotemeta($pattern);
		$string =~ s/^$qm$/$placeholder/ig;
		$string =~ s/^$qm(\W+)/$placeholder$1/ig;
		$string =~ s/(\W+)$qm(\W+)/$1$placeholder$2/ig;
		$string =~ s/(\W+)$qm$/$1$placeholder/ig;
	}

	while ($string =~ /\x00(\d+)\x00/i) {
		my $id = $1;
		my $result = $ph[$id];
		$string =~ s/\x00$id\x00/$result/i;
	}

	return $string;
}

1;
__END__

=head1 RIVESCRIPT

This interpreter tries its best to follow RiveScript standards. Currently it
supports RiveScript 2.0 documents. A current copy of the RiveScript working
draft is included with this package: see L<RiveScript::WD>.

=head1 UTF-8 SUPPORT

RiveScript supports Unicode but it is not enabled by default. Enable it by
passing a true value for the C<utf8> option in the constructor, or by using the
C<--utf8> argument to the C<rivescript> application.

In UTF-8 mode, most characters in a user's message are left intact, except for
certain metacharacters like backslashes and common punctuation characters like
C</[.,!?;:]/>.

If you want to override the punctuation regexp, you can provide a new one by
assigning the `unicode_punctuation` attribute of the bot object after
initialization. Example:

  my $bot = new RiveScript(utf8 => 1);
  $bot->{unicode_punctuation} = qr/[.,!?;:]/;

=head1 CONSTANTS

This module can export some constants.

  use RiveScript qw(:standard);

These constants include:

=over 4

=item RS_ERR_MATCH

This is the reply text given when no trigger has matched the message. It equals
"C<ERR: No Reply Matched>".

  if ($reply eq RS_ERR_MATCH) {
    $reply = "I couldn't find a good reply for you!";
  }

=item RS_ERR_REPLY

This is the reply text given when a trigger I<was> matched, but no reply was
given from it (for example, the trigger only had conditionals and all of them
were false, with no default replies to fall back on). It equals
"C<ERR: No Reply Found>".

  if ($reply eq RS_ERR_REPLY) {
    $reply = "I don't know what to say about that!";
  }

=back

=head1 SEE ALSO

L<RiveScript::WD> - A current snapshot of the Working Draft that
defines the standards of RiveScript.

L<http://www.rivescript.com/> - The official homepage of RiveScript.

=head1 CHANGES

  2.0.3  Aug 26 2016
  - Fix inline comment regexp that was making URLs impossible to represent
    in replies.

  2.0.2  Jan 11 2016
  - Fix typo in changelog.

  2.0.1  Jan 11 2016
  - When formatting a user's message, consolidate multiple consecutive spaces
    down to one.
  - Apply downstream Debian patch that fixes a typo in RiveScript::WD.

  2.0.0  Dec 28 2015
  - Switch from old-style floating point version number notation to dotted
    decimal notation. This bumps the version number to `2.0.0` because the next
    dotted-decimal version greater than `1.42` (`v1.420.0`) is `v1.421.0` and
    I don't like having that many digits in the version number. This release is
    simply a version update; no breaking API changes were introduced.

  1.42  Nov 20 2015
  - Add configurable `unicode_punctuation` attribute to strip out punctuation
    when running in UTF-8 mode.

  1.40  Oct 10 2015
  - Fix the regexp used when matching optionals so that the triggers don't match
    on inputs where they shouldn't. (RiveScript-JS issue #46)

  1.38  Jul 21 2015
  - New algorithm for handling variable tags (<get>, <set>, <add>, <sub>,
    <mult>, <div>, <bot> and <env>) that allows for iterative nesting of these
    tags (for example, <set copy=<get orig>> will work now).
  - Fix trigger sorting so that triggers with matching word counts are sorted
    by length descending.
  - Add support for `! local concat` option to override concatenation mode
    (file scoped)
  - Bugfix where Perl object macros set via `setSubroutine()` failed to load
    because they were missing a programming language internally.

  1.36  Nov 26 2014
  - Relicense under the MIT License.
  - Strip punctuation from the bot's responses in UTF-8 mode to
    support compatibility with %Previous.
  - Bugfix in deparse(): If you had two matching triggers, one with a %Previous
    and one without, you'd lose the data for one of them in the output.

  1.34  Feb 26 2014
  - Update README.md to include module documentation for github.
  - Fixes to META.yml

  1.32  Feb 24 2014
  - Maintenance release to fix some errors per the CPANTS.
  - Add license to Makefile.PL
  - Make Makefile.PL not executable
  - Make version numbers consistent

  1.30  Nov 25 2013
  - Added "TCP Mode" to the `rivescript` command so that it can listen on a
    socket instead of using standard input and output.
  - Added a "--data" option to the `rivescript` command for providing JSON
    input as a command line argument instead of standard input.
  - Added experimental UTF-8 support.
  - Bugfix: don't use hacky ROT13-encoded placeholders for message
    substitutions... use a null character method instead. ;)
  - Make .rive the default preferred file extension for RiveScript documents
    instead of .rs (which conflicts with the Rust programming language).
    Backwards compatibility remains to load .rs files, though.

See the `Changes` file for older change history.

=head1 AUTHOR

  Noah Petherbridge, http://www.kirsle.net

=head1 KEYWORDS

bot, chatbot, chatterbot, chatter bot, reply, replies, script, aiml, alpha

=head1 COPYRIGHT AND LICENSE

  The MIT License (MIT)

  Copyright (c) 2015 Noah Petherbridge

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

=cut
