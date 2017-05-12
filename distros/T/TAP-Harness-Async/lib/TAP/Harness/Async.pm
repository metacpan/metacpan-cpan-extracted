package TAP::Harness::Async;
# ABSTRACT: Asynchronous subclass for TAP::Harness
use strict;
use warnings;
use parent qw(TAP::Harness);

our $VERSION = '0.001';

=head1 NAME

TAP::Harness::Async - Run tests in a subprocess through L<IO::Async>

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use TAP::Harness::Async;
 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;
 my $harness = TAP::Harness::Async->new({
   loop => $loop,
 });
 $harness->runtests(@ARGV);
 $harness->on_complete(sub { $loop->later(sub { $loop->loop_stop }) });
 $loop->loop_forever;

=head1 DESCRIPTION

This is a simple test harness which does the bare minimum required to
run the test process under L<IO::Async::Process>.

WARNING: This is an early proof-of-concept version, see examples/tickit.pl
for a simple demonstration and please note that the API is not stable
and may change significantly in the next version.

=cut

use Carp;
use TAP::Base;

##############################################################################

=head1 METHODS

=cut

sub _initialize {
	my ($self, $args) = @_;
	my $loop = delete $args->{loop} or die 'loop?';
	$self->{loop} = $loop;
	$self->SUPER::_initialize($args);
}

sub _aggregate_parallel {
	my ( $self, $aggregate, $scheduler ) = @_;

	my $jobs = $self->jobs;
	my $mux  = $self->_construct( $self->multiplexer_class );

	RESULT: {

# Keep multiplexer topped up
		FILL:
		while ( $mux->parsers < $jobs ) {
			my $job = $scheduler->get_job;

# If we hit a spinner stop filling and start running.
			last FILL if !defined $job || $job->is_spinner;

			my ( $parser, $session ) = $self->make_parser($job);
			$mux->add( $parser, [ $session, $job ] );
		}

		if(my ($parser, $stash, $result) = $mux->next) {
			my ($session, $job) = @$stash;
			if(defined $result) {
				$session->result($result);
				$self->_bailout($result) if $result->is_bailout;
			} else {

# End of parser. Automatically removed from the mux.
				$self->finish_parser( $parser, $session );
				$self->_after_test( $aggregate, $job, $parser );
				$job->finish;
			}
			redo RESULT;
		}
	}

	return;
}

sub loop { shift->{loop} }

sub _aggregate_single {
	my ( $self, $aggregate, $scheduler ) = @_;

	my $code;
	$code = sub {
		if(my $job = $scheduler->get_job ) {
			return $code->() if $job->is_spinner;

			my ( $parser, $session ) = $self->make_parser($job);
			my $it = $parser->_iterator;
			$it->{on_line} = sub {
				my ($line) = @_;
				while ($it->lines && defined( my $result = $parser->next ) ) {
					$session->result($result);
					if ( $result->is_bailout ) {
						$self->_bailout($result);
					}
				}
			};
			$it->{on_finished} = sub {
				$self->finish_parser( $parser, $session );
				$self->_after_test( $aggregate, $job, $parser );
				$job->finish;
				$self->loop->later($code);
			},
		} else {
			$self->{on_tests_complete}->($self, $aggregate) if exists $self->{on_tests_complete};
		}
	};
	$code->();
	return;
}

sub runtests {
	my ( $self, @tests ) = @_;

	my $aggregate = $self->_construct( $self->aggregator_class );

	$self->_make_callback( 'before_runtests', $aggregate );
	$aggregate->start;
	my $finish = sub {
		my $interrupted = shift;
		$aggregate->stop;
		$self->summary( $aggregate, $interrupted );
		$self->_make_callback( 'after_runtests', $aggregate );
	};
	my $run = sub {
		$self->{on_tests_complete} = sub { $finish->(0) };
		$self->aggregate_tests( $aggregate, @tests );
	};

	if ( $self->trap ) {
		local $SIG{INT} = sub {
			print "\n";
			$finish->(1);
			exit;
		};
		$run->();
	}
	else {
		$run->();
	}

	return $aggregate;
}

=head2 on_complete

Accessor for code to run on test completion.

=cut

sub on_complete {
	my ($self, $code) = @_;
	if($code) {
		$self->{on_complete} = $code;
		return $self;
	}
	return $self->{on_complete};
}

1;

__END__

=head1 SEE ALSO

L<Test::Harness> has all the important documentation.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2012. Licensed under the same terms as Perl itself.
