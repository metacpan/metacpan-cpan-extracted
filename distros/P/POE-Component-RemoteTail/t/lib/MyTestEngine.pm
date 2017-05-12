package MyTestEngine;

use strict;
use warnings;
$| = 1;

sub new {
    my $class = shift;
    my %args  = @_;

    return bless {%args}, $class;
}

sub process_entry {
    my $self = shift;
    my $arg  = shift;
    
    my $host     = $arg->{host};
    my $path     = $arg->{path};
    my $user     = $arg->{user};
    my $password = $arg->{password};

    for(1..1000){
        my $log = "logloglog_" . $_;
        print STDOUT $log,"\n";
    }
}

1;
