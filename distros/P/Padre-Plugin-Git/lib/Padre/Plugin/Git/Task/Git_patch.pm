package Padre::Plugin::Git::Task::Git_patch;

use v5.10;
use strict;
use warnings;

use Carp qw( croak );
our $VERSION = '0.12';

use Padre::Task ();
use Padre::Unload;
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
	my $cmd  = $self->{action};
	my $system;

	if (Padre::Constant::WIN32) {
		my $title = $cmd;
		$title =~ s/"//g;
		$system = qq(start "$title" cmd /C "$cmd  & pause");
	} elsif (Padre::Constant::UNIX) {

		if ( defined $ENV{COLORTERM} ) {
			if ( $ENV{COLORTERM} eq 'gnome-terminal' ) {

				#Gnome-Terminal line format:
				#gnome-terminal -e "bash -c \"prove -lv t/96_edit_patch.t; exec bash\""
				$system = qq($ENV{COLORTERM} -e "bash -c \\\"$cmd ; exec bash\\\"" & );
			} else {
				$system = qq(xterm -sb -e "$cmd ; sleep 1000" &);
			}
		}
	} elsif (Padre::Constant::MAC) {

		# tome
		my $pwd = $self->current->document->project_dir();
		$cmd =~ s/"/\\"/g;

		# Applescript can throw spurious errors on STDERR: http://helpx.adobe.com/photoshop/kb/unit-type-conversion
		$system = qq(osascript -e 'tell app "Terminal"\n\tdo script "cd $pwd; clear; $cmd ;"\nend tell'\n);

	} else {
		$system = qq(xterm -sb -e "$cmd ; sleep 1000" &);
	}

	# say $system;

	my $git_patch;
	require Padre::Util;
	$git_patch = Padre::Util::run_in_directory_two(
		cmd    => $system,
		dir    => $self->{project_dir},
		option => 0
	);

	# if ( $self->{action} !~ m/^diff/ ) {

		# #strip leading #
		# $git_patch->{output} =~ s/^(\#)//sxmg;
	# }

	# #ToDo sort out Fudge, why O why do we not get correct response
	# # p $git_cmd;
	# if ( $self->{action} =~ m/^[push|fetch]/ ) {
		# $git_patch->{output} = $git_patch->{error};
		# $git_patch->{error}  = undef;
	# }

	# #saving to $self makes thing availbe to on_finish under $task

	# $self->{error}  = $git_patch->{error};
	# $self->{output} = $git_patch->{output};

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
