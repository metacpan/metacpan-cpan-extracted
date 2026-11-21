package TUI::Help;
# ABSTRACT: Help-related modules for the framework

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Help::Const;
use TUI::Help::HelpBase;
use TUI::Help::RefTable;
use TUI::Help::TopicDefinition;
use TUI::Help::HelpTopic;
use TUI::Help::HelpIndex;
use TUI::Help::HelpFile;
use TUI::Help::HelpViewer;
use TUI::Help::HelpWindow;

sub import {
  my $target = caller;
  TUI::Help::Const->import::into( $target, qw( :all ) );
  TUI::Help::RefTable->import::into( $target );
  TUI::Help::TopicDefinition->import::into( $target );
  TUI::Help::HelpTopic->import::into( $target );
  TUI::Help::HelpIndex->import::into( $target );
  TUI::Help::HelpFile->import::into( $target );
  TUI::Help::HelpViewer->import::into( $target );
  TUI::Help::HelpWindow->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::Help::Const->unimport::out_of( $caller );
  TUI::Help::RefTable->unimport::out_of( $caller );
  TUI::Help::TopicDefinition->unimport::out_of( $caller );
  TUI::Help::HelpTopic->unimport::out_of( $caller );
  TUI::Help::HelpIndex->unimport::out_of( $caller );
  TUI::Help::HelpFile->unimport::out_of( $caller );
  TUI::Help::HelpViewer->unimport::out_of( $caller );
  TUI::Help::HelpWindow->unimport::out_of( $caller );
}


1

__END__

=head1 NAME

TUI::Help - Help-related modules for the framework

=head1 SYNOPSIS

  use TUI::Help;

  open my $stream, '<:raw', 'help.hlp' or die;
  my $hFile = THelpFile->new( stream => $stream );
  my $window = THelpWindow->new(
    hFile   => $hFile,
    context => 0,
  );

=head1 DESCRIPTION

C<TUI::Help> provides help-related view classes and functionality for the 
L<TUI::Vision> framework.

The module loads L<TUI::Help::HelpBase>, which defines the C<TParagraph>,
C<TCrossRef>, and C<TReference> records. They are not re-exported.

This module re-exports symbols from the following modules:

=over 4

=item * L<TUI::Help::Const> -
Symbolic constants for help behavior, including C<MAXHELPTOPICID>, the
C<:cXXXX> palette constants, and the C<:wrapXXXX> state constants.

=item * L<TRefTable|TUI::Help::RefTable>
Sorted symbol table of topic references, including C<TRefTable> and
C<new_TRefTable>.

=item * L<THelpIndex|TUI::Help::HelpIndex>
Help context position index, including C<THelpIndex> and C<new_THelpIndex>.

=item * L<TTopicDefinition|TUI::Help::TopicDefinition>
Linked topic definition, including C<TTopicDefinition> and
C<new_TTopicDefinition>.

=item * L<THelpTopic|TUI::Help::HelpTopic>
Paragraph text, wrapping, and cross-references, including C<THelpTopic>
and C<new_THelpTopic>, with C<Storable> persistence.

=item * L<THelpFile|TUI::Help::HelpFile>
Help file source and topic lookup, including C<THelpFile> and
C<new_THelpFile>.

=item * L<THelpViewer|TUI::Help::HelpViewer>
Scrollable help topic view, including C<THelpViewer> and
C<new_THelpViewer>.

=item * L<THelpWindow|TUI::Help::HelpWindow>
Centered help window hosting a C<THelpViewer>, including C<THelpWindow> and
C<new_THelpWindow>.

=back

Help related views are responsible for displaying and managing help content 
within the framework's user interface. The design is inspired by the Borland
I<Turbo Vision> help framework, so behavior and naming may resemble the
original where practical.

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).
