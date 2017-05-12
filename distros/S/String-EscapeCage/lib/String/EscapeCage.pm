package String::EscapeCage;

use warnings;
use strict;

our $VERSION = '0.02';
use base qw( Exporter );
our @EXPORT_OK = qw( cage uncage );  # escape<foo> added automatically
use overload
  '""' => \&stringify,
  '.'  => \&concat,
  '0+' => \&numify,
  bool => \&boolify;

use Carp;
use Symbol qw( qualify_to_ref );
sub untaint($) {  $_[0] =~ /(.*)/s;  return $1;  }
  # This should be in a module, but Scalar::Util provides only "tainted",
  # and Taint::Util and Taint::Runtime aren't in the standard distribution.



# configuration constants:

my $disable_cage = '';  # iff disable checking everywhere
my %dmz_callers = ();  # disable checking when called from some packages
# TODO:  make subs respect these, provide interface to set them




# implementation

sub new
{
	my $class = shift;
	my $string = shift;
	# TODO:  error checking unless $disable_error_checking;
	return bless \$string, $class;
}

sub cage($)
{
	my $value = shift;  # a string
	return __PACKAGE__->new($value);
}

# TODO:  Should we die/warn when the programmer attempts to uncage a
# normal string?  I think so, because programmers really should keep track
# of what is caged and what is not.  That is, they shouldn't just uncage
# everything in an attempt to get the data out.  If a programmer wants to
# do that during rapid development, the solution is to temporarily import
# the uncageany sub under the name "uncage".

sub uncage($)
{
	my $self = shift;
	croak "Not a caged string" unless UNIVERSAL::isa( $self, __PACKAGE__ );
	  # TODO:  unless $disable_error_checking;
	return untaint $$self;  # assume user is competent, so untaint
}

# I recommend against using uncageany:  you should know what's caged and what's not
sub uncageany
{
	return map {
	  untaint( UNIVERSAL::isa( $_, __PACKAGE__ ) ? $$_ : $_ )
	} @_;
}

sub stringify
{
	my $self = shift;
	# TODO:  return $$self if caller_is_matching_string_against_regexp();
	return $$self if $disable_cage;  # don't untaint
	  # TODO:  disable fatal errors according to program scope, caller scope
	# TODO:  warn only once per caller, object, creation point, value, etc
	croak "Access of unescaped Caged string";
	# TODO:  report contents, where it was caged, etc
	return $$self;
}

sub concat
{
	my $self = shift;
	my $other = shift;  # !ref string may get extra escaping
	my $order = shift;
	UNIVERSAL::isa($other,__PACKAGE__) and $other = $$other;
	return cage( $order ? $other.$$self : $$self.$other );
}

# when used as a number, we can ignore the danger, I think.
# anyway, the user really needs numeric access just to do bounds checking etc
sub numify
{
	my $self = shift;
	return $$self;
}


# when used as a boolean guard, we can ignore the danger
sub boolify
{
	my $self = shift;
	return $$self;
}

# though I'd prefer to overload =~
sub re
{
	my $self = shift;
	my $re = shift;  # qr/regexp/
	return $$self =~ /$re/;
}




