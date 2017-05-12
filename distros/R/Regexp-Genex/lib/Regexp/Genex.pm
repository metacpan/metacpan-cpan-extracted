package Regexp::Genex;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.07';

our $MAX_QUANTIFIER = 20;
our $rx;
our $in = '';
our @stack = { 
	dot_nl => 0,   # /s modifier
	multiline => 0,# /m modifier
	anycase => 0,  # /i modifier
}; 


package Regexp::Genex::Element;
use List::Util qw(shuffle);

my $top = -1;

# global status
sub anycase { 
	return $stack[$top]{anycase} unless defined $_[1];
	$stack[$top]{anycase} = $_[1];
}

sub dot_nl  { 
	return $stack[$top]{dot_nl} unless defined $_[1];
	$stack[$top]{dot_nl} = $_[1];
}

sub multiline  { 
	return $stack[$top]{multiline} unless defined $_[1];
	$stack[$top]{multiline} = $_[1];
}

sub adjust_mods {
	my ($self, $on, $off) = @_;
	$self->anycase(1)    if $on  =~ /i/;
	$self->anycase(0)    if $off =~ /i/;
	$self->dot_nl(1)     if $on  =~ /s/;
	$self->dot_nl(0)     if $off =~ /s/;
	$self->multiline(1)  if $on  =~ /m/;
	$self->multiline(0)  if $off =~ /m/;
}

sub push_state {
	my ($self) = shift;
	push @stack, { 
		# current state overwriten by new state
		anycase => $self->anycase, 
		dot_nl => $self->dot_nl, 
		multiline => $self->multiline, 
		quant => $stack[$top]{quant},
		@_, # new state
	};
}
sub pop_state {
	my ($self) = @_;
	pop @stack or Carp::confess "Pop without a push";
}

sub add {
	my ($self, $code, $comment) = @_;

	$code = $in.$code;
	if((my $len = length($code)) < 40) {
		# comment after code at col 40
		$rx .= $code;
		if(defined $comment) {
			$rx .= (' 'x(40-$len))."## $comment\n";
		} else {
			$rx .= "\n";
		}
	} else {
		# comment on line before code
		$rx .= "\n".(' 'x40)."## $comment (below)\n" if defined $comment;
		$rx .= "$code\n\n";
	}
}

sub safe_quant {
	my ($self, $quant) = @_;
	# dodge perl's optimizations
	my $nq = $quant;
	#$nq =~ s/\*/{0,$MAX_QUANTIFIER}/;
	#$nq =~ s/\+/{1,$MAX_QUANTIFIER}/;
	return $nq;
}

sub case_mod {
	# i modifier in effect, use \u \L etc to muck with string at rx creation
	return (!$_[0]->anycase) ? '' : ( "", qw(\U \L \u \l) )[rand 5];
}

# $; = undef  ???
# keys = all characters, values = quoted string equivalent
# (String::Escape \80 != perl \x80)
my %all_chars = map { chr($_), '"'.escape(chr($_)).'"' } 0..255;

# regex to pick random
# x "string" =~ /(?=(?>^.*(?{$n=int rand$+[0]})))(??{".{$n}"})(.)/s
sub class_chars {
	my ($self, $qr_class) = @_;

	my @chars = map { $all_chars{$_} } 
				grep { $_ =~ $qr_class } 
				keys %all_chars;

	if(@chars > 10) { # too big, sample
		@chars = shuffle(@chars);
		# XXX can't produce anything possible for regex .{$n+1} exhausts range
		$#chars = 4;
		# could put %all_chars generation in regex and do \d filter
	}
	return scalar(@chars), @chars;
}

sub escape {
	local($_) = shift;
	s/([\\{}"@\$])/\\$1/g; # protect " string interpolation & {} regex parse
	s/([^[:graph:] ])/sprintf "\\%03o", ord($1)/eg;
	#s/(.*)/"$1"/s;
	return $_;
}
#use String::Escape qw(qprintable);
#print qprintable($_)," = ",escape($_),"\n" 
#	for grep { $_ ne eval escape($_) } map chr, 0..255;

package Regexp::Genex::flags;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);

	#my ($on, $off) = @_[1,2];
	# ignore x, always on for us
	# off overrides: perl -le 'print "A" =~ /(?i-i)a/'
	$self->adjust_mods(@_[1,2]);
	
	$self->add('',$self->string);
}

