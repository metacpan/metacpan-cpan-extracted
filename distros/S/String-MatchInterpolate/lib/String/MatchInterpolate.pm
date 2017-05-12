#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2010 -- leonerd@leonerd.org.uk

package String::MatchInterpolate;

our $VERSION = '0.06';

use strict;
use warnings;

use Carp;
use Text::Balanced qw( extract_delimited );

=head1 NAME

C<String::MatchInterpolate> - named regexp capture and interpolation from the
same template.

=head1 SYNOPSIS

 use String::MatchInterpolate;

 my $smi = String::MatchInterpolate->new( 'My name is ${NAME/\w+/}' );

 my $vars = $smi->match( "My name is Bob" );
 my $name = $vars->{NAME};

 print $smi->interpolate( { NAME => "Jim" } ) . "\n";

=head1 DESCRIPTION

This module provides an object class which represents a string matching and
interpolation pattern. It contains named-variable placeholders which include
a regexp pattern to match them on. An instance of this class represents a
single pattern, which can be matched against or interpolated into.

Objects in this class are not modified once constructed; they do not store
any runtime state other than data derived arguments passed to the constructor.

=head2 Template Format

The template consists of a string with named variable placeholders embedded in
it. It looks similar to a perl or shell string with interpolation:

 A string here with ${NAME/pattern/} interpolations

The embedded variable is delmited by perl-style C<${ }> braces, and contains
a name and a pattern. The pattern is a normal perl regexp fragment that will
be used by the C<match()> method. This regexp should not contain any capture
brackets C<( )> as these will confuse the parsing logic. If the variable is
not named, it will be assigned a name based on its position, starting from 1
(i.e. similar to regexp capture buffers). If a variable does not provide a
matching pattern but the constructor was given a default with the
C<default_re> option, this will be used instead.

Outside of the embedded variables, the string is interpreted literally; i.e.
not as a regexp pattern. A backslash C<\> may be used to escape the following
character, allowing literal backslashes or dollar signs to be used.

The intended use for this object class is that the template strings would come
from a configuration file, or some other source of "trusted" input. In the
current implementation, there is nothing to stop a carefully-crafted string
from containing arbitrary perl code, which would be executed every time the
C<match()> or C<interpolate()> methods are called. (See "SECURITY" section).
This fact may be changed in a later version.

=head2 Suffices

By default, the beginning and end of the string match are both anchored. If
the C<allow_suffix> option is passed to the constructor, then the end of the
string is not anchored, and instead, any suffix found by the C<match()> method
will be returned in a hash key called C<_suffix>. This may be useful, for
example, when matching directory names, URLs, or other cases of strings with
unconstrained suffices. The C<interpolate()> method will not recognise this
hash key; instead just use normal string concatenation on the result.

 my $userhomematch = String::MatchInterpolate->new(
    '/home/${USER/\w+/}/',
    allow_suffix => 1
 );

 my $vars = $userhomematch->match( "/home/fred/public_html" );
 print "Need to fetch file $vars->{_suffix} from $vars->{USER}\n";

=cut

=head1 CONSTRUCTOR

=cut

=head2 $smi = String::MatchInterpolate->new( $template, %opts )

Constructs a new C<String::MatchInterpolate> object that represents the given
template and returns it.

=over 8

=item $template

A string containing the template in the format given above

=item %opts

A hash containing extra options. The following options are recognised:

=over 4

=item allow_suffix => BOOL

A boolean flag. If true, then the end of the string will not be anchored, and
instead, an extra suffix will be allowed to follow the matched portion. It
will be returned as C<_suffix> by the C<match()> method.

=item default_re => Regexp or STRING

A precompiled Regexp or string defining a regexp to use if a variable does not
provide a pattern of its own.

=item delimiters => ARRAY of [Regexp or STRING]

An array containing two precompliled Regexps or strings, giving the variable
openning and closing delimiters. These default to C<qr/\$\{/> and C<qr/\}/>
respectively, but by passing other values, other styles of template string may
be parsed.

 delimiters => [ qr/\{/, qr/\}/ ]   # To match {name/pattern/}

=back

=back

=cut

