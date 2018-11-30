package Perl::Critic::Policy::Freenode::IndirectObjectNotation;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy::Objects::ProhibitIndirectSyntax';

our $VERSION = '0.028';

sub default_severity { $SEVERITY_HIGHEST }
sub default_themes { 'freenode' }

1;

=head1 NAME

Perl::Critic::Policy::Freenode::IndirectObjectNotation - Don't call methods
indirectly

=head1 DESCRIPTION

Perl allows a form of method call where the method name is first, followed by
the invocant (class or object to call the method on), then the argument list.
This is an unfortunate legacy syntax that should no longer be used. See
L<perlobj/"Indirect Object Syntax"> and L<indirect/"REFERENCES"> for more
information.

 my $obj = new My::Class @args;   # not ok
 my $obj = My::Class->new(@args); # ok

It is difficult to detect indirect object notation by static analysis, so this
policy only forbids the C<new> method call by default, as it is highly unlikely
to be the name of a standard subroutine call. Consider using the L<indirect>
pragma to cause the code to warn or die when indirect object notation is used.

This policy is a subclass of the L<Perl::Critic> core policy
L<Perl::Critic::Policy::Objects::ProhibitIndirectSyntax>, and performs the same
function but in the C<freenode> theme.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy can be configured, in the same way as its parent policy
L<Perl::Critic::Policy::Objects::ProhibitIndirectSyntax>, to attempt to forbid
additional method names from being called indirectly. Be aware this may lead to
false positives as it is difficult to detect indirect object notation by static
analysis. The C<new> subroutine is always forbidden in addition to these.

 [Freenode::IndirectObjectNotation]
 forbid = create destroy

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>, L<indirect>
