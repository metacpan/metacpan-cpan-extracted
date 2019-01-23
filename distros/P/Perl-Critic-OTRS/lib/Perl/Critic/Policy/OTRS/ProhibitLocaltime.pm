package Perl::Critic::Policy::OTRS::ProhibitLocaltime;

# ABSTRACT: do not use "localtime"

use strict;
use warnings;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

use Readonly;

our $VERSION = '0.03';

Readonly::Scalar my $DESC => q{Use of "localtime" is not allowed};
Readonly::Scalar my $EXPL => q{Use methods of TimeObject instead.};

sub supported_parameters { return; }
sub default_severity     { return $SEVERITY_HIGHEST; }
sub default_themes       { return qw( otrs otrs_lt_3_3 ) }
sub applies_to           { return 'PPI::Token::Word'  }

sub violates {
    my ( $self, $elem ) = @_;

    return if $elem ne 'localtime';
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::OTRS::ProhibitLocaltime - do not use "localtime"

=head1 VERSION

version 0.09

=head1 METHODS

=head2 supported_parameters

There are no supported parameters.

=head1 AUTHOR

Renee Baecker <info@perl-services.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
