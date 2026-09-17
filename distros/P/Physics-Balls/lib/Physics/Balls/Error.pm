package Physics::Balls::Error;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.02';

our (@FLAGS, %MESSAGE);

BEGIN {
	@FLAGS = qw/
		no_ball
		bad_direction
		bad_power
		bad_spin
		bad_layout
		overlap
		engine
	/;

	%MESSAGE = (
		no_ball       => 'the shot names a ball that is not in the layout',
		bad_direction => 'dx and dy must be integers within plus or minus 1,000,000 and not both zero',
		bad_power     => 'power must be an integer from 0 to 1000',
		bad_spin      => 'sx and sy must be integers from -500 to 500',
		bad_layout    => 'a layout is a list of [id, x, y] integers with distinct ids',
		overlap       => 'two balls in the layout overlap',
		engine        => 'the engine gave up',
	);
}

has [@FLAGS] => (
	is => 'ro'
);

has error => (
	is => 'ro',
	default => 1
);

has code => (
	is => 'ro',
	isa => Str
);

has detail => (
	is => 'ro',
	isa => Str,
	default => ''
);

sub of {
	my ($class, $code, $detail) = @_;
	die "Physics::Balls::Error: unknown code $code" unless exists $MESSAGE{$code};
	return $class->new($code => 1, code => $code, detail => defined $detail ? $detail : '');
}

sub message {
	my ($self) = @_;
	my $m = $MESSAGE{ $self->code };
	return $self->detail ne '' ? "$m: " . $self->detail : $m;
}

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls::Error - a flagged refusal, returned and never thrown

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $out = Physics::Balls->strike($world, %shot);
    if ($out->error) {
        print $out->code, ': ', $out->message, "\n";
        print "too hard\n" if $out->bad_power;
    }

=head1 DESCRIPTION

Every refusal is one of these, so a caller tests C<error> and reads C<code>
rather than parsing a string. The codes are C<no_ball>, C<bad_direction>,
C<bad_power>, C<bad_spin>, C<bad_layout>, C<overlap> and C<engine>, each also a
true attribute on the object.

=head1 METHODS

=head2 of

    my $err = Physics::Balls::Error->of('bad_power', 'got 1200');

=head2 code

The code.

=head2 message

The sentence for the code, with the detail after a colon when there is one.

=head2 detail

What was wrong, when the refusal can say.

=head2 error

Always true.

=head1 FLAGS

Each code is also a method that is true on an error of that code and false
otherwise, so a caller can test C<< $err->bad_power >> without comparing
strings.

=head2 no_ball

The shot names a ball that is not in the layout.

=head2 bad_direction

C<dx> and C<dy> must be integers within plus or minus 1,000,000 and not both
zero.

=head2 bad_power

C<power> must be an integer from 0 to 1000.

=head2 bad_spin

C<sx> and C<sy> must be integers from -500 to 500.

=head2 bad_layout

A layout is a list of C<[id, x, y]> integers with distinct ids.

=head2 overlap

Two balls in the layout are more than a tenth of a millimetre inside each other.

=head2 engine

The engine gave up; the detail says why.

=cut
