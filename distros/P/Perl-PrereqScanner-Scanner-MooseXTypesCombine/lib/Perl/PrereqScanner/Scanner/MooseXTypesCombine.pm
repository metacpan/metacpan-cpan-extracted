#
# This file is part of Perl-PrereqScanner-Scanner-MooseXTypesCombine
#
# This software is copyright (c) 2012 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Perl::PrereqScanner::Scanner::MooseXTypesCombine;
{
  $Perl::PrereqScanner::Scanner::MooseXTypesCombine::VERSION = '0.001';
}
# git description: b29ba10

BEGIN {
  $Perl::PrereqScanner::Scanner::MooseXTypesCombine::AUTHORITY = 'cpan:RWSTAUNER';
}
use Moose;
with 'Perl::PrereqScanner::Scanner';
# ABSTRACT: Scan for type libraries exported with MooseX::Types::Combine

use List::MoreUtils qw( any );
use Params::Util ();


sub scan_for_prereqs {
  my ($self, $ppi_doc, $req) = @_;

  # * split doc into chunks by package (very tricky - PPI does not support this yet)
  # * for each package:
  # * check for base/parent/isa
  # * find provide_types_from
  # * find quoted words

  foreach my $chunk ( $ppi_doc ){
    my @prereqs = $self->_determine_inheritance_from_mxtc($chunk);

    # short-circuit if it doesn't look like this package isa mxtc
    next unless @prereqs;

    # find the method call that sets the types being exported
    my $methods = $chunk->find(sub {
      $_[1]->isa('PPI::Token::Word') and $_[1]->content eq 'provide_types_from'
    }) || [];

    # parse the statements that contain the method call we just searched for
    push @prereqs, $self->_parse_mxtypes_from_statement($_)
      for map { $_->parent } @$methods;

    $req->add_minimum($_ => 0) for @prereqs;
  }
}

# There should be a 'use base', 'use parent', or '@ISA = ' (or 'push @ISA')
# somewhere that includes MooseX::Types::Combine.
sub _determine_inheritance_from_mxtc {
  my ($self, $ppi_doc) = @_;
  my @modules;
  my $mxtc = 'MooseX::Types::Combine';

  # NOTE: Similar logic is found in some of the scanners;
  # perhaps this could be refactored into something reusable.

  # find "use base" or "use parent"
  my $includes = $ppi_doc->find('Statement::Include') || [];
  for my $node ( @$includes ) {
    if (grep { $_ eq $node->module } qw{ base parent }) {
      my @meat = grep {
           $_->isa('PPI::Token::QuoteLike::Words')
        || $_->isa('PPI::Token::Quote')
      } $node->arguments;

      my @parents = map { $self->_q_contents($_) } @meat;

      # the main scanner should pick up base/parent and mxtc
      # but it's easy enough to add them here, so do it for completeness
      push @modules, $node->module, $mxtc
        if any { $_ eq $mxtc } @parents;
    }
  }

  return @modules if @modules;

  # if there was no base/parent, look for any statement that mentions @ISA
  my $isa = $ppi_doc->find(sub {
    $_[1]->isa('PPI::Token::Symbol') && $_[1]->content eq '@ISA'
  }) || [];
  $isa = [ map { $_->parent } @$isa ];

  # See if any of those @ISA statements include our module.
  # This is far from foolproof, but probably good enough.
  @modules = $mxtc
    if any { $_->find_any(sub {
        (
          $_[1]->isa('PPI::Token::QuoteLike::Words') ||
          $_[1]->isa('PPI::Token::Quote')
        ) &&
          any { $_ eq $mxtc } $self->_q_contents($_[1])
      });
    } @$isa;

  # take care to always return a list
  return @modules;
}

sub _parse_mxtypes_from_statement {
  my ($self, $statement) = @_;

  # this is naive and very specific but it matches the MXTC synopsis
  my $wanted = [
    [ Word     => '__PACKAGE__' ],
    [ Operator => '->' ],
    [ Word     => 'provide_types_from' ],
  ];

  my @tokens = $statement->schildren;
  my $i = 0;
  # check that the statement matches $wanted
  foreach my $token ( @tokens ){
    my ($type, $content) = @{ $wanted->[$i++] };
    return
      unless $token->isa('PPI::Token::' . $type)
        and $token->content eq $content;
    last if $i == @$wanted;
  }

  # the list passed to this method is what we are looking for
  my $list = $tokens[$i];
  return
    unless $list && $list->isa('PPI::Structure::List');

  # this expects quoted module names and won't work if vars are passed
  my $words = $list->find(sub {
    $_[1]->isa('PPI::Token::QuoteLike::Words') ||
    $_[1]->isa('PPI::Token::Quote')
  }) || [];

  return
    grep { Params::Util::_CLASS($_) }
    map  { $self->_q_contents($_) }
      @$words;
}

1;


__END__
=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS cpan testmatrix url annocpan anno bugtracker
rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Perl::PrereqScanner::Scanner::MooseXTypesCombine - Scan for type libraries exported with MooseX::Types::Combine

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  Perl::PrereqScanner->new( extra_scanners => ['MooseXTypesCombine'] );

Or with L<Dist::Zilla::Plugin::AutoPrereqs>:

  # dist.ini
  [AutoPrereqs]
  extra_scanners = MooseXTypesCombine

=head1 DESCRIPTION

This scanner will look for L<MooseX::Types> libraries
exported via L<MooseX::Types::Combine>.

It is currently very naive and very specific
but works for simple cases like this:

  package MyTypes;
  use parent 'MooseX::Types::Combine';

  __PACKAGE__->provide_types_from(qw(
    MooseX::Types::Moose
    MooseX::Types::Path::Class
  ));

As always patches and bug reports are welcome.

=for Pod::Coverage scan_for_prereqs

=head1 SEE ALSO

=over 4

=item *

L<Perl::PrereqScanner>

=item *

L<Dist::Zilla::Plugin::AutoPrereqs>

=item *

L<MooseX::Types::Combine>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Perl::PrereqScanner::Scanner::MooseXTypesCombine

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Perl-PrereqScanner-Scanner-MooseXTypesCombine>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-PrereqScanner-Scanner-MooseXTypesCombine>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Perl-PrereqScanner-Scanner-MooseXTypesCombine>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/P/Perl-PrereqScanner-Scanner-MooseXTypesCombine>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Perl-PrereqScanner-Scanner-MooseXTypesCombine>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Perl::PrereqScanner::Scanner::MooseXTypesCombine>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-perl-prereqscanner-scanner-moosextypescombine at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-PrereqScanner-Scanner-MooseXTypesCombine>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Perl-PrereqScanner-Scanner-MooseXTypesCombine>

  git clone https://github.com/rwstauner/Perl-PrereqScanner-Scanner-MooseXTypesCombine.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

