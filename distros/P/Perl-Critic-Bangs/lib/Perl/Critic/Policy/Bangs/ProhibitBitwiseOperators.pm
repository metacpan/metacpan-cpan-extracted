package Perl::Critic::Policy::Bangs::ProhibitBitwiseOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.12';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use of bitwise operator};
Readonly::Scalar my $EXPL => q{Use of bitwise operator};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_HIGHEST      }
sub default_themes       { return qw( bangs bugs )       }
sub applies_to           { return 'PPI::Token::Operator' }

#-----------------------------------------------------------------------------

my %bitwise_operators = hashify( qw( & | ^ ~ &= |= ^= ) );

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $content = $elem->content();
    if ( $bitwise_operators{$content} ) {
        return $self->violation( $DESC, qq{$EXPL "$content"}, $elem );
    }
    return;    #ok!
}

1;

__END__
=pod

=head1 NAME

Perl::Critic::Policy::Bangs::ProhibitBitwiseOperators - Bitwise operators are usually accidentally used instead of logical boolean operators.

=head1 AFFILIATION

This Policy is part of the L<Perl::Critic::Bangs> distribution.

=head1 DESCRIPTION

Bitwise operators are usually accidentally used instead of logical
boolean operators.  Instead of writing C<$a || $b>, people will often
write C<$a | $b>, which is not correct.

=head1 CONFIGURATION

This policy cannot be configured.

=head1 AUTHOR

Mike O'Regan <moregan@stresscafe.com>

=head1 COPYRIGHT

Copyright (C) 2006-2017 Andy Lester and Mike O'Regan

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut
