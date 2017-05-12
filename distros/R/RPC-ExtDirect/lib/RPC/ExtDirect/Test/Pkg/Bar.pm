#
# WARNING WARNING WARNING
#
# DO NOT CHANGE ANYTHING IN THIS MODULE. OTHERWISE, A LOT OF API
# AND OTHER TESTS MAY BREAK.
#
# This module is here to test certain behaviors. If you need
# to test something else, add another test module.
# It's that simple.
#

# This does not need to be indexed by PAUSE
package
    RPC::ExtDirect::Test::Pkg::Bar;

use strict;
use warnings;
no  warnings 'uninitialized';

use base 'RPC::ExtDirect::Test::Pkg::Foo';

# Define package scope hooks
use RPC::ExtDirect BEFORE => \&bar_before, after => \&bar_after;

use Carp;

# This one croaks merrily
sub bar_foo : ExtDirect(4) { croak 'bar foo!' }

# Return the number of passed arguments
sub bar_bar : ExtDirect(5) { shift; return scalar @_; }

# This is a form handler
sub bar_baz : ExtDirect(formHandler, decode_params => [qw/frob guzzard/]) {
    my ($class, %param) = @_;

    # Simulate uploaded file handling
    my $uploads = $param{file_uploads};
    return \%param unless $uploads;

    # Return 'uploads' data
    my $response = "The following files were processed:\n";
    for my $upload ( @$uploads ) {
        my $name = $upload->{basename};
        my $type = $upload->{type};
        my $size = $upload->{size};

        $response .= "$name $type $size\n";
    };

    delete $param{file_uploads};
    $param{upload_response} = $response;

    return \%param;
}

sub bar_before {
    return 1;
}

sub bar_after {
}

1;
