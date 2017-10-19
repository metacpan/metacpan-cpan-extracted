package Term::ReadLine::Perl5::OO::Keymap;
use strict; use warnings;
eval "use rlib '.' ";  # rlib is now optional
use Term::ReadLine::Perl5::Common;

# For extra debug messages
my $DEBUG = $ENV{'KEYMAP_DEBUG'};

sub new {
    my ($class, $name, $default) = @_;
    my $self = {
	name     => $name,
	default  => canonic_command_function($default),
	function => [],
    };
    bless $self, $class;
    return $self;
}

# A GNU ReadLine function
sub rl_make_bare_keymap() {
    __PACKAGE__->new();
}

sub lookup_key($$) {
    my ($self, $key) = @_;
    return $self->{function};
}

=head2 bind_parsed_keyseq

#B<bind_parsed_keyseq>(I<$keyseq_list> I<$function>, I<$keyseq_str>)

Actually inserts the binding for given I<$keyseq_list>
to I<$function> into the keymap object. I<$keyseq_list> is
reference an list of character ordinals.

If C<sequence> is more than one element long, all but the last will
cause meta maps to be created. The name will be derived from
$<keyseq_str>.

I<$Function> will have an implicit I<F_> prepended to it.

0 is returned if there is no error.

=cut

sub bind_parsed_keyseq($$;$)
{
    my ($self, $keyseq_list, $function, $loc_str) = @_;
    $loc_str = '' unless $loc_str;
    my $bad  = 0;
    my @keys = @{$keyseq_list};
    # make sure $key is set to an int if undefined.
    my $key = shift(@keys) || 0;
    my $func_tuple = $self->{function}[$key];
    # use Data::Printer;
    # p $func_tuple;
    # p $key;
    # p $function;
    if (@keys) {
	my $next_keymap;
	if (defined($func_tuple) && $func_tuple->[0] eq 'PrefixMeta') {
	    # Good - extending an existing meta map.
	    $next_keymap = $func_tuple->[1];
	} else {
	    if (defined($func_tuple) && $^W) {
		my $mess =
		    sprintf("Warning%s: Rebinding char #%s from [%s] " .
			    "to meta in keymap %s\n",
			    $loc_str, $key, $func_tuple->[1], $self->{name});
		    warn $mess;
	    }
	}
	$self->{function}[$key] = ['F_PrefixMeta', $next_keymap];
	return $next_keymap->bind_parsed_keyseq(\@keys, $function, $loc_str);
    }

    if (defined($func_tuple) && $func_tuple->[0] ne 'F_PrefixMeta' &&
	$function ne 'PrefixMeta')  {
	if ($^W) {
	    my $mess =
		sprintf("Warning%s: Rebinding char #%s to " .
			"non-meta (%s) in keymap %s\n",
			$loc_str, $key, $function, $self->{name});
	    warn $mess;
	}
    }

    # FIXME 2nd arg really should be code ref when it is not
    # a keymap. And do better than =~.
    my $function_name =
	($function =~ /Term::ReadLine::Perl5::OO::Keymap/) ?
	'PrefixMeta' : $function;

    $self->{function}[$key] = [$function_name, $function];
    # p $self->{function}[$key];
    return $bad;
}

=head3 rl_bind_keyseq

B<rl_bind_keyseq>(I<$keyspec>, I<$function>)

Bind the key sequence represented by the string I<keyseq> to the
function function, beginning in the current keymap. This makes new
keymaps as necessary. The return value is non-zero if keyseq is
invalid.  I<$keyspec> should be the name of key sequence in one of two
forms:

Old (GNU readline documented) form:

     M-x        to indicate Meta-x
     C-x        to indicate Ctrl-x
     M-C-x      to indicate Meta-Ctrl-x
     x          simple char x

where I<x> above can be a single character, or the special:

     special    means
     --------   -----
     space      space   ( )
     spc        space   ( )
     tab        tab     (\t)
     del        delete  (0x7f)
     rubout     delete  (0x7f)
     newline    newline (\n)
     lfd        newline (\n)
     ret        return  (\r)
     return     return  (\r)
     escape     escape  (\e)
     esc        escape  (\e)

New form:
  "chars"   (note the required double-quotes)

where each char in the list represents a character in the sequence, except
for the special sequences:

          \\C-x         Ctrl-x
          \\M-x         Meta-x
          \\M-C-x       Meta-Ctrl-x
          \\e           escape.
          \\x           x (if not one of the above)


C<$function> should be in the form C<BeginningOfLine> or C<beginning-of-line>.

It is an error for the function to not be known....

As an example, the following lines in .inputrc will bind one's xterm
arrow keys:

    "\e[[A": previous-history
    "\e[[B": next-history
    "\e[[C": forward-char
    "\e[[D": backward-char

=cut

