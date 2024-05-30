package Perl::Critic::Policy::Plicease::ProhibitSignaturesAndAtUnderscore;

use strict;
use warnings;
use 5.010001;
use Perl::Critic::Utils qw( $SEVERITY_HIGH );
use base qw( Perl::Critic::Policy );

# ABSTRACT: Prohibit the use of @_ in subroutine using signatures
our $VERSION = '0.07'; # VERSION


use constant DESC => 'Using @_ in a function with signatures';
use constant EXPL => 'The use of @_ in a subroutine that is also using subroutine signatures is experimental.';

sub supported_parameters {
  return ({
    name        => 'signature_enablers',
    description => 'Non-standard modules to recognize as enabling signatures',
    behavior    => 'string list',
  });
}

sub default_severity { $SEVERITY_HIGH }
sub default_themes { () }
sub applies_to { 'PPI::Document' }

sub violates {
  my($self, $elem) = @_;

  my $has_signatures = 0;

  # Check if signatures are enabled
  my $includes = $elem->find('PPI::Statement::Include') || [];
  foreach my $include (@$includes) {
    next unless $include->type eq 'use';

    if(($include->version and version->parse($include->version) >= version->parse('v5.36'))
    || ($include->pragma eq 'feature' and $include =~ m/\bsignatures\b/)
    || ($include->pragma eq 'experimental' and $include =~ m/\bsignatures\b/)
    || ($include->module eq 'Mojo::Base' and $include =~ m/-signatures\b/)
    || ($include->module eq 'Mojolicious::Lite' and $include =~ m/-signatures\b/)
    || (exists $self->{_signature_enablers}{$include->module})) {
      $has_signatures = 1;
    }
  }

  my @violations;

  if($has_signatures) {

    my $subs = $elem->find('PPI::Statement::Sub') || [];
    foreach my $sub (@$subs) {
      next unless defined $sub->prototype;
      my $symbols = $sub->find('PPI::Token::Symbol') || [];
      foreach my $symbol (@$symbols) {
        next unless $symbol->symbol eq '@_';
        push @violations, $self->violation(DESC, EXPL, $symbol);
      }
    }
  }

  return @violations;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Plicease::ProhibitSignaturesAndAtUnderscore - Prohibit the use of @_ in subroutine using signatures

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 sub foo ($$) { my($a,$b) = @_; }                                    # ok
 use experimental qw( signatures ); foo ($a, $b) { my($c,$d) = @_; } # not ok

=head1 DESCRIPTION

When signatures were made non-experimental, C<@_> used in a subroutine that used signatures was kept as
experimental.  This is a problem for a few reasons, for one you don't see the experimental warning
specific to C<@_> unless you are running a Perl after signatures were made non-experimental, for another
as of Perl 5.39.10 this is still experimental.

=head1 AFFILIATION

None.

=head1 CONFIGURATION

This policy can be configured to recognize additional modules as enabling the signatures feature, by
putting an entry in a .perlcriticrc file like this:

 [Community::Prototypes]
 signature_enablers = Plicease::ProhibitSignaturesAndAtUnderscore

=head1 CAVEATS

This module assumes that "prototypes" detected in a source file that has signatures enabled are actually
subroutine signatures.  This is because through static analysis alone it is not possible to determine if
a "prototype" is really a prototype and not a signature.  There thus may be false negatives/positives.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ville Skyttä (SCOP)

Yoshikazu Sawa (yoshikazusawa)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
