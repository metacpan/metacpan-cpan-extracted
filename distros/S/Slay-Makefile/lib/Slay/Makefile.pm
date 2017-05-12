package Slay::Makefile;

use warnings;
no warnings qw(void);
use strict;

=head1 NAME

Slay::Makefile - Wrapper to Slay::Maker that reads the rules from a file

=cut

our $VERSION = '0.12';

=head1 DESCRIPTION

C<Slay::Maker> is a make engine that uses perl declaration syntax for
rules, including regular expressions for targets and anonymous subs
for targets, dependencies, and actions.  This C<Slay::Makefile>
wrapper allows for the rules to be contained within a SlayMakefile
file whose syntax is similar to that of a normal Makefile.

=head1 FILE SYNTAX

The file syntax is a series of statements where each statement is one of:

   <perl-block>

   <target(s)> : <dependencies>
           <actions>

   [-] include <filename>

   # Comment

<perl-block> has the syntax:

   {
       <perl-statement(s)>
   }

where <perl-statement(s)> is any series of perl statements.

<target(s>) is either a space-delimited set of targets, each of which
is either a literal string or a <perl-block> which returns an array,
each of which is either a literal string or a regular expression
('Regexp') reference (C<qr/.../>).  A literal string can contain a
C<%> character to act as a wild-card, just as with GNU make.  However,
the Regexp feature is more general, since it can capture more than one
substring and use the values C<$!>, C<$2>, ... inside the
dependencies.  Note that only one target can realistically contain
wildcards, whether in a Regexp or using C<%>, since there is only one
set of C<$1>, C<$2>, ... variables.

The colon separating a <perl-block> for <target(s)> must be on the
same line as the closing brace of the <perl-block>.

<dependencies> is either a space-delimited set of dependency strings
or a <perl-block> which returns an array of dependencies (or a
combination). The dependency string can contain C<$1>, C<$2>, ..., or
C<%>, which is synonymous with C<$1> and C<${TARGET}>, which gets the
target name.  They can also use any scalar global variables previously
defined in a <perl-block>.  A dependency <perl-block> is called with
the values C<($make, $target, $matches)>, where C<$make> is a
C<Slay::Maker> object, C<$target> is the target name, and C<$matches> is
a reference to an array containing the captured values from that
target's Regexp (if any).

The colon separating a <perl-block> for <dependencies> must be on the
same line as the opening brace of the <perl-block>.

<actions> is a series of zero or more action "lines", where each
action is either a string, which will be executed inside a shell, a
perl anonymous array, which is executed without a shell (see
IPC::Run), or a <perl-block>.  For purposes of this discussion, a
"line" continues as long as the lines of string action end with "\" or
as long as a perl anonymous array or <perl-block> do not have their
closing punctuation.  A string action can use the strings C<$1>,
C<$2>, ..., for the matches, C<$DEP0>, C<$DEP1>, ..., for the
dependencies, and C<$TARGET>, which represents the target being built.
For make enthusiasts, C<$*> can be used for C<$1>.  A string action
can also use any scalar global variables previously defined in a
<perl-block>.  An action <perl-block> is called with the values
C<($make, $target, $deps, $matches)>, where C<$make> is a C<Slay::Maker>
object, C<$target> is the target name, C<$deps> is a reference to the
array of dependencies and $matches is a reference to an array
containing the captured values from that target's Regexp (if any).

An include line includes the content of a file with <filename> as a
SlayMakefile file.  If there is no such file, C<Slay::Makefile> tries
to build it using rules that have already been presented.  If there is
no such rule, C<Slay::Makefile> exits with an error unless there was a
C<-> before the "include".

The equivalent of make's defines are handled by setting perl global
variables.  Each main <perl-block> is executed in the order it appears
in the file, but any <perl-block> that is part of a dependency or
action is evaluated lazily, so that all the global variables will have
been set.  A main <perl-block> is called with the value
C<($makefile)>, where C<$makefile> is the C<Slay::Makefile> object,
so that such code can, for example, recursively call the parse method.

Comments begin with a C<#> and extend to the end of line.

Continuation lines can be specified by putting a backslash at the end
of the previous line, provided however, that continuation lines are
unnecessary (automatic) within a perl block or perl anonymous array.
Although continuation lines in a perl dependency or action must begin
with at least one space so a that the parser does not think a new rule
is beginning, the minimum indentation is removed prior to evaluation
so that HEREIS strings can be used.

=head1 METHODS

=over

=cut

use Carp;
use Slay::Maker 0.04;

=item C<new([$options])>

Class method.  Creates a new C<Slay::Makefile> object using the
optional C<$options> argument.  It also process the following options
out of C<$options>:

  strict:      If 0, do not enforce strict checking on perl blocks

=cut