package Regexp::Genex::group;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);

	$self->push_state(quant => $self->quant);
	# modify new state
	$self->adjust_mods(@_[1,2]);

	$self->add("(?:", $self->string);
	$in .= ' '; # ->add_indent
	return $self;
}

package Regexp::Genex::capture;
my $number = 0;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	$number++;
	$self->push_state(quant => $self->quant);

	$self->add("(","( -> \$$number");
	$in .= ' ';
	return $self;
}

package Regexp::Genex::close;
# group, capture, perl code bit
# Pcond Pcut Pahead Pbehind Pgroup Pcapture Pcode Plater
sub new {
    my $self = $_[0]->SUPER::new(@_[1..$#_]);
    chop($in);
	no warnings 'uninitialized';
	my $q = "$_[1]$_[2]";
	my $nq = $self->safe_quant($q);
    $self->add(")$nq",")$q");
	$self->pop_state;
    return $self;
}

package Regexp::Genex::alt;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	$self->add('|','|');
	return $self;
}

package Regexp::Genex::backref;
#  perl -W -MRegexp::Genex -e 'Regexp::Genex::rx(qr/(.)=\1{0,2}/)'
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $var = $_[1];
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);
	my $text = $self->text;

	# the offsets are to the target string but we take that section of $^R
	$self->add(
		'(?: .{1} (?{ $^R.substr($^R,$-[1],$+[1]-$-[1]) }) )'.$nq, $text.$q
	);
	return $self;
}

package Regexp::Genex::text;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $text = $self->text;
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);
	my $case_mod = $self->case_mod;

	my $len = length($text);
	$text = Regexp::Genex::Element::escape($text);
	$self->add("(?: .{$len} (?{ \$^R.\"$case_mod$text\" }) )$nq", $text.$q);
	return $self;
}

package Regexp::Genex::oct;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $text = $self->text;
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);
	my $case_mod = $self->case_mod;

	$self->add("(?: . (?{ \$^R.\"$case_mod$text\" }) )$nq", $text.$q);
	return $self;
}

package Regexp::Genex::hex;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $text = $self->text;
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);
	my $case_mod = $self->case_mod;

	$self->add("(?: . (?{ \$^R.\"$case_mod$text\" }) )$nq", $text.$q);
	return $self;
}

package Regexp::Genex::utf8hex;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $text = $self->text;
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);
	my $case_mod = $self->case_mod;

	$self->add("(?: . (?{ \$^R.\"$case_mod$text\" }) )$nq", $text.$q);
	return $self;
}

package Regexp::Genex::ctrl;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $text = $self->text;
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);
	my $case_mod = $self->case_mod;

	$self->add("(?: . (?{ \$^R.\"$case_mod$text\" }) )$nq", $text.$q);
	return $self;
}

package Regexp::Genex::named;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $text = $self->text;
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);
	my $case_mod = $self->case_mod;

	$self->add("(?: . (?{ \$^R.\"$case_mod$text\" }) )$nq", $text.$q);
	return $self;
}

package Regexp::Genex::Cchar;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $text = $self->text;
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);
	my $case_mod = $self->case_mod;

	$self->add("(?: . (?{ \$^R.\"$case_mod$text\" }) )$nq", $text.$q);
	return $self;
}

package Regexp::Genex::slash;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $text = $self->text;
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);
	my $case_mod = $self->case_mod;

	$self->add("(?: . (?{ \$^R.\"$case_mod$text\" }) )$nq", $text.$q);
	return $self;
}

package Regexp::Genex::any;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);

	#my ($nl, $n) = ('', 3);
	#($nl, $n) = (',"\n"', 4) if($self->dot_nl);
	my ($n, @chars) = ($self->dot_nl) 
		? $self->class_chars(qr/./s)
		: $self->class_chars(qr/./);

	local($") = ",";
	$self->add("(?: . (?{ \$^R.(@chars)[rand $n] }) )$nq", ".$q");
	#$self->add("(?: . (?{ \$^R.('.','x','X'$nl)[rand $n] }) )$nq",".$q");
	return $self;
}

