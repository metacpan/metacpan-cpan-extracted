package Plack::Handler::Stomp::Types;
$Plack::Handler::Stomp::Types::VERSION = '1.15';
{
  $Plack::Handler::Stomp::Types::DIST = 'Plack-Handler-Stomp';
}
use MooseX::Types -declare =>
    [qw(
           Logger
           PathMapKey Path
           PathMap
   )];
use MooseX::Types::Moose qw(Str);
use MooseX::Types::Structured qw(Map);
use MooseX::Types::Common::String qw(NonEmptySimpleStr);
use namespace::autoclean;

# ABSTRACT: type definitions for Plack::Handler::Stomp


duck_type Logger, [qw(trace debug info
                      warn error)];


subtype PathMapKey, as Str,
    where { m{^/(?:queue|topic|subscription)/} };


subtype Path, as NonEmptySimpleStr;


subtype PathMap, as Map[PathMapKey,Path];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Handler::Stomp::Types - type definitions for Plack::Handler::Stomp

=head1 VERSION

version 1.15

=head1 TYPES

=head2 C<Logger>

Any object that can C<trace>, C<debug>, C<info>, C<warn>, C<error>.

=head2 C<PathMapKey>

A string starting with C</queue/>, C</topic/> or C</subscription/>.

=head2 C<Path>

A non-empty string.

=head2 C<PathMap>

A hashref with keys maching L</PathMapKey> and values maching L</Path>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
