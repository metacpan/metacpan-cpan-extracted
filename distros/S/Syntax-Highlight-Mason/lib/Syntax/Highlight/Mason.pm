#!/usr/bin/perl
package Syntax::Highlight::Mason;

=head1 NAME

Syntax::Highlight::Mason - Perl extension to Highlight HTML::Mason code

=head1 SYNOPSIS

  use Syntax::Highlight::Mason;
  use IO::All;
  my $compiler = Syntax::Highlight::Mason->new();
  while (my $file = shift @ARGV) {
    my $source < io($file);
    print $compiler->compile($source);
  }

=head1 DESCRIPTION

Produce colorized and HTML escaped code from HTML::Mason source
suitable for displaying on the WWW and perhaps even in an Mason
environment.  Lots of things are customizable, but the defaults
are pretty reasonable.

=head2 Customization

The following items can be customized:

 $debug          Set it to 1 to enable debugging output
 $style_sheet    A CSS style sheet that maps HTML ids to colors
 $preamble       HTML that gets inserted at the beginning of a page
 $postamble      HTML that gets inserted at the end of a page
 $color_table    A mapping of perl syntax elements to colors
 @mason_highlight An array, element[0] is inserted before mason code
                            element[1] is inserted after mason code

These are all package Global variables, which you can just set to
your own values if desired.  A simple:
C<$Syntax::Highlight::Mason::debug = 1;>
should do the trick.

=cut

use strict;
our $VERSION = '1.23';

use HTML::Mason::Lexer;
use HTML::Mason::Exceptions (abbr => [qw(syntax_error)]);
use HTML::Mason::Compiler;
use HTML::Entities ();
use Syntax::Highlight::HTML;
use Syntax::Highlight::Perl::Improved ':FULL';
use Class::Container;
use Params::Validate qw(:all);
use base qw(HTML::Mason::Compiler);