# TODO:  let extensions add elements
my %SCHEMES = (  # schemename => (transforming (xform)) escaping sub

  percent => sub {
	my $string = shift;
	$string =~ s/ [ =] / sprintf '%%%02X', ord($&) /xeg;
	return $string;
  },

  html => do {
	my %ESCAPE_OF = (
	  '<'	=> '&lt;',
	  '>'	=> '&gt;',
	  '&'	=> '&amp;',
	  "\n"	=> "<br>\n",  # maybe
	);
	my $RE = eval 'qr/[' . join( '', keys(%ESCAPE_OF) ) . ']/';
	# TODO:  implement escaping properly
	# TODO:  better yet, use CGI::escapeHTML (and think about dependencies)
	sub {
		my $string = shift;
		$string =~ s/$RE/$ESCAPE_OF{$&}/xg;
		return $string;
	}
  },

  cstring => do {  # or maybe use String::Escape
	my %ESCAPE_OF = map { eval qq| "\\$_" | => "\\$_" }
	  qw( 0 a b t n f r \ " );
	my $RE = eval 'qr/[' . join( '', keys(%ESCAPE_OF) ) . ']/';
	sub {
		my $string = shift;
		$string =~ s/$RE/$ESCAPE_OF{$&}/xg;
		return $string;
	}
  },

  # TODO:  shell, sql, http header, cat -v
);


while( my($name,$xform) = each %SCHEMES ) {
	my $subname = 'escape' . $name;
	push @EXPORT_OK, $subname;
	*{qualify_to_ref( $subname )} = sub($) {
		my $self = shift;
		# TODO:  should pass remaining @_ params to xform sub?
		# (would want to specify a different prototype)
		my $string = UNIVERSAL::isa( $self, __PACKAGE__ ) ?
		  $$self :
		  !ref $self ?
		    $self :  # TODO:  think we should be a util for bare strings
		    croak "Not an EscapeCaged string";
		return untaint $xform->( $string );
	};
}




1;




=pod

=head1 NAME

String::EscapeCage - Cage and escape strings to prevent injection attacks


=head1 VERSION

Version 0.02


=head1 SYNOPSIS

The String::EscapeCage module puts dangerous strings in a cage.  It eases
escaping to various encodings, helps developers track what data are
dangerous, and prevents injection attacks.


    use String::EscapeCage qw( cage uncage escapehtml );

    my $name = cage $cgi->param('name');
    print "Hello, ", $name, "\n";  # croaks to avoid HTML injection attack
    print "Hello, ", escapehtml $name, "\n";  # nice and safe
    print "Hello, ", uncage $name, "\n";  # remove protection




=head1 DESCRIPTION

After the L<C<cage>> function cages a string, the L<C<uncage>> method
releases it and L<C<escapehtml>>, L<C<escapecstring>>, etc methods safely
escape (transform) it.  If an application cages all user-supplied strings,
then a run-time exception will prevent application code from accidentally
allowing an SQL, shell, cross-site scripting, cat -v, etc injection attack.
String::EscapeCage's paranoia can be adjusted for development.  The concept is
similar to "tainted" data, but is implemented by "overload"ing the '""'
stringify method on blessed scalar references.


By default C<String::EscapeCage> does not export any subroutines.
The subroutines are (available for import and/or as methods):


=over 4


=item cage STRING / new STRING

Return a new EscapeCage object holding the given string.  C<cage> is
only available as an exported function; C<new> is only available as a
class method.


=item uncage CAGE

Returns the string that had been "caged" in the given EscapeCage object.
It will be untainted, since you presumably know what you're doing with it.
Available as an exported function or an object method.


=item re CAGE REGEXP

Applies the REGEXP to the string that had been "caged", taking the place
of the regular expression binding operator C<=~>.

I want to overload C<=~> and let an EscapeCage uncage and untaint
itself just as if it were a tainted strings, but L<C<overload>> doesn't
support C<=~>.  So, this is an ugly work-around to get a little brevity
and to mark points for when we figure out overloading.  Doesn't set the
(implicitly local()ized) numbered match variables (eg C<$1>) the way
you want.


=item escapecstring CAGE

Returns the C-string-escaped transformation of the string that had been
"caged" in the given EscapeCage object.  It will be untainted, since it
should be safe to print now.  Available as an exported function or an
object method.


=item escapepercent CAGE

Returns the URL percent-escaped transformation of the string that had been
"caged" in the given EscapeCage object.  It will be untainted, since it
should be safe to print now.  Available as an exported function or an
object method.


=back




=head1 ADDING STRING::ESCAPECAGE TO AN EXISTING PROJECT

=over 4

=item * Turn global paranoia off (not yet implemented); cage all incoming strings.

=item * Over time, in each package, turn local paranoia on (not yet implemented); escape strings in the package's code and cage new strings.

=item * When done, turn global paranoia back on.

=item * Remove explicit local paranoia setting if desired.

=back




=head1 CAVEATS

=over 4

=item * Different ref()/blessed() behavior

=item * Doesn't protect against strings you build yourself; eg building
a URL string by manually decoding hex digits (May I suggest that the
decoding function should return a cage?).

=back




=head1 COMPARISON WITH TAINT

=over 4

=item * Taint checking (for setuid etc) distrusts the invoking user;
String::EscapeCage focuses its distrust on explicitly marked data (usually input).

=item * A tainted value may be print()ed or syswrite()d; an attempt to
print a caged value will croak.

=item * Tainting lacks granularity; EscapeCages may be explicitly wrapped
around some data but not others.

=item * A tainted value may be used as a method name or symbolic sub;
String::EscapeCage disallows this.

=item * Taintedness can (essentially only) be removed via regular
expressions or hash keys; a String::EscapeCage can only be removed
with an explicit call to L<C<uncage>>, L<C<re> (regular expression)>,
L<C<escapehtml>>, etc.

=item * String::EscapeCage doesn't do the cleanup that the C<-T> taint flag
enables:  C<@INC>, C<$ENV{PERL5LIB}> and C<$ENV{PERLLIB}>, C<$ENV{PATH}>,
any setuid/setgid issues.

=back




=head1 BUGS

=over 4

=item * The interface was designed without input from a real project
and is subject to change.

=item * You can't use a regular expression on a caged string

=back

Please report any bugs or feature requests to
C<bug-escapecage at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-EscapeCage>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.




=head1 TODO

=over 4

=item * Define the interface.  Until this is used in a real project,
it's tough to say what the optimal interface would be.

=item * Provide different levels of strictness/fatality.

=item * Provide levels of debugging.  Notate cages with information for
humans:  place where caged, reason, etc.

=item * Give formally precise implementations of current escaping schemes:
percent, html, cstring.

=item * Add other escaping schemes:  shell, sql, http header, cat -v,
lots more.

=item * Add a nice mechanism by which other modules can add other
escaping schemas.

=item * Make wrappers of standard libraries that perform caging.
For example:  A wrapper class for an IO::Handle object whose C<readline>
returns caged strings or whose C<print> etc automatically htmlescapes
caged strings.  A sub that changes all the values in an Apache::Request
object into caged values.  Validation routines that "see through" cages.

=item * Optimize.  Maybe memoize escaped values, either by object
or by value.  Maybe add the ability to turn off error checking.
Faster implementations of each escaping schema.

=back




=head1 AUTHOR

    Mark P Sullivan
    CPAN ID: msulliva
    Zeroth Solutions


=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

taint in L<perlsec>, L<Apache::TaintRequest>

=cut
