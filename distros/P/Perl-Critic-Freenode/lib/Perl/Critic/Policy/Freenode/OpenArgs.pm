package Perl::Critic::Policy::Freenode::OpenArgs;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.024';

use constant DESC => 'open() called with less than 3 arguments';
use constant EXPL => 'The one- and two-argument forms of open() parse functionality from the filename, use the three-argument form instead.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_MEDIUM }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Token::Word' }

sub violates {
	my ($self, $elem) = @_;
	return () unless $elem eq 'open' and is_function_call $elem;
	
	my @args = parse_arg_list $elem;
	if (@args < 3) {
		return () if @args == 2 and $args[1][0]->isa('PPI::Token::Quote')
			and $args[1][0]->string =~ /^(?:-\||\|-)\z/;
		return $self->violation(DESC, EXPL, $elem);
	}
	
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::OpenArgs - Always use the three-argument form
of open

=head1 DESCRIPTION

The C<open()> function may be called in a two-argument form where the filename
is parsed to determine the mode of opening, which may include piping input or
output. (In the one-argument form, this filename is retrieved from a global
variable, but the same magic is used.) This can lead to vulnerabilities if the
filename is retrieved from user input or could begin or end with a special
character. The three-argument form specifies the open mode as the second
argument, so it is always distinct from the filename.

  open FILE;                   # not ok
  open my $fh, "<$filename";   # not ok
  open my $fh, '<', $filename; # ok

This policy is similar to the core policy
L<Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen>, but additionally
prohibits one-argument opens.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
