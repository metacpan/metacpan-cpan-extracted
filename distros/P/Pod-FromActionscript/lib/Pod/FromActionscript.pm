package Pod::FromActionscript;

use strict;
use warnings;
use Exporter;
use Carp;

our $VERSION = "0.53";
our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw(asdoc2pod);

# Use Regexp::Common if available, but fall back to an extract from
# v2.120 if needed
our $comment_re =
    eval("local \$SIG{__WARN__} = 'DEFAULT'; local \$SIG{__DIE__} = 'DEFAULT';".
         "use Regexp::Common qw(comment); \$RE{comment}{C}")
    || qr/(?:(?:\/\*)(?:(?:[^\*]+|\*(?!\/))*)(?:\*\/))/;

=head1 NAME

Pod::FromActionscript - Convert Actionscript documentation to POD

=head1 SYNOPSIS

    use Pod::FromActionscript (asdoc2pod);
    asdoc2pod(infile => "com/clotho/Foo.as", outfile => "com.clotho.Foo.pod");
    asdoc2pod(infile => "-" outfile => "-");
    asdoc2pod(infile => \*STDIN, outfile => \*STDOUT);
    asdoc2pod(in => $ascontent, out => \$podcontent);

or use the C<asdoc2pod> command-line program included in this
distribution.

=head1 DESCRIPTION

Parse Actionscript code, searching for Javadoc-style
comments.  If any are found, convert them to POD (Perl's Plain Old
Documentation format).  The output is just the POD, unless the
C<code> flag is used, in which case the original Actionscript is
output with the Javadoc converted to POD.

Only a limited subset of Javadoc commands are understood.  See below
for the full list. Any unrecognized directives cause parsing to abort.
Future versions of this module should handle such failures more
gracefully.

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=over

=item asdoc2pod OPTIONS...

Convert Javadoc-style comments embedded in Actionscript code into POD.
The arguments are key-value pairs as follows:

=over

=item in => SCALAR

The input Actionscript code as a string.

=item infile => FILENAME

=item infile => FILEHANDLE

Read the Actionscript code from a file.  If the value is a reference,
it is assumed to be a filehandle.  If it is a scalar, it is assumed to
be a filename.  If the filename is C<->, then code is read in from
C<STDIN>.

=item out => SCALARREF

The output POD, or an empty string if no Javadoc is detected, is
assigned to the specified scalar reference.

=item outfile => FILENAME

=item outfile => FILEHANDLE

Write the POD to a file.  If there is no POD found, the no data is
written.  If the C<outfile> value is a reference, it is assumed to be a
filehandle.  If it is a scalar, it is assumed to be a filename.  If
the filename is C<->, then POD is written to C<STDOUT>.

=item verbose => BOOLEAN

If true, some debugging information is printed.  Defaults to false.

=item code => BOOLEAN

If true, then the Actionscript code is included in the output, with
the Javadoc comments replace with appropriate POD comments.  If false,
then just the POD is output, with the code omitted.  Defaults to false.

=back

=cut

sub asdoc2pod
{
   my %opts = @_;

   my $in = _get_input(\%opts);
   my $out = _convert($in, \%opts);
   _write_output($out, \%opts);
}

sub _get_input
{
   my $opts = shift;

   my $in;
   if (exists $opts->{in})
   {
      $in = $opts->{in};
   }
   elsif (exists $opts->{infile})
   {
      local $/ = undef;
      if (ref $opts->{infile})
      {
         my $infh = $opts->{infile};
         $in = <$infh>;
      }
      elsif ($opts->{infile} eq "-")
      {
         $in = <STDIN>;
      }
      else
      {
         local *IN;
         open(IN, '<', $opts->{infile})
             or croak("Failed to read file $opts->{infile}: $!\n");
         $in = <IN>;
         close(IN);
      }
   }
   else
   {
      croak("No input source specified\n");
   }
   return $in;
}

