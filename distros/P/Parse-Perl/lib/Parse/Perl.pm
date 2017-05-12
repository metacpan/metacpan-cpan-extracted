=head1 NAME

Parse::Perl - interpret string as Perl source

=head1 SYNOPSIS

	use Parse::Perl qw(current_environment);

	$env = current_environment;

	use Parse::Perl qw(parse_perl);

	$func = parse_perl($env, '$foo + 3');

=head1 DESCRIPTION

This module provides the capability to parse a string at runtime as Perl
source code, so that the resulting compiled code can be later executed.
This is part of the job of the string form of the C<eval> operator,
but in this module it is separated out from the other jobs of C<eval>.
Parsing of Perl code is generally influenced by its lexical context,
and this module provides some explicit control over this process, by
reifying lexical environments as Perl objects.

Perl's built-in C<eval> operator (in string form) actually performs four
distinct jobs: capture lexical environment, parse Perl source, execute
code, and catch exceptions.  This module allows each of these four jobs
to be performed separately, so they can then be combined in ways that
C<eval> doesn't permit.  Capturing lexical environment is performed
using a special operator supplied by this module.  Parsing Perl source
is performed by a function supplied by this module.  Executing code is
adequately handled by Perl's native mechanisms for calling functions
through references.  Finally, exception catching is handled by the block
form of C<eval>.

=cut

package Parse::Perl;

{ use 5.008004; }
use warnings;
use strict;

use Devel::CallChecker 0.003 ();

our $VERSION = "0.007";

use parent "Exporter";
our @EXPORT_OK = qw(current_environment parse_perl);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

{
	package Parse::Perl::CopHintsHash;
	our $VERSION = "0.007";
}

{
	package Parse::Perl::Environment;
	our $VERSION = "0.007";
}

=head1 OPERATORS

=over

=item current_environment

This operator generates a L<Parse::Perl::Environment> object which
encapsulates the lexical environment at the site where the operator
is used.  It evaluates to a reference to the environment object.
The environment object encapsulates the lexical variables that are
available at this site, the lexical warning status, and the effects of
all other lexical pragmata.

This operator captures I<all> the lexical variables that are visible
at the point where it is used.  This can result in surprisingly long
lifetimes for variables in enclosing scopes.  This aspect of this operator
is unlike C<eval>, which only captures those variables that are referenced
in the directly enclosing function, leading to "Variable not available"
warnings.

This operator should be used through bareword function call syntax, as if
it were a function.  However, it cannot otherwise be called as a function
in the normal manner.  Attempting to take a reference to it will result
in a code reference that does not have any of the behaviour described.

=back

=head1 FUNCTIONS

=over

=item parse_perl(ENVIRONMENT, SOURCE)

I<ENVIRONMENT> must be a reference to a L<Parse::Perl::Environment>
object, which encapsulates a lexical environment.  I<SOURCE> must be
a string.  I<SOURCE> is parsed as a block of Perl code (specifically,
as if it were the body of a function), in the lexical environment
represented by I<ENVIRONMENT>.  If there is any error in compilation,
a suitable exception is thrown.  If there is no error, the compiled code
is returned, in the form of a reference to a Perl function.  The code
represented by I<SOURCE> can then be executed by calling the function.

=back

=head1 SEE ALSO

L<Parse::Perl::Environment>,
L<perlfunc/eval>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
