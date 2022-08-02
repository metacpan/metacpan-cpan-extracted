package Perl::Critic::Policy::Dancer2::ProhibitDeprecatedKeywords;

our $VERSION = '0.4100'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
# ABSTRACT: Trigger perlcritic alerts on deprecated Dancer2 keywords
use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{
    :booleans :characters :severities :classification :data_conversion
};
use Perl::Critic::Utils::PPI qw{ is_ppi_expression_or_generic_statement };
use base 'Perl::Critic::Policy';

sub default_severity { return $SEVERITY_HIGH }
sub default_themes   { return qw( dancer2 ) }
sub applies_to       { return 'PPI::Token::Word' }

Readonly::Hash my %deprecated_words => (
   context     => 'app',
   header      => 'response_header',
   headers     => 'request_headers',
   push_header => 'push_response_header'
);
Readonly::Scalar my $EXPL =>
    'You are using a Dancer2 keyword that is being or has been deprecated.';

sub violates {
   my ( $self, $elem, $doc ) = @_;

   my $included = $doc->find_any(
      sub {
         $_[1]->isa('PPI::Statement::Include')
             and defined( $_[1]->module() )
             and ( $_[1]->module() eq 'Dancer2' )
             and $_[1]->type() eq 'use';
      }
   );
   return if !$included;
   if ( defined $deprecated_words{$elem} ) {
      return if is_hash_key($elem);
      my $alternative = $deprecated_words{$elem};
      my $desc        = qq{Use '$alternative' instead of deprecated Dancer2 keyword '$elem'};
      return $self->violation( $desc, $EXPL, $elem );
   }
   return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Dancer2::ProhibitDeprecatedKeywords - Trigger perlcritic alerts on deprecated Dancer2 keywords

=head1 VERSION

version 0.4100

=head1 DESCRIPTION

The L<Dancer2> team has a deprecation policy, detailed at
L<Dancer2::DeprecationPolicy>, that will, in time, cause certain
keywords to be removed from the Dancer2 codebase. You should not
use these keywords, to prevent breaking your application when
you update Dancer2 beyond that deprecation point.

=cut

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Dancer2>.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
