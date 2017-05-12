package Plack::Middleware::Log::Contextual::Logger;
use strict;

my @levels = (qw( trace debug info warn error fatal ));

my %level_num;
@level_num{ @levels } = (0 .. $#levels);
for my $name (@levels) {
    no strict 'refs';
    my $is_name = "is_$name";
    *{$name} = sub {
        my $self = shift;
        my $level = $name eq "trace" ? "debug" : $name;
        $self->{logger}->({
            level => $level,
            message => $_[0],
        }) if $self->$is_name;
    };
    *{$is_name} = sub {
        my $self = shift;
        my $upto = lc $self->{level} || 'debug';
        return $level_num{$name} >= $level_num{$upto};
    };
}

sub new {
    my($class, $logger, $level) = @_;
    bless { logger => $logger, level => $level }, $class;
}

1;
