package TM::Workbench::Plugin::Test;

use base 'TM::Workbench::Plugin';

sub precedence { return 'p2'; }

sub matches {
    my $self = shift;
    my $cmd  = shift;
    return $cmd =~ /^test$/
}

sub execute {
    my $self = shift;
    return "TEST\n";
}

1;

