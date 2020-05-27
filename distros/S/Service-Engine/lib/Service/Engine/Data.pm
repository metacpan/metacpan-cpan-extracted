package Service::Engine::Data;

use 5.010;
use strict;
use warnings;
use Carp;
use Service::Engine;
use Data::Dumper;
use Module::Runtime qw(require_module);
use threads;
use threads::shared;

our $Config;
our $Log;
our $Handles = {};

# load desired classes 
# Service::Engine::Data:*

sub new {
    
    my ($class,$options) = @_;
    
    # set some defaults
    my $attributes = {'handles'=>{}};
    
    # load options
    if (ref($options) eq 'HASH') {
        foreach my $option (keys %{$options}) {
            $attributes->{$option} = $options->{$option};
        }
    }
    
    # pull in some Service::Engine globals
    $Config = $Service::Engine::Config;
    $Log = $Service::Engine::Log;
    
    # create our data handles
    # these will be autoloaded from Service::Engine like this my $dbh = $Data->handlename();
    # this works by adding the connection handles to $attributes->{'handles'}->{handlename}
    # save the handle label to $Handles->{$label} = $type;
    if (ref($Config->get_config('data')) eq 'HASH') {
        foreach my $service (keys $Config->get_config('data')) {
            my $handles = $Config->get_config('data')->{$service};
            if (ref($handles) eq 'HASH' && keys %{$handles}) {
                foreach my $handle (keys %{$handles}) {
                    next unless keys %{$handles->{$handle}};
                    $Log->log({msg=>"loading handle $handle for $service",level=>2});
                    my $package = 'Service::Engine::Data::' . ucfirst lc $service;
                    my $res = eval { require_module($package) };
                    if ($@) {
                        $Log->log({msg=>"error loading $handle for $service: $@",level=>1});
                    } else {
                        my $obj = $package->new($handles->{$handle});
                        if ($obj->handle()) {
                            $attributes->{'handles'}->{$handle} = $obj->handle();
                            $Handles->{$handle} = $service;
                        }
                    }
                    
                }
            }
        }
    }
    
    $Log->log({msg=>Dumper($attributes->{'handles'}),level=>3});
    $Log->log({msg=>Dumper($Handles),level=>3});

    my $self = bless $attributes, $class;
    
    return $self;

}

sub get_status {
    my ($self, $handle) = @_;
        
    my $type = $Handles->{$handle}; 
    my $status = ($type) ? 1 : 0;
    my $result = {'status'=>$status, 'type'=>$type};
    
    return $result;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    # Remove qualifier from original method name...
    my $called =  $AUTOLOAD =~ s/.*:://r;
    # $Log->log({msg=>"AUTO loading data handle $called",level=>3});
    # Is there an attribute of that name?
    croak "No such attribute: $called"
      unless exists $self->{'handles'}->{$called};
    # If so, return it...
    return $self->{'handles'}->{$called};
}

1;