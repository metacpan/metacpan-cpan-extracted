package Net::WAMP::Client::Features;

use strict;
use warnings;

our %FEATURES;

#sub get_features_hr {
#    return \%FEATURES;
#}
#
#sub register_role_feature {
#    my (@parts) = @_;
#
#    my ($final_key, $value) = splice( @parts, -2 );
#
#    my $hr = \%FEATURES;
#
#    while (@parts) {
#        $hr = $hr->{shift @parts};
#    }
#
#    $hr->{$final_key} = $value;
#
#    return;
#}

1;
