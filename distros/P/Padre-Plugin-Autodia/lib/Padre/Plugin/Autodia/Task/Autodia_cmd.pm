package Padre::Plugin::Autodia::Task::Autodia_cmd;

use v5.10;
use strict;
use warnings;

use Carp qw( croak );
our $VERSION = '0.04';

use Padre::Task ();
use Padre::Unload;
use parent qw{ Padre::Task };

# use Autodia;
# use GraphViz;


#######
# Default Constructor from Padre::Task POD
#######
sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Assert required command parameter
	if ( not defined $self->{action} ) {
		croak "Failed to provide an action to git cmd task\n";
	}

	return $self;
}

#######
# Default run, see: Padre::Task POD
#######
sub run {
	my $self = shift;

	my $autodia_cmd;
	require Padre::Util;
	$autodia_cmd = Padre::Util::run_in_directory_two(
		cmd    => "$self->{action} -o $self->{outfile} -l $self->{language}",
		dir    => $self->{project_dir},
		option => 0
	);

	#saving to $self makes thing available to on_finish under $task
	$self->{error}  = $autodia_cmd->{error};
	$self->{output} = $autodia_cmd->{output};

	return;
}

1;

__END__


=pod

=encoding UTF-8

=head1 NAME

Padre::Plugin::Autodia::Task::Autodia_cmd - Autodia plugin for Padre, The Perl IDE.

=head1 VERSION

version 0.04

=head1 SYNOPSIS

Run Autodia.pl as a Background Task, help to keep Padre sweet.

=head1 DESCRIPTION

Autodia actions in a padre task

=head1 Standard Padre::Task API

In order not to freeze Padre during web access, nopasting is done in a thread,
as implemented by L<Padre::Task>. Refer to this module's documentation for more
information.

The following methods are implemented:

=head1 METHODS

=over 4

=item * new()

default Padre Task constructor, see Padre::Task POD

=item * run()

This is where all the work is done.

=back

=head1 BUGS AND LIMITATIONS

None known.

=head1 DEPENDENCIES

Padre::Task,

=head1 SEE ALSO

For all related information (bug reporting, source code repository,
etc.), refer to L<Padre::Plugin::Autodia>.

=head1 AUTHOR

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2008-2012 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
