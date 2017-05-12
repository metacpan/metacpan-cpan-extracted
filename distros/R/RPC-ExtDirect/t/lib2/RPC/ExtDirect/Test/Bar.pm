package RPC::ExtDirect::Test::Bar;

use strict;
use warnings;
no  warnings 'uninitialized';

use base 'RPC::ExtDirect::Test::Foo';

# Define package scope hooks
use RPC::ExtDirect BEFORE => \&bar_before, after => \&bar_after;

use Carp;

# This one croaks merrily
sub bar_foo : ExtDirect(4) { croak 'bar foo!' }

# Return number of passed arguments
sub bar_bar : ExtDirect(5) { shift; return scalar @_; }

# This is a form handler
sub bar_baz : ExtDirect( formHandler ) {
    my ($class, %param) = @_;

    delete $param{_env};

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
