package RPC::ExtDirect::Test::Util;

use strict;
use warnings;
no  warnings 'uninitialized';

use base 'Exporter';

use Test::More;
use JSON;

our @EXPORT = qw/
    ref_ok
    is_deep
    cmp_api
    prepare_input
/;

our @EXPORT_OK = qw/
    cmp_json
/;

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Replacement for isa_ok that actually checks that wanted value
# is a blessed object and not a string with package name. :(
#

sub ref_ok {
    my ($have, $want, $desc) = @_;

    $desc = "Object isa $want" unless $desc;

    ok( (ref $have eq $want) && $have->isa($want), $desc )
        or diag explain "Expected '", $have, "' to be an object blessed into ",
                        $want, " package";
}

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# A wrapper around Test::More::is_deeply() that will print
# the diagnostics if a test fails
#

sub is_deep {
    is_deeply @_ or diag explain "Expected: ", $_[1], "Actual: ", $_[0];
}

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Compare two JavaScript API declarations
#

sub cmp_api {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($have, $want, $desc) = @_;
    
    $have = deparse_api($have) unless ref $have;
    $want = deparse_api($want) unless ref $want;
    
    is_deep $have, $want, $desc;
}

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Compare two strings ignoring the whitespace
#

sub cmp_str {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($have, $want, $desc) = @_;
    
    $_ =~ s/\s//g for ($have, $want);
    
    is $have, $want, $desc;
}

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Compare two JSON structures, ignoring the whitespace
#

sub cmp_json {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($have_json, $want_json, $desc) = @_;
    
    $_ =~ s/\s//g for ($have_json, $want_json);
    
    my $have = JSON::from_json($have_json);
    my $want = JSON::from_json($want_json);
    
    is_deep $have, $want, $desc;
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Deparse and normalize a JavaScript string with Ext.Direct API
# declaration into Perl data structures suitable for deep comparison
#

sub deparse_api {
    my ($api_str) = @_;
    
    $api_str =~ s/\s*//gms;

    my @parts = split /;\s*/, $api_str;

    for my $part ( @parts ) {
        next unless $part =~ /=\{/;

        my ($var, $json) = split /=/, $part;
        
        my $api_def = JSON::from_json($json);
        
        my $actions = sort_action_methods($api_def->{actions});

        if ( defined $actions ) {
            $api_def->{actions} = $actions;
        }

        $part = { $var => $api_def };
    }

    return [ @parts ];
}

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Convert a test input hashref into the actual object
#

sub prepare_input {
    my ($mod, $input) = @_;
    
    return $input unless ref $input;
    
    # Package name should be in the RPC::ExtDirect::Test::Util namespace
    my $pkg = __PACKAGE__.'::'.$mod;
    
    # Convertor sub name goes first
    my $conv = $input->{type};
    my $arg  = $input->{arg};
    
    # Calling the sub as a class method is easier
    # than taking its ref, blah blah
    my $result = $pkg->$conv(@$arg);
    
    return $result;
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Sort the Method hashrefs on an Action object
#

sub sort_action_methods {
    my ($api_href) = @_;

    # %$api_href will auto-vivify if $api_href is undef
    # This can bite your ass.
    return unless $api_href;
    
    my $new_href = {};
    
    # map() looks too unwieldy here
    for my $action_name ( keys %$api_href ) {
        my @methods = @{ $api_href->{ $action_name } };
        
        $new_href->{ $action_name }
            = [ sort { $a->{name} cmp $b->{name} } @methods ];
    }
    
    return $new_href;
}

1;

