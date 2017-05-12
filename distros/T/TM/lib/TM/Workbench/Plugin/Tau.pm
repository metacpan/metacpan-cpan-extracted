package TM::Workbench::Plugin::Tau;

use base 'TM::Workbench::Plugin';

sub precedence { return 'p9'; }

sub matches {
    my $self = shift;
    my $cmd  = shift;
    return 1;
}

sub execute {
    my $self = shift;
    my $cmd  = shift;

    use TM::Tau;
    eval {
	my $te = new TM::Tau ($cmd);                                         # this is completely burdened on the breath-in-out mechanism within TM::Tau
#       $te->DESTROY;
    }; if ($@) {
	return "$@\n";
    }
}

1;
