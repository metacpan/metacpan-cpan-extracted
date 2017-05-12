#------------------------------------------------------------------------------
# Preproc::Tiny - Minimal stand-alone preprocessor for code generation using perl
# Copyright (C) 2016 by Paulo Custodio
#------------------------------------------------------------------------------

package Preproc::Tiny;

use 5.010;
use strict;
use warnings;
use File::Basename;

require Exporter;

our @ISA = qw( Exporter );
our @EXPORT = qw( pp );
our $VERSION = '0.02';

#------------------------------------------------------------------------------
# Code borrowed from Data::Dump
#------------------------------------------------------------------------------
my %esc = (
    "\a" => "\\a",
    "\b" => "\\b",
    "\t" => "\\t",
    "\n" => "\\n",
    "\f" => "\\f",
    "\r" => "\\r",
    "\e" => "\\e",
);

sub quote {
	local($_) = $_[0];
	# If there are many '"' we might want to use qq() instead
	s/([\\\"\@\$])/\\$1/g;
	return qq("$_") unless /[^\040-\176]/;  # fast exit

	s/([\a\b\t\n\f\r\e])/$esc{$1}/g;

	# no need for 3 digits in escape for these
	s/([\0-\037])(?!\d)/sprintf('\\%o',ord($1))/eg;

	s/([\0-\037\177-\377])/sprintf('\\x%02X',ord($1))/eg;
	s/([^\040-\176])/sprintf('\\x{%X}',ord($1))/eg;

	return qq("$_");
}

#------------------------------------------------------------------------------
# Path::Tiny spew and slurp
#------------------------------------------------------------------------------
sub spew {
	my($file, $text) = @_;
	open(my $fh, '>', $file) 
		or die "Cannot write file $file: $!\n";
	print $fh $text;
}

sub slurp {
	my($file) = @_;
	open(my $fh, '<', $file) 
		or die "Cannot read file $file: $!\n";
	local $/ = undef;
	my $text = <$fh>;
	close($fh);
	return $text;
}

#------------------------------------------------------------------------------
# pp(), the only export
#------------------------------------------------------------------------------
sub pp {
	for my $infile (@_) {
		(my $outfile = $infile) =~ s/\.pp$//i 
			or die "Error: input file needs .pp extension\n";
		my $plfile = "$outfile.pl";

		# build code to pre-process
		my $pl = 'my $OUT = "";'."\n";

		local $_ = slurp($infile);
		while (! at_end($_) ) {
			if (/\G (?| ^ \@\@ (.*) \n? 
			          |   \@\@ (.*) 
					) /gcxim) {
				$pl .= $1."\n";
			}
			elsif (/\G \[\@> \s* (.*?)  (?: -\@\] \s* | \@\] ) /gcxis) {
				$pl .= '$OUT .= '.$1.";\n";
			}
			elsif (/\G \[\@  \s* (.*?)  (?: -\@\] \s* | \@\] ) /gcxis) {
				$pl .= $1.";\n";
			}
			elsif (/ ( [^\[\@]+ ) /gcxi) {
				$pl .= '$OUT .= '.quote($1).";\n";
			}
			else {
				die "$infile: parse error at ".quote(substr($_, pos($_)||0, 100))."\n";
			}
		}
		
		# build code to generate output file
		$pl .=  'open(my $fh, ">", '.quote($outfile).') or die $!;'."\n".
				'print $fh $OUT;'."\n".
				"1;\n";

		# run template
		spew($plfile, $pl);
		system($^X, $plfile)==0 or die "$infile: parse error\n";
		
		# delete temp file
		unlink $plfile;
	}
}

sub at_end {
	return (pos($_[0])||0) >= length($_[0]);
}

#------------------------------------------------------------------------------
# Run if called as a script
#------------------------------------------------------------------------------
unless (caller) {
	@ARGV or die "Usage: ",basename($0)," file.pp...\n";
	pp(@ARGV);
}

1;
__END__

=head1 NAME

Preproc::Tiny - Minimal stand-alone preprocessor for code generation using perl

=head1 SYNOPSIS

   # in perl
   use Preproc::Tiny;
   pp("main.c.pp");
   
   # in the shell
   $ pp.pl main.c.pp

=head1 DESCRIPTION

This preprocessor originated from the need to generate C++ code
in a flexible way and without having to adapt to limitations of
the several mini-languages of other templating engines available
in CPAN. The template language used is just perl.

Being a Tiny module, it has no external dependencies and can be
used by just copying the pp.pl file to any executable directory.

The input file has to have a .pp extension. The .pp is removed to generate 
the output file, e.g.

   $ pp.pl main.c.pp   # parses main.c.pp and generates main.c

Inside the input file, the default action is to copy plain text to the 
output file, e.g.

   // main.c.pp:
   int main() { return 0; }
   
   // main.c:
   int main() { return 0; }

Any text after '@@' is interpreted as perl code and executed. The 
global variable $OUT contains the text to be dumped to the output file, e.g.

   // main.c.pp:
   @@ $ret = 0;
   int main() { 
      return @@ $OUT .= $ret.";";
   }
  
   // main.c:
   int main() { 
      return 0;
   }

Perl code can also be interpolated inside the text and span multiple lines
by enclosing it between '[@' and '@]', e.g.

   // main.c.pp:
   [@ 
      use strict;
      use warnings;
      my $ret = 0;
   @]
   int main() { 
      return [@ $OUT .= $ret @];
   }
   
   // main.c:
   
   int main() { 
      return 0;
   }

The extra newline after the closing quote can be removed by using '-@]', e.g.

   // main.c.pp:
   [@ 
      use strict;
      use warnings;
      my $ret = 0;
   -@]
   int main() { 
      return [@ $OUT .= $ret @];
   }
   
   // main.c:
   int main() { 
      return 0;
   }

The common case of appending text in the perl section has the shortcut '[@>', e.g.

   // main.c.pp:
   [@ 
      use strict;
      use warnings;
      my $ret = 0;
   -@]
   int main() { 
      return [@> $ret @];
   }
   
   // main.c:
   int main() { 
      return 0;
   }

Global actions can be executed by manipulating the $OUT variable, e.g.

   // main.c.pp:
   int main() {
      return 0;  // comment
   }
   @@ $OUT =~ s!//.*!!g;
   
   // main.c:
   int main() {
      return 0;
   }

Any perl control structure can be used in the code blocks, e.g.

   // main.c.pp:
   @@ $ok = 1;
   int main() {
      return [@ if ($ok) { @] 0 [@ } else { @] 1 [@ } @];
   }
   
   // main.c:
   int main() {
      return  0 ;
   }

=head2 EXPORTS

=over 4

=item pp

Input argument is the list of the input file names; runs the preprocessor 
for each input and generates the corresponding output file.

=back

=head2 INTERNALS

The module works by transforming the input file into a perl script and 
executing it. At the end the perl script is removed.

If there is any error in the input that causes a compile error in the script, 
the module dies and does not remove the script. This allows the error
to be investigated, e.g.

   // main.c.pp
   @@ ok=1

causes the error:

   Can't modify constant item in scalar assignment at main.c.pl line N

The file main.c.pl is kept for investigating the error.

=head1 SEE ALSO

L<Template> toolkit from CPAN as a full-fledged templating system.

=head1 AUTHOR

Paulo Custodio, E<lt>pscust@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Paulo Custodio

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