sub new
{
   my $class = shift;
   my ( $template, %opts ) = @_;

   my $self = bless {
      template => $template,
      vars     => [],
   }, $class;

   my %vars;

   my $matchpattern = "";
   my $varnumber = 0;
   my @matchbinds;

   my @interpparts;

   # The interpsub closure will contain elements of this array in its
   # environment
   my @literals;

   my ( $delim_open, $delim_close ) = $opts{delimiters} ? 
      @{ $opts{delimiters} } :
      ( qr/\$\{/, qr/\}/ );

   while( length $template ) {
      if( $template =~ s/^$delim_open// ) {
         $template =~ s/^(\w*)//;
         my $var = length $1 ? $1 : ( $varnumber + 1 );

         croak "Multiple occurances of $var" if exists $vars{$var};
         $vars{$var} = 1;
         push @{ $self->{vars} }, $var;

         my $pattern;
         if( $template =~ m{^/} ) {
            ( $pattern, $template ) = extract_delimited( $template, "/", '', '' );

            # Remove delimiting slashes
            s{^/}{}, s{/$}{} for $pattern;
         }
         elsif( $opts{default_re} ) {
            $pattern = $opts{default_re};
         }
         else {
            croak "Expected a pattern for $var variable";
         }

         $template =~ s/^$delim_close// or croak "Expected $delim_close";

         $matchpattern .= "($pattern)";
         push @matchbinds, "$var => \$ ". ( $varnumber + 1 );
         push @interpparts, "\$_[$varnumber]";

         $varnumber++;
      }
      else {
         # Grab up to the next delimiter, or end of the string
         $template =~ m/^((?:\\.|[^\\])*?)(?:$|$delim_open)/;
         my $literal = $1;

         substr( $template, 0, length $literal ) = "";

         # Unescape
         $literal =~ s{\\(.)}{$1}g;

         $matchpattern .= quotemeta $literal;

         push @literals, $literal;
         push @interpparts, "\$literals[$#literals]";
      }
   }

   if( $opts{allow_suffix} ) {
      $matchpattern .= "(.*?)";
      push @matchbinds, "_suffix => \$" . ( $varnumber + 1 );
      $varnumber++;
   }

   my $matchcode = "
   \$_[0] =~ m{^$matchpattern\$} or return undef;
   return {
" . join( ",\n", map { "      $_" } @matchbinds ) . "
   }
";

   $self->{matchsub} = eval "sub { $matchcode }";
   croak $@ if $@;

   my $interpcode;
   # By some benchmark testing, join() seems to be faster than chained concat
   # after about 10 items. This is likely due to the fact that the result
   # string only needs allocating once, rather than being incrementally grown.
   # The call/return overhead of join() itself seems to mask this effect below
   # that limit.
   if( @interpparts < 10 ) {
      $interpcode = join( " . ", @interpparts );
   }
   else {
      $interpcode = "join( '', " . join( ", ", @interpparts ) . " )";
   }

   $self->{interpsub} = eval "sub { $interpcode }";
   croak $@ if $@;

   return $self;
}

=head1 METHODS

=cut

=head2 @values = $smi->match( $str )

=head2 $vars = $smi->match( $str )

Attempts to match the given string against the template. In list context it
returns a list of the captured variables, or an empty list if the match fails.
In scalar context, it returns a HASH reference containing all the captured
variables, or undef if the match fails.

=cut

sub match
{
   my $self = shift;
   my ( $str ) = @_;

   my $vars = $self->{matchsub}->( $str ) or return;

   return $vars if !wantarray;

   my @values = @{$vars}{ $self->vars };
   push @values, $vars->{_suffix} if exists $vars->{_suffix};
   return @values;
}

=head2 $str = $smi->interpolate( @values )

=head2 $str = $smi->interpolate( \%vars )

Interpolates the given variable values into the template and returns the
generated string. The values may either be given as a list of strings, or in a
single HASH reference containing named string values.

=cut

sub interpolate
{
   my $self = shift;
   if( ref $_[0] eq "HASH" ) {
      return $self->{interpsub}->( @{$_[0]}{ $self->vars } );
   }
   else {
      return $self->{interpsub}->( @_ );
   }
}

=head2 @vars = $smi->vars()

Returns the list of variable names defined / used by the template, in the
order in which they appear.

=cut

sub vars
{
   my $self = shift;
   return @{ $self->{vars} };
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 BENCHMARKS

The template is compiled into a pair of strings containing perl code, which
implement the matching and interpolation operations using normal perl regexps
and string contatenation. These strings are then C<eval()>ed into CODE
references which the object stores. This makes it faster than a simple regexp
that operates over the template string each time a match or interpolation
needs to be performed. The following output compares the speed of 
C<String::MatchInterpolate> against both direct hard-coded perl, and simple
regexp operations.

 Comparing 'interpolate':
 
            Rate   s///  S::MI native
 s///    81938/s     --   -44%   -90%
 S::MI  145232/s    77%     --   -82%
 native 806800/s   885%   456%     --
 
 Comparing 'match':
 
            Rate    m//  S::MI native
 m//     35354/s     --   -46%   -73%
 S::MI   65749/s    86%     --   -50%
 native 131885/s   273%   101%     --

(This was produced by the F<benchmark.pl> file in the module's distribution.)

=head1 SECURITY CONSIDERATIONS

Because of the way the optimised match and interpolate functions are
generated, it is possible to inject arbitrary perl code via the template given
to the constructor. As such, this object should not be used when the source of
that template is considered untrusted.

Neither the C<match()> nor C<interpolate()> methods suffer this problem; any
input into these is safe from exploit in this way.

=head1 SEE ALSO

The following may be used to provide just C<interpolate()>-style operations:

=over 4

=item *

L<String::Interpolate> - Wrapper for builtin the Perl interpolation engine

=item *

L<Text::Sprintf::Named> - sprintf-like function with named conversions

=back

The following may be used to provide just C<match()>-style operations:

=over 4

=item *

L<Regexp::NamedCaptures> - Saves capture results to your own variables

=item *

perlre(1) - named capture buffers in perl 5.10 (the C<< (?<NAME>pattern) >>
format)

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