package Regexp::Genex::macro;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $text = $self->text;
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);

	# \d \D \w \W \s \S
	my ($n, @chars) = $self->class_chars(qr/$text/);

	local($") = ",";
	$self->add("(?: . (?{ \$^R.(@chars)[rand $n] }) )$nq", "$text$q");
	return $self;
}

package Regexp::Genex::class;
sub new {
	my $self = $_[0]->SUPER::new(@_[1..$#_]);
	my $text = $self->text;
	my $q = $self->quant;
	my $nq = $self->safe_quant($q);

	# [^dfads]
	my ($n, @chars) = $self->class_chars(qr/$text/);

	local($") = ",";
	$self->add("(?: . (?{ \$^R.(@chars)[rand $n] }) )$nq", "$text$q");
	return $self;
}

# TODO
package Regexp::Genex::anchor;
# $ is a lookahead \n|\z
# \A \z \Z ^ $ \G
# ^ $ are /s sensitive (multiline)
sub new {
    Carp::croak("Genex: Anchors not implemented ^ \$ \\A \\Z \\z \\G\n");
}
package Regexp::Genex::lookahead;
# could run look ahead code at the end and check the output...
# might be no match possible with random string selections
sub new {
    Carp::croak("Genex: Look-ahead not implemented (?=...) (?!...)\n");
}
package Regexp::Genex::lookbehind;
# can look behind! match against the string we have made or fail
sub new {
    Carp::croak("Genex: Look-behind not implemented (?<=...) (?<!...)\n");
}

package Regexp::Genex::cond;
# probably ok, except for the close complications
# (?(1) ... ) should test our $1
sub new {
	Carp::croak("Genex: Cut not implemented (?(...)...|...)\n");
}

package Regexp::Genex::cut;
# probably ok, except for the close complications
sub new {
	Carp::croak("Genex: Cut not implemented (?>...)\n");
}

package Regexp::Genex::code; 
# trashes $^R (stash it somewhere else locally)
# could use condition to avoid $^R trashing (?( (?{...}) ) )
sub new {
	Carp::croak("Genex: Code assertion not implemented (?{...})\n");
}

package Regexp::Genex::later; # (??{})
# probably ok, except for the close complications
# may need original modifier state (esp. /x)
sub new {
	Carp::croak("Genex: Delayed regex not implemented (??{...})\n");
}

#sub new {
#	Carp::carp("Delayed regex not handled (??{...})");
#	my $self = $_[0]->SUPER::new(@_[1..$#_]);
#	my $text = $self->text;
#	my $q = $self->quant;
#	my $nq = $self->safe_quant($q);
#
#	# HACK needs no_close handling in close->new
#    push @stack, { 
#        anycase => $self->anycase, dot_nl => $self->dot_nl,
#        q => $stack[$top]{q}, nq => $stack[$top]{nq},
#		no_close => 1,
#    }; 
#
#	$in .= ' ';
#
#	$self->add($text.$nq, $text.$q);
#	return $self;
#}

package Regexp::Genex;
use YAPE::Regex 'Regexp::Genex';

require Exporter;
our @ISA = qw(Exporter YAPE::Regex);
our @EXPORT_OK = qw(strings strings_rx generator generator_rx);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

our $DEFAULT_LEN = 10;

sub strings {
	my ($rx_arg, $len) = @_;
	my $rx_str = strings_rx($rx_arg);

	$len ||= $DEFAULT_LEN;

	use re 'eval';
	#eval 'use re "debug"';
	("a"x$len) =~ qr/$rx/x;

	return @_;
}

sub _main_rx {
    my $in_rx = shift;

	$rx = "";
	my $orig_rx = Regexp::Genex::Element::escape($in_rx);
	Regexp::Genex::Element->add('', "Orignal: $orig_rx");

	# The ^ means the target length can limit output
	Regexp::Genex::Element->add(
		'^(?> (?{ @_ = (); "" }) )', 'Initialize $^R & @_');
	$in = '  ';

    my $yape = Regexp::Genex->new($in_rx);
    $yape->parse; die $yape->error if $yape->error;
 
	$in = '';
	# left in $rx
}

sub strings_rx {
    my $in_rx = shift;

	_main_rx($in_rx);
 
	Regexp::Genex::Element->add(
		'(?{ push @_, $^R }) (?!)', 'Save & backtrack');

	return $rx;
}

sub generator_rx {
	my $in_rx = shift;

	_main_rx($in_rx);

	Regexp::Genex::Element->add(
		'(?(?{ @_ = $^R if $c++ == $n; }) (?=) | (?!) )',
		'Replay up to $n then stop');

	return $rx;
}

# perl -MRegexp::Genex=:all -le '$i = generator(qr/ab*?/); print $i->() for 1..4; print $i->(1)'
sub generator {
	my ($rx_arg, $len) = @_;
	$len ||= $DEFAULT_LEN;
	my $rx_str = generator_rx($rx_arg);

	# These vars are captured both by the closure and the regex
	my $n = 0;
	my $c;

	use re 'eval';
	#eval "use re 'debug'";
	my $qr = qr/$rx_str/x;

	return sub {
		$n = shift if defined $_[0]; # reset's with argument

		$c = 0; # reset found counter
		('a'x$len) =~ $qr;
		$n++;   # track next to show
		return $_[0];
	};
}

1;
__END__

=pod

=head1 NAME

Regexp::Genex - get the strings a regex will match, with a regex

=head1 SYNPOSIS

 # first try:
 $ perl -MRegexp::Genex=:all -le 'print for strings(qr/a(b|c)d{2,3}e*/)'

 $ perl -x `pmpath Regexp::Genex`
#!/usr/bin/perl -l

 use Regexp::Genex qw(:all);

 $regex = shift || "a(b|c)d{2,4}?";

 print "Trying: $regex";
 print for strings($regex);
 # abdd
 # abddd
 # abdddd
 # acdd
 # acddd
 # acdddd


 print "\nThe regex code for that was:\nqr/";
 print strings_rx($regex);
 print "/x\n";

 my $generator = generator($regex);
 print "Taking first two using generator";
 print $generator->() for 1..2;

 my $big_rx = 'b*?c*?d*?';   # * becomes {0,20}

 my $big = generator($big_rx, ($max_length = 100) );

 print "Taking string 100 of $big_rx";
 print $big->(100); # (caveats below)
 # ccccdddddddddddddddd   NOT 'd'x100 as you may expect

__END__

=head1 HALF-BAKED ALPHA CODE

This is alpha code that relies on experimental features of perl
(regex (?{ }) and friends) and avoiding optimizations in the 
regex engine.  New optimizations could break this module. 

The interface is also quite likely to change.

=head1 DESCRIPTION

This module uses the regex engine to generate the strings that
a given regex would match.  

Some ideas for uses:

  Test and debug your regex.
  Generate test data.
  Generate combinations.
  Generate data according to a lexical pattern (urls, etc)
  Edit the regex code to do your things (eg. add assertions)
  Generate strings, reverse & alternate for pseudo-variable look behind

=head1 EXPORT

Nothing by default, everything with the C<:all> tag.

=over 4

=item @list = strings( $regex, [ $max_length = 10 ] )

Produce a list of strings that would match the regex.

=item $regex_string = strings_rx( $regex )

Returns the regex string used to implement the above.
You'll need to C<use re 'eval'> for this and maybe
C<no warnings 'regexp'>

=item $generator = generator( $regex, [ $max_length = 10 ] )

Return a closure to access the strings one at a time.

Calling $generator->() will return the next string (starting from 0).
Calling $generator->($n) will reset the iterator to string $n
and return it.

=item $regex_string = generator_rx( $regex )

Returns the regex string used to implement the above.
You'll need to C<use re 'eval'> for this and maybe
C<no warnings 'regexp'>

=back

=head2 Gx Package

Small package which is not installed by default, nor officially
approved as a namespace.
It's not part of the public interface, don't use it in modules.
Gx.pm is just a short cut to import Regexp::Genex qw(:all)
mainly useful from the command line:

 perl -MGx -le 'print for strings(qr/a(b|c){2,4}/);'

=head1 LIMITATIONS

Many regex elements such as anchors (^ $ \A \G), look ahead, 
look-behind, code elements and conditionals are not implemented.
Some may be in the future.  I'm considering making a pattern
not wrapped in ^ $ generate leading and trailing junk.
Look-ahead inparticular, is unlikely to ever get implemented.
Perhaps for finite languages.

Regex elements which could match a number of things such as
. [class] \w \s \D currently select a few items from the
set of possibilities and the randomly select one at runtime.
So . may become C<("~","`","\307","9","\266")[rand 5]>.
The rand call is only repeat if the element is backtracked over.
Try these a few times:

 perl -MRegexp::Genex=:all -e 'print strings_rx(qr/\d\w/);'
 perl -MRegexp::Genex=:all -le 'print for strings(qr/\d\w/);'
 perl -MRegexp::Genex=:all -le 'print for strings(qr/\d{1,2}\t\w{1,2}/);'

If you pick apart the generated expression you'll note that
the quantifier * translates to {0,20} (+ to {1,20}).
This can be set (but don't tell ayone it was me that told you)
with $Regexp::Genex::MAX_QUANTIFIER. 32767 is what perl uses.
MAX_QUANTIFIER keeps string generation to smaller sizes.

The generator actually has to replay the match up to where
it was in order to get the next one.  Pretty inefficient but
I can't suspend/yield from within the regex.  Best way forward
might be to fork and use pipes for lazy generation.

The /ismx mode handling is probably not all it could be, 'x' isn't
very relevant, 'm' relates to unimplemented anchors, 'i' will mess
with the case of you text items and 's' mean dot might produce newlines.

Try:

 perl -MRegexp::Genex=:all -e 'print strings_rx(qr/aBc/i);'
 perl -MRegexp::Genex=:all -le 'print for strings(qr/aBc/i);'

Currently, a small patch is required to YAPE::Regex to get
this module to work correctly, see the end of this file.
Hopefully it will be fixed soon (vers currently 3.01)

=head1 TODO

  keep funky state in %_
  work out a good max_length
  dynamically select chars in classes
  unimplemented: anchors, lookbehind, code

  testing code
  packaging
  could upload with patch
  note modifiers in effect in comment

=head1 AUTHOR

Brad Bowman, E<lt>genex@bowman.bsE<gt>

=head1 SEE ALSO

L<YAPE::Regex>
L<String::Random>
http://www.perlmonks.org/index.pl?node_id=284513

=cut



# Canonical and bit twiddleable flags:
$flags =~ tr/gism/abdh/;
 perl -le 'print sprintf "$_ %b",ord $_ for qw(g i m s a b d h)'

$flags =~  s{ (?=(?:.*?(i))?) (?=(?:.*?(m))?) (?=(?:.*?(s))?) (?=(?:.*?(x))?) }
		 	{ $1&&'i' }ex;

perl -le '$ARGV[0] =~ m/ (?=.*?(i))? (?=.*?(m))? (?=.*?(s))? (?=.*?(x))? /x; print "$1 $2 $3 $4"' mixxi
i m  x

perl -W -MGx -e 'Regexp::Genex::rx(qr/\141 \n\x62??((?i-x).c{1,2}|d*)?.{2}\1/sx)'


YAPE::Regex patch

--- /usr/local/share/perl/5.6.1/YAPE/Regex.pm   2004-05-29 13:12:18.000000000 +1000
+++ /usr/local/share/perl/5.6.1/YAPE/Regex.pm.orig      2004-05-29 13:11:50.000000000 +1000
@@ -482,13 +482,12 @@
   if ($self->{DEPTH}-- and $self->{CONTENT} =~ s/^$pat{Pclose}//) {
     my ($quant,$ngreed) = $self->_get_quant;
     return if $quant eq -1;
+    my $node = (ref($self) . "::close")->new;
     
     $self->{CURRENT} = pop @{ $self->{TREE_STACK} };
     $self->{CURRENT}{QUANT} = $quant;
     $self->{CURRENT}{NGREED} = $ngreed;
 
-    my $node = (ref($self) . "::close")->new($quant. $ngreed);
-
   # this code is special to YAPE::Regex::Reverse
   if ($self->isa('YAPE::Regex::Reverse')) {
     if ($quant eq '*' or $quant eq '+') {

