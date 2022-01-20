package MooseX::Types::JSON;

use strict;
use warnings;
use 5.008003;

# ABSTRACT: JSON datatype for Moose
our $VERSION = '1.01'; # VERSION


use MooseX::Types -declare => [qw/ JSON relaxedJSON /];
use Moose::Util::TypeConstraints;
use JSON ();  ## no critic (Community::PreferredAlternatives)

subtype JSON,
  as "Str",
  where { ref( eval { 'JSON'->new->decode($_) } ) ne '' },
  message { "Must be valid JSON" };

coerce JSON,
  from 'Defined',
    via { 'JSON'->new->allow_nonref->encode($_) };

subtype relaxedJSON,
  as "Str",
  where { ref( eval { 'JSON'->new->relaxed->decode($_) } ) ne '' },
  message { "Must be at least relaxed JSON" };

coerce relaxedJSON,
  from 'Defined',
    via { 'JSON'->new->allow_nonref->encode($_) };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::JSON - JSON datatype for Moose

=head1 VERSION

version 1.01

=head1 SYNOPSIS

 package Foo;
 
 use Moose;
 use Moose::Util::TypeConstraints;
 use MooseX::Types::JSON qw( JSON relaxedJSON );
 
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

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Steve Huff

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014,2022 by Michael Langner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
