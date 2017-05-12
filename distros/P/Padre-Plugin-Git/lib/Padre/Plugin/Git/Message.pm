package Padre::Plugin::Git::Message;

use v5.10;
use strict;
use warnings;

use Padre::Unload                    ();
use Padre::Plugin::Git::FBP::Message ();
use File::Spec;
use File::Slurp;

our $VERSION = '0.12';
use parent qw(
	Padre::Plugin::Git::FBP::Message
	Padre::Plugin
);

#######
# Method new
#######
sub new {
	my $class       = shift;
	my $main        = shift;
	my $title       = shift;
	my $project     = shift;
	my $commit_file = shift;

	# Create the dialogue
	my $self = $class->SUPER::new($main);

	$self->{project} = $project;

	# define where to display main dialogue
	$self->CenterOnParent;
	$self->SetTitle($title);

	if ($commit_file) {
		$self->type->SetLabel('File:');
		$self->commit_file->SetLabel($commit_file);
	} else {
		$self->type->SetLabel('Project:');
		$self->commit_file->SetLabel($project);
	}

	return $self;
}

#######
# event handler for on_show_last
#######
sub on_show_last {
	my $self = shift;
	my $previous_commit_file = File::Spec->catfile( $self->{project}, '.git/COMMIT_EDITMSG' );

	if ( -e $previous_commit_file ) {
		my $previous_text = read_file($previous_commit_file);
		$self->message->SetValue($previous_text);
	}

	return;
}

#######
# event handler for on_commit
#######
sub on_commit {
	my $self    = shift;
	my $message = $self->message->GetValue;
	chomp $message;

	# save config info
	my $config = $self->config_read;
	$config->{message} = $message;
	$self->config_write($config);

	$self->Hide;
	return;
}


1;

__END__

# Spider bait
Perl programming -> TIOBE

=pod

=encoding utf8

=head1 NAME

Padre::Plugin::Git::Message - Git plugin for Padre, The Perl IDE.

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This module handles the Commit messages dialogue.

=head1 METHODS

=over 4

=item * new

	$self->{dialog} = Padre::Plugin::Git::Message->new( $main, $title, $document->project_dir, $filename );

=item * on_commit

=item * on_show_last

=back


=head1 BUGS AND LIMITATIONS

None known.

=head1 DEPENDENCIES

Padre, Padre::Plugin::Git::FBP::Message

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
