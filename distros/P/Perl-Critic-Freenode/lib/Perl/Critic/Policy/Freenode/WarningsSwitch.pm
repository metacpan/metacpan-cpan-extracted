package Perl::Critic::Policy::Freenode::WarningsSwitch;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.033';

use constant DESC => 'Using -w switch';
use constant EXPL => 'Don\'t use -w (or -W), it\'s too eager. use warnings; instead.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_LOW }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Document' }

sub violates {
	my ($self, $elem) = @_;
	my $shebang = $elem->first_token;
	return () unless $shebang->isa('PPI::Token::Comment') and $shebang->content =~ m/^#!/;
	
	return $self->violation(DESC, EXPL, $elem) if $shebang->content =~ m/\h-[a-zA-Z]*[wW]/;
	
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::WarningsSwitch - Scripts should not use the -w
switch on the shebang line

=head1 DESCRIPTION

The C<-w> switch enables warnings globally in a perl program, including for any
modules that did not explicitly enable or disable any warnings. The C<-W>
switch enables warnings even for modules that explicitly disabled them. The
primary issue with this is enabling warnings for code that you did not write.
Some of these modules may not be designed to run with warnings enabled, but
still work fine. Instead, use L<warnings> within your own code only.

  #!/usr/bin/perl -w # not ok
  #!/usr/bin/perl -W # not ok
  use warnings;      # ok

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

L<Perl::Critic>, L<warnings>
