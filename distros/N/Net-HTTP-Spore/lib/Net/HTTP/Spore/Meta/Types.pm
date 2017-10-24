package Net::HTTP::Spore::Meta::Types;
$Net::HTTP::Spore::Meta::Types::VERSION = '0.07';
# ABSTRACT: Moose type definitions for Net::HTTP::Spore

use Moose::Util::TypeConstraints;
use MooseX::Types -declare => [ qw(UriPath Boolean HTTPMethod JSONBoolean) ];
use MooseX::Types::Moose qw(Str Int Defined);
use JSON;

subtype UriPath,
    as Str,
    where { $_ =~ m!^/! },
    message {"path must start with /"};

enum HTTPMethod, [qw(OPTIONS HEAD GET POST PUT DELETE TRACE PATCH)];

subtype Boolean,
    as Int,
    where { $_ eq 1 || $_ eq 0 };

subtype JSONBoolean,
    as Defined,
    where { JSON::is_bool($_) };

coerce Boolean,
    from JSONBoolean,
      via { return $_ == JSON::true() ? 1 : 0 },
    from Str,
      via { return $_ eq 'true' ? 1 : 0 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Spore::Meta::Types - Moose type definitions for Net::HTTP::Spore

=head1 VERSION

version 0.07

=head1 AUTHORS

=over 4

=item *

Franck Cuny <franck.cuny@gmail.com>

=item *

Ash Berlin <ash@cpan.org>

=item *

Ahmad Fatoum <athreef@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
