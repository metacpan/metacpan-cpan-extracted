package Perl::Critic::Policy::Freenode::BarewordFilehandles;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.021';

use constant DESC => 'Using bareword filehandles';
use constant EXPL => 'Bareword filehandles are a legacy feature, creating the filehandles as package variables. Use lexical, scoped filehandles instead (open my $fh, ...).';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Token::Word' }

my %openers = (
	accept     => 1,
	open       => 1,
	opendir    => 1,
	pipe       => 2,
	socket     => 1,
	socketpair => 2,
);

my %builtins = (
	ARGV    => 1,
	ARGVOUT => 1,
	DATA    => 1,
	STDERR  => 1,
	STDIN   => 1,
	STDOUT  => 1,
);

sub violates {
	my ($self, $elem) = @_;
	return () unless exists $openers{$elem} and is_function_call $elem;
	my $num_handles = $openers{$elem};
	
	my @args = parse_arg_list $elem;
	my @handles = splice @args, 0, $num_handles;
	
	my @violations;
	foreach my $handle (@handles) {
		my $name = pop @$handle // next;
		push @violations, $self->violation(DESC, EXPL, $elem)
			if $name->isa('PPI::Token::Word') and !exists $builtins{$name};
	}
	
	return @violations;
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::BarewordFilehandles - Don't use bareword
filehandles other than built-ins

=head1 DESCRIPTION

Bareword filehandles are allowed in C<open()> as a legacy feature, but will use
a global package variable. Instead, use a lexical variable with C<my> so that
the filehandle is scoped to the current block, and will be automatically closed
when it goes out of scope. Built-in bareword filehandles like C<STDOUT> and
C<DATA> are ok.

  open FH, '<', $filename;     # not ok
  open my $fh, '<', $filename; # ok

This policy is similar to the core policy
L<Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles>, but allows
more combinations of built-in bareword handles and filehandle-opening functions
such as C<pipe> and C<socketpair>.

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

L<Perl::Critic>, L<bareword::filehandles>
