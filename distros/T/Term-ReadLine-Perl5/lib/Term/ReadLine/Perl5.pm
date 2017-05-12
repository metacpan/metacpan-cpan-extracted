# -*- Perl -*-
package Term::ReadLine::Perl5;
=encoding utf8

=head1 Name

Term::ReadLine::Perl5 - A Perl5 implementation GNU Readline

=head2 Overview

This is a implementation of the GNU Readline/History Library written
in Perl5.

GNU Readline reads lines from an interactive terminal with I<emacs> or
I<vi> editing capabilities. It provides as mechanism for saving
history of previous input.

This package typically used in command-line interfaces and REPLs (Read,
Eval, Print, Loop).

=head2 Demo program

Another package, L<Term::ReadLine::Perl5::Demo> is available to let
you run I<Term::ReadLine::Perl5> to experiment with its capabilities
and show how to use the API.

=head1 Synopsis

  use Term::ReadLine::Perl5;
  $term = Term::ReadLine::Perl5->new('ProgramName');
  while ( defined ($_ = $term->readline('prompt>')) ) {
    ...
  }

=cut
use warnings; use strict;
use Term::ReadLine::Perl5::readline;
no warnings 'once';

our $VERSION = '1.43';

use Carp;
eval "use rlib '.' ";  # rlib is now optional
use Term::ReadLine::Perl5::History;
use Term::ReadLine::Perl5::OO;
use Term::ReadLine::Perl5::OO::History;
use Term::ReadLine::Perl5::Tie;
use Term::ReadLine::Perl5::readline;

if (require Term::ReadLine) {
    our @ISA = qw(Term::ReadLine::Stub Exporter);
}
my (%attribs, $term);

our @EXPORT  = qw(IN OUT);


=head2 Variables

Following GNU Readline/History Library variables can be accessed from
Perl program.  See 'GNU Readline Library Manual' and ' GNU History
Library Manual' for each variable.  You can access them via the
C<Attribs> method.  Names of keys in this hash conform to standard
conventions with the leading C<rl_> stripped.

Example:

    $term = Term::ReadLine::Perl5->new('ReadLineTest');
    $attribs = $term->Attribs;
    $v = $attribs->{history_base};	# history_base

=head3 Attribute Names

	completion_suppress_append (bool)
	history_base               (int)
	history_stifled            (int)
        max_input_history          (int)
	outstream                  (file handle)

=cut

my %features = (
		 appname => 1,       # "new" is recognized
		 minline => 1,       # we have a working MinLine()
		 autohistory => 1,   # lines are put into history automatically,
		                     # subject to MinLine()
		 getHistory => 1,    # we have a working getHistory()
		 setHistory => 1,    # we have a working setHistory()
		 addHistory => 1,    # we have a working add_history(), addhistory(),
                                     # or addHistory()
		 readHistory => 1,   # we have read_history() or readHistory()
		 writeHistory => 1,  # we have writeHistory()
		 preput => 1,        # the second argument to readline is processed
		 attribs => 1,
		 newTTY => 1,        # we have newTTY()
		 stiflehistory => 1, # we have stifle_history()
      );

tie %attribs, 'Term::ReadLine::Perl5::Tie' or die ;
sub Attribs {
  \%attribs;
}

=head1 Subroutine

=head2 Standard Term::ReadLine Methods

These methods are standard methods defined by
L<Term::ReadLine>.

=head3 C<ReadLine>

    Readline() -> 'Term::ReadLine::Perl5'

returns the actual package that executes the commands. If this package
is used, the value is C<Term::ReadLine::Perl5>.

=cut
sub ReadLine {'Term::ReadLine::Perl5'}


=head3 readline

   $bool = $term->readline($prompt, $default)

The main routine to call interactively read lines. Parameter
I<$prompt> is the text you want to prompt with If it is empty string,
no preceding prompt text is given. It is I<undef> a default value of
"INPUT> " is used.

Parameter I<$default> is the default value; it can be can be
omitted. The next input line is returned or I<undef> on EOF.

=cut

sub readline {
  shift;
  &Term::ReadLine::Perl5::readline::readline(@_);
}

=head3 new

B<new>(I<$name>,[I<IN>[,I<OUT>]])

