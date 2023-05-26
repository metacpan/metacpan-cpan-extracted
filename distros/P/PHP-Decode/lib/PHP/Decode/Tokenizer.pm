#
# tokenize PHP source files
#
package PHP::Decode::Tokenizer;

use strict;
use warnings;

our $VERSION = '1.47';

# Initialize PHP::Decode::Tokenizer
# {inscript}   - set to indicate already inside of script
# {warn}       - warning message handler
#
sub new {
	my ($class, %args) = @_;
	my $self = bless {
		inscript => 0, # look for start of script
		warn => sub { },
		%args, # might override preceding keys
	}, $class;
	return $self;
}

sub inc_linenum {
	my ($self, $s) = @_;

	my $off = 0;
	while (($off = index($s, "\n", $off)) != -1) {
		$self->add_white("\n");
		$off++;
	}
	return;
}

# extract variables from interpolated strings
#
sub expand_str {
	my ($self, $s, $off) = @_;
	my @word = ();
	my $cont;

	# http://php.net/manual/en/language.types.string.php#language.types.string.parsing
	# for variable names see: https://www.php.net/manual/en/language.variables.basics.php
	#
	while (1) {
		unless ($s =~ /\G([^\\\$\{]*)([\\\$\{]|$)/sgc) {
			last;
		}
#print ">>> '$1' '$2'\n";
		#$self->inc_linenum($1);
		push(@word, $1);
		if ($2 ne "\\") {
			# http://php.net/manual/en/language.types.string.php#language.types.string.parsing
			if ($2 eq '$') {
				# expand simple variable
				if ($s =~ /\G([a-zA-Z_\x80-\xff][\w\x80-\xff]*)((\:\:|\-\>)([a-zA-Z_\x80-\xff][\w\x80-\xff]*))?/sgc) {
					my $w = join('', @word);
					if (defined $cont) {
						$self->add('.');
					}
					#if ($w ne '') {
						$self->add_str($w);
						$self->add('.');
					#}
					# just simple object references here
					#
					$self->add_var($1, $off);
					if (defined $2 && ($2 ne '')) {
						$self->add($3);
						$self->add_sym($4, $off);
					}
					if ($s =~ /\G(\[)/sgc) {
						if ($s =~ /\G([^"]*?)\]/sgc) {
							$self->add_open('[');
							# todo: split index special chars
							my $i = $1;
							if ($i =~ /^([0-9]+)$/) {
								$self->add_num($1);
							} elsif ($i =~ /^'(.*)'$/) {
								$self->add_str($1);
							} else {
								$self->add_sym($i, $off);
							}
							$self->add_close(']');
						} else {
							push(@word, '[');
						}
					}
					$cont = 1;
					@word = ();
				} else {
					push(@word, '$');
				}
				next;
			} elsif ($2 eq '{') {
				# expand complex variable
				if ($s =~ /\G(\$)/sgc) {
					if ($s =~ /\G([^"]*?)\}/sgc) {
						my $w = join('', @word);
						if (defined $cont) {
							$self->add('.');
						}
						if ($w ne '') {
							$self->add_str($w);
							$self->add('.');
						}
						my $v = $1;
						if ($v =~ /^([a-zA-Z_\x80-\xff][\w\x80-\xff]*)((\:\:|\-\>)([a-zA-Z_\x80-\xff][\w\x80-\xff]*))?(\[(.*?)\])?$/) {
							# split object references
							#
							$self->add_var($1, $off);
							if (defined $2 && ($2 ne '')) {
								$self->add($3);
								$self->add_sym($4, $off);
							}
							if (defined $5) {
								my $i = $6;
								$self->add_open('[');
								# todo: split var special chars
								if ($i =~ /^([0-9]+)$/) {
									$self->add_num($1);
								} elsif ($i =~ /^'(.*)'$/) {
									$self->add_str($1);
								} else {
									$self->add_sym($i, $off);
								}
								$self->add_close(']');
							}
						} else {
							$self->add_var($v, $off);
						}
						$cont = 1;
						@word = ();
					} else {
						push(@word, '{$');
					}
				} else {
					push(@word, '{');
				}
				next;
			}
			last;
		}
		$s =~ /\G(.)/sgc;
		# escape characters in double quoted strings:
		# http://php.net/manual/de/language.types.string.php
		# http://perldoc.perl.org/perlrebackslash.html
		#
		if ($1 eq 'n') {
			push(@word, "\n");
		} elsif ($1 eq 'r') {
			push(@word, "\r");
		} elsif ($1 eq 't') {
			push(@word, "\t");
		} elsif ($1 eq 'v') {
			push(@word, chr(0x0b));
		} elsif ($1 eq 'f') {
			push(@word, "\f");
		} elsif ($1 eq "\\") {
			push(@word, "\\");
		} elsif ($1 eq '$') {
			push(@word, '$');
		} elsif ($1 eq '"') {
			push(@word, '"');
		} elsif ($1 eq 'x') {
			$s =~ /\G([0-9a-fA-F]{1,2})/sgc;
			if (defined $1) {
				push(@word, chr(hex($1)));
			} else {
				push(@word, "\\".'x');
			}
		} elsif (($1 ge '0') && ($1 le '7')) {
			my $o = $1;
			$s =~ /\G([0-7]{0,2})/sgc;
			$o .= $1;
			push(@word, chr(oct($o)));
		} else {
			push(@word, "\\".$1);
		}
	}
	my $w = join('', @word); 
	if (defined $cont) {
		if ($w ne '') {
			$self->add('.');
			$self->add_str($w, $off);
		}
	} else {
		$self->add_str($w, $off);
	}
	return;
}

# split into tokens, unquote quoted fields, and allow escapes
#
sub tokenize_line {
	my ($self, $line, $quote) = @_;

	# use regex to tokenize (https://perldoc.perl.org/perlrequick)
	#
	# The most interesting behaviour of /PAT/g is when not in list context,
	# but in scalar context. In that case, the next regexp can continue
	# where the previous one left off, using the \G anchor. Conceptually,
	# it is the same as the ^ anchor, which anchors at the beginning of the
	# string - except now it anchors on the current value of pos(), for
	# this string, which is at the end of where the previous pattern
	# matched. The /c modifier prevents reset of the pos pointer # to 0
	# when the match fails.
	#
	# Such a lexer could look like this:
	#
	# $_ = 'unquoted text: "quoted text."';
	# while (1) {
	#	 /\G\s*(?=\S)/gc or last;
	#	 if (/\G(\w+)/gc) {
	#		 print "Found word: $1\n";
	#	 } elsif (/\G(['"])/gc) {
	#		 print "Found quote: $1\n";
	#	 } elsif (/\G([.,;:!?])/gc) {
	#		 print "Found punctuation: $1\n";
	#	 } else {
	#		 /\G(?=(\S+))/gc;
	#		 printf "Unknown token: %s +(pos %d)", $1, pos;
	#	 }
	# }
	#
	$_ = $line;
	WORD: while (1) {
		if (!$self->{inscript}) {
			my @seq = ();
			my $sym;

			# parse everything between ?> and <? as string
			# and convert to 'echo #str;'
			#
			NOSCRIPT: while (1) {
				if (defined $quote) {
					my @word = ();
					if ($quote eq '\'') {
						while (1) {
							unless (/\G([^$quote\\]*)([$quote\\])/sgc) {
								push(@seq, $quote);
								#push(@seq, join("", @word));
								push(@seq, @word);
								$self->add_noscript(join('', @seq), pos);
								last NOSCRIPT;
							}
							$self->inc_linenum($1);
							push(@word, $1);
							last if ($2 ne "\\");
							/\G(.)/sgc;
							push(@word, "\\".$1);
						}
					} else {
						while (1) {
							# strings are expanded single quoted, so
							# escape single quotes in other strings
							#
							unless (/\G([^$quote'\\]*)([$quote'\\])/sgc) {
								push(@seq, $quote);
								#push(@seq, join("", @word));
								push(@seq, @word);
								$self->add_noscript(join('', @seq), pos);
								last NOSCRIPT;
							}
							$self->inc_linenum($1);
							push(@word, $1);
							if ($2 eq '\'') {
								push(@word, "\\".$2);
								next;
							}
							last if ($2 ne "\\");
							/\G(.)/sgc;
							push(@word, "\\".$1);
						}
					}
					push(@seq, $quote);
					push(@seq, @word);
					push(@seq, $quote);
					$quote = undef;
				} elsif (/\G(["'`])/sgc) {
					$quote = $1;
				} elsif (/\G(\\)/sgc) {
					/\G(.)/sgc;
					if (defined $1) {
						push(@seq, "\\".$1);
					} else {
						$self->add_noscript(join('', @seq), pos);
						last;
					}
				} elsif (/\G(<)/sgc) {
					my $cur = pos;
					if (/\G(\?php)/sgci) {
						my $s = join('', @seq);
						if ($s ne '') {
							$self->add_noscript($s, $cur-2);
						}
						$self->add_script_start('<?php', $cur-1); 
						$self->{inscript} = 1;
						last;
					} elsif (/\G(\?)/sgc) {
						my $s = join('', @seq);
						if ($s ne '') {
							$self->add_noscript($s, $cur-2);
						}
						$self->add_script_start('<?', $cur-1); 
						$self->{inscript} = 1;
						last;
					} elsif (/\G(\?=)/sgc) {
						# short_open_tag for echo since php-5.4 always avail
						my $s = join('', @seq);
						if ($s ne '') {
							$self->add_noscript($s, $cur-2);
						}
						$self->add_script_start('<?', $cur-1); 
						$self->add_sym('echo');
						$self->{inscript} = 1;
						last;
					} elsif (/\G(script\s*language\s*=\s*["']php["']\s*>)/sgci) {
						# <script language='php'> .. </script>
						#
						my $s = join('', @seq);
						if ($s ne '') {
							$self->add_noscript($s, $cur-2);
						}
						$self->add_script_start('<?php', $cur-1); 
						$self->{inscript} = 2;
						last;
					} else {
						push(@seq, '<');
					}
				} else {
					unless (/\G([^"'`'<\\]+)/sgc) {
						#/\G(.)/sgc;
						#printf ">> WARN: parse end after: [0x%02x] %s\n", ord($1), $self->tok_dump();
						my $s = join('', @seq);
						if ($s ne '') {
							$self->add_noscript($s, pos);
						}
						last;
					}
					push(@seq, $1);
				}
			}
		}
#printf ">>>>> [pos: %d] %s\n", pos, $self->tok_dump();
		my $cur = pos;

		if (defined $quote) {
			# handle quotes
			#
			my @word = ();

			# before php 5.3 php silently truncated strings
			# after a 0-byte (0-byte poisioning)
			# https://bugs.php.net/bug.php?id=39863
			#
			if ($quote eq "\"") {
				# In the first pass, just scan for the end of the string, and
				# in the second pass expand variables and other escape codes.
				# (keep escapes intact here)
				#
				while (1) {
					unless (/\G([^$quote\\]*)([$quote\\])/sgc) {
						last WORD;
					}
					$self->inc_linenum($1);
					push(@word, $1);
					last if ($2 ne "\\");
					/\G(.)/sgc;
					push(@word, "\\".$1);
				}
				$self->expand_str(join('', @word), $cur); 
			} else {
				while (1) {
					unless (/\G([^$quote\\]*)([$quote\\])/sgc) {
						last WORD;
					}
					$self->inc_linenum($1);
					push(@word, $1);
					last if ($2 ne "\\");
					/\G(.)/sgc;
					if (($1 eq '\\') || ($1 eq $quote)) {
						push(@word, $1);
					} else {
						push(@word, "\\".$1);
					}
				}
				$self->add_str(join('', @word), $cur);
			}
			$quote = undef;
		} elsif (/\G(["'`])/sgc) {
			$quote = $1;
		} elsif (/\G(\/)/sgc) {
			if (/\G(\*)/sgc) {
				# parse /* ... */ comments
				unless (/\G(.*?)\*\//sgc) {
					$quote = '*';
					last WORD;
				}
				# insert as string without newlines
				my $s = $1;
				$self->inc_linenum($s);
				$s =~ s/[\r\n]/ /g;
				$self->add_comment($s, pos);
			} elsif (/\G(\/)/gc) {
				# skip comments
				# parse // comments (up to ?> or line end)
				#
				# ?> tags have a higher priority and stop the comment
				# http://php.net/manual/en/language.basic-syntax.comments.php
				#
				unless (/\G(.*?)(\?>|\n|\r\n|\0|$)/gc) {
					last WORD;
				}
				$self->add_comment($1, pos);
				if ($2 eq '?>') {
					$self->add_script_end('?>', pos);
					$self->{inscript} = 0;
				} elsif ($2 eq "\n") {
					$self->add_white($2);
				}
			} else {
				$self->add('/');
			}
		} elsif (/\G(#)/gc) {
			#if (/\G((str|num|const|arr|fun|class|trait|call|elem|expr|stmt|blk|ref|obj|scope|ns)\d+)/gc) {
			#	# parse inserted #str symbols (might be useful for sub evals)
			#	$self->add('#'.$1);
			#} else {
				# parse # comments (up to ?> or line end)
				#
				unless (/\G(.*?)(\?>|\n|\r\n|\0)/gc) {
					last WORD;
				}
				$self->add_comment($1, pos);
				if ($2 eq '?>') {
					$self->add_script_end('?>', pos);
					$self->{inscript} = 0;
					if (/\G(\n|\r\n)/sgc) {
						$self->add_white("\n");
					}
				}
			#}
		} elsif (/\G(\n)/sgc) {
			# skip whitespace token
			$self->add_white($1);
		} elsif (/\G([^\S\n]+)/sgc) {
			# skip whitespace token
			$self->add_white($1);
		} elsif (/\G([\x01-\x1f\x7f])/sgc) {
			# skip non printable token
			$self->add_white($1);
		} elsif (/\G(<)/sgc) {
			if (/\G(\?php)/sgci) {
				if ($self->tok_count() > 0) {
					$self->add_bad_open('<?php');
				}
			} elsif (/\G(\?)/sgc) {
				if ($self->tok_count() > 0) {
					$self->add_bad_open('<?');
				}
			} elsif (/\G(\?=)/sgc) {
				if ($self->tok_count() > 0) {
					$self->add_bad_open('<?=');
				}
			} elsif (/\G(script\s*language\s*=\s*["']php["']\s*>)/sgci) {
				if ($self->tok_count() > 0) {
					$self->add_bad_open('<script language=\'php\'>');
				}
			} elsif (($self->{inscript} == 2) && /\G(\/script\s*>)/sgci) {
				# <script language='php'> .. </script>
				#
				$self->add_script_end('?>', pos);
				$self->{inscript} = 0;
				if (/\G(\n|\r\n)/sgc) {
					$self->add_white("\n");
				}
			} elsif (/\G(<<)/sgc) {
				# heredoc or nowdoc
				# http://php.net/manual/de/language.types.string.php
				#
				if (/\G([\w\pL]+)(\n|\r\n)/sgc) {
					my $e = $1;
					$self->inc_linenum("\n");
					unless (/\G(.*?\n)$e(\;)?(\n|\r\n|\0|$)/sgc) {
						last WORD;
					}
					$self->inc_linenum($1);
					$self->expand_str($1, $cur);
					#$self->add_str($1);
					$self->inc_linenum($3);
				} elsif (/\G\'([\w\pL]+)\'(\n|\r\n)/sgc) {
					my $e = $1;
					$self->inc_linenum("\n");
					unless (/\G(.*?\n)$e(\;)?(\n|\r\n|\0|$)/sgc) {
						last WORD;
					}
					$self->inc_linenum($1);
					$self->add_str($1);
					$self->inc_linenum($3);
				} else {
					$self->add('<<<');
				}
			} else {
				$self->add('<');
			}
		} elsif (/\G(\?)/sgc) {
			if (/\G(>)/sgc) {
				# http://php.net/manual/en/language.basic-syntax.instruction-separation.php
				# the closing tag includes an optional immediately following newline
				#
				$self->add_script_end('?>', pos);
				$self->{inscript} = 0;
				if (/\G(\n|\r\n)/sgc) {
					$self->add_white("\n");
				}
			} else {
				$self->add('?');
			}
		} elsif (/\G(\0)/sgc) {
			$self->add_script_end($1, pos);
			$self->{inscript} = 0;
		} elsif (/\G([\[\(\{])/sgc) {
			$self->add_open($1, $cur);
		} elsif (/\G([\}\)\]])/sgc) {
			$self->add_close($1, $cur);
		} elsif (/\G([>\;\=\,\.\:\&\-\+\|\^\~\%\!\\])/sgc) {
			# backslash is php namespace separator (not escape)
			#
			$self->add($1);
		} elsif (/\G(\$)/sgc) {
			# variable $var or '${'
			#
			if (/\G([a-zA-Z_\x80-\xff][\w\x80-\xff]*)/sgc) {
				$self->add_var($1, $cur);
			} else {
				$self->add('$');
			}
		} elsif (/\G(\@)/sgc) {
			# '@' is allowed in php-identifiers
			# it suppresses error messages
			#
			$self->add_white('@');
		} elsif (/\G([0-9]+)/sgc) {
			my $v = $1;
			if (($v eq '0') && /\G([xX][0-9a-fA-F]+)/sgc) {
				$self->add_num('0'.$1); # hex
			} else {
				if (/\G(\.[0-9]+)/sgc) {
					$v .= $1; # float
				}
				if (/\G([eE][\+\-]?[0-9]+)/sgc) {
					$v .= $1; # exponent
				}
				$self->add_num($v); # dec/oct/float
			}
		} elsif (/\G([\w\x80-\xff]+)/sgc) {
			$self->add_sym($1, $cur);
		} else {
			unless (/\G([^"'`<>\\\/#\s\w\[\]\(\)\{\}\$\?\;\=\,\.\:\&\-\+\|\^\~\%\!]+)/sgc) {
				#/\G(.)/sgc;
				#printf ">> WARN: parse end after: [0x%02x] %s\n", ord($1), $self->tok_dump();
				last;
			}
			$self->add($1);
		}
	}
	if ($self->{inscript}) {
		$self->add_script_end('', pos);
	}
	return $quote;
}

# set up method stubs
# (when just the add()-method is overridden, then all
#  other handlers call this subclass method)
#
sub add { }
sub _add { my ($self, $sym) = @_; $self->add($sym); return; }
*add_open         = \&_add;
*add_close        = \&_add;
*add_white        = \&_add;
*add_comment      = \&_add;
*add_sym          = \&_add;
*add_var          = \&_add;
*add_str          = \&_add;
*add_num          = \&_add;
*add_script_start = \&_add;
*add_script_end   = \&_add;
*add_noscript     = \&_add;
*add_bad_open     = \&_add;

sub tok_dump  { return ''; }
sub tok_count { return 0; }

sub DESTROY {
	my $self = shift;
	return;
}

1;


__END__

=head1 NAME

PHP::Decode::Tokenizer

=head1 SYNOPSIS

  # Create an instance

  package SymTokenizer;
  use base 'PHP::Decode::Tokenizer';

  my @tok;

  sub new {
	my ($class, %args) = @_;
	return $class->SUPER::new(%args);
  }

  sub add {
	my ($tab, $sym) = @_;
	push(@tok, $sym);
  }

  package main;

  my $parser = SymTokenizer->new();

  # Tokenize functions

  my $line = '<?php echo "test"; ?>';
  my $quote = $parser->tokenize_line($line);

  printf "tokens: %s\n", join(' ', @$tok);

=head1 DESCRIPTION

The PHP::Decode::Tokenizer module is the tokenizer base class for a php parser.

=head1 METHODS

=head2 new

Create a PHP::Decode::Tokenizer object. Arguments are passed in key => value pairs.

    $parser = PHP::Decode::Tokenizer->new(%args)

The tokenizer class is designed to be used as base class for a parser which
overrides at least the basic add() method.

The accepted arguments are:

=over 4

=item inscript: set to indicate that paser starts inside of script

=item warn: optional handler to log warning messages

=back

=head2 tokenize_line

Tokenize a php code string.

    my $quote = $parser->tokenize_line($line, $quote);

=over 4

=item quote: optional opening quote if line starts in quoted mode.

=back

The tokenize_line method can be called once for a complete php code string,
or incremental for consecutive parts of a script. Internally the tokenizer
keeps the 'inscript' and 'quote' state between subsequent calls. The initial
'inscript state can be set when 'new' is called. If the tokenizer should
start in quoted mode, an optional opening 'quote' can be passed to the call.

The tokenize_line method returns undef if not in quoted mode after the input
was processed, or the type of 'quote' to indicate quoted mode.

The tokenizer will call the add() methods of the parser sub-class for each
token. If one of the following add-methods is not overridden, the tokenizer
will call $self->add($sym) as a default:

=over 4

=item add_open: opening bracket

=item add_close: closing bracket

=item add_white: white space

=item add_comment: php comment

=item add_sym: php symbol like function name or const

=item add_var: php variable name (without leading '$')

=item add_str: php quoted string (without quotes)

=item add_num: php unquoted int number or float

=item add_script_start: script start tag

=item add_script_end: script end tag

=item add_noscript: text outside of script tags

=item add_bad_open: bad start script tag

=back

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=cut

