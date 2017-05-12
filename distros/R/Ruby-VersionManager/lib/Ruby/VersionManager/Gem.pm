package Ruby::VersionManager::Gem;

use 5.010;
use Moo;
use strict;
use feature 'say';
use warnings;
use Data::Dumper;

our $VERSION = 0.004004;

has _gem_list => ( is => 'rw' );
has _dispatch => ( is => 'rw' );
has _options  => ( is => 'rw' );

sub BUILD {
	my ($self) = @_;

	my $dispatch = { reinstall => $self->can('_reinstall'), };

	$self->_dispatch($dispatch);

	return 1;
}

sub run_action {
	my ( $self, $action, @options ) = @_;

	if ( exists $self->_dispatch->{$action} ) {
		$self->_options(@options);
		$self->_dispatch->{$action}->($self);
	}
	else {
		system 'gem ' . join ' ', ( $action, @options );
	}

	return 1;
}

sub _reinstall {
	my ($self) = @_;

	my $stdin .= $_ while (<>);
	if ($stdin) {
		$self->_gem_list( $self->_parse_gemlist($stdin));
	}
	elsif ( defined $self->_gem_list && -f $self->_gem_list ) {
		my $gemlist = '';
		{
			local $/;
			open my $fh, '<', $self->_gem_list;
			$gemlist = <$fh>;
			close $fh;
		}
		$self->_gem_list( $self->_parse_gemlist($gemlist) );
	}
	elsif ( defined $self->_options && -f ( $self->_options )[0] ) {
		my $gemlist = '';
		{
			local $/;
			open my $fh, '<', ( $self->_options )[0];
			$gemlist = <$fh>;
			close $fh;
		}
		$self->_gem_list( $self->_parse_gemlist($gemlist) );
	}
	else {
		my $gemlist = qx[gem list];
		$self->_gem_list( $self->_parse_gemlist($gemlist) );
	}

	$self->_install_gems( $self->_gem_list, { nodeps => 1 } );
}

sub _parse_gemlist {
	my ( $self, $gemlist ) = @_;

	my $gems = {};
	for my $line ( split /\n/, $gemlist ) {
		my ( $gem, $versions ) = $line =~ /
			([-_\w]+)\s # capture gem name
			[(](
				(?:
					(?:
						(?:\d+\.)*\d+
					)
					,?\s?
				)+
			)[)]/mxg;
		$gems->{$gem} = [ split ', ', $versions ] if defined $gem;
	}

	return $gems;
}

sub _install_gems {
	my ( $self, $gems, $opts ) = @_;

	for my $gem ( keys %$gems ) {
		for my $version ( @{ $gems->{$gem} } ) {
			my $cmd = "gem install $gem ";
			$cmd .= "-v=$version";
			if ( defined $opts && $opts->{'nodeps'} ) {
				$cmd .= " --ignore-dependencies";
			}

			my $output = qx[$cmd];
		}
	}

	return 1;
}

1;

__END__

=head1 NAME

Ruby::VersionManager::Gem

=head1 WARNING!

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.004004

=head1 SYNOPSIS

The Ruby::VersionManager::Gem module is basically a wrapper around the gem command providing some additional funcionality.

=head1 CONSTRUCTION

	my $gem = Ruby::VersionManager::Gem->new;

=head1 METHODS

=head2 run_action

Run the gem command with parameters or use one of the additional functions.

	$gem->run_action('install', ('unicorn', '-v=4.0.1'));

=head1 ACTIONS

The additional actions to pass to Ruby::VersionManager::Gem::run_action.

=head2 reinstall

You can resemble gemsets from other users or machines by using reinstall with a file containing the output of 'gem list'. When omiting the file name the gemset is read from <STDIN>. If nothing can be read the currently installed gemset will be completely reinstalled without pulling in any additional dependencies.

	$gem->run_action('reinstall', ($filename));

=head1 AUTHOR

Matthias Krull, C<< <m.krull at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Ruby::VersionManager issue tracker

L<https://github.com/uninets/p5-Ruby-VersionManager/issues>

=item * support at uninets.eu

C<< <m.krull at uninets.eu> >>

=back

=head1 SUPPORT

=over 2

=item * Technical support

C<< <m.krull at uninets.eu> >>

=back

=cut