sub rl_bind_keyseq($$$;$)
{
    my ($self, $keyseq, $func, $location_msg) = @_;
    $location_msg = '' unless $location_msg;
    $func = canonic_command_function($func);

    # print "sequence [$keyseq] func [$func]\n"; ##DEBUG

    my @keys = ();
    if ($keyseq =~ m/"((?:\\.|[^\\])*)"/s) {
	# A new-style binding.
	@keys = unescape("$1");
    } else {
	# An old-style binding... only one key (or Meta+key)
	my $new_keyseq = $keyseq;
	my $is_ctrl = ($new_keyseq =~ s{\b(C|Control|CTRL)-}{}i);
	if ($keyseq =~ s{\b(M|Meta)-}{}i) {
	    push(@keys, ord("\e"));
	}

	# Isolate key part. This matches GNU's implementation.
	# If the key is '-', be careful not to delete it!
	$new_keyseq =~ s/.*-(.)/$1/;
	if    ($new_keyseq =~ /^(space|spc)$/i)   { $new_keyseq = ' ';    }
	elsif ($new_keyseq =~ /^(rubout|del)$/i)  { $new_keyseq = "\x7f"; }
	elsif ($new_keyseq =~ /^tab$/i)           { $new_keyseq = "\t";   }
	elsif ($new_keyseq =~ /^(return|ret)$/i)  { $new_keyseq = "\r";   }
	elsif ($new_keyseq =~ /^(newline|lfd)$/i) { $new_keyseq = "\n";   }
	elsif ($new_keyseq =~ /^(escape|esc)$/i)  { $new_keyseq = "\e";   }
	elsif (length($new_keyseq) > 1) {
	    warn "Warning$location_msg: strange binding [$keyseq->$new_keyseq]\n"
		if $^W;
	}
	my $key  = ord($new_keyseq);
	$key     = Term::ReadLine::Perl5::Common::ctrl($key) if $is_ctrl;
	push(@keys, $key);
    }

    # Now do the mapping of the sequence represented in @keys
    printf("rl_bind_keyseq(%s->%s, %s)\n",
	   $keyseq, $func, join(', ', @keys)) if $DEBUG;
    $self->bind_parsed_keyseq(\@keys, $func);
}

=head3 bind_keys

Accepts an array as pairs ($keyspec, $function, [$keyspec, $function]...).
and maps the associated bindings to the current KeyMap.

=cut

sub bind_keys
{
    my $self = shift;
    my ($keyseq, $func);
    while (defined($keyseq = shift(@_)) &&
	   defined($func   = shift(@_)))   {
	$self->rl_bind_keyseq($keyseq, $func);
    }
}

sub classify($) {
    my $ord = shift;
    return 'C-' . chr($ord+96) if $ord <= 26;
    return chr($ord) if $ord >= 33 && $ord < 127;
    return 'DEL' if $ord == 127;
    return "' '" if $ord == 32;
    return "ESC" if $ord == 27;
    return $ord;
}

# Turn command function names into their GNU Readline equivalet according to
# these rules:
#
# * names start with a lowercase letter
# * a lowercase followed by an Uppercase letter gets turned into lower-case - lower-case
#
# Examples:
#   Yank              => yank
#   BeginningOfLine   => beginning-of-line
sub gnu_command_function($) {
    my $function_name = shift;
    $function_name = "\l$function_name";
    $function_name =~ s/([a-z])([A-Z])/$1-\l$2/g;
    $function_name;
}

sub inspect($) {
    my ($self, $prefix) = @_;
    my @results = ();
    my @continue = ();
    for (my $i=0; $i<=127; $i++) {
	my $command_name = $self->{function}[$i][0];
	next unless defined($command_name);
	push @results, sprintf("%s%s\t%s\n", $prefix,
			       classify($i),
			       gnu_command_function($command_name));
	push @continue, $i if $command_name eq 'PrefixMeta';
    }
    return (\@results, \@continue);
}

# GNU Emacs Meta Key bindings
sub EmacsMetaKeymap() {
    my $keymap = __PACKAGE__->new('EmacsMeta', undef);
    $keymap->bind_keys(
	'k', 'unix-line-rubout',
	);
    return $keymap
}

# GNU Emacs Key binding
sub EmacsKeymap() {
    my $keymap = __PACKAGE__->new('Emacs', 'self-insert');
    $keymap->bind_keys(
	# 'C-a',  'beginning-of-line',
	# 'C-b',  'backward-char',
	# 'C-c',  'interrupt',
	# 'C-d',  'delete-char',
	# 'C-e',  'end-of-line',
	# 'C-f',  'forward-char',
	# 'C-h',  'backward-delete-char',
	# 'C-j',  'accept-line',
	# 'C-k',  'kill-line',
	# 'C-l',  'clear-screen',
	# 'C-m',  'accept-line',
	# 'C-n',  'next-history',
	# 'C-p',  'previous-history',
	# 'C-r',  'reverse-search-history',
	# 'C-t',  'transpose-chars',
	# 'C-u',  'unix-line-discard',
	# 'C-w',  'unix-word-rubout',
	# 'C-z',  'suspend',
	'ESC',  EmacsMetaKeymap,
#	'DEL',  'backward-delete-char',
	# 'ESC-b', 'backward-char',

	);
    return $keymap
}

# Vi input mode key bindings.
sub ViKeymap() {
    my $keymap = __PACKAGE__->new('vi', 'self-insert');
    $keymap->bind_keys(
	# "\e",   'ViEndInsert',
	'C-c',  'interrupt',
	'C-h',  'backward-delete-char',
	'C-u',  'unix-line-discard',
	# 'C-v',  'quoted-insert',
	'C-w',  'unix-word-rubout',
	'DEL',  'backward-delete-char',
	# "\n",   'ViAcceptInsert',
	# "\r",   'ViAcceptInsert',
	);
    return $keymap;
};

unless (caller) {
    # foreach my $keymap (EmacsKeymap(), EmacsMetaKeymap(), ViKeymap()) {
    foreach my $keymap (EmacsKeymap()) {
	my ($results, $continue) = $keymap->inspect('');
	foreach my $line (@{$results}) {
	    print $line;
	}
	print '=' x 30, "\n";
    }
}

1;
