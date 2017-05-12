package Silki::JSON;
{
  $Silki::JSON::VERSION = '0.29';
}

use strict;
use warnings;

use JSON::XS;

{
    my $json = JSON::XS->new();
    $json->pretty(1);
    $json->utf8(1);

    sub Encode { $json->encode( $_[1] ) }

    sub Decode { $json->decode( $_[1] ) }
}

1;

# ABSTRACT: A thin wrapper around a JSON::XS object

__END__
=pod

=head1 NAME

Silki::JSON - A thin wrapper around a JSON::XS object

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

