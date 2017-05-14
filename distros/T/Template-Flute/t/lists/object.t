#
# Object tests for list params

use strict;
use warnings;

use Test::More tests => 8;
use Template::Flute;

package ObjectTest;

use Moo;
use Scalar::Util qw/looks_like_number/;

has value => (
    is => 'rw',
);

sub computed_value {
    my ($self) = @_;

    if (looks_like_number($self->value)) {
        return $self->value * 2;
    }
    else {
        return $self->value . $self->value;
    }
};

package main;

my ($spec, $html, $flute, $out, $obj, $computed);

$spec = q{<specification>
<list name="list" iterator="test">
<param name="value"/>
<param name="computed" field="computed_value"/>
</list>
</specification>
};

$html = q{
<html>	
	<div class="list">
		<div class="value">TEST</div>
		<div class="computed">COMPUTED</div>
	</div>
</html>};

for my $value (0, 1, ' ', 'test') {
    $obj = ObjectTest->new(value => $value);

    $flute = Template::Flute->new(template => $html,
                                  specification => $spec,
                                  values => {test => [$obj]},
    );

    $out = $flute->process();

    ok ($out =~ m%<div class="value">$value</div>%,
        "basic list param test with: $value")
        || diag $out;

    $computed = $obj->computed_value;

    ok ($out =~ m%<div class="computed">$computed</div>%,
        "object list param test with: $computed")
        || diag $out;
}
