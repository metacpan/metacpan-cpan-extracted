use 5.008001;
use strict;
use warnings;

package Pry;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003001';

use Exporter::Shiny our @EXPORT = qw(pry);

# cargo-culted Win32 stuff... untested!
#
BEGIN {
	if ($^O eq 'MSWin32') {
		require Term::ANSIColor;
		require Win32::Console::ANSI;
		Win32::Console::ANSI->import;
	}
};

our ($Lexicals, $Trace, $Already);

# a refinement for the Reply class
#
my $_say = sub {
	require Term::ANSIColor;
	shift;
	my ($text, $colour) = (@_, "cyan");
	print Term::ANSIColor::colored($text, "bold $colour"), "\n";
};

our $Dumper = 'Data::Dumper';

my $_display_vars = sub {
	my $invocant = shift;
	my $_dumper  = $Dumper eq 'Data::Dump'
		? do { require Data::Dump;   \&Data::Dump::dump }
		: do { require Data::Dumper; \&Data::Dumper::Dumper };
	
	local $Data::Dumper::Deparse = 1;
	local $Data::Dumper::Terse   = 1;
	
	for my $var (@_)
	{
		my $val  = ($var =~ /\A\$/) ? ${$Lexicals->{$var}} : $Lexicals->{$var};
		my $dump = $_dumper->($val);
		chomp($dump);
		$dump =~ s/(\A\[)/\(/ and $dump =~ s/(\]\z)/\)/ if $var =~ /\A\@/;
		$dump =~ s/(\A\{)/\(/ and $dump =~ s/(\}\z)/\)/ if $var =~ /\A\%/;
		$invocant->$_say("$var = $dump;", "yellow");
	}
};

# shim to pass lexicals to Reply
#
{
	package #hide
		Pry::_Lexicals;
	our @ISA = qw( Reply::Plugin );
	sub lexical_environment { $Lexicals }
	$INC{'Pry/_Lexicals.pm'} = __FILE__;
}

# the guts
#
sub pry (;@)
{
	my ($caller, $file, $line) = caller;
	
	if ( $Already )
	{
		Reply->$_say(
			"Pry is not re-entrant; not prying again at $file line $line",
			"magenta",
		);
		return;
	}
	local $Already = 1;
	
	require Devel::StackTrace;
	require Reply;
	require PadWalker;
	
	$Lexicals = +{
		%{ PadWalker::peek_our(1) },
		%{ PadWalker::peek_my(1) },
	};
	$Trace = Devel::StackTrace->new(
		ignore_package => __PACKAGE__,
		message        => "Prying",
	);
	
	my $repl = Reply->new(
		config  => ".replyrc",
		plugins => [ "/Pry/_Lexicals" ],
	);
	$repl->step("package $caller");
	
	$repl->$_say("Prying at $file line $line", "magenta");
	$repl->$_display_vars(@_) if @_;
	$repl->$_say("Current package:   '$caller'");
	$repl->$_say("Lexicals in scope: @{[ sort keys %$Lexicals ]}");
	$repl->$_say("Ctrl+D to finish prying.", "magenta");
	$repl->run;
	$repl->$_say("Finished prying!", "magenta");
	
	my @return = map($Lexicals->{$_}, @_);
	wantarray ? @return : \@return;
}

# utils
#
sub Lexicals ()  { $Lexicals if $] }
sub Trace    ()  { $Trace    if $] }
sub Dump     (@) { __PACKAGE__->$_display_vars(@_) }

1;

__END__

=pod

=begin trustme

=item pry

=end trustme

=encoding utf-8

=head1 NAME

Pry - intrude on your code

=head1 SYNOPSIS

   use Pry;
   
   ...;
   pry;
   ...;

=head1 DESCRIPTION

Kind of a bit like a debugger, kind of a bit like a REPL.

This module gives you a function called C<pry> that you can drop into
your code anywhere. When Perl executes that line of code, it will stop
and drop you into a REPL. You can use the REPL to inspect any lexical
variables (and even alter them), call functions and methods, and so on.

All the clever stuff is in the REPL. Rather than writing yet another
Perl REPL, Pry uses L<Reply>, which is an awesome yet fairly small REPL
with support for plugins that can do some really useful stuff, such as
auto-complete of function and variable names.

Once you've finished using the REPL, just hit Ctrl+D and your code will
resume execution.

=head2 Functions

=over

=item C<< pry() >>

Starts the Pry REPL.

=item C<< pry(@varnames) >>

Dumps selected variables before starting the Pry REPL.

Note a list of variable I<names> is expected; not I<values>. For
example:

   my $x = 42;
   my @y = (666, 999);
   pry('$x', '@y');

=back

=head3 Utility Functions

The following functions are provided for your convenience. They cannot
be exported, so you should access them, from the REPL, using their
fully-qualified name.

=over

=item C<< Pry::Lexicals >>

Returns a hashref of your lexical variables.

=item C<< Pry::Trace >>

Returns the stack trace as a L<Devel::StackTrace> object.

=item C<< Pry::Dump(@variable_names) >>

Dumps variables (which must exist somewhere in the C<< Pry::Lexicals >>
hashref).

=back

=head2 Package Variable

=over

=item C<< $Pry::Dumper >>

Decides the backend dumper implementation used by C<< Pry::Dump() >>.
Valid values are "Data::Dump" and "Data::Dumper".

=back

=head1 CONFIGURATION

Pry's REPL can be configured in the same way as L<Reply>.

=head1 CAVEATS

I imagine this probably breaks pretty badly in a multi-threaded or
multi-process scenario.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Pry>.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Read–eval–print_loop>,
L<Reply>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

