
require 5;
package Pod::Simple::LaTeX;

#use utf8;

#sub DEBUG () {4};
#sub Pod::Simple::DEBUG () {4};
#sub Pod::Simple::PullParser::DEBUG () {4};

use strict;
use vars qw($VERSION @ISA %Escape $WRAP %Tagmap);
$VERSION = '0.06';
use Pod::Simple::PullParser ();
BEGIN {@ISA = ('Pod::Simple::PullParser')}

use Carp ();
BEGIN { *DEBUG = \&Pod::Simple::DEBUG unless defined &DEBUG }

$WRAP = 1 unless defined $WRAP;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new {
  my $new = shift->SUPER::new(@_);
  $new->nix_X_codes(1);
  $new->nbsp_for_S(1);
  $new->accept_targets( qw( tex TeX TEX latex LaTeX LATEX ) );

#  $new->{'Tagmap'} = {%Tagmap};

#  $new->accept_codes(@_to_accept);
#  $new->accept_codes('VerbatimFormatted');
#  DEBUG > 2 and print "To accept: ", join(' ',@_to_accept), "\n";

  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub run {
  my $self = $_[0];
  return $self->do_middle if $self->bare_output;
  return
    $self->do_beginning && $self->do_middle && $self->do_end;
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub accent {
  my $str_ref = shift;
  my %latin_1 = (
    "\xa0" => '~',		#(no-break space)
    "\xa1" => '!`',

    "\xa3" => q(\pounds{}),

    "\xa7" => q(\S{}),

    "\xa9" => q(\copyright{}),

    "\xac" => '\neg',

    "\xb1" => q($\pm$),

    "\xb4" => q($\prime$),
    "\xb5" => q($\mu$),
    "\xb6" => q(\P{}),
    "\xb7" => q($\cdot{}$),

    "\xbf" => '?`',
    "\xc0" => q(\`A),
    "\xc1" => q(\'A),
    "\xc2" => q(\^A),
    "\xc3" => q(\~A),
    "\xc4" => q(\"A),
    "\xc5" => q(\AA{}),
    "\xc6" => q(\AE{}),
    "\xc7" => q(\cC),
    "\xc8" => q(\`E),
    "\xc9" => q(\'E),
    "\xca" => q(\^E),
    "\xcb" => q(\"E),
    "\xcc" => q(\`I),
    "\xcd" => q(\'I),
    "\xce" => q(\^I),
    "\xcf" => q(\"I),
   #"\xd0" => q(\Dh), # Requires wasysym package
    "\xd1" => q(\~N),
    "\xd2" => q(\`O),
    "\xd3" => q(\'O),
    "\xd4" => q(\^O),
    "\xd5" => q(\~O),
    "\xd6" => q(\"O),
    "\xd7" => q(\times{}),
    "\xd8" => q(\O{}),
    "\xd9" => q(\`U),
    "\xda" => q(\'U),
    "\xdb" => q(\^U),
    "\xdc" => q(\"U),
    "\xdd" => q(\'Y),
   #"\xde" => q(\thorn), # Requires wasysym package
    "\xdf" => q(\ss{}),
    "\xe0" => q(\`a),
    "\xe1" => q(\'a),
    "\xe2" => q(\^a),
    "\xe3" => q(\~a),
    "\xe4" => q(\"a),
    "\xe5" => q(\aa{}),
    "\xe6" => q(\ae{}),
    "\xe7" => q(\cc{}),
    "\xe8" => q(\`e),
    "\xe9" => q(\'e),
    "\xea" => q(\^e),
    "\xeb" => q(\"e),
    "\xec" => q(\`{\i}),
    "\xed" => q(\'{\i}),
    "\xee" => q(\^{\i}),
    "\xef" => q(\"{\i}),
   #"\xf0" => q(\dh), # Requires wasysym package
    "\xf1" => q(\~n),
    "\xf2" => q(\`o),
    "\xf3" => q(\'o),
    "\xf4" => q(\^o),
    "\xf5" => q(\~o),
    "\xf6" => q(\"o),
    "\xf7" => q(\div{}),
    "\xf8" => q(\o{}),
    "\xf9" => q(\`u),
    "\xfa" => q(\'u),
    "\xfb" => q(\^u),
    "\xfc" => q(\"u),
    "\xfd" => q(\'y),
   #"\xfe" => q(\thorn), # Requires wasysym package
    "\xff" => q(\"y),
  );

  $$str_ref =~ s/$_/$latin_1{$_}/eg for keys %latin_1;
#$$str_ref =~ s{\\(\d)}{"FIXME XXX $1\$"}eg; # XXX Aiyee, s/// escaping and $ madness ensues
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub do_middle {      # the main work
  my $self = $_[0];
  my $fh = $self->{'output_fh'};
  
  $self->{in_section} ||= 0; # Note when entering/leaving section

  my %default_tags = (
    B => [ "\\textbf{","}\n" ],
    Data => [ "\n","\n" ],
    Document => [ "\\begin{document}\n","\\end{document}\n" ],
    F => [ "\\textsl{","}\n" ],
    I => [ "\\textsl{","}\n" ],
    Para => [ "\n\n","\n\n" ],
    L => [ "\\textsl{","}\n" ],
    Verbatim => [ "\\begin{verbatim}\n","\\end{verbatim}\n" ],
    VerbatimFormatted => [ "\\begin{verbatim}\n","\\end{verbatim}\n" ],
    VerbatimI => [ "\\begin{verbatim}\\textsl{","}\\end{verbatim}" ],
    VerbatimB => [ "\\begin{verbatim}\\textbf{","}\\end{verbatim}" ],
    VerbatimBI => [ "\\begin{verbatim}\\textsl{\\textbf{","}}\\end{verbatim}" ],

    head1 => [ "\\section{","}\n" ],
    head2 => [ "\\subsection{","}\n" ],
    head3 => [ "\\subsubsection{","}\n" ],
    head4 => [ "\\paragraph{","}\n" ],
    head5 => [ "\\subparagraph{","}\n" ],

   'item-block' => [ '','' ],
   'item-bullet' => [ "\\item{}\n",'' ],
   'item-number' => [ "\\item{}\n",'' ],
   'item-text' => [ "\\item{}\n",'' ],

   'over-block' => [ "\\begin{verbatim}\n","\\end{verbatim}" ],
   'over-bullet' => [ "\\begin{itemize}\n","\\end{itemize}\n" ],
   'over-number' => [ "\\begin{enumerate}\n","\\end{enumerate}\n" ],
   'over-text' => [ "\\begin{itemize}\n","\\end{itemize}\n" ],
  );

  while (my $token = $self->get_token) {
    my $type = $token->type;
    if($type eq 'start') {
      my $name = $token->tagname;
      DEBUG > 1 and print "+$type <", $token->tagname,
        "> ( ", map("<$_> ", %{$token->attr_hash}), ")\n";
      print $fh $default_tags{$name}[0] if exists $default_tags{$name};

      $self->{in_section}++ if $name =~ /^head/;
      $self->{verbatim}++ if $name =~/^Verbatim/;
      $self->{in_c}++ if $name eq 'C' or $name eq 'F';
      if($name eq 'C' or $name eq 'F') {
        if($self->{in_section} > 0) {
          print $fh "\\texttt{" # Just use \textsl{} inside \section{} et al
        }
        else {
          $self->{verbatim}++;
          print $fh "\\texttt{" # Just use \textsl{} inside \section{} et al
        }
      }
    }
    elsif($type eq 'end') {
      my $name = $token->tagname;
      DEBUG > 1 and print "-$type <", $token->tagname, ">\n";
      print $fh $default_tags{$name}[1] if exists $default_tags{$name};

      $self->{in_section}-- if $name =~ /^head/;
      $self->{verbatim}-- if $name =~/^Verbatim/;
      $self->{in_c}-- if $name eq 'C' or $name eq 'F';
      if($name eq 'C' or $name eq 'F') {
        if($self->{in_section} > 0) {
          print $fh "}\n" # Just use \textsl{} inside \section{} et al
        }
        else {
          $self->{verbatim}--;
          print $fh "}\n" # Skip verbatim inside \section{}
        }
      }
    }
    elsif($type eq 'text') {
      my $text = $token->text;
      DEBUG > 1 and print "=$type <$text>\n";

      $self->{in_section} > 0 and do { print $fh texesc($text); next };
      $self->{in_c} > 0 and do { print $fh texesc($text); next };
      if($self->{verbatim} > 0) {
        print $fh $text;
      }
      else {
        print $fh texesc($text);
      }
    }
    else {
die "Unknown tag type <$type> encountered!\n";
    }
  }
  return 1;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub do_beginning {
  my $self = $_[0];
  my $fh = $self->{'output_fh'};
  return print $fh join '',
    $self->doc_init,
    $self->doc_info,
    $self->doc_start,
    "\n"
  ;
}

sub do_end {
  my $self = $_[0];
  my $fh = $self->{'output_fh'};
}

###########################################################################
# Override these as necessary for further customization


sub doc_init {
   return <<'END';
\documentclass{article}
%\usepackage{alltt}

END
}

sub doc_info {
   my $self = $_[0];

   my $class = ref($self) || $self;

   my $tag = __PACKAGE__ . ' ' . $VERSION;
   
   unless($class eq __PACKAGE__) {
     $tag = " ($tag)";
     $tag = " v" . $self->VERSION . $tag   if   defined $self->VERSION;
     $tag = $class . $tag;
   }

   return sprintf "%% %s using %s v%s under Perl v%s at %s GMT\n",
    $tag, 
    $ISA[0], $ISA[0]->VERSION(),
    $], scalar(gmtime),
  ;
}

sub doc_start {
  my $self = $_[0];
  my $title = $self->get_short_title();
  DEBUG and print "Short Title: <$title>\n";
  $title .= ' ' if length $title;
  
  $title =~ s/ *$/ /s;
  $title =~ s/^ //s;
  $title =~ s/ $//s;

  DEBUG and print "Title0: <$title>\n";
  $title = texesc($title);
  DEBUG and print "Title1: <$title>\n";

  return '';
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#-------------------------------------------------------------------------

use integer;
my $escaperange;
sub texesc {
  if(!defined wantarray) { # alter in place! -- just leave @_
  } elsif(wantarray) { # return an array
    @_ = map "$_", @_;
  } else { # return a single scalar
    @_ = (join '', @_);
  }
  
  unless($escaperange) {
    $escaperange =
      join '', '([',
               '\\\\', grep( not($_ eq '.' or $_ eq '//'), keys %Escape ),
               '])';
    $Escape{'\\\\'} = '\\\\';
    $escaperange = qr/$escaperange/;
  }
  for(@_) { s/$escaperange/$Escape{$1}/g }
  for(@_) { accent(\$_); }

  return $_[0] unless wantarray;
  return @_;
}

%Escape = ( # Backslashes have to be taken care of specially
  '\#' => '\\#',
  '%' => '\%', # LaTeX comments
  '<' => '\textless{}',
  '>' => '\textgreater{}',
#  '~' => '\textasciitilde{}',
  '{' => '\{',
  '}' => '\}',
  '&' => '\&',
  '$' => '\$', # Math-mode
  '^' => '\^{}', # Math-mode superscript
  '_' => '\_', # Math-mode subscript
#  "\cm"  => "\n", # Newlines
#  "\cj"  => "\n",
);

1;

__END__

=head1 NAME

Pod::Simple::LaTeX -- format Pod as LaTeX

=head1 SYNOPSIS

  perl -MPod::Simple::LaTeX -e \
   "exit Pod::Simple::LaTeX->filter(shift)->any_errata_seen" \
   thingy.pod > thingy.tex

=head1 DESCRIPTION

This class is a formatter that takes Pod and renders it as LaTeX.

If you are particularly interested in customizing this module's output
even more, see the source and/or write to me.

=head1 SEE ALSO

L<Pod::Simple>

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2003 TODO-AUTHNAME.  All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

TODO-AUTHNAME+addr

=cut

