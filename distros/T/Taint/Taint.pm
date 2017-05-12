package Taint;

# See docs at end for author and copyright info

=head1 NAME

Taint - Perl utility extensions for tainted data

=head1 SYNOPSIS

  use Taint;
  warn "Oops"
    if tainted $num, @ids;	# Test for tainted data
  kill $num, @ids;		# before using it

  use Carp;
  use Taint;
  sub baz { croak "Insecure request" if tainted @_; ... }

  use Taint qw(taint);
  taint @list, $item;		# Intentionally taint data

  use Taint qw(:ALL);
  $pi = 3.14159 + tainted_zero;	# I don't trust irrational numbers

=head1 DESCRIPTION

Perl has the ability to mark data as 'tainted', as described in
L<perlsec(1)>. Perl will prevent tainted data from being used for
some operations, and you may wish to add such caution to your own
code. The routines in this module provide convenient ways to taint
data and to check data for taint. To remove the taint from data,
use the method described in L<perlsec(1)>, or use the make_extractor
routine.

Please read L</COPYRIGHT> and L</DISCLAIMER>.

=head1 ROUTINES

=over 5

=cut

require 5.004;
use strict;
use vars qw(
    $VERSION
    $DEBUGGING
    @ISA
    @EXPORT @EXPORT_OK %EXPORT_TAGS
);
my %insanity;
my %no_taint_okay;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(tainted);

@EXPORT_OK = qw(
    taint
    is_tainted any_tainted all_tainted taintedness
    make_extractor
    tainted_null tainted_zero taint_checking
);

#		Installer's option:
# Use 1 for normal operation, 0 to disable the ability to
# use the unconditional untainting code from this module.
# Edit with care: This is a machine-editable line.
sub allowing_insanity () { 1 }		# Default is 1.
# This constant sub is for internal (testing) use only.
# It's not documented or intended for outside use.

# The pseudo-tag ALL does not include unconditional_untaint. That
# must be explicitly imported, in a special way. Don't bother. Use
# the untainting methods described in the perlsec(1) manpage, or use
# make_extractor.

%EXPORT_TAGS = ( ALL => [ @EXPORT, @EXPORT_OK ] );

$VERSION = '0.09';

BEGIN {
    my $saved_warnings;
    BEGIN {
	$saved_warnings = $^W;
	$^W = 0;	# No warnings while compiling this sub
    }
    $^W = $saved_warnings;

    # A note to the worried, curious, or paranoid:
    #
    # This sub does _not_ actually kill anything. The signal
    # 0 is actually a fake signal which doesn't get sent, and
    # which wouldn't do anything if it were sent. And besides,
    # we never send it anywhere, since there are no process ids
    # being passed to kill.
    #
    # Here's how it works:
    # First, join unites the arguments, then they are silently
    # discarded by the comma operator. Next, Perl tries to do
    # a harmless kill 0. Kill refuses to work if there are any
    # tainted data being used in the same statement. So, either
    # the eval aborts (returning undef), or it succeeds, and 
    # returns 1. That return value is inverted by the not
    # operator, thus making the function return value. Ta da!
    #
    sub any_tainted (@) {
	local(@_, $@, $^W) = @_;  # Prevent errors, stringifying
	not eval { join("",@_), kill 0; 1 };
    }
}

# Just a different prototype
sub is_tainted ($) {
    goto &any_tainted;
}

sub all_tainted (@) {
    for (@_) { return unless is_tainted $_ }
    1;
}

sub tainted (@) {
    goto &any_tainted;
}

=item     tainted LIST

=item  is_tainted EXPR

=item any_tainted LIST

=item all_tainted LIST

Test one or more items for taint. C<tainted> is an alias for
C<any_tainted>, provided for convenience. (Also, C<tainted> is
exported by default.) C<is_tainted> is prototyped to take a B<single
scalar> argument, the others take lists. (If you're not sure which
one to use, use C<tainted>.) When taint checks are off, these always
return false.

=cut

sub taintedness (@) {
    # Could do this with C<local(@_) = @_; substr("@_", 0, 0)>,
    # but that's buggy through 5.004_03.
    any_tainted(@_) ? tainted_null() : '';
}

=item taintedness LIST

