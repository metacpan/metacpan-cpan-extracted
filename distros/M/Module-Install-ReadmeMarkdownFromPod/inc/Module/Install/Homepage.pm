#line 1
package Module::Install::Homepage;

use strict;
use warnings;
use 5.006;

our $VERSION = '0.01';

use base qw(Module::Install::Base);

sub auto_set_homepage {
    my $self = shift;
    if ($self->name) {
        $self->homepage(sprintf "http://search.cpan.org/dist/%s/", $self->name)
    } else {
        warn "can't set homepage if 'name' is not set\n";
    }
}

1;

__END__

#line 93

