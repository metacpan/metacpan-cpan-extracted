package POE::Component::YahooMessenger::Event;
use strict;

BEGIN {
    use POE::Component::YahooMessenger::Constants;

    sub _make_body_accessor {
	my $wantkey = shift;
	return sub {
	    my($self, $number) = @_;
	    my @values;
	    my @params = $self->params;
	    while (my($key, $value) = splice(@params, 0, 2)) {
		push @values, $value if $key eq $BodyNames->{$wantkey};
	    }
	    return defined $number ? $values[$number]
		: wantarray ? @values : $values[0];
	};
    }

    for my $name (keys %$BodyNames) {
	no strict 'refs';
	*$name = _make_body_accessor($name);
    }
}

sub new_from_body {
    my($class, $code, $body) = @_;
    bless {
	code   => $code,
	option => 0, 		# XXX ?
	params => [ split /$BodySeparater/, $body ],
    }, $class;
}

sub new {
    my($class, $name, $option, $params) = @_;
    bless {
	code   => $SendEventNames->{$name},
	option => $option,
	params => [ map { $BodyNames->{$_} => $params->{$_} } keys %$params ],
    }, $class;
}

sub code   { shift->{code} }
sub name   { $ReceiveEventCodes->{shift->code} }
sub option { shift->{option} }

sub body   {
    my $self = shift;
    return join($BodySeparater, $self->params) . $BodySeparater;
}

sub params { @{shift->{params}} }

package POE::Component::YahooMessenger::Event::Null;

use base qw(POE::Component::YahooMessenger::Event);

sub new { bless {}, shift }
sub DESTROY { }
sub AUTOLOAD { }

1;