sub _write_output
{
   my $out = shift;
   my $opts = shift;

   if (exists $opts->{out})
   {
      if (ref $opts->{out})
      {
         my $var = $opts->{out};
         $$var = $out;
      }
      else
      {
         croak("The out parameter is not a reference\n");
      }
   }
   elsif ($out eq "")
   {
      # No output
   }
   elsif (exists $opts->{outfile})
   {
      if (ref $opts->{outfile})
      {
         my $of = $opts->{outfile};
         print $of $out;
      }
      elsif ($opts->{outfile} eq "-")
      {
         print STDOUT $out;
      }
      else
      {
         local *OUT;
         open(OUT, '>', $opts->{outfile})
             or croak("Failed to write file $opts->{outfile}: $!\n");
         print(OUT $out)
             or croak("Failed to write file $opts->{outfile}: $!\n");
         close(OUT)
             or croak("Failed to write file $opts->{outfile}: $!\n");
      }
   }
   else
   {
      croak("No output destination specified\n");
   }
}

sub _convert
{
   my $content = shift;
   my $opts = shift;

   if (!$opts->{code} && $content !~ /\/\*\*/)
   {
      # No javadoc included...
      return "";
   }

   my @out;
   my @parts = split /($comment_re)/, $content;
   #_diag($opts, "Got ".@parts." parts in ".length($content)." characters\n");

   my $over = 0;
   my $inapi = 0;
   foreach my $i (0..$#parts)
   {
      if ($i < $#parts && $parts[$i] =~ /^\/\*\*/)
      {
         # exclude comments like /** foo **/
         next if ($parts[$i] =~ /^\/\*\*+[^\n\*]*\*+\//);
         
         my $comment = $parts[$i];
         
         # Remove comment open and close
         $comment =~ s/^\/\*\s*//;
         $comment =~ s/\s*\*\/$//;
         
         # Unindent the comment lines
         $comment =~ s/^\s*\*[ \t]?//gm;
         
         # Convert {@code foobar} to C<foobar>
         $comment =~ s/\{\@code\s+([^\}]+)\}/C<$1>/gs;
         
         
         if ($parts[$i+1] &&
             $parts[$i+1] =~ /^\s*(?:class|interface)\s+([^\s;]+)/)
         {
            my $class = $1;
            _diag($opts, "Class: $class\n");
            
            my $descrip = "";
            my $name = _get_name(\$comment);
            my $license = _get_license(\$comment);
            my $author = _get_author(\$comment);
            my $sees = _get_sees(\$comment);
            if ($comment =~ /\S/)
            {
               $descrip = "=head1 DESCRIPTION\n\n$comment\n\n";
            }
            $comment = "$name$descrip$sees$license$author";
            
            $inapi = 0;
         }
         elsif ($parts[$i+1] && 
                $parts[$i+1] =~ /^\s*((?:public|private)\s+|)(static\s+|)function\s+(\w+)\s*\(([^\)]*)\)(:\w+|)/)
         {
            my $private = $1;
            my $static = $2;
            my $fname = $3;
            my $args = $4;
            my $ftype = $5;
            $private = $private =~ /private/;
            $static = $static =~ /static/;
            
            if (!$inapi)
            {
               $inapi = 1;
               $parts[$i-1] .= "/*\n\n=head1 API\n\n=cut\n*/\n";
               push @out, "=head1 API\n\n";
            }
            if (!$over)
            {
               $over++;
               $parts[$i-1] .= "/*\n\n=over\n\n=cut\n*/\n";
               push @out, "=over\n\n";
            }
            
            _diag($opts, "Function: ".($private?"private ":"").($static?"static ":"")."function $fname($args)$ftype\n");
            
            my ($paramlist, $params) = _get_params(\$comment); 
            my $returns = _get_returns(\$comment); 
            my $sees = _get_sees(\$comment); 
            
            $comment = "=item $fname$paramlist\n\n$params$comment\n\n$returns$sees";
         }
         elsif ($parts[$i+1] && 
                $parts[$i+1] =~ /^\s*((?:public|private)\s+|)(static\s+|)var\s+(\w+)(:\w+|)(\s*=\s*[^;]+|)/)
         {
            my $private = $1;
            my $static = $2;
            my $vname = $3;
            my $vtype = $4;
            my $default = $5;
            $private = $private =~ /private/;
            $static = $static =~ /static/;
            
            $default =~ s/^\s*=\s*//;
            if ($default ne "")
            {
               $default = "B<Default value:> $default\n\n";
            }
            
            if (!$inapi)
            {
               $inapi = 1;
               $parts[$i-1] .= "/*\n\n=head1 API\n\n=cut\n*/\n";
               push @out, "=head1 API\n\n";
            }
            if (!$over)
            {
               $over++;
               $parts[$i-1] .= "/*\n\n=over\n\n=cut\n*/\n";
               push @out, "=over\n\n";
            }
            
            _diag($opts, "Var: ".($private?"private ":"").($static?"static ":"")."var $vname$vtype\n");
            
            my ($paramlist, $params) = _get_params(\$comment); 
            my $returns = _get_returns(\$comment); 
            my $sees = _get_sees(\$comment); 
            
            $comment = "=item $vname$paramlist\n\n$params$comment\n\n$default$returns$sees";
         }
         else
         {
            carp("Unhandled comment type\n");
         }
         
         if ($comment =~ /^=/)
         {
            $comment =~ s/\n\n\n+/\n\n/gs;
            $parts[$i] = "/*\n\n$comment=cut\n*/";
            push @out, $comment;
         }
         
         if ($parts[$i] =~ /^\s*(\@\w*)/m)
         {
            #carp("Unhandled $1 in \n$comment\n");
            carp("Unhandled $1\n");
         }
      }
   }
   if ($over > 0)
   {
      push @parts, "/*\n\n";
      for (1..$over)
      {
         push @parts, "=back\n\n";
         push @out, "=back\n\n";
      }
      push @parts, "=cut\n*/\n";
   }
   
   if (!$opts->{code} && @out == 0)
   {
      # No POD to emit
      return "";
   }
   return join("", $opts->{code} ? @parts : @out);
}

###############################################

# Extracts @param tags from comments
sub _get_params
{
   my $R_comment = shift;

   my $paramlist = "";
   my $params = "";
   while ($$R_comment =~ s/\n?[ \t]*\@param[ \t]+(\w+)(?:[ \t]*:)?[ \t]+([^\n]+)(?:\n|$)/\n/s)
   {
      my $pname = $1;
      my $pdesc = $2;
      $paramlist .= ($paramlist ? "," : "") . " $pname";
      #$params .= "=item $pname\n\n$pdesc\n\n";
      $params .= "B<$pname>: $pdesc\n\n";
   }
   #if ($params)
   #{
   #   $params = "B<Parameters:>\n\n=over\n\n" . $params . "=back\n\n";
   #}
   return ($paramlist, $params);
}

# Extracts @returns tags from comments
sub _get_returns
{
   my $R_comment = shift;

   my $returns = "";
   while ($$R_comment =~ s/\n?[ \t]*\@returns?[ \t]+([^\n]+)(?:\n|$)/\n/s)
   {
      my $rdesc = $1;
      $returns .= "B<Returns:> $rdesc\n\n";
   }
   return $returns;
}

# Extracts @see tags from comments
sub _get_sees
{
   my $R_comment = shift;

   my $sees = "";
   while ($$R_comment =~ s/\n?[ \t]*\@see[ \t]+([^\n]+)(?:\n|$)/\n/s)
   {
      my $sdesc = $1;
      $sees .= "B<See Also:> $sdesc\n\n";
   }
   return $sees;
}

# Extracts @author tags from comments
sub _get_author
{
   my $R_comment = shift;

   my $author = "";
   while ($$R_comment =~ s/\n?[ \t]*\@author[ \t]+([^\n]+)(?:\n|$)/\n/s)
   {
      my $adesc = $1;
      $author .= "=head1 AUTHOR\n\n$adesc\n\n";
   }
   return $author;
}

# Extracts @license tags from comments
sub _get_license
{
   my $R_comment = shift;

   my $license = "";
   while ($$R_comment =~ s/\n?[ \t]*\@license[ \t]*(.*?)(\n[ \t]*\@|$)/$2/s)
   {
      my $adesc = $1;
      $license .= "=head1 LICENSE\n\n$adesc\n\n";
   }
   return $license;
}

# Extracts =head1 NAME from comments
sub _get_name
{
   my $R_comment = shift;

   my $name = "";
   if ($$R_comment =~ s/^\n*([\w\.]+)[ \t]+\-[ \t]+([^\n]+)(?:\n+|$)//s)
   {
      my $title = $1;
      my $desc = $2;
      $name = "=head1 NAME\n\n$title - $desc\n\n";
   }
   return $name;
}

sub _diag
{
   my $opts = shift;
   my $msg = shift;

   warn $msg if ($opts->{verbose});
}

1;

__END__

=back

=head1 SEE ALSO

JavaDoc-style Actionscript documentation (sometimes called ASDoc)
derives from Sun's JavaDoc system.  The official JavaDoc page:
L<http://java.sun.com/j2se/javadoc/>

Here are some actively-developed non-Perl tools that can also render
Actionscript comments.  None of these do POD, but that's not always a
drawback.

=over

=item VisDoc

Commercial, Mac OSX only.  This one makes very pretty HTML output.

L<http://visiblearea.com/visdoc/>

=item as2api

Ruby, GPL (I think), cross-platform, fairly well documented.  The URL below contains links to a lot of other parsers.

L<http://www.badgers-in-foil.co.uk/projects/as2api/>

=item AS2Doc

Commercial, Windows-only.  I haven't tried it.

L<http://www.as2doc.com/>

=item AS2Docular

Free, web-based, in development (will be released "soon"), HTML
output only.  Supports Dreamweaver template syntax.

L<http://www.senocular.com/projects/AS2Docular/help.php>

=item ACID

Python, Windows only, no license specified, HTML output.  The
code is uncommented and nearly unintelligible.

L<http://icube.freezope.org/acid>

=back

=head1 COMPATIBILITY

Here is a list of all of the POD/Javadoc directives that are
understood.  I distinguish between one line directives (terminated by
a new line) and block directives (terminated by the end of the comment
or the start of a new directive.

=over

=item NAME

This is a POD-specific, one-line heuristic.  If the first line of the
comment above the class/interface declaration has a pattern like
C<E<lt>wordE<gt> - E<lt>wordsE<gt>> then it becomes a C<=head1 NAME> block.

=item DESCRIPTION

This is a POD-specific, block heuristic.  After all other ASDoc
directives have been parsed out of the comment above a class/interface
declaration, all remaining text is put in a C<=head1 DESCRIPTION>
block.

=item API

This is a POD-specific heuristic.  A C<=head1 API> block is started
just before the first function declaration.

=item FUNCTION

This is a POD-specific, block heuristic.  Each comment above a
function declaration becomes an C<=item> block.  After all ASDoc is
parsed from the comment, the remainder is added as prose below the
C<=item>.

=item PROPERTY

This is a POD-specific, block heuristic.  Each comment above a
property declaration becomes an C<=item> block.  After all ASDoc is
parsed from the comment, the remainder is added as prose below the
C<=item>.

Because a property may be a pointer to a function, all function
declaration directives are also valid in property declarations.

=item PROPERTY DEFAULT VALUE

This is a heuristic that adds a C<Default value:> comment above a
class or instance property that has an intial value set.

=item @author

This one-line directive becomes a C<=head1 AUTHOR> block.  It can only appear in a block just
above the class/interface declaration.

=item @license

This block directive becomes a C<=head1 LICENSE> block.  It can only appear in a block just
above the class/interface declaration.

=item @see

This one-line directive becomes a C<=head1 SEE ALSO> block.  It can
appear above a class/interface declaration, a function declaration or
a property declaration.

TODO: Add LE<lt>E<gt> tags around links.

=item @param

Every one-line @param directive above a function declaration becomes
an argument entry in the function comment just above any prose comments.

=item @returns

A one-line @returns directive above a function declaration becomes
a line in the function comment just below any prose comments.

=item {@code ...}

This delimited block can appear anywhere.  It is converted to a
C<CE<lt>...E<gt>> block.

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
