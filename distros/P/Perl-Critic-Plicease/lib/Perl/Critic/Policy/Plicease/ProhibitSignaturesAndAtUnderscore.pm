package Perl::Critic::Policy::Plicease::ProhibitSignaturesAndAtUnderscore;

use strict;
use warnings;
use 5.010001;
use Perl::Critic::Utils qw( $SEVERITY_HIGH );
use base qw( Perl::Critic::Policy );

# ABSTRACT: Prohibit the use of @_ in subroutine using signatures
our $VERSION = '0.09'; # VERSION


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
      next unless( $PPI::Document::VERSION > 1.279 ?
        @{$sub->find('PPI::Structure::Signature') || []} : defined $sub->prototype );

      foreach my $symbol ( _recurse($sub->schildren) ) {
        push @violations, $self->violation(DESC, EXPL, $symbol);
      }
    }
  }

  return @violations;
}

# since PPI doesn't detect anonymous subroutines...
# look to ignore a PPI::Token::Word with `sub` followed by sibling PPI::Structure::Block

sub _recurse {
  my @ret;
  my(@children) = @_;
  for my $i (0..$#children) {
    next if $children[$i]->isa('PPI::Statement::Sub');
    next if $i >= 1 && $children[$i]->isa('PPI::Structure::Block') && $children[$i-1]->isa('PPI::Token::Word') && $children[$i-1]->literal eq 'sub';

    if($children[$i]->isa('PPI::Token::Symbol') && $children[$i]->symbol eq '@_') {
      push @ret, $children[$i];
    } elsif($children[$i]->can('schildren')) {
      push @ret, _recurse($children[$i]->schildren);
    }
  }
  return @ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Plicease::ProhibitSignaturesAndAtUnderscore - Prohibit the use of @_ in subroutine using signatures

=head1 VERSION

version 0.09

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

 [Plicease::ProhibitSignaturesAndAtUnderscore]
 signature_enablers = Foo::Bar

=head1 CAVEATS

For older versions of L<PPI> (newer version is yet unreleased as of this writing), this module assumes
that "prototypes" detected in a source file that has signatures enabled are actually subroutine signatures.
This is because through static analysis alone it is not possible to determine if a "prototype" is really a
prototype and not a signature.  There thus may be false negatives/positives.  Future versions of this module
will require a L<PPI> with better signature detection.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ville Skyttä (SCOP)

Yoshikazu Sawa (yoshikazusawa)

Christian Walde (wchristian, MITHALDU)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
