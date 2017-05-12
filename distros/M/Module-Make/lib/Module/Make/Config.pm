package Module::Make::Config;
use strict;
use warnings;
use Module::Make::Base -base;
use YAML;

sub init {
    my $self = shift;
    %$self = (%$self, %{YAML::Load(io('config.yaml')->all)});
    return $self;
}

sub exec_command {
    my $self = shift;
    return "$self->{perl_path} -M$self->{maker_class}=exec -";
}

1;