This is a utility function, mostly useful for authors of subroutines
in modules. It is possible that an algorithm, by its nature, doesn't
propagate taintedness as it should. This routine returns the
taintedness of its parameters in the form of a null string which
is either tainted or not. (When taint checking is off, the return
value is always an untainted null string.) That string may be (for
example) appended to a return value to taint it if needed.

    sub frobnicate {
	my($taintedness) = taintedness @_;	# save it
	# ...do some stuff which may or may not
	# properly propagate taint...
	return undef if $you_want_to;
	return $taintedness . $return_value;	# restore it
    }

=cut

BEGIN {
    # Before anything else, we need to get a little
    # taint on our taintbrush.
    my $TAINT;
    {
	# Let's try the easy way first. Either of these should be
	# tainted, unless somebody has untainted them, so this
	# will almost always work on the first try.
	# (Unless, of course, taint checking has been turned off!)
	$TAINT = substr("$0$^X", 0, 0);
	last if is_tainted $TAINT;

	# Let's try again. Maybe somebody cleaned those.
	$TAINT = substr(join("", @ARGV, %ENV), 0, 0);
	last if is_tainted $TAINT;

	# Oh, a wise guy, eh?
	local(*FOO);
	my $data = '';
	for (qw(/dev/null / . ..), values %INC, $0, $^X) {
	    # Why so many? Maybe a file was just deleted or moved;
	    # you never know! :-)  At this point, taint checks
	    # are probably off anyway, but this is the ironclad
	    # way to get tainted data if it's possible.
	    # (Yes, even reading from /dev/null works!)
	    #
	    last if open FOO, $_
		and defined sysread FOO, $data, 1
	}
	# Assume one of them succeeded. We need only one!
	$TAINT = substr($data, 0, 0);
	close FOO;
    }

    # Sanity check
    die "Internal error. Oops!" if length $TAINT;

    # A tainted zero
    my $TAINT0 = 0+"0$TAINT";

    sub taint (@) {
	return unless taint_checking();
	for (@_) {
	    next if not defined;
	    next if ref;
	    # Taint tied objects by method, if possible
	    if (defined(my $thingy = tied $_)) {
		if ($thingy->can('TAINT')) {
		    $thingy->TAINT(1);
		    next;
		}
	    }
	    eval {
		if ( not $_ & '00' | '00' ) {
		    # Must already be a number,
		    # so don't stringify it now
		    $_ += $TAINT0;
		} else {
		    $_ .= $TAINT;
		}
	    };
	    if ($@ =~ /read-only/) {
		require Carp;
		&Carp::carp("Attempt to taint read-only value");
	    } elsif ($@) {
		require Carp;
		&Carp::carp("Unexpected error: $@");
	    }
	}
	return;		# explicitly, no return value
    }

=item taint LIST

If taint checks are turned on, marks each (apparently) taintable
argument in LIST as being tainted. (References and C<undef> are
never taintable and are left unchanged. Some C<tie>d and magical
variables may fail to be tainted by this routine, try as it may.)

To taint (the values of) an entire hash, use this idiom.

    taint @hash{ keys %hash };		# taint values of %hash

=cut

    # The following subs are inlineable constants
    # because their values have no outside refs
    # (That's why the extra scopes.)
    {
	my $taint = $TAINT;
	sub tainted_null () { $taint }	# a tainted null string
    }
    {
	my $taint = $TAINT0;
	sub tainted_zero () { $taint }	# a tainted zero
    }

=item tainted_null 

=item tainted_zero

If you'd rather taint your data yourself, these constants will let
you do it. C<tainted_null> is a tainted null string, which may be
appended to any data to taint it. (Of course, that will also
stringify the data, if needed.) C<tainted_zero> is (surprise) a
tainted zero, which may be added to any number to taint it. Note
that when taint checking is off, nothing can be tainted, so then
these are merely mundane C<''> and C<0> values.

=cut

    # This one is inlineable as well
    {
	my $taint_checking = is_tainted $TAINT;
	sub taint_checking () { $taint_checking }
    }

=item taint_checking

This constant tells whether taint checks are in use.  This is
usually only useful in connection with the allow_no_taint option
(see L</allow_no_taint>).

    print LOG "Warning: Taint checks not enabled\n"
	unless taint_checking;

=cut

}

