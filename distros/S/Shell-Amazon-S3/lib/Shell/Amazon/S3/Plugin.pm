package Shell::Amazon::S3::Plugin;

use strict;
use warnings;
use Shell::Amazon::S3::Meta::Plugin;
use Moose::Role ();

sub import {
    my $target = caller;
    my $meta   = Shell::Amazon::S3::Meta::Plugin->initialize($target);
    $meta->alias_method( 'meta' => sub {$meta} );
    goto &Moose::Role::import;
}

1;
