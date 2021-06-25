use strict;
use warnings;
package Querylet::Input 0.402;
# ABSTRACT: generic input handler for Querlet::Query

use Carp;

#pod =head1 SYNOPSIS
#pod
#pod This is an abstract base class, meant for subclassing.
#pod
#pod  package Querylet::Input::Term;
#pod  use base qw(Querylet::Input);
#pod
#pod  sub default_type { 'term' }
#pod  sub handler      { \&from_term }  
#pod
#pod  sub from_term {
#pod    my ($query, $parameter) = @_;
#pod
#pod    print "$parameter: ";
#pod    my $input = <STDIN>;
#pod    chomp $input;
#pod    $query->{input}->{$parameter} = $input;
#pod  }
#pod
#pod  1;
#pod
#pod Then, in a querylet:
#pod
#pod  use Querylet::Input::Term
#pod
#pod  query: SELECT * FROM users WHERE userid = ?
#pod  
#pod  input: userid
#pod
#pod Or, to override the registered type:
#pod
#pod  use Querylet::Input::Term 'stdin';
#pod
#pod  output format: stdin
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class provides a simple way to write input handlers for Querylet, mostly
#pod by providing an import routine that will register the handler with the
#pod type-name requested by the using script.
#pod
#pod The methods C<default_type> and C<handler> must exist, as described below.
#pod
#pod =head1 IMPORT
#pod
#pod Querylet::Input provides an C<import> method that will register the handler
#pod when the module is imported.  If an argument is given, it will be used as the
#pod type name to register.  Otherwise, the result of C<default_type> is used.
#pod
#pod =cut

sub import {
	my ($class, $type) = @_;
	$type = $class->default_type unless $type;

	my $handler = $class->handler;

	Querylet::Query->register_input_handler($type => $handler);
}

#pod =head1 METHODS
#pod
#pod =over 4
#pod
#pod =item default_type
#pod
#pod This method returns the name of the type for which the input handler will be
#pod registered if no override is given.
#pod
#pod =cut

sub default_type { croak "default_type method unimplemented" }

#pod =item handler
#pod
#pod This method returns a reference to the handler, which will be used to register
#pod the handler.
#pod
#pod =cut

sub handler { croak "handler method unimplemented" }

#pod =back
#pod
#pod =cut

"I do endeavor to give satisfaction, sir.";

__END__

=pod

=encoding UTF-8

=head1 NAME

Querylet::Input - generic input handler for Querlet::Query

=head1 VERSION

version 0.402

=head1 SYNOPSIS

This is an abstract base class, meant for subclassing.

 package Querylet::Input::Term;
 use base qw(Querylet::Input);

 sub default_type { 'term' }
 sub handler      { \&from_term }  

 sub from_term {
   my ($query, $parameter) = @_;

   print "$parameter: ";
   my $input = <STDIN>;
   chomp $input;
   $query->{input}->{$parameter} = $input;
 }

 1;

Then, in a querylet:

 use Querylet::Input::Term

 query: SELECT * FROM users WHERE userid = ?
 
 input: userid

Or, to override the registered type:

 use Querylet::Input::Term 'stdin';

 output format: stdin

=head1 DESCRIPTION

This class provides a simple way to write input handlers for Querylet, mostly
by providing an import routine that will register the handler with the
type-name requested by the using script.

The methods C<default_type> and C<handler> must exist, as described below.

=head1 PERL VERSION SUPPORT

This code is effectively abandonware.  Although releases will sometimes be made
to update contact info or to fix packaging flaws, bug reports will mostly be
ignored.  Feature requests are even more likely to be ignored.  (If someone
takes up maintenance of this code, they will presumably remove this notice.)

=head1 IMPORT

Querylet::Input provides an C<import> method that will register the handler
when the module is imported.  If an argument is given, it will be used as the
type name to register.  Otherwise, the result of C<default_type> is used.

=head1 METHODS

=over 4

=item default_type

This method returns the name of the type for which the input handler will be
registered if no override is given.

=item handler

This method returns a reference to the handler, which will be used to register
the handler.

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