# Private stuff for _display_pattern
{
    my @map;	# for converting a pattern to
		# the usual form, more or less.
    sub _display_pattern ($) {
	my $pattern = shift;
	# Make the map, if we have to
	unless (@map) {
	    for (0..0x1f, 0x7f..0xff) {	# defaults
		$map[$_] = '\\x' . sprintf '%02x', $_;
	    }
	    for (0x20..0x7e) {	# printables
		$map[$_] = chr;
	    }
	    $map[ord("\n")] = '\\n';
	    $map[ord("\t")] = '\\t';
	    for (qw( / $ @ )) {	# backwhackables
		$map[ord] = '\\' . $_;
	    }
	}
	# We want to display the poor user's pattern in the way
	# they're used to seeing it...
	# ...more or less. If this prints out '\-', that might
	# not do what a real \- would. But there's no way to be
	# sure to get it right, really, without parsing the
	# (possibly invalid) regexp. :-(
	my $copy = 
	    join '',		# Glue together
	    map $map[ord],	# a string representing
	    split //,		# each character
	    $pattern;		# in the pattern
	require Carp;
	&Carp::carp("Pattern was /$copy/o");
    }
}

sub make_extractor ($) {
    my $pattern = shift;
    # We could allow $pattern to be tainted, but we shouldn't.
    # (The contents of $pattern can't break anything, even
    # if it's not a valid regexp. It may die, but not break.)
    if (is_tainted $pattern) {
	require Carp;
	&Carp::croak("Can't make code from tainted string '$pattern'");
    }
    _display_pattern $pattern if $DEBUGGING;
    my $sub = eval q{		# Yes, a single-quote eval!
	my $sub = sub {
	    my @list;
	    for (@_) {
		push @list, ($_ =~ /$pattern/o);
	    }
	    wantarray ? @list : $list[0];	# return value
	};
	&$sub('dummy parameter');	# catch bad patterns
	$sub;			# return value from eval
    };
    if ($@) {
	$@ =~ s/ at \(eval \d+\) line \d+\.\n?$//;
	require Carp;
	&Carp::croak($@);
    }
    $sub;				# return value
}

=item make_extractor EXPR

This routine returns a coderef for a subroutine which untaints its
arguments according to the pattern passed in the string EXPR.
Although the argument to this routine must be untainted, the
arguments to the generated code may be tainted or not. When taint
checking is off, this routine and its generated code behave in
essentially the same way, even though neither their parameters nor
return values are tainted.

B<Note>: When untainting data, it's often easier to use the method
described in L<perlsec(1)>, especially if you're unfamiliar with
constructing strings to be used as regular expressions.

Here's one way this routine might be used. This example is part of
a server (similar in some ways to B<fingerd>; see L<fingerd(8)>)
which, when given a username, runs the Unix C<who> command, extracts
and untaints some information about that user, and reports it. Note
that the regular expression is compiled just once, (within the
C<make_extractor> routine) even though the username may change
every time through the main loop. 

    while () {	# The server runs in an infinite loop
	my $username = &get_next_request;
	# $username must already be untainted! (But let's not
	# assume it doesn't have metacharacters, even though
	# Unix usernames can't have any.)
	my $pattern =
	    '^' .
	    quotemeta($username) .
	    '\s+(\S+)\s+(.+)$';
	my $get_who = make_extractor $pattern;

	my %info = ();
	for (`who`) {
	    # $_ has lines of tainted information
	    my($tty, $date) = &$get_who($_);
	    # but $tty and $date are untainted
	    $info{$tty} = $date;
	}
	# %info now has untainted information
	...
    }

Any items which need to be extracted should be within memory parens.
Because of that, the string should normally have at least one set
of memory parens. The pattern will be applied to each of the
arguments in turn, returning a list of all matched items in memory
parens. Any arguments which fail to match will add no items to the
list. If called in a scalar context, the generated sub will return
just the first untainted item in the list. No locale is used; see
L<perllocale/SECURITY>.

Note that the pattern may need to be written a little differently
than usual, since it's going to be passed as a string. For example,
it's not necessary to backwhack forward slashes in the pattern,
since those aren't regexp metacharacters. Also, if the pattern is
built up in an expression, it's important that the components all
be untainted! And, of course, it needs to be a valid regular
expression; otherwise, it causes an immediate error which may
be trapped with C<eval>.

For a case-insensitive match, which would usually be indicated with
the C</i> modifier, use the embedded C<(?i)> modifier, as described
in L<perlre(1)>. The other embeddable modifiers also work.

If the pattern contains backslashes, as many do, it is especially
problematic. For example, these attempts to make a pattern aren't
doing what they might look like.

    $pattern1 = "(\w+)";	# effectively /(w+)/

    $pattern2 = '\Q' . $foo;	# doesn't use quotemeta

