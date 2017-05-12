package System::InitD::GenInit::Centos;

use parent qw/System::InitD::Base/;

use strict;
use warnings;

use Carp;

use File::ShareDir qw/dist_file/;

use constant TEMPLATE => 'centos.tpl';


sub generate {
    if ( !ref $_[0] && $_[0] eq __PACKAGE__ ) {
        shift;
    }
    else {
        croak 'Bad params';
    }
    my ($options) = @_;

    my $generator = __PACKAGE__->new($options);

    my $data_location = dist_file('System-InitD', TEMPLATE);
    
    # пока-что так, MVP
    $generator->forward_render_params($options, keys %$options);

    $generator->write_script($data_location);
    return 1;
};


1;

__END__