sub new {
    my ($class, $options) = @_;

    my $self = bless {}, $class;
    $options = {} unless $options;

    $self->{maker}   = new Slay::Maker({options => $options});
    $self->{options} = $options;

    return $self;
}

=item C<maker>

Method.  Returns the C<Slay::Maker> object used by this
C<Slay::Makefile> object.

=cut

sub maker : method {
    return $_[0]{maker};
}

=item C<make (@targets)>

Method.  Calls the C<Slay::Maker> object's make method to build the list
of targets.  If no targets are given, makes the targets of the first rule 
with constant targets.

=cut

# '
sub make : method {
    my $self = shift;
    
    $self->_croak('No targets specified and no default target provided')
	if ! @_ && ! $self->{first};
    $self->{maker}->make(@_ ? @_ : $self->{first}->targets);
}

=item C<parse ($filename)>

Method.  Parses file C<$filename> as a SlayMakefile and populates the
C<Slay::Maker> object with its rules.  Returns a reference to an array
of parse errors.

=cut

sub parse : method {
    my ($self, $filename) = @_;

    open IN, $filename or croak "Cannot open $filename";
    my $string = join '', <IN>;
    close IN;
    return $self->parse_string($string, $filename);
}

=item C<parse_string ($string, [$filename, [$lineno]])>

Method.  Parses C<$string> as a SlayMakefile.  If C<$filename> and/or
C<$lineno> arguments are provided, they are used for more detailed
error reporting.  Returns a reference to an array of parse errors.

=cut