Usually, though, single quotes will do what you expect (and double
quotes will confuse you). To help in debugging, you may set
C<$Taint::DEBUGGING = 1> before calling make_extractor, which will
produce an allegedly-helpful debugging message as a warning. This
message will have a form of the regular expression passed, like
C</(w+)/> for C<$pattern1> above.

=cut

sub import {
    my $class = shift;
    my @importables;
    my $pkg = caller;
    for (@_) {
	if ($_ eq 'unconditional_untaint') {
	    unless ($insanity{$pkg}) {
		require Carp;
		&Carp::croak("Wrong way to import unconditional_untaint()");
	    }
	    my $name = "${pkg}::unconditional_untaint";
	    no strict 'refs';
	    if (defined &$name) {
		require Carp;
		&Carp::croak("Can't redefine &$name");
	    }
	    # Okay, you want it, you got it.
	    *{$name} = sub {
		#
		# This routine is provided on the long-established 
		# Perlian principle that, if you really want it, you
		# should always be given enough rope to shoot yourself
		# in the foot.
		# 
		# Besides, if this routine wasn't here, some fool would
		# write it up, do it badly, document it worsely, and
		# then print it in a book which would continue to
		# haunt us for the next decade.  (It's happened
		# before. Remember 'getgrid'? And the bad methods
		# some books still use instead of using CGI.pm?)
		# 
		# If you really want to use this, you lunatic, first put
		# "no Taint 'sanity';" into your code. This will show
		# other programmers that you have an odd number of bits
		# per byte, and they will shun you.
		#
		# You have been warned.
		#
		# (If you haven't heard by now, the real way to untaint
		# is described in the perlsec man pages. Doing it this 
		# way is foolish. There's no point in using taint
		# checking at all if you'll do things like this. But,
		# hey, it's your funeral.)
		#
		# On the other hand, if you've gotten this far, maybe
		# you should consider a different line of work, such
		# as a opening a turnip-polishing franchise
		# or becoming a galley slave.
		#
		# You should know that whoever installed this module
		# may have disabled this routine. That person may
		# be smarter than you, and secretly laughing at 
		# you now. If I were you, I'd go read the perlsec
		# manpage. Or at least a good Dilbert book.
		#
		# I can't put this off any longer, no matter how
		# hard I try...
		#
		for (@_) {
		  $_ = $1 if is_tainted $_ and /^(.*)$/s
		}
		return;		# explicitly returns nothing
	    };

=item unconditional_untaint LIST

By unpopular request, this routine is included. Don't use it. Use
the method described in L<perlsec(1)> instead. You'd have to be crazy
to use this routine. (If you are, read the module itself to see
how to enable it. I'm not gonna tell you here.) 

Given a list of possibly tainted B<lvalues>, this untaints each of them
without any regard for whether they should be untainted or not.

=cut

	} elsif ($_ eq 'allow_no_taint') {
	    $no_taint_okay{$pkg} = 1;
	} else {
	    push @importables, $_;
	}
    }
    return unless @importables;
    unless ($no_taint_okay{$pkg} or is_tainted tainted_null) {
	# What happened? Probably somebody forgot to use -T,
	# or they thought their script would be setuid/setgid.
	warn "Hmmm... Tainting doesn't seem to be turned on.\n";
	warn "Did you forget to use the -T invocation option?\n";
	require Carp;
	&Carp::croak("Taint checks not enabled");
    }
    local($Exporter::ExportLevel) = 1;
    SUPER::import $class @importables;
}

=item allow_no_taint

By default, importing symbols from this module requires taint checks
to be turned on. If you wish to use this module without requiring
taint checking (for example, if writing a module which may or may
not be run under C<-T>) either import this pseudo-item...

    use Taint qw(allow_no_taint);	# allow to run without -T
    use Taint;				# default import list

or avoid importing any symbols by explicitly passing an empty import
list.

    use Taint ();	# importing no symbols

If you use either of these methods to allow taint checks not to be
required, you may want to use the constant C<taint_checking> (see
L</taint_checking>) to determine whether checks are on. 

It may be helpful to allow checks to be off during development,
but be sure to require them after release!

=cut

# This is the fake sub! (But you would have figured that
# out for yourself.)
sub unconditional_untaint (@) {
    require Carp;
    &Carp::carp("sub unconditional_untaint() not properly imported");
}

sub unimport {
    my $class = shift;
    my $pkg = caller;
    for (@_) {
	if ($_ eq 'sanity') {
	    if (allowing_insanity) {
		$insanity{$pkg} = 1;
	    } else {
		require Carp;
		&Carp::croak("Disabled option requested");
	    }
	} else {
	    # Simply ignore other unimports
	}
    }
}

1;
__END__

=back

=head2 Exports

The only routine exported by default is C<tainted()>. Fortunately,
this is the only one most folks need. Other routines may be imported
by name, or with the pseudo-import tag C<:ALL>, or the other
pseudo-import tags defined in L<Exporter>.

=head1 NOTES

Tainting may be explicitly turned on with the C<-T> invocation
option (see L<perlrun/-T>). Perl will force taint checking to be
on if a process was started with setuid or setgid privileges.  By
default, this module requires taint checking to be on (but see
L<allow_no_taint>).

A set-id script may not necessarily run with privileges; that
depends upon your system, the privileges of the user running the
script, and possibly upon the configuration of perl. This means
that if a set-id script is run by its own id(s), it won't have any
taint checks - so your script may fail, but only when B<you> run
it!

If you're having trouble getting your script to work when taint
checks are on, you should remember that Perl will automatically
take some extra precautions. By default, Perl doesn't use some
environment variables that it normally would, using locales may
cause data to be tainted, and the current directory ('.') won't be
included in the C<@INC> list. See L<perlsec(1)> for the full list.

=head1 DIAGNOSTICS

=over 4

=item Attempt to taint read-only value

Just what it sounds like. C<taint> is not able to taint something
which can't be modified, such as an expression or a constant.

=item Pattern was /.../o

When C<$Taint::DEBUGGING> is set to a true value, this message will
be issued as a warning for each pattern passed to make_extractor().
This sub will make an attempt to represent the pattern in the
"traditional" C</foo/> format, although there are some differences.
For example, some escapes, such as C<\Q>, aren't really part of
the regular expression engine. So, if this shows a regular expression
as C</\Q/>, that means that it's trying to match a backslash followed
by a capital Q. Also, this format does backwhack the slash mark
itself (since it'll be quoted in the string by slashes), even though
you don't want to pass a backslash before a true slash in the
pattern.  The represented pattern always ends in /o, since that
option is always used internally in make_extractor().

=item sub unconditional_untaint() not properly imported

You should read L<perlsec(1)> again to see how to untaint your
data. Repeat as needed.

=item Can't make code from tainted string

You tried to pass a tainted string to make_extractor(). You should
be ashamed of yourself.

=item Wrong way to import unconditional_untaint()

You should read L<perlsec(1)> again to see how to untaint your
data. Repeat as needed.

=item Can't redefine

You already had a subroutine with the same name as the
C<unconditional_untaint()> routine you were trying to import. How
many of these do you need?

=item Taint checks not enabled

Just what it sounds like. Somehow, you didn't have taint checks
turned on, and (since you're using this module) you probably were
counting on them. Possible reasons:  You thought your script would
be run set-id, but it wasn't. You forgot to put C<-T> on the top
of your script.  You're using a module which uses this one, and
you didn't know that that module expects taint checks to be on.
(If you wish to allow taint checks to be either on or off, see
L</allow_no_taint>.

=item Disabled option requested

You tried to use the C<unconditional_untaint()> routine, but
whoever installed this module thought you shouldn't.
You should read L<perlsec(1)> again to see how to untaint your
data. Repeat as needed.

=item Unexpected error

Something went wrong when trying to taint some data, probably
because you tried to taint the untaintable. (For example, a C<tie>d
variable.) If this happens, please let the author of this module
know the circumstances and the error message so that I can try to
get a better error message into a future version.

=head1 BUGS

We have no way to enforce understanding the docs.

Debugging a program which uses taint checks can be
problematic.

Some modules aren't compatible with taint checking. Write to
their authors and offer to help improve the modules. Modules which
implement tied variables often need help.

The look of some of this module's internal code makes some people
think its author was smoking crack. But some people think that when
they see B<any> Perl code.

C<is_tainted @foo> isn't what you might think. And it don't use no
good grammars, neither, if you asks me.

C<taint %bar> doesn't do anything good. (Hey, I'd make an error
message if I knew how to detect it.)

There is no routine which will taint all the taintable parts
of a structure more complex than a simple list.

Taint checking is a largely-unexplored area of Perl. It's not
unlikely that there are as-yet undiscovered bugs in Perl's tainting
code. While working on this module and its tests, the author found
three bugs in Perl's internal taint handling. (Using taint checking
is like using a safety net with holes. At least it's better than
no net at all.) Most new versions of Perl (and even many subversions)
fix at least one tainting-related bug. The moral of the story: Stay
on alert for announcements about new versions of Perl and vital
modules like this one. (Watch comp.lang.perl.announce.)

C<no Taint;> doesn't turn off taint checks (lexically or otherwise),
and C<use Taint;> doesn't turn them on. Dang.

Some bugs are documented only in this sentence. (Please send
documentation patches and other corrections to the author.)

The following data can never be tainted: references, C<undef>, hash
keys, anything which is not a scalar, and some magical or C<tie>d
variables. Attempting to taint some of these may cause interesting
and educational results. (The module which implements a C<tie>d
variable may allow (or even force) tainting. (For that matter, a
C<tie>d hash could conceivably have tainted keys! But untainting
those would be ...interesting.) Although a reference can't be
tainted, it may reference a thingy which is tainted in whole or in
part.)

There's no routine which taints data "in passing". That is, there's
nothing to which you can pass B<@foo> and get back a tainted copy
of it, leaving @foo unmodified. I have a wonderful reason for this,
but there's not enough room to write it here in the margin.

=begin for_your_eyes_only

Okay, here's the reason, which is simply too big and complex to
stuff into the BUGS section of the manpage.

Suppose you have a module that you're adding taint checks to.
You've got a sub that ends something like this:

      ...
      return &foo(@bar);
    }

Now you decide to add taint to the data you're returning, so you
apply the (hypothetical) taint_in_passing routine to it.

      ...
      return taint_in_passing &foo(@bar);
    }