returns the handle for subsequent calls to following functions.
Argument is the name of the application.  Optionally can be followed
by two arguments for C<IN> and C<OUT> file handles. These arguments
should be globs.

I<$name> is the name of the application.

This routine may also get called via
C<Term::ReadLine-E<gt>new($term_name)> if you have
C<$ENV{PERL_RL}> set to 'Perl5';

At present, because this code has lots of global state, we currently don't
support more than one readline instance.

=cut
sub new {
    my $class = shift;
    if (require Term::ReadLine) {
	$features{tkRunning} = Term::ReadLine::Stub->Features->{'tkRunning'};
	$features{ornaments} = Term::ReadLine::Stub->Features->{'ornaments'};
    }
    if (defined $term) {
	my $stderr = $Term::ReadLine::Perl5::readline::term_OUT;
	print $stderr "Cannot create second readline interface\n";
	print "Using experimental OO interface based on Caroline\n";
	my ($name, $in, $out) = @_;
	my $opts = {
	    name => $name,
	    in   => $in,
	    out  => $out,
	};
	return Term::ReadLine::Perl5::OO->new($opts);
    }
    shift; # Package name
    if (@_) {
	if ($term) {
	    warn "Ignoring name of second readline interface.\n"
		if defined $term;
	    shift;
	} else {
            # Set Name
	    $Term::ReadLine::Perl5::readline::rl_readline_name = shift;
	}
    }
    if (!@_) {
	if (!defined $term) {
	    my ($IN,$OUT) = Term::ReadLine->findConsole();
	    # Old Term::ReadLine did not have a workaround for a bug
	    # in Win devdriver
	    $IN = 'CONIN$' if $^O eq 'MSWin32' and "\U$IN" eq 'CON';
	    open(my $in_fh,
		 # A workaround for another bug in Win device driver
		 (($IN eq 'CONIN$' and $^O eq 'MSWin32') ? "+< $IN" : "< $IN"))
		or croak "Cannot open $IN for read";
	    open(my $out_fh, ">$OUT") || croak "Cannot open $OUT for write: $!";
	    $Term::ReadLine::Perl5::readline::term_IN  = $in_fh;
	    $Term::ReadLine::Perl5::readline::term_OUT = $out_fh;
	}
    } else {
	if (defined $term and ($term->IN ne $_[0] or $term->OUT ne $_[1]) ) {
	    croak "Request for a second readline interface with different terminal";
	}
	$Term::ReadLine::Perl5::readline::term_IN = shift;
	$Term::ReadLine::readline::term_OUT = shift
    }
    # The following is here since it is mostly used for perl input:
    # $readline::rl_basic_word_break_characters .= '-:+/*,[])}';
    $term = bless [$readline::term_IN,$readline::term_OUT];
    my $self = {
	'IN'  => $readline::term_IN,
	'OUT' => $readline::term_OUT,
    };
    bless $self, $class;

    unless ($ENV{PERL_RL} and $ENV{PERL_RL} =~ /\bo\w*=0/) {
	local $Term::ReadLine::termcap_nowarn = 1; # With newer Perls
	local $SIG{__WARN__} = sub {}; # With older Perls
	$term->ornaments(1);
    }

    # FIXME: something rl_term_set in here causes terminal attributes
    # like bold and underline to work.
    Term::ReadLine::Perl5::readline::rl_term_set();

    return $self;
}

=head3 IN

B<Term::ReadLine::Perl5-E<gt>IN>

Returns the input filehandle
=cut
sub IN {
    my ($self) = @_;
    $self->{IN};
}

=head3 OUT

B<Term::ReadLine::Perl5-E<gt>OUT>

Returns the output filehandle
=cut
sub OUT {
    my ($self) = @_;
    $self->{OUT};
}


=head3 newTTY

B<Term::ReadLine::Perl5-E<gt>newTTY>(I<IN>, I<OUT>)

takes two arguments which are input filehandle and output filehandle.
Switches to use these filehandles.
=cut
sub newTTY($$$) {
  my ($self, $in, $out) = @_;
  $Term::ReadLine::Perl5::readline::term_IN   = $self->{'IN'}  = $in;
  $Term::ReadLine::Perl5::readline::term_OUT  = $self->{'OUT'} = $out;
  my $sel = select($out);
  $| = 1;				# for DB::OUT
  select($sel);
}

=head3 Minline

B<MinLine>([I<$minlength>])>