sub parse_string : method {
    my ($self, $string, $filename, $lineno) = @_;

    $self->{errors} = [];
    $lineno ||= 1;

    my $in_braces = 0;
    my $stmt = '';
    my $stmt_line = $lineno;

    my $EOL = '(?:\n\r?|\r\n?)';
    my @lines = split /$EOL/o, $string;
  parse_stmt:
    for (my $l=0; $l < @lines; $l++) {
	$_ = $lines[$l];
	# TODO: The following does not check whether braces are in
	# strings, comments, or are backslash-quoted...
	s/^\s*\#.*// if $in_braces == 0; # Delete comments
	my $net_braces = tr/\{// - tr/\}//;
	$in_braces += $net_braces;
	# Append this line to the previous statement
	$stmt .= "$_\n";
	if ($in_braces <= 0 && ! /\\$/) {
	    # We may have a statement to process
	    if ($stmt =~ /^\s*$/) {
		# Ignore null statement
	    }
	    elsif ($stmt =~ /^\s*(-?)\s*include\s+(?!:)(.*)/) {
		# include directive
		my ($opt, $incfile) = ($1, $2);
		$incfile = eval qq(package Slay::Makefile::Eval; "$incfile");
		if (! -f $incfile) {
		    # Check if we can build it with rules we already have
		    eval { $self->{maker}->make($incfile) } ;
		}
		if (-f $incfile) {
		    1;		# Coverage misses next statement without this
		    $self->parse($incfile);
		}
		elsif (! $opt) {
		    1;		# Coverage misses next statement without this
		    $self->_croak("Cannot build include file '$incfile'",
				  $filename, $stmt_line);
		}
	    }
	    else {
		my $braces;
		# Need to collapse matching { } pairs
		($stmt, $braces) = _collapse($stmt);
		my $re = %$braces ? join('|', keys %$braces) : "\n";
		if ($stmt =~ /^(?!\s)(.*?)\s*:\s*(.*)/) {
		    my ($raw_tgts, $raw_deps) = ($1, $2);
		    my (@tgts, @deps, @acts);
		    my $rule_line = $stmt_line;
		    # It's a rule

		    # Process the targets
		    my @raw_tgts = split /\s+/, $raw_tgts;
		    foreach my $target (@raw_tgts) {
			if ($target =~ s/^($re)//) {
			    # A perl expression
			    my $perl = _expand($1, $braces);
			    if ($perl eq '') { # It was a \ at end of line
				$rule_line++;
				next;
			    }
			    my @targets = $self->_eval($perl,
						       $filename, $rule_line);
			    foreach (@targets) {
				my $ref = ref $_;
				if ($ref eq 'Regexp' || $ref eq '') {
				    1; # Coverage misses next stmt without this
				    push @tgts, $_;
				}
				else {
				    $self->_carp("Illegal return type for target: $ref",
						 $filename, $rule_line);
				}
			    }
			    $self->_carp("Extraneous input: $target",
					 $filename, $rule_line)
				if $target !~ /^\s*$/;
			    $rule_line += $perl =~ tr/\n//;
			}
			else {
			    # A string target
			    if ($target =~ /\%/) {
				my @const = split /(\%)/, $target;
				grep do { $_ = "\Q$_" }, @const;
				my $qr = 'qr(^' .
				    join('', map($_ eq '\%' ? '(.*)' : $_,
						 @const)) . '$)';
				($target) = $self->_eval($qr, $filename,
							 $rule_line);
			    }
			    push @tgts, $target;
			}
		    }

		    # Process the dependencies
		    my @raw_deps = split /\s+/, $raw_deps;
		    grep s/\%/\$1/g, @raw_deps; # Handle % in dependencies;
		    foreach my $dep (@raw_deps) {
			if ($dep =~ s/^($re)//) {
			    # A perl expression
			    my $perl = _expand($1, $braces);
			    if ($perl eq '') { # It was a \ at end of line
				$rule_line++;
				next;
			    }
			    my ($sub) = $self->_eval("sub { $perl }",
						     $filename, $rule_line);
			    push @deps, $sub;
			    $self->_carp("Extraneous input: $dep",
					 $filename, $rule_line)
				if $dep !~ /^\s*$/;
			    $rule_line += $perl =~ tr/\n//;
			}
			else {
			    # A string dependency
			    push @deps, _substitute($dep);
			}
		    }		    

		    # Read the actions
		    my $act = '';
		    my $in_braces = 0; # Shadows outer $in_braces
		    $stmt_line = $lineno+$l+1;
		    while ($l < $#lines && ($lines[++$l] =~ /^\s/ ||
					    $lines[$l] =~ /^\z/ && $in_braces))
		    {
			$_ = $lines[$l];
			my $net_braces = tr/\{\[// - tr/\}\]//;
			$in_braces += $net_braces;
			s/^\t//;
			$act .= "$_\n";
			if ($in_braces <= 0 && ! /\\$/) {
			    # We have another action
			    my ($act1, $braces) = _collapse($act);
			    my $braces_re = %$braces ?
				join('|', keys %$braces)   : "\n";
			    my ($act2, $brackets) = _collapse($act1, qw([ ]));
			    my $brackets_re = %$brackets ?
				join('|', keys %$brackets) : "\n";
			    if ($act2 =~ s/^\s*($braces_re)//) {
				# It's a perl block
				my $exp = _expand($1, $braces);
				my ($sub) =
				    $self->_eval("sub { $exp }",
						 $filename, $stmt_line);
				push @acts, $sub;
			    }
			    elsif ($act2 =~ s/^\s*($brackets_re)//) {
				# It's an anonymous array
				my $array = _expand(_expand($1, $brackets,
							    '[', ']'),
						    $braces);
				my ($array_p) =
				    $self->_eval("do { $array }",
						 $filename, $stmt_line);
				push @acts, $array_p;
			    }
			    else {
				# It's a command
				$act2 = _expand($act2, $brackets, qw([ ]));
				chomp ($act2 =
				       _substitute(_expand($act2, $braces)));
				$act2 =~ s/^\s*\#.*//;
				# Allow use of $* for $1
				$act2 =~ s/\$\*/\$1/g;
				push @acts, $act2 if $act2 ne '';
				$act2 = ''
			    }
			    chomp $act2;
			    $self->_carp("Extraneous input: $act2",
					 $filename, $stmt_line)
				if $act2 !~ /^\s*$/;
			    
			    $act = '';
			    $stmt_line = $lineno+$l+1;
			    $in_braces = 0;
			}
		    }
		    if ($in_braces) {
			1; # Coverage misses next statement without this
			$self->_carp("Unmatched '{' or '['",
				     $filename, $stmt_line);
		    }
		    $l-- unless $l == $#lines;

		    # Process the rule
		    $self->maker->add_rules([@tgts, ':', @deps, '=', @acts]);

		    # Make note of first constant rule
		    if (!$self->{first} && ! grep ref $_ eq 'Regexp', @tgts) {
			my $rules = $self->maker->rules;
			$self->{first} = $rules->[-1];
		    }
		}
		else {
		    # It'd better be a sequence of perl blocks
		    my $re = %$braces ? join('|', keys %$braces) : "\n";
		    my @blocks = split /($re)/, $stmt;
		    foreach my $block (@blocks) {
			next if $block =~ /^\s*$/; # Ignore whitespace
			if (defined $braces->{$block}) {
			    # It's a perl block
			    my $perl = _expand($block, $braces);
			    if ($perl eq '') { # It was a \ at end of line
				$stmt_line++;
				next;
			    }
			    # Remove the enclosing {}
			    $perl =~ s/\A \{ (.*) \} \z/$1/xs;
			    $self->_eval("\@_ = \$self; $perl", $filename,
					 $stmt_line);
			    $stmt_line += $perl =~ tr/\n//;
			}
			else  {
			    $self->_carp("Illegal input: '$block'",
					 $filename, $stmt_line);
			}
		    }
		}
	    }

	    # Set-up for next statement
	    $in_braces = 0 if $in_braces < 0;
	    $stmt = '';
	    $stmt_line = $lineno+$l+1;
	}
    }
    $self->_croak("Unmatched \{", $filename, $stmt_line) if $in_braces;
    return $self->{errors};
}

# Internal routines

# Calls carp with information as to where the problem occurred
# Arguments: message, [filename, [lineno]]
sub _carp : method {
    my ($self, $msg, $filename, $lineno) = @_;

    my @where = ($filename) if defined $filename;
    push @where, $lineno if $lineno;
    my $where = @where ? join(', ', @where) . ": " : '';
    push @{$self->{errors}}, Carp::shortmess("$where$msg");
}

# Calls croak with information as to where the problem occurred
# Arguments: message, [filename, [lineno]]
sub _croak {
    my ($self, $msg, $filename, $lineno) = @_;

    my @where = ($filename) if defined $filename;
    push @where, $lineno if $lineno;
    my $where = @where ? join(', ', @where) . ": " : '';
    croak("$where$msg");
}

# Collapses braces in a string to make evident the nesting
# Arguments: string, optional open char, optional close char
# Returns:   collapsed string, ref. to braces hash to re-constitute it
sub _collapse {
    my ($str, $open, $close) = @_;
    ($open, $close) = qw({ }) unless defined $close;
    my $ord = ord $open;
    grep do { $_ = "\Q$_" }, ($open, $close);
    my (%braces, $braces);
    while ($str =~ s/$open([^$open$close]*)$close/ do {
	my $s = sprintf "<%x,%d>", $ord, ++$braces;
	$braces{$s} = $1;
	$s }
	   /seg) { }
    # Collapse \ at end of lines, too
    $braces{'<0d>'} = '' if $str =~ s/\\\n/ <0d> /g;

    return ($str, \%braces);
}

# Evaluates a string within the proper package
# Arguments: string, filename, line number
# Returns:  result of eval
sub _eval : method {
    my ($self, $perl, $filename, $stmt_line) = @_;

    my $ld = defined $filename ? qq(\#line $stmt_line "$filename"\n) : '';
    my $strict = defined $self->{options}{strict} &&
	$self->{options}{strict} == 0 ? 'no strict;' : '';
    # Remove minimum indentation of perl block so that HEREIS strings
    # can be used as part of dependencies or actions
    $perl =~ s/^(\t+)/' ' x (8*length($1))/gem;
    my @indents = $perl =~ m/^([ ]+)/gm;
    my $min_indent = @indents ? $indents[0] : '';
    grep do {$min_indent = $_ if length $_ < length $min_indent}, @indents;
    $perl =~ s/^$min_indent//gm if $min_indent;
    my @val = eval "${ld}package Slay::Makefile::Eval; $strict $perl";
    chomp $@;
    $self->_croak($@, $filename, $stmt_line) if $@;
    return @val;
}

# Expands a string where the things in braces have been collapsed
# Arguments: string, ref to braces hash, optional open/close chars
sub _expand {
    my ($string, $braces, $open, $close) = @_;
    
    $string =~ s/<0d>//g;
    return $string unless %$braces;
    ($open, $close) = qw({ }) unless defined $close;
    my $re = join '|', map "\Q$_", keys %$braces;
    while ($string =~ s/($re)/$open$braces->{$1}$close/g) { }
    return $string;
}

# Substitutes global variables in a string
# Arguments: string
# Returns:   substituted string
sub _substitute {
    my ($string) = @_;

    package Slay::Makefile::Eval;
    no strict 'refs';
    $string =~ s/(\$([a-z_]\w*))/defined ${$2} ? ${$2} : $1/gie;
    $string =~ s/(\$\{([a-z_]\w*)\})/defined ${$2} ? ${$2} : $1/gie;

    return $string;
}

=back

=head1 LIMITATIONS

The parsing of perl blocks is only semi-smart.  In particular,
unbalanced braces within comments or strings can cause parsing to end
prematurely or not at all.  For example,

  {
     # This comment has an unbalanced }
  }
  {
     "This string has an unbalanced {";
  }

will not parse correctly.  The first block will stop parsing at the
end of the comment and the second will continue swallowing text after
the end of its closing brace.  As long as the total number of {'s
exceeds the total number lf }'s, parsing continues.  You can always
overcome this problem by putting comments in judicious places:

  {
     # Compensate with {
     # This comment has an unbalanced }
  }
  {
     "This string has an unbalanced {";  # Compensate with }
  }

=head1 ACKNOWLEDGEMENTS

I want to acknowledge Barrie Slaymaker, who wrote the original
Slay::Maker module for CPAN and has been very kind in his support for
developing this module.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Mark Nodine, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
