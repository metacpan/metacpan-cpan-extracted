package Perl::Critic::Policy::Community::POSIXImports;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = 'v1.0.3';

use constant DESC => 'Using POSIX.pm without an explicit import list';
use constant EXPL => 'Using the POSIX module without specifying an import list results in importing hundreds of symbols. Import the functions or constants you want explicitly, or prevent the import with ().';

sub supported_parameters { () }
sub default_severity { $SEVERITY_LOW }
sub default_themes { 'community' }
sub applies_to { 'PPI::Statement::Include' }

sub violates {
	my ($self, $elem) = @_;
	return $self->violation(DESC, EXPL, $elem) if ($elem->type // '') eq 'use'
		and ($elem->module // '') eq 'POSIX' and !$elem->arguments;
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Community::POSIXImports - Don't use POSIX without
specifying an import list

=head1 DESCRIPTION

The L<POSIX> module imports hundreds of symbols (functions and constants) by
default for backwards compatibility reasons. To avoid this, and to assist in
finding where functions have been imported from, specify the symbols you want
to import explicitly in the C<use> statement. Alternatively, specify an empty
import list with C<use POSIX ()> to avoid importing any symbols, and fully
qualify the functions or constants, such as C<POSIX::strftime>.

 use POSIX;         # not ok
 use POSIX ();      # ok
 use POSIX 'fcntl'; # ok
 use POSIX qw(O_APPEND O_CREAT O_EXCL O_RDONLY O_RDWR O_WRONLY); # ok

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Community>.

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
