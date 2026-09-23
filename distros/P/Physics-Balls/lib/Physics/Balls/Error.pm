package Physics::Balls::Error;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.07';

our (@FLAGS, %MESSAGE);

BEGIN {
	@FLAGS = qw/
		no_ball
		bad_direction
		bad_power
		bad_spin
		bad_layout
		bad_kind
		bad_adjust
		bad_roll
		overlap
		engine
		bad_velocity
		bad_horizon
	/;

	%MESSAGE = (
		no_ball       => 'the shot names a ball that is not in the layout',
		bad_direction => 'dx and dy must be integers within plus or minus 1,000,000 and not both zero',
		bad_power     => 'power must be an integer from 0 to 1000',
		bad_spin      => 'sx and sy must be integers from -500 to 500',
		bad_layout    => 'a layout is a list of [id, x, y] or [id, x, y, kind] integers with distinct ids',
		bad_kind      => 'a kind is an integer index into the kinds the world declares',
		bad_adjust    => 'an adjust is a line in hundredths of a millimetre on axis 0 or 1, a direction of 1 or -1, and two factors in thousandths from 0 to 100000',
		bad_roll      => 'a release roll is a direction tx, ty within plus or minus 1,000,000, not both zero, and a spin from 0 to 1000',
		overlap       => 'two balls in the layout overlap',
		engine        => 'the engine gave up',
		bad_velocity  => 'a starting velocity is two integers within plus or minus 100,000,000 hundredths of a millimetre a second',
		bad_horizon   => 'a horizon is an integer number of microseconds from 1 to 40,000,000',
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

Version 0.07

=head1 SYNOPSIS

    my $out = Physics::Balls->strike($world, %shot);
    if ($out->error) {
        print $out->code, ': ', $out->message, "\n";
        print "too hard\n" if $out->bad_power;
    }

=head1 DESCRIPTION

Every refusal is one of these, so a caller tests C<error> and reads C<code>
rather than parsing a string. The codes are C<no_ball>, C<bad_direction>,
C<bad_power>, C<bad_spin>, C<bad_layout>, C<bad_kind>, C<bad_adjust>,
C<bad_roll>, C<overlap>, C<engine>, C<bad_velocity> and C<bad_horizon>, each
also a true attribute on the object.

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

A layout is a list of C<[id, x, y]> or C<[id, x, y, kind]> integers with
distinct ids.

=head2 bad_kind

A row's kind is not an integer index into the kinds the world declares. A
world with no kinds accepts kind 0 only.

=head2 bad_adjust

The adjust fields are not integers in range: C<adjust_at> any integer,
C<adjust_axis> 0 or 1, C<adjust_dir> 1 or -1, C<adjust_mu> and
C<adjust_curve> 0 to 100000.

=head2 bad_roll

The release roll is not a direction within plus or minus 1,000,000, not both
zero, with a spin from 0 to 1000.

=head2 overlap

Two balls in the layout are more than a tenth of a millimetre inside each
other, at the touching distance of their kinds.

=head2 engine

The engine gave up; the detail says why.

=head2 bad_velocity

An advance row's C<vx, vy> are not integers within plus or minus 100,000,000.

=head2 bad_horizon

An advance's C<t> is not an integer number of microseconds from 1 to
40,000,000.

=cut
