package # hide from PAUSE
    JSON_DOT_PM;

use base JSON;

package MooseX::Types::JSON;
$MooseX::Types::JSON::VERSION = '1.00';
use strict;
use warnings;

=head1 NAME

MooseX::Types::JSON - JSON datatype for Moose

=head1 SYNOPSIS

 package Foo;

 use Moose;
 use Moose::Util::TypeConstraints;
 use MooseX::Types::JSON qw( JSON );

 has config  => ( is => 'rw', isa => JSON        );
 has options => ( is => 'rw', isa => relaxedJSON );
 
String type constraints that match valid and relaxed JSON. For the meaning of
'relaxed' see L<JSON>. All the heavy lifting in the background is also
done by L<JSON>.

Coercions from Defined types are included.

=over

=item * JSON

A Str that is valid JSON.

=item * relaxedJSON

A Str that is 'relaxed' JSON. For the meaning of 'relaxed' see L<JSON>. 

=back
=cut

use MooseX::Types -declare => [qw/ JSON relaxedJSON /];
use Moose::Util::TypeConstraints;

subtype JSON,
  as "Str",
  where { ref( eval { JSON_DOT_PM->new->decode($_) } ) ne '' },
  message { "Must be valid JSON" };

coerce JSON,
  from 'Defined',
    via { JSON_DOT_PM->new->allow_nonref->encode($_) };

subtype relaxedJSON,
  as "Str",
  where { ref( eval { JSON_DOT_PM->new->relaxed->decode($_) } ) ne '' },
  message { "Must be at least relaxed JSON" };

coerce relaxedJSON,
  from 'Defined',
    via { JSON_DOT_PM->new->allow_nonref->encode($_) };

=head1 CONTRIBUTORS

Steve Huff

=head1 AUTHOR

Michael Langner

=head1 CONTRIBUTING 

If you'd like to contribute, just fork my repository
(L<http://github.com/cpan-mila/perl-moosex-types-json>)
on Github, commit your changes and send me a pull request.

=head1 BUGS

Please report any bugs or feature requests at
L<http://github.com/cpan-mila/perl-moosex-types-json/issues>.

=head1 COPYRIGHT & LICENSE

Copyright 2014 Michael Langner, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

1; # track-id: 3a59124cfcc7ce26274174c962094a20
