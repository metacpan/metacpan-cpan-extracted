use strict;
use warnings;
package Pod::Weaver::PluginBundle::Default 4.018;
# ABSTRACT: a bundle for the most commonly-needed prep work for a pod document

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

#pod =head1 OVERVIEW
#pod
#pod This is the bundle used by default (specifically by Pod::Weaver's
#pod C<new_with_default_config> method).  It may change over time, but should remain
#pod fairly conservative and straightforward.
#pod
#pod It is nearly equivalent to the following:
#pod
#pod   [@CorePrep]
#pod
#pod   [-SingleEncoding]
#pod
#pod   [Name]
#pod   [Version]
#pod
#pod   [Region  / prelude]
#pod
#pod   [Generic / SYNOPSIS]
#pod   [Generic / DESCRIPTION]
#pod   [Generic / OVERVIEW]
#pod
#pod   [Collect / ATTRIBUTES]
#pod   command = attr
#pod
#pod   [Collect / METHODS]
#pod   command = method
#pod
#pod   [Collect / FUNCTIONS]
#pod   command = func
#pod
#pod   [Leftovers]
#pod
#pod   [Region  / postlude]
#pod
#pod   [Authors]
#pod   [Legal]
#pod
#pod =cut

use namespace::autoclean;

use Pod::Weaver::Config::Assembler;
sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
  return (
    [ '@Default/CorePrep',        _exp('@CorePrep'), {} ],
    [ '@Default/SingleEncoding',  _exp('-SingleEncoding'), {} ],
    [ '@Default/Name',            _exp('Name'),      {} ],
    [ '@Default/Version',         _exp('Version'),   {} ],

    [ '@Default/prelude',   _exp('Region'),    { region_name => 'prelude'  } ],
    [ 'SYNOPSIS',           _exp('Generic'),   {} ],
    [ 'DESCRIPTION',        _exp('Generic'),   {} ],
    [ 'OVERVIEW',           _exp('Generic'),   {} ],

    [ 'ATTRIBUTES',         _exp('Collect'),   { command => 'attr'   } ],
    [ 'METHODS',            _exp('Collect'),   { command => 'method' } ],
    [ 'FUNCTIONS',          _exp('Collect'),   { command => 'func'   } ],

    [ '@Default/Leftovers', _exp('Leftovers'), {} ],

    [ '@Default/postlude',  _exp('Region'),    { region_name => 'postlude' } ],

    [ '@Default/Authors',   _exp('Authors'),   {} ],
    [ '@Default/Legal',     _exp('Legal'),     {} ],
  )
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Default - a bundle for the most commonly-needed prep work for a pod document

=head1 VERSION

version 4.018

=head1 OVERVIEW

This is the bundle used by default (specifically by Pod::Weaver's
C<new_with_default_config> method).  It may change over time, but should remain
fairly conservative and straightforward.

It is nearly equivalent to the following:

  [@CorePrep]

  [-SingleEncoding]

  [Name]
  [Version]

  [Region  / prelude]

  [Generic / SYNOPSIS]
  [Generic / DESCRIPTION]
  [Generic / OVERVIEW]

  [Collect / ATTRIBUTES]
  command = attr

  [Collect / METHODS]
  command = method

  [Collect / FUNCTIONS]
  command = func

  [Leftovers]

  [Region  / postlude]

  [Authors]
  [Legal]

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
