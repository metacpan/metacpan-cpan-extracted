package TAP::Formatter::Event::Session;
{
  $TAP::Formatter::Event::Session::VERSION = '0.001';
}
use strict;
use warnings;
use 5.010;
use parent qw(TAP::Formatter::Session Mixin::Event::Dispatch);
use Time::HiRes ();

sub header {
	my $self = shift;
	$self->{started} = Time::HiRes::time;
	$self->invoke_event(test_started => $self->{started});
	return $self->SUPER::header(@_);
}

=pod

=cut

sub result {
	my $self = shift;
	my $test = shift;
	use Data::Dumper;
	$self->invoke_event(test_result => $test);
	if($test->{type} eq 'plan') {
		$self->invoke_event(test_plan => $test);
	} elsif($test->{type} eq 'test') {
		given($test->{ok}) {
			when('not ok') { $self->invoke_event(test_failed => $test); }
			when('ok') { $self->invoke_event(test_passed => $test); }
			default { $self->invoke_event(test_unknown => $test); }
		}
	}
	return 1;
}

sub testfile {
	my $self = shift;
	if(@_) {
		$self->{testfile} = shift;
		return $self;
	}
	return $self->{testfile};
}

sub close_test {
	my $self = shift;
	$self->invoke_event(test_finished => $self->{started});
	1;
}

sub invoke_event {
	my $self = shift;
	my $event = shift;
	$self->formatter->invoke_event($event => $self, @_);
}

1;

