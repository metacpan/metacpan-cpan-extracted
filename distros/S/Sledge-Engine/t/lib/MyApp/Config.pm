package MyApp::Config;
use strict;

use base qw(Edge::Config Class::Singleton);

sub case_sensitive { 0 }

sub _new_instance {
    my $class = shift;
    unless (defined $ENV{SLEDGE_CONFIG_NAME}) {
        do '/etc/MyApp-conf.pl' or warn $!;
    }
    $class->SUPER::new($ENV{SLEDGE_CONFIG_NAME});
}

sub as_hashref {
    my $self = shift;
    return 
        {map { lc($_) => $self->{$_}, uc($_) => $self->{$_}} keys %$self};
}

1;
