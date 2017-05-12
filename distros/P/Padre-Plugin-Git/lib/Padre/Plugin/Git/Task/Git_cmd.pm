package Padre::Plugin::Git::Task::Git_cmd;

use v5.10;
use strict;
use warnings;

use Carp qw( croak );
our $VERSION = '0.12';

use Padre::Task   ();
use Padre::Unload ;
use parent qw{ Padre::Task };


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
# Default run re: Padre::Task POD
#######
sub run {
	my $self = shift;

	my $git_cmd;
	require Padre::Util;
	$git_cmd = Padre::Util::run_in_directory_two(
		cmd    => "git $self->{action} $self->{location}",
		dir    => $self->{project_dir},
		option => 0
	);

	if ( $self->{action} !~ m/^diff/ ) {

		#strip leading #
		$git_cmd->{output} =~ s/^(\#)//sxmg;
	}

	#ToDo sort out Fudge, why O why do we not get correct response
	# p $git_cmd;
	if ( $self->{action} =~ m/^[push|fetch]/ ) {
		$git_cmd->{output} = $git_cmd->{error};
		$git_cmd->{error}  = undef;
	}

	#saving to $self makes thing availbe to on_finish under $task

	$self->{error}  = $git_cmd->{error};
	$self->{output} = $git_cmd->{output};

	return;
}

1;

__END__

# Spider bait
Perl programming -> TIOBE

=pod

=encoding utf8

=head1 NAME

Padre::Plugin::Git::Task::Git_cmd - Git plugin for Padre, The Perl IDE.

=head1 VERSION

version 0.12

=head1 SYNOPSIS

Perform the Git Task as a background Job, help to keep Padre sweet.

=head1 DESCRIPTION

git cmd actions in a padre task

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
etc.), refer to L<Padre::Plugin::Git>.

=head1 AUTHOR

See L<Padre::Plugin::Git>

=head2 CONTRIBUTORS

See L<Padre::Plugin::Git>

=head1 COPYRIGHT

See L<Padre::Plugin::Git>

=head1 LICENSE

See L<Padre::Plugin::Git>

=cut