If B<$minlength> is given, set C<$readline::minlength> the minimum
length a $line for it to go into the readline history.

The previous value is returned.
=cut
sub MinLine($;$) {
    my $old = $minlength;
    $minlength = $_[1] if @_ == 2;
    return $old;
}

#################### History ##########################################

=head3 add_history

   $term->add_history>($line1, $line2, ...)

adds the lines, I<$line1>, etc. to the input history list.

I<AddHistory> is an alias for this function.

=cut

# GNU ReadLine names
*add_history            = \&Term::ReadLine::Perl5::History::add_history;
*remove_history         = \&Term::ReadLine::Perl5::History::remove_history;
*replace_history_entry  = \&Term::ReadLine::Perl5::History::replace_history_entry;

*clear_history          = \&Term::ReadLine::Perl5::History::clear_history;

*history_is_stifled     = \&Term::ReadLine::Perl5::History::history_is_stifled;
*read_history           = \&Term::ReadLine::Perl5::History::read_history;
*unstifle_history       = \&Term::ReadLine::Perl5::History::unstifle_history;
*write_history          = \&Term::ReadLine::Perl5::History::write_history;

# Not sure about the difference between history_list and GetHistory.
*history_list           = \&Term::ReadLine::Perl5::OO::GetHistory;

*rl_History            = *Term::ReadLine::Perl5::rl_History;


# Some Term::ReadLine::Gnu names
*AddHistory             = \&add_history;
*GetHistory             = \&Term::ReadLine::Perl5::History::GetHistory;
*SetHistory             = \&Term::ReadLine::Perl5::History::SetHistory;
*ReadHistory            = \&Term::ReadLine::Perl5::History::ReadHistory;
*WriteHistory           = \&Term::ReadLine::Perl5::History::WriteHistory;

# Backward compatibility:
*addhistory = \&add_history;
*StifleHistory = \&stifle_history;

=head3 stifle_history

   $term->stifle_history($max)

Stifle or put a cap on the history list, remembering only C<$max>
number of lines.

I<StifleHistory> is an alias for this function.

=cut
### FIXME: stifle_history is still here because it updates $attribs.
## Pass a reference?
sub stifle_history($$) {
    my ($self, $max) = @_;
    $max = 0 if !defined($max) || $max < 0;

    if (scalar @rl_History > $max) {
	splice @rl_History, $max;
	$attribs{history_length} = scalar @rl_History;
    }

    $Term::ReadLine::Perl5::History::history_stifled = 1;
    $attribs{max_input_history} = $self->{rl_max_input_history} = $max;
}

=head3 Features

B<Features()>

Returns a reference to a hash with keys being features present in
current implementation. Several optional features are used in the
minimal interface:

=over

=item *
I<addHistory> is present if you can add lines to history list via
the I<addHistory()> method

=item *
I<appname> is be present if a name, the first argument
to I<new()> was given

=item *
I<autohistory> is present if lines are put into history automatically
subject to the line being longer than I<MinLine>.

=item *
I<getHistory> is present if we get retrieve history via the I<getHistory()>
method

=item *
I<minline> is present if the I<MinLine> method available.

=item *
I<preput> is present if the second argument to I<readline> method can
append text to the input to be read subsequently

=item *
I<readHistory> is present you can read history
items previosly saved in a file.

=item *
I<setHistory> is present if we can set history

=item *
I<stifleHistory> is present you can put a limit of the nubmer of history
items to save via the I<writeHistory()> method

=item *
I<tkRunning> is present if a Tk application may run while I<ReadLine> is
getting input.

=item *
I<writeHistory> is present you can save history to a file via the
I<writeHistory()> method

=back

=cut

sub Features { \%features; }

=head1 See also

=over

=item *

L<Term::ReadLine::Perl5::OO> is the newer but unfinished fully OO version.

=item *

L<Term::ReadLine::Perl5> is the first try at the OO package that most
programmers will use.

=item *

L<Term::ReadLine::Perl5::readline-guide> is guide to the guts of the
non-OO portion of L<Term::ReadLine::Perl5>

=item *

L<Term::ReadLine::Perl5::History> describes the history
mechanism

=item *

L<Term::ReadLine> is a generic package which can be used to
select this among other compatible GNU Readline packages.

=back

=cut
1;
