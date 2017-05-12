package Net::Route::Parser::Test;
use strict;
use warnings;
use version; our ( $VERSION ) = '$Revision: 254 $' =~ m{(\d+)}xms;
use Moose;

extends 'Net::Route::Parser';

has 'command_line' => (
    is => 'rw',
);

sub parse_routes {
    return [];
}
    
no Moose;
__PACKAGE__->meta->make_immutable();
1;
