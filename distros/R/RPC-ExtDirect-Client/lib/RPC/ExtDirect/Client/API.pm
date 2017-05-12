package RPC::ExtDirect::Client::API;

use strict;
use warnings;
no  warnings 'uninitialized';   ## no critic

use JSON;

use RPC::ExtDirect::Util::Accessor;
use RPC::ExtDirect::Config;
use RPC::ExtDirect::API;

use base 'RPC::ExtDirect::API';

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Instantiate a new API declaration from JavaScript code
#

sub new_from_js {
    my ($class, %params) = @_;
    
    my $config = delete $params{config} || RPC::ExtDirect::Config->new();
    my $js     = delete $params{js};
    
    my $api_href = _decode_api($js);
    
    my $self = $class->SUPER::new_from_hashref(
        config   => $config,
        api_href => $api_href->{actions},
        type     => $api_href->{type},
        url      => $api_href->{url},
        %params,
    );
    
    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Return an Action object or a list of Action objects, depending on context
#

sub actions {
    my ($self, @actions) = @_;

    if ( wantarray ) {
        my @set = @actions ? @actions
                :            keys %{ $self->{actions} }
                ;
        
        my @result = map { $self->get_action_by_name($_) } @set;

        return @result;
    }
    else {
        my $action_name = shift @actions;
        
        return $self->get_action_by_name($action_name);
    };
}

### PUBLIC INSTANCE METHODS ###
#
# Read-write accessors
#

RPC::ExtDirect::Util::Accessor->mk_accessors(
    simple => [qw/ type url /],
);

############## PRIVATE METHODS BELOW ##############

### PRIVATE PACKAGE SUBROUTINE ###
#
# Decode API declaration and check basic constraints
#

sub _decode_api {
    my ($js) = @_;

    $js =~ s/^[^{]+//;
    
    my ($api_js) = eval { JSON->new->utf8(1)->decode_prefix($js) };

    die "Can't decode API declaration: $@\n" if $@;

    die "Empty API declaration\n"
        unless 'HASH' eq ref $api_js;

    die "Unsupported API type\n"
        unless $api_js->{type} =~ /remoting|polling/i;
    
    # Convert the JavaScript API definition to the format
    # API::new_from_hashref expects
    my $actions = $api_js->{actions};
    
    my %remote_actions
        = map { $_ => _convert_action($actions->{$_}) } keys %$actions;
    
    $api_js->{actions} = \%remote_actions;
    
    return $api_js;
}

### PRIVATE PACKAGE SUBROUTINE ###
#
# Convert JavaScript Action definition to remote Action definition
#

sub _convert_action {
    my ($action_def) = @_;
    
    my %methods = map { delete $_->{name} => $_ } @$action_def;
    
    return {
        remote  => 1,
        methods => \%methods,
    };
}

1;
