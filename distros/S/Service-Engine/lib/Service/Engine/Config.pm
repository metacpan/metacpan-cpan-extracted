package Service::Engine::Config;

use 5.010;
use strict;
use warnings;
use File::Slurp;
use Carp;
use Data::Dumper;
use File::stat;
use Time::localtime;

sub new {
    
    my ($class,$options) = @_;
    
    # set some defaults
    my $attributes = {
                        'config'=>  {
                                        'logging' => {
                                                        'log_level'   =>  0
                                                     }
                                    }
                     };
    
    # load options
    if (ref($options) eq 'HASH') {
        foreach my $option (keys %{$options}) {
            $attributes->{$option} = $options->{$option};
        }
    }
    
    # load configuration file
    my $config;
    if ($attributes->{config_file}) {
        if (-e $attributes->{config_file}) {
            my $text = read_file($attributes->{config_file}, { err_mode => 'carp' });
            $config = eval($text);
            if (ref($config) ne 'HASH') {
                croak("config file is not a valid Perl file: " . $attributes->{config_file});
            }
        } else {
            croak("Can't open config file " . $attributes->{config_file});
        }
    }
    
    $attributes->{config}->{mtime} = ctime(stat($attributes->{config_file})->mtime);
    
    if (ref($config) eq 'HASH') {
        foreach my $option (keys %{$config}) {
        	$attributes->{'config'}->{$option} = $config->{$option};
        }
    }
    
    my $self = bless $attributes, $class;
    
    return $self;

}

sub get_config {
    
    my ($self, $key) = @_;
    
    if ($key) {
        return $self->{'config'}->{$key};
    }
    
    # with no $key return the entire config object
    return $self->{'config'};
    
}

sub reload {

    # THIS IS NOT IMPLEMENTED
    
    my ($self) = @_;
        
    if ($self->{'config'}->{'mtime'} ne ctime(stat($self->{'config_file'})->mtime)) {
                
        # load configuration file
        my $config;

        if (-e $self->{config_file}) {
            my $text = read_file($self->{config_file}, { err_mode => 'carp' });
            $config = eval($text);
            if (ref($config) ne 'HASH') {
                croak("config file is not a valid Perl file: " . $self->{config_file});
            }
        } else {
            croak("Can't open config file " . $self->{config_file});
        }
    
        $self->{'config'}->{'mtime'} = ctime(stat($self->{config_file})->mtime);
    
        if (ref($config) eq 'HASH') {
            foreach my $option (keys %{$config}) {
                $self->{'config'}->{$option} = $config->{$option};
            }
        }
        
    }
    
}

1;