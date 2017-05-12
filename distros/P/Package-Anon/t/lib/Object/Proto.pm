use strict;
use warnings;

package Object::Proto;

use Package::Anon;

use Sub::Exporter -setup => {
    exports => ['new_instance', 'add_method'],
    groups  => { default => ['new_instance', 'add_method'] },
};

sub new_instance {
    my ($ref, $proto) = @_;

    my $s = Package::Anon->new;
    my $o = $s->bless($ref);

    if ($proto) {
        my $stash = $proto->{__prototype__};
        for my $inherited (keys %{ $stash }) {
            next if exists $s->{$inherited};
            $s->{$inherited} = $stash->{$inherited};
        }
    }

    $o->{__prototype__} = $s;

    return $o;
}

sub add_method {
    my ($o, $n, $c) = @_;
    $o->{__prototype__}->add_method($n => $c);
}

1;
