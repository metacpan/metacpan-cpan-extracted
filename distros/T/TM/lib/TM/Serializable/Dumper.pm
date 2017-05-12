package TM::Serializable::Dumper;

use Class::Trait 'base';
use Class::Trait 'TM::Serializable';

use Data::Dumper;

sub serialize {
    my $self = shift;
    use Data::Dumper;

    my $s;
    {
	local $Data::Dumper::Purity = 1;
	$s = Data::Dumper->Dump ([$self], ['tm']);         # NB: we have recursive data structures
    }
    return $s;
}

sub deserialize {
    my $self = shift;
    my $s    = shift;
    my $tm;
    eval $s;
    $self->melt ($tm);
}

1;
