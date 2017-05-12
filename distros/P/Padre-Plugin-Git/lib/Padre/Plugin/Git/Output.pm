package Padre::Plugin::Git::Output;

use v5.10;
use strict;
use warnings;

use Padre::Unload ();
use Padre::Plugin::Git::FBP::Output ();

our $VERSION = '0.12';
use parent qw(
	Padre::Plugin::Git::FBP::Output
	Padre::Plugin
);

#######
# Method new
#######
sub new {
	my $class = shift;
	my $main  = shift;
	my $title = shift || '';
	my $text  = shift || '';

	# Create the dialogue
	my $self = $class->SUPER::new($main);

	# define where to display main dialogue
	$self->CenterOnParent;
	$self->SetTitle( $title );
	$self->text->SetValue( $text );

	return $self;
}


1;

__END__

# Spider bait
Perl programming -> TIOBE

=pod

=encoding utf8

=head1 NAME

Padre::Plugin::Git::Output - Git plugin for Padre, The Perl IDE.

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This module handles the Output dialogue that is used to show git response.


=head1 METHODS

=over 4

=item * new

	$self->{dialog} = Padre::Plugin::Git::Output->new( $main, "Git $action -> $location", $git_cmd->{output} );


=back


=head1 BUGS AND LIMITATIONS

None known.

=head1 DEPENDENCIES

Padre, Padre::Plugin::Git::FBP::Output

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

