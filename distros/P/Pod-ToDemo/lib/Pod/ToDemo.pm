package Pod::ToDemo;
BEGIN {
  $Pod::ToDemo::VERSION = '1.20110709';
}
# ABSTRACT: writes a demo program from a tutorial POD

use strict;
use warnings;

sub import
{
	my ($self, $action) = @_;
	return unless $action;

	my $call_package    = caller();
	my @command         = caller( 3 );

	return if @command and $command[1] ne '-e';

	my $import_sub = defined &$action ?
	                $action : $self->import_default( $action );

	no strict 'refs';
	*{ $call_package . '::' . 'import' } = $import_sub;
}

sub import_default
{
	my ($self, $text) = @_;

	return sub
	{
		my ($self, $filename) = @_;
		Pod::ToDemo::write_demo(
			$filename, "#!$^X\n\nuse strict;\nuse warnings;\n\n$text"
		);
	};
}

sub write_demo
{
	my ($filename, $demo) = @_;
	my $caller_package    = (caller())[0];

	die "Usage:\n\t$0 $caller_package <filename>\n"    unless $filename;
	die "Cowardly refusing to overwrite '$filename'\n" if  -e $filename;

	open( my $out, '>', $filename ) or die "Cannot write '$filename': $!\n";
	print $out $demo;
}

1;
__END__

=head1 NAME

Pod::ToDemo - writes a demo program from a tutorial POD

=head1 SYNOPSIS

  use Pod::ToDemo <<'END_HERE';

  print "Hi, here is my demo program!\n";
  END_HERE

=head1 DESCRIPTION

Pod::ToDemo allows you to write POD-only modules that serve as tutorials which
can write out demo programs if you invoke them directly.  That is, while
L<SDL::Tutorial> is a tutorial on writing beginner SDL applications with Perl,
you can invoke it as:

  $ perl -MSDL::Tutorial=sdl_demo.pl -e 1

and it will write a bare-bones demo program called C<sdl_demo.pl> based on the
tutorial.

=head1 USAGE

You can do things the easy way or the hard way.  I recommend the easy way, but
the hard way has advantages.

=head2 The Easy Way

The easy way is to do exactly as the synopsis suggests.  Pass a string
containing your code as the only argument to the C<use Pod::ToDemo> line.  The
module will write the demo file, when appropriate, and refuse to do anything,
when appropriate.

=head2 The Hard Way

The hard way exists so that you can customize exactly what you write.  This is
useful, for example, if you want to steal the demo file entirely out of your
POD already -- so grab the module's file handle, rewind it as appropriate, and
search through it for your verbatim code.

Call C<Pod::ToDemo::write_demo()> with two arguments.  C<$filename> is the name
of the file to write.  If there's no name, this function will C<die()> with an
error message.  If a file already exists with this name, this function will
also C<die()> with another error message.  The second argument, C<$demo>, is
the text of the demo program to write.

If you're using this in tutorial modules, as you should be, you will probably
want to protect programs that inadvertently use the tutorial from attempting to
write demo files.  Pod::ToDemo does this automatically for you by checking that
you haven't invoked the tutorial module from the command line.

To prevent C<perl> from interpreting the name of the file to write as the name
of a file to invoke (a file which does not yet exist), you must pass the name
of the file on the command line as an argument to the tutorial module's
C<import()> method.  If this doesn't make sense to you, just remember to tell
people to write:

  $ perl -MTutorial::Module=I<file_to_write.pl> -e 1

=head1 FUNCTIONS and METHODS

=over

=item import_default( $program_text )

This is a class method.

Given the test of the demo program to write, returns a subroutine suitable for
writing a demo file.  The subroutine returned takes the current package and the
name of the file to write and writes the file to the filesystem.

The program text does not need to include the C<#!> line, or the use of the
L<strict> and L<warnings> pragmas.

=item write_demo( $filename, $demo_text )

Given the name of a file to write and the test of the demo program, attempts to
write the file.  This will throw an exception that there is no filename if
there is no filename and will throw an exception if you attempt to overwrite an
existing file.  Finally, it will also throw an exception if it cannot write the
file.

=back

=head1 AUTHOR

chromatic, C<< chromatic at wgz dot org >>.

=head1 BUGS

No known bugs, now.  Thanks to Greg Lapore for helping me track down a bug in
0.10 and to Robert Rothenberg for Windows test tweaks.

=head1 COPYRIGHT

Copyright (c) 2003 - 2011, chromatic. Some rights reserved. You may use,
modify, and distribute this module under the same terms as Perl 5.12, in the
hope that it is useful but certainly under no guarantee.
