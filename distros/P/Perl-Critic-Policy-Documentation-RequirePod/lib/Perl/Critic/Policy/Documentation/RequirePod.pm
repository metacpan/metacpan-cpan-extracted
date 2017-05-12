package Perl::Critic::Policy::Documentation::RequirePod;
# ABSTRACT: file requires POD
$Perl::Critic::Policy::Documentation::RequirePod::VERSION = '0.005';
use utf8;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent qw(Perl::Critic::Policy);

Readonly::Scalar my $DESC => q{file requires POD};
Readonly::Scalar my $EXPL =>
    q{Missing POD in the current file};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw(core pbp maintenance) }
sub applies_to           { return qw(PPI::Document) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # This policy does not apply unless there is some real code in the
    # file.  For example, if this file is just pure POD, then
    # presumably this file is ancillary documentation and you can use
    # whatever headings you want.
    return if ! $doc->schild(0);

    my $pods_ref = $doc->find('PPI::Token::Pod');

    return if $pods_ref;

    return $self->violation( $DESC, $EXPL, $elem );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Documentation::RequirePod - file requires POD

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This policy requires your code to contain POD.

=head1 AUTHOR

Andreas Schröter <andreas.schroeter@autinity.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by afr-consulting GmbH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