Unknown to you, somebody has been calling your sub in a scalar
context, and somebody else has been calling it in a list context.
Now, C<&foo(@bar)> is being called in the context of taint_in_passing,
which will be the wrong context part of the time.

You may be wondering now why we don't simply make taint_in_passing
notice the context it's called in, with C<wantarray>, so that it
can evaluate its args in the same context it was called in. (If
you're wondering why we don't just have it return the number of
elements returned by C<&foo(@bar)> when it's called in a scalar
context, you don't understand context issues very well.) But that's
not something that can be done with Perl, at least not currently.
By the time the sub is called, the args have already been evaluated,
context right or wrong.

Thus, there's no way to write a taint_in_passing sub which can
be counted on to do the right thing. :-(

Instead, you should see what your code returns in different
contexts, and then do the right thing, whatever that is.

This module's author believes that a taint_in_passing sub in this
module would be misused by people who don't understand this issue.
If you still want one, now that you understand this issue of
context, you should be able to make one which will do what you need
for your application. Just don't add it to this module unless and
until you can change my mind. :-)  Thanks!

=end for_your_eyes_only

Some bugs should be construed as features, and vice versa. This
may be one of them.

=head1 AUTHOR

Tom Phoenix, E<lt>F<rootbeer@teleport.com>E<gt>

=head1 COPYRIGHT

This entire module is Copyright (C) 1997 by Tom Phoenix. This module
is experimental and may be installed for TESTING AND DEVELOPMENT
PURPOSES ONLY. It may not be distributed or redistributed except
through the Comprehensive Perl Archive Network (CPAN). A modified
or partial copy of this package must not be redistributed without
prior written permission. In particular, this module and Perl's
taint checking may not do what you want, and they may do what you
do not want; using this module in any way without understanding
that fact is strictly forbidden.

=head1 DISCLAIMER

THIS ENTIRE MODULE, INCLUDING ITS DOCUMENTATION AND ALL OTHER FILES,
IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY
AND FITNESS FOR A PARTICULAR PURPOSE.

You B<must> read and understand all appropriate documentation,
especially including L<perlsec(1)> and this manpage. I say again,
this module and Perl's taint checking may not do what you want,
and they may do what you do not want; using this module in any way
without understanding that fact is strictly forbidden.

Although all reasonable efforts have been made to ensure its quality,
utility, and accuracy, it is the users' responsibility to decide
whether this is suitable for any given purpose. You runs your code
and you takes your chances.

Okay, this is a heck of a disclaimer. Try not to be too scared;
the author uses this code himself (when not writing about himself
in the third person). Watch the newsgroup comp.lang.perl.announce
for announcements of new versions of this module and other cool
stuff.

=head1 SEE ALSO

L<perlsec(1)> and L<perlre(1)>.

=cut
