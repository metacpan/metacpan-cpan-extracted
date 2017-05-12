use strict;
use warnings;
require 5.006;
package Parse::Template;
$Parse::Template::VERSION = '3.08';

use Carp;
use constant DEBUG => 0;
use vars qw/$AUTOLOAD/;
sub AUTOLOAD {
  my($class, $part) = ($AUTOLOAD =~ /(.*)::(.*)$/);
  no strict 'refs';
  *$AUTOLOAD = sub { (ref $_[0] || $class)->eval("$part", @_) };
  goto &$AUTOLOAD;
}

use Symbol qw(delete_package);
{ my $id = 0; sub getid { $id++ } }

my $PACKAGE = __PACKAGE__;
sub new {
  my $receiver = shift;
  my $class = $PACKAGE . '::Sym' . getid();
  my $self = bless {}, $class;	# absolutely nothing in $self
  no strict 'refs';
  %{"${class}::template"} = ();	# so no 'used only once' warning
  ${"${class}::ancestor"} = '';	# so no 'used only once' warning

  @{"${class}::ISA"} = ref $receiver || $receiver;
  ${"${class}::ancestor"} = $receiver;	# reverse the destruction order
  *{"${class}::AUTOLOAD"} = \&AUTOLOAD; # so no warning for procedural calls
  %{"${class}::template"} = @_ ;
  $self;
}
use constant TRACE_ENV => 0;
sub env {
  my $self = shift;
  my $class = ref $self || $self;
  my $symbol = shift;
  if ($symbol =~ /\W/) {
    Carp::croak "invalid symbol name: $symbol"
  }
  no strict;
  if (@_) {
    do {
      my $value = shift;
      print STDERR "${class}::$symbol\t$value\n" if TRACE_ENV;
      if (ref $value) {
		*{"${class}::$symbol"} = $value;
      } else {			# scalar value
      	*{"${class}::$symbol"} = \$value;
      }
      $symbol = shift if @_;
      if ($symbol =~ /\W/) {
		Carp::croak "invalid symbol name: $symbol";
      }
    } while (@_);
  } 
  elsif (defined *{"${class}::$symbol"}) { # borrowed from Exporter.pm
    return \&{"${class}::$symbol"} unless $symbol =~ s/^(\W)//;
    my $type = $1;
    return 
		$type eq '*' ?  *{"${class}::$symbol"} :
		$type eq "\$" ? \${"${class}::$symbol"} :
		$type eq '%' ? \%{"${class}::$symbol"} :
		$type eq '@' ? \@{"${class}::$symbol"} :
		$type eq '&' ? \&{"${class}::$symbol"} :
		do { Carp::croak("Can\'t find symbol: $type$symbol") };
  } 
  else {
    undef;
  }
}
sub DESTROY {
  print STDERR "destroy(@_): ", ref $_[0], "\n" if DEBUG;
  delete_package(ref $_[0]);
}
# Purpose: validate the regexp and replace "!" by "\!", and "/" by "\/" 
#          if not already escaped
# Arguments: a regexp
# Returns: the preprocessed regexp
sub ppregexp {
  #  my $self = $_[0]; # useless
  my $regexp = $_[1];
  eval { '' =~ /$regexp/ };
  if ($@) {	
    $@ =~ s/\s+at\s+[^\s]+\s+line\s+\d+[.]\n$//; # annoying info
    Carp::croak $@;	
  }
  for ($regexp) {
	s{
		( (?: \G | [^\\] ) (?: \\{2} )* )		# even number of back-slashes 
		( [!/\"] )								# used delimiters
	}{$1\\$2}xg;
	
	# replace back exceptions (?!...), (?<!...)
	s{
		( \( \? <? ) 							# (? or (?<
		\\										# inserted by first replace
		( ! )									# delimiter
	}{$1$2}xg;									# remove back-slash
  }
  $regexp;
}
sub getPart {		
  my $self = shift;
  my $part = shift;
  my $class = ref $self || $self;
  my $text = '';
  no strict 'refs';
  unless (defined($text = ${"${class}::template"}{$part})) {
     my $parent = ${"${class}::ISA"}[0]; # delegation
     unless (defined $parent) {
      Carp::croak("'$part' template part is not defined");
    }
    $text = $parent->getPart($part);
  } 
  $text;
}
sub setPart {		
  my $self = shift;
  my $part = shift;
  my $class = ref $self || $self;
  no strict 'refs';
  ${"${class}::template"}{$part} = shift; 
}
$Parse::Template::CONFESS = 1;
my $Already_shown = 0;
my $__DIE__ = sub { 
  if  (not($Parse::Template::CONFESS) and $Already_shown) {
    # Reset when the eval() processing is finished
    $Already_shown = 0 if defined($^S); 
    return;
  }
  # evaluated expressions are not always available in (caller(1))[6];
  if (defined($1) and $1 ne '') {
    my $expr = $1;		# what is the template expression?
    { package DB;		# what is the part name?
      @DB::caller = caller(1);
      @DB::caller = caller(2) unless @DB::args;
    };	
    #local $1;
    $expr =~ s/package\s+${PACKAGE}::\w+\s*;//o;
    my $line = 0;
    $expr =~ s/^/sprintf "%2s ", ++$line/egm;
    $expr =~ s/\n;$//;
    my $part = defined $DB::args[1] ? $DB::args[1] : '';
    if ($Already_shown) {
      print STDERR "call from part '$part':\n$expr\n";
    } else {
      print STDERR "Error in part '$part':\n$expr\n";
    }
  } 
  else {
    print STDERR "\$1 not defined";    
  }
  print STDERR "\$1: $1\n";    
  # ignore Already_shown if you won't confess your exception
  $Already_shown = 1 unless $Parse::Template::CONFESS;
};
$Parse::Template::SIG{__WARN__} = sub { # don't know how to suppress this:
  print STDERR "$_[0]" 
    unless ($_[0] =~ /^Use of uninitialized value in substitution iterator/)
};

use constant EVAL_TRACE => 0;
use constant SHOW_PART => 0;
use constant SIGN_PART => 0;
$Parse::Template::SIGN_START = "# Template %s {\n"; # not documented
$Parse::Template::SIGN_END = "# } Template %s\n"; # not documented
my $indent = 0;
my @part = ();
sub eval {
  print STDERR do { 
    local $" = q!', '! ; '..' x ++$indent, "=>eval('@_')\n" 
  } if EVAL_TRACE;
  my $self = shift;
  my $part = shift;		# can't declare $part in eval()
  push @part, $part;
  my $class = ref $self || $self;
  my $text = $self->getPart($part);
  print STDERR qq!$part content: $text\n! if SHOW_PART;
  if (SIGN_PART) {		# not documented
    $text =~ s!^!sprintf $Parse::Template::SIGN_START, $part!e;
    $text =~ s!$!sprintf $Parse::Template::SIGN_END, $part!e;
  }
  local $SIG{__DIE__} = $__DIE__;
  # eval expression in class
  $text =~ s( %% (.*?) %% ){	# the magical substitution
    print STDERR '..' x $indent, "Eval part name: $part\n" if EVAL_TRACE;
    print STDERR '..' x $indent, "  expr: package $class;\n$1\n" if EVAL_TRACE;
    "package $class; $1";
  }eegsx;
  print STDERR "after: $class - $1\n" if EVAL_TRACE;
  die "$@" if $@;		# caught by __DIE__
  pop @part; $part = $part[-1];
  --$indent if EVAL_TRACE;
  $text;
}
1;
__END__

=head1 NAME

Parse::Template - Processor for templates containing Perl expressions

=head1 SYNOPSIS

  use Parse::Template;

  my %template = 
    (
     'TOP' =>  q!Text before %%$self->eval('DATA')%% text after!,
     'DATA' => q!Insert data: ! .
               q!1. List: %%"@list$N"%%! .
               q!2. Hash: %%"$hash{'key'}$N"%%! .
               q!3. File content: %%<FH>%%! .
               q!4. Sub: %%&SUB()$N%%!
    );
 
  my $tmplt = new Parse::Template (%template);
  open FH, "< foo";

  $tmplt->env('var' => '(value!)');
  $tmplt->env('list' => [1, 2, 10], 
              'N' => "\n",
              'FH' => \*FH,
              'SUB' => sub { "->content generated by a sub<-" },
              'hash' => { 'key' => q!It\'s an hash value! });
  print $tmplt->eval('TOP'), "\n";

=head1 DESCRIPTION

The C<Parse::Template> class evaluates Perl expressions
placed within a text.  This class can be used as a code generator,
or a generator of documents in various document formats (HTML, XML,
RTF, etc.).

The principle of template-based text generation is simple.  A template
consists of a text which includes expressions to be evaluated.
Interpretation of these expressions generates text fragments which are
substituted in place of the expressions.  In the case of
C<Parse::Template> the expressions to be evaluated are Perl expressions placed within
two C<%%>.

Evaluation takes place within an environment in which, for example,
you can place data structures which will serve to generate the
parts to be completed.


             TEMPLATE
           Text + Perl Expression 
                |
                +-----> Evaluation ----> Text(document or program)
                |
           Subs + Data structures
            ENVIRONMENT

The C<Parse::Template> class permits decomposing a template into
parts.  These parts are defined by a hash passed as an argument to the
class constructor:
C<Parse::Template->E<gt>C<new('someKey', '... text with expressions to
evaluate ...')>.  Within a part, a sub-part can be included by means of
an expression of the form:

  $self->eval('SUB_PART_NAME')

C<$self> designates the instance of the C<Parse::Template> class.
In an expression you can also use the C<$part> which contains the
part of the template where the expression is found.

Within an expression it is possible to specify only the name of a part
to be inserted.  In this case a subroutine with the name of this part
is generated dynamically.  In the example given in the synopsis, the
insertion of the C<TOP> part can thus be rewritten as follows:

  'TOP' => q!Text before %%DATA()%% text after!

C<DATA()> is placed within C<%%> and is in effect treated as an
expression to be evaluated.

The subroutines take arguments.  In the following example,
the argument is used to control the depth of recursive calls
of a template:

  print Parse::Template->new(
    'TOP' => q!%%$_[0] < 10 ? '[' . TOP($_[0] + 1) . ']' : ''%%!
   )->eval('TOP', 0);

C<$_[0]> initially contains 0. C<TOP> is included as long as the
argument is less than 10.  For each inclusion, 1 is added to the argument.

The C<env()> method permits constructing the environment required for
evaluation of a template.  Each entry to be defined within this
environment must be specified using a key consisting of the name of
the symbol to be created, associated with a reference whose type is
that of the entry to be created within this environment (for example,
a reference to an array to create an array).  A scalar variable is
defined by associating the name of the variable with its value.  A
scalar variable containing a reference is defined by writing
C<'var'=>E<gt>C<\$variable>, where C<$variable> is a lexical variable
that contains the reference.

Each instance of C<Parse::Template> is defined within a specific class,
a subclass of C<Parse::Template>.  The subclass contains the environment
specific to the template and inherits methods from the C<Parse::Template> class.

If a template is created from an existing template (i.e. calling
C<new> as a method of the existing template), it inherits all the parts defined by its ancestor.

In case of a syntax error in the evalutaion of an expression,
C<Parse::Template> tries to indicate the template part and the
expression that is "incriminated".  If the variable
C<$Parse::Template::CONFESS> contains the value TRUE, the stack
of evaluations is printed.

=head1 METHODS

=over 4

=item new HASH

Constructor for the class. C<HASH> is a hash which defines the
template text.

Example:

  use Parse::Template;
  $t = new Parse::Template('key' => 'associated text');

=item env HASH

=item env SYMBOL

Permits defining the environment that is specific to a template.

C<env(SYMBOL)> returns the reference associated with the symbol, or
C<undef> if the symbol is not defined.  The reference that is returned
is of the type indicated by the character (C<&, $, %, @, *>) that
prefixes the symbol.

Examples:

  $tmplt->env('LIST' => [1, 2, 3])}   Defines a list

  @{$tmplt->env('*LIST')}             Returns the list

  @{$tmplt->env('@LIST')}             Ditto


=item eval PART_NAME

Evaluates the template part designated by C<PART_NAME>.  Returns the
string resulting from this evaluation.

=item getPart PART_NAME

Returns the designated part of the template.

=item ppregexp REGEXP

Preprocesses a regular expression so that it can be inserted into a
template where the regular expression delimiter is either a "/" or a
"!".

=item setPart PART_NAME => TEXT

C<setPart()> permits defining a new entry in the hash that defines the
contents of the template.

=back

=head1 EXAMPLES

The C<Parse::Template> class can be used in all sorts of amusing
ways. Here are a few illustrations.

=head2 HTML Generator

The first example shows how to generate an HTML document by using a
data structure placed within the evaluation environment.  The template
consists of two parts, C<DOC> and C<SECTION>.  The C<SECTION> part is
called within the C<DOC> part to generate as many sections as there are
elements in the array C<section_content>.

  my %template = ('DOC' => <<'END_OF_DOC;', 'SECTION' => <<'END_OF_SECTION;');
  <html>
  <head></head>
  <body>
  %%
  my $content;
  for (my $i = 0; $i <= $#section_content; $i++) {
    $content .= SECTION($i);
  }
  $content;
  %%
  </body>
  </html>
  END_OF_DOC;
  %%
  $section_content[$_[0]]->{Content} =~ s/^/<p>/mg;
  join '', '<H1>', $section_content[$_[0]]->{Title}, '</H1>',
                   $section_content[$_[0]]->{Content};
  %%
  END_OF_SECTION;

  my $tmplt = new Parse::Template (%template);

  $tmplt->env('section_content' => [
      {
        Title => 'First Section',
        Content => 'Nothing to write'
      },
      {
        Title => 'Second section',
        Content => 'Nothing else to write'
      }
    ]
  );

  print $tmplt->eval('DOC'), "\n";

=head2 HTML generation using functional notation

The second example shows how to generate an HTML document using a
functional notation, in other words, obtaining the text:

  <P><B>text in bold</B><I>text in italic</I></P>

from:

  P(B("text in bold"), I("text in italic"))

The functions P(), B() and I() are defined as parts of a template.  The Perl expression
that permits producing the content of an element is
very simple, and reduces to:

  join '', @_

The content to be evaluated is the same regardless of the tag and can
therefore be placed within a variable.  We therefore obtain the
following template:

  my $ELT_CONTENT = q!%%join '', @_%%!;
  my $HTML_T1 = new Parse::Template(
       'DOC' => '%%P(B("text in bold"), I("text in italic"))%%',
       'P'   => qq!<P>$ELT_CONTENT</P>!,
       'B'   => qq!<B>$ELT_CONTENT</B>!,
       'I'   => qq!<I>$ELT_CONTENT</I>!,
      );
  print $HTML_T1->eval('DOC'), "\n";

We can go further by making use of the C<$part> variable, which
is defined by default in the environment of evaluation of the template:

  my $ELT_CONTENT = q!%%"<$part>" . join('', @_) . "</$part>"%%!;
  my $HTML_T2 = new Parse::Template(
       'DOC' => '%%P(B("text in bold"), I("text in italic"))%%',
       'P'   => qq!$ELT_CONTENT!,
       'B'   => qq!$ELT_CONTENT!,
       'I'   => qq!$ELT_CONTENT!,
      );
  print $HTML_T2->eval('DOC'), "\n";

Let's look at another step which automates the production of 
expressions from the list of HTML tags which are of interest to us:

  my $DOC = q!P(B("text in bold"), I("text in italic"))!;
  my $ELT_CONTENT = q!%%"<$part>" . join('', @_) . "</$part>"%%!;
  my $HTML_T3 = new Parse::Template(
       'DOC' => qq!%%$DOC%%!,
       map { $_ => $ELT_CONTENT } qw(P B I)
      );
  print $HTML_T3->eval('DOC'), "\n";

To benefit from the possibility of using the template parts as procedures, we can
inherit from the generated template class:

  use Parse::Template;
  my $ELT_CONTENT = q!%%"<$part>" . join('', @_) . "</$part>"%%!;
  my $G = new Parse::Template(
       map { $_ => $ELT_CONTENT } qw(H1 B I)
      );
  @main::ISA = ref($G);
  *AUTOLOAD = \&Parse::Template::AUTOLOAD;
  print H1(B("text in bold"), I("text in italic"));

The reference to C<Parse::Template::AUTOLOAD> avoids the warning message:

  Use of inherited AUTOLOAD for non-method %s() is deprecated

Not very elegant.

=head2 HTML generation by method call

With a slight transformation it is possible to use a 
method-invocation notation:

  my $ELT_CONTENT = q!%%shift(@_); "<$part>" . join('', @_) . "</$part>"%%!;
  my $HTML_T4 = new Parse::Template(
       map { $_ => $ELT_CONTENT } qw(P B I)
      );
  print $HTML_T4->P(
                    $HTML_T4->B("text in bold"),
                    $HTML_T4->I("text in italic")
                   ), "\n";

The C<shift(@_)> permits getting rid of the template object, which
we don't need within the expression.

=head2 Inheritance of parts

In the following example the child template C<$C> inherits the parts defined 
in its parent template C<$A>:

  my %ancestor = 
    (
     'TOP' => q!%%"Use the $part model and -> " . CHILD()%%!,
     'ANCESTOR' => q!ANCESTOR %%"'$part' part\n"%%!,
    );

  my %child = 
    (
     'CHILD' => q!CHILD %%"'$part' part"%% -> %%ANCESTOR() . "\n"%%!,
    );
  my $A = new Parse::Template (%ancestor);
  my $C = $A->new(%child);
  print $C->TOP();

The part <TOP> defined in C<$A> can be called directly from C<$C>, that derives from C<$A>.

=head2 Other examples

C<Parse::Template> was initially created to serve as a code generator
for the C<Parse::Lex> class.  You will find other examples of its use
in the classes C<Parse::Lex>, C<Parse::CLex> and C<Parse::Token>.

=head1 NOTES CONCERNING THE CURRENT VERSION

I would be very interested to receive your comments and suggestions.

=head1 BUGS

Instances are not destroyed.  Therefore, do not use this class 
to create a large number of instances.

=head1 AUTHOR

Philippe Verdret (with translation of documentation into English by Ocrat)

=head1 COPYRIGHT

Copyright (c) 1995-2001 Philippe Verdret. All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
