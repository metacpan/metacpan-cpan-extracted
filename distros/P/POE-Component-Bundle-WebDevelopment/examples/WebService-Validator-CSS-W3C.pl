#!perl

use strict;
use warnings;

# VERSION

die "usage: validator.pl <uri_to_validate>\n"
    unless @ARGV;

my $URI_to_validate = shift;

use lib qw(../lib lib);
use POE qw(Component::WebService::Validator::CSS::W3C);

my $poco = POE::Component::WebService::Validator::CSS::W3C->spawn;

POE::Session->create(
    package_states => [
        main => [ qw( _start validated ) ],
    ],
);

$poe_kernel->run;

sub _start {
    $poco->validate( {
            event => 'validated',
            uri => $URI_to_validate,
        }
    );
}

sub validated {
    my $input = $_[ARG0];
    if ( $input->{request_error} ) {
        print "Failed to access validator: $input->{request_error}\n";
    }
    else {
        if ( $input->{is_valid} ) {
            printf "%s is valid! See %s for proof\n",
                        @$input{ qw(uri refer_to_uri) };
        }
        else {
            printf "%s contains %d error(s), see %s\nErrors are:\n",
                        @$input{ qw(uri num_errors refer_to_uri) };

                        use Data::Dumper;
                        print Dumper $input->{errors};
            printf "    %s on line %d\n",
                        @$_{ qw(message line) }
                for @{ $input->{errors} };
        }
    }

    $poco->shutdown;
}

=pod

Usage: perl validator.pl http://page_to_validate.com

=cut
