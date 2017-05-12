# Hide from indexer, at least until we get some documentation
package
 TAP::Parser::Iterator::Process::Async;
use strict;
use warnings;
use parent qw(TAP::Parser::Iterator::Process);
use IO::Async::Process;
use Carp qw(cluck);

sub _initialize {
	my ($self, $args) = @_;
	$self->{lines} = [];
	my $loop = $args->{loop} or die "loop?";
	$self->{$_} = delete $args->{$_} for grep exists $args->{$_}, qw(on_line on_finished);
	my $process = IO::Async::Process->new(
		command => $args->{command},
		stdin => { from => "\n" },
		stdout => {
			on_read => sub {
				my ( $stream, $buffref ) = @_;
				while( $$buffref =~ s/^(.*)\n// ) {
					my $txt = $1;
					push @{$self->{lines}}, $txt;
					$self->{on_line}->($txt) if exists $self->{on_line};
				}
				return 0;
			},
		},
		stderr => {
			on_read => sub {
				my ( $stream, $buffref ) = @_;
				while( $$buffref =~ s/^(.*)\n// ) {
					my $txt = $1;
					$self->{on_line}->($txt) if exists $self->{on_line};
					push @{$self->{lines}}, $txt;
				}
				return 0;
			},
		},
	    
		on_finish => sub {
			$self->{on_finished}->() if exists $self->{on_finished};
		},
		on_exception => sub { die"Exception: Died with @_" },
	);

# TAP::Harness
	$loop->add( $process );
	return $self;
}

sub lines { scalar @{ shift->{lines} } }
sub next_raw {
	my $self = shift;
	return unless @{$self->{lines}};
	return shift @{$self->{lines}};
}

sub wait { shift->exit }

sub exit {
	my $self = shift;
	return 1 unless @{$self->{lines}};
	return;
}

1;

__END__

=head1 SEE ALSO

L<TAP::Iterator::Process> has all the important documentation.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2012. Licensed under the same terms as Perl itself.