our $debug = 0;
################################################################
## Copied from:                                               ##
## CPAN Syntax::Highlight::HTML distribution                  ##
################################################################
our $style_sheet = <<END;
<style type="text/css">
.m-tag { color: #0000ff; font-weight: bold;  }   /* mason tag             */
/* ====================================================================== *
 * Sample stylesheet for Syntax::Highlight::HTML                          *
 *                                                                        *
 * Copyright (C)2004 Sebastien Aperghis-Tramoni, All Rights Reserved.     *
 *                                                                        *
 * This file is free software; you can redistribute it and/or modify      *
 * it under the same terms as Perl itself.                                *
 * ====================================================================== */

.h-decl { color: #336699; font-style: italic; }   /* doctype declaration  */
.h-pi   { color: #336699;                     }   /* process instruction  */
.h-com  { color: #338833; font-style: italic; }   /* comment              */
.h-ab   { color: #000000; font-weight: bold;  }   /* angles as tag delim. */
.h-tag  { color: #993399; font-weight: bold;  }   /* tag name             */
.h-attr { color: #000000; font-weight: bold;  }   /* attribute name       */
.h-attv { color: #333399;                     }   /* attribute value      */
.h-ent  { color: #cc3333;                     }   /* entity               */
.h-lno  { color: #aaaaaa; background: #f7f7f7;}   /* line numbers         */
</style>
END

our $preamble = <<END;
<html>
<head>
$style_sheet
</head>
<body>
<pre>
END

our $postamble = <<END;
</pre>
</body>
</html>
END

################################################################
## Copied from:                                               ##
## http://sedition.com/perl/perl-colorizer.html               ##
################################################################
our $color_table = {
		   'Variable_Scalar'   => 'color:#080;',
		   'Variable_Array'    => 'color:#f70;',
		   'Variable_Hash'     => 'color:#80f;',
		   'Variable_Typeglob' => 'color:#f03;',
		   'Subroutine'        => 'color:#980;',
		   'Quote'             => 'color:#00a;',
		   'String'            => 'color:#00a;',
		   'Comment_Normal'    => 'color:#069;font-style:italic;',
		   'Comment_POD'       => 'color:#014;font-family:' .
		   'garamond,serif;font-size:11pt;',
		   'Bareword'          => 'color:#3A3;',
		   'Package'           => 'color:#900;',
		   'Number'            => 'color:#f0f;',
		   'Operator'          => 'color:#000;',
		   'Symbol'            => 'color:#000;',
		   'Keyword'           => 'color:#000;',
		   'Builtin_Operator'  => 'color:#300;',
		   'Builtin_Function'  => 'color:#001;',
		   'Character'         => 'color:#800;',
		   'Directive'         => 'color:#399;font-style:italic;',
		   'Label'             => 'color:#939;font-style:italic;',
		   'Line'              => 'color:#000;',
		  };

our @mason_highlight = ( '<span class="m-tag">', '</span>' );

=head3 Further Customization

More customization can be done by passing parmeters to the
C<new()> method if desired. You can set the B<preamble>,
B<postamble>, and B<color_table> parameters here too.  In
addition, you can specify your own callback subroutines which
encode B<perl>, B<html>, B<plain> (text), and B<mason> code.
The defaults use I<Syntax::Highlight::Perl::Improved> for perl,
I<Syntax::Highlight::HTML> for HTML, I<HTML::Entities::encode>
for plain text, and bold blue I<HTML::Entities::encode> for
mason code.

=cut

my %spec;
foreach (qw(preamble postamble color_table)) {
  $spec{$_} = {type => SCALAR, parse => 'string', optional => 1};
}
foreach (qw(perl html plain mason)) {
  $spec{$_} = {type => CODEREF, parse => 'code', optional => 1};
}

__PACKAGE__->valid_params(%spec);
undef %spec;

sub initialize {
  my $self = shift;
  my $perl_formatter = Syntax::Highlight::Perl::Improved->new();
  my $html_formatter = Syntax::Highlight::HTML->new(pre => 0);
  $html_formatter->xml_mode(1);
  my $actions = 
    {
     perl => sub { return $perl_formatter->format_string(@_)},
     html => sub { my $t = $html_formatter->parse(@_);
		   return $t
		 },
     plain => sub {return HTML::Entities::encode(join('',@_))},
     mason => sub {return $mason_highlight[0] .
		          HTML::Entities::encode(join('',@_)) .
			  $mason_highlight[1]}
    };
  my %p = validate(@_,{
		       preamble => {default => $preamble},
		       postamble => {default => $postamble},
		       color_table => {default => $color_table},
		       perl => {default => $actions->{perl}},
		       html => {default => $actions->{html}},
 		       plain => {default => $actions->{plain}},
		       mason => {default => $actions->{mason}}
		      });
  $perl_formatter->define_substitution('<' => '&lt;', 
				       '>' => '&gt;', 
				       '&' => '&amp;');	# HTML escapes.

  while ( my ( $type, $style ) = each %{$p{color_table}} ) {

    $perl_formatter->set_format($type, [ qq|<span style="$style">|, 
					 '</span>' ] );
  }
  $self->{HighlightMason} = \%p;
  $self->{HighlightMason}->{out} = '';
}

# Subclass HTML::Mason::compiler.  If it ever stops returning a
# blessed hash, this code is going to be very unhappy.

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->initialize(@_);
  return $self;
}

# All output is collected and returned here.

sub collect_output(@) {
  my $self = shift;
  return $self->{HighlightMason}->{out} unless @_;
  $self->{HighlightMason}->{out} .= join('',@_) if @_;
}

# Sends back collected output wrapped with the preamble and the
# postamble

sub result {
  my $self = shift;
  return join('',
	      $self->{HighlightMason}->{preamble},
	      $self->collect_output(),
	      $self->{HighlightMason}->{postamble}
	      );
}

=item $self->highlight($type,@args)

calls the apropriate callback subroutine set up in C<new()>
above, depending on the type of encoding (perl, html, plain,
mason) to be performed.  Output is collected for later.  You
could also subclass this if you wanted to generate your own
highlighting

=cut

sub highlight {
  my ($self,$type,@rest) = @_;
  $self->collect_output($self->{HighlightMason}->{$type}(@rest));
}

=cut $self->compile($source)

This subclasses the HTML::Mason compiler, and instead of
compiling code suitable for the HTML::Mason::Interp module,
generates colorified HTML text of the code,

=cut

sub compile {
  my ($self,$source) = @_;
  $self->{HighlightMason}->{out} = '';
  $self->lexer->lex( comp_source => $source,
                     name => "Highlight",
                     compiler => $self );
  return $self->result;
}

# See the HTML::Mason::Compiler pod documentation for why these
# methods are defined here, and how they are supposed to behave.

# Let Perl write some code.  This way we get debugging at no runtime cost,
# how cool is that?

my @code_definition =
(
#   name                  args to $self->highlight
  [ "init_block",                 '"perl", $p{block}' ],
  [ "doc_block",                  '"plain", $p{block}' ],
  [ "text_block",                 '"plain", $p{block}'],
  [ "raw_block",                  '"perl", $p{block}' ],
  [ "perl_block",                 '"perl", $p{block}' ],
  [ "start_block",                '"mason", "<%"  . $p{block_type} . ">\n"' ], #" (emacs)
  [ "end_block",                  '"mason", "</%" . $p{block_type} . ">\n"' ],
  [ "start_named_block",          '"mason", "<%"  . $p{block_type} . " " . $p{name} . ">\n"' ],
  [ "end_named_block",            '"mason", "</%" . $p{block_type} . ">\n"' ],
  [ "text",                       '"html",          $p{text}' ],
  [ "component_call",             '"mason", "<&"  . $p{call} . "&>"' ],
  [ "component_content_call",     '"mason", "<&|" . $p{call} . "&>"' ],
  [ "component_content_call_end", '"mason", "</&>"' ],
  [ "key_value_pair",             '"plain", $p{key} . " => " . $p{value} ,"\n"' ]
);

my $code = '';

foreach (@code_definition) {
  my ($name,$type) = @$_;
  $code .= <<'END';
  sub <name> {
  my ($self,%p) = @_;
END
  if ($debug) {
  $code .= <<'END';
  $self->collect_output('<!-- start <name> -->');
  print STDERR "In <name>\n";
  $self->highlight(<type>);
  $self->collect_output('<!-- end <name>  -->');
END
  } else {
    $code .= q{  $self->highlight(<type>);};
  }
  $code .= "}\n";
  $code =~ s/<name>/$name/gs;
  $code =~ s/<type>/$type/gs;
}

# The code generated by the above looks like this if we are
# debugging:

#   sub init_block {
#     my ($self,%p) = @_;
#     $self->collect_output('<!-- start init_block -->');
#     print STDERR "In init_block\n";
#     $self->highlight("perl", $p{block});
#     $self->collect_output('<!-- end init_block  -->');
#   }

# and like this we are are not:

#   sub init_block {
#     my ($self,%p) = @_;
#     $self->highlight("perl", $p{block});
#   }

print STDERR $code if $debug;

eval $code; die $@ if $@;

# There are always exceptions to every rule, and here they are:

sub perl_line {
  print STDERR "In block perl_line\n" if $debug;
  my ($self,%p) = @_;
  my $line = $p{line};
  $line =~ s/^%//;
  $self->collect_output(' %'); # fudge a space in front so Mason is happy
  $self->highlight('perl',"$line\n");
}

sub substitution {
  my ($self,%p) = @_;
  my $content = $p{substitution};
  $content .= " | " . $p{escape} if $p{escape};
  $self->highlight('mason',"<%" . $content . " %>"); # another fudged space
}

# Why did I put that extra space before the % sign?
# Because if the output of this module is fed directly to a Mason app
# it will try to execute those lines beginning with a % as perl code
# which is NOT what I wanted.

sub variable_declaration {
  my ($self,%p) = @_;
  print STDERR "In block variable_declaration\n" if $debug;
  my $text = $p{type} . $p{name};
  $text .= ' => ' . $p{default} if defined $p{default};
  $self->highlight('plain', $text ,"\n");
}

1;

=head1 AUTHOR

Henry Laxen nadine.and.henry@pobox.com

=head1 SEE ALSO

Syntax::Highlight::HTML Syntax::Highlight::Perl::Improved
HTML::Mason

=cut
