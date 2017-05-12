package DebugDynamoDB;

use strict;
use warnings;
use parent 'Amazon::DynamoDB::20120810';
use Module::Load;
use Kavorka qw(-all);

classmethod new (%args) {
    $args{implementation} //= 'Amazon::DynamoDB::LWP';

    unless (ref $args{implementation}) {
        Module::Load::load($args{implementation});
        $args{implementation} = $args{implementation}->new(%args);
    }

    return $class->SUPER::new(%args);
}

around make_request (%args) {
    my $req = $next->($self, %args);
    warn $req->as_string;
    return $req;
}

1;
__END__
