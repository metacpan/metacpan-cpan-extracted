package Zoo::Representation::Text;
use Moose;

with 'Sloth::Representation';

sub content_type { qr/.*/ }

sub serialize {
    my ($self, $what) = @_;
    return "An animal";
}

1;
