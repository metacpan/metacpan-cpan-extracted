package Pod::Weaver;
# ABSTRACT: weave together a Pod document from an outline
$Pod::Weaver::VERSION = '4.017';
use Moose;
use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod   my $weaver = Pod::Weaver->new_with_default_config;
#pod
#pod   my $document = $weaver->weave_document({
#pod     pod_document => $pod_elemental_document,
#pod     ppi_document => $ppi_document,
#pod
#pod     license  => $software_license,
#pod     version  => $version_string,
#pod     authors  => \@author_names,
#pod   })
#pod
#pod =head1 DESCRIPTION
#pod
#pod Pod::Weaver is a system for building Pod documents from templates.  It doesn't
#pod perform simple text substitution, but instead builds a
#pod Pod::Elemental::Document.  Its plugins sketch out a series of sections
#pod that will be produced based on an existing Pod document or other provided
#pod information.
#pod
#pod =cut

use File::Spec;
use Log::Dispatchouli 1.100710; # proxy
use Pod::Elemental 0.100220;
use Pod::Elemental::Document;
use Pod::Weaver::Config::Finder;
use Pod::Weaver::Role::Plugin;
use String::Flogger 1;

#pod =attr logger
#pod
#pod This attribute stores the logger, which must provide a log method.  The
#pod weaver's log method delegates to the logger's log method.
#pod
#pod =cut

has logger => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Log::Dispatchouli->new({
      ident     => 'Pod::Weaver',
      to_stdout => 1,
      log_pid   => 0,
    });
  },
  handles => [ qw(log log_fatal log_debug) ]
);

#pod =attr plugins
#pod
#pod This attribute is an arrayref of objects that can perform the
#pod L<Pod::Weaver::Role::Plugin> role.  In general, its contents are found through
#pod the C<L</plugins_with>> method.
#pod
#pod =cut

has plugins => (
  is  => 'ro',
  isa => 'ArrayRef[Pod::Weaver::Role::Plugin]',
  required => 1,
  lazy     => 1,
  init_arg => undef,
  default  => sub { [] },
);

#pod =method plugins_with
#pod
#pod   my $plugins_array_ref = $weaver->plugins_with('-Section');
#pod
#pod This method will return an arrayref of plugins that perform the given role, in
#pod the order of their registration.  If the role name begins with a hyphen, the
#pod method will prepend C<Pod::Weaver::Role::>.
#pod
#pod =cut

sub plugins_with {
  my ($self, $role) = @_;

  $role =~ s/^-/Pod::Weaver::Role::/;
  my @plugins = grep { $_->does($role) } @{ $self->plugins };

  return \@plugins;
}

#pod =method weave_document
#pod
#pod   my $document = $weaver->weave_document(\%input);
#pod
#pod This is the most important method in Pod::Weaver.  Given a set of input
#pod parameters, it will weave a new document.  Different section plugins will
#pod expect different input parameters to be present, but some common ones include:
#pod
#pod   pod_document - a Pod::Elemental::Document for the original Pod document
#pod   ppi_document - a PPI document for the source of the module being documented
#pod   license      - a Software::License object for the source module's license
#pod   version      - a version (string) to use in produced documentation
#pod
#pod The C<pod_document> should have gone through a L<Pod5
#pod transformer|Pod::Elemental::Transformer::Pod5>, and should probably have had
#pod its C<=head1> elements L<nested|Pod::Elemental::Transformer::Nester>.
#pod
#pod The method will return a new Pod::Elemental::Document.  The input documents may
#pod be destructively altered during the weaving process.  If they should be
#pod untouched, pass in copies.
#pod
#pod =cut

sub weave_document {
  my ($self, $input) = @_;

  my $document = Pod::Elemental::Document->new;

  for (@{ $self->plugins_with(-Preparer) }) {
    $_->prepare_input($input);
  }

  for (@{ $self->plugins_with(-Dialect) }) {
    $_->translate_dialect($input->{pod_document});
  }

  for (@{ $self->plugins_with(-Transformer) }) {
    $_->transform_document($input->{pod_document});
  }

  for (@{ $self->plugins_with(-Section) }) {
    $_->weave_section($document, $input);
  }

  for (@{ $self->plugins_with(-Finalizer) }) {
    $_->finalize_document($document, $input);
  }

  return $document;
}

#pod =method new_with_default_config
#pod
#pod This method returns a new Pod::Weaver with a stock configuration by using only
#pod L<Pod::Weaver::PluginBundle::Default>.
#pod
#pod =cut

sub new_with_default_config {
  my ($class, $arg) = @_;

  my $assembler = Pod::Weaver::Config::Assembler->new;

  my $root = $assembler->section_class->new({ name => '_' });
  $assembler->sequence->add_section($root);

  $assembler->change_section('@Default');
  $assembler->end_section;

  return $class->new_from_config_sequence($assembler->sequence, $arg);
}

sub new_from_config {
  my ($class, $arg, $new_arg) = @_;

  my $root = $arg->{root} || '.';
  my $name = File::Spec->catfile($root, 'weaver');
  my ($sequence) = Pod::Weaver::Config::Finder->new->read_config($name);

  return $class->new_from_config_sequence($sequence, $new_arg);
}

sub new_from_config_sequence {
  my ($class, $seq, $arg) = @_;
  $arg ||= {};

  my $merge = $arg->{root_config} || {};

  confess("config must be a Config::MVP::Sequence")
    unless $seq and $seq->isa('Config::MVP::Sequence');

  my $core_config = $seq->section_named('_')->payload;

  my $self = $class->new({
    %$merge,
    %$core_config,
  });

  for my $section ($seq->sections) {
    next if $section->name eq '_';

    my ($name, $plugin_class, $arg) = (
      $section->name,
      $section->package,
      $section->payload,
    );

    $self->log_debug("initializing plugin $name ($plugin_class)");

    confess "arguments attempted to override 'plugin_name'"
      if defined $arg->{plugin_name};

    confess "arguments attempted to override 'weaver'"
      if defined $arg->{weaver};

    push @{ $self->plugins },
      $plugin_class->new({
        %$arg,
        plugin_name => $name,
        weaver      => $self,
      });
  }

  return $self;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver - weave together a Pod document from an outline

=head1 VERSION

version 4.017

=head1 SYNOPSIS

  my $weaver = Pod::Weaver->new_with_default_config;

  my $document = $weaver->weave_document({
    pod_document => $pod_elemental_document,
    ppi_document => $ppi_document,

    license  => $software_license,
    version  => $version_string,
    authors  => \@author_names,
  })

=head1 DESCRIPTION

Pod::Weaver is a system for building Pod documents from templates.  It doesn't
perform simple text substitution, but instead builds a
Pod::Elemental::Document.  Its plugins sketch out a series of sections
that will be produced based on an existing Pod document or other provided
information.

=head1 ATTRIBUTES

=head2 logger

This attribute stores the logger, which must provide a log method.  The
weaver's log method delegates to the logger's log method.

=head2 plugins

This attribute is an arrayref of objects that can perform the
L<Pod::Weaver::Role::Plugin> role.  In general, its contents are found through
the C<L</plugins_with>> method.

=head1 METHODS

=head2 plugins_with

  my $plugins_array_ref = $weaver->plugins_with('-Section');

This method will return an arrayref of plugins that perform the given role, in
the order of their registration.  If the role name begins with a hyphen, the
method will prepend C<Pod::Weaver::Role::>.

=head2 weave_document

  my $document = $weaver->weave_document(\%input);

This is the most important method in Pod::Weaver.  Given a set of input
parameters, it will weave a new document.  Different section plugins will
expect different input parameters to be present, but some common ones include:

  pod_document - a Pod::Elemental::Document for the original Pod document
  ppi_document - a PPI document for the source of the module being documented
  license      - a Software::License object for the source module's license
  version      - a version (string) to use in produced documentation

The C<pod_document> should have gone through a L<Pod5
transformer|Pod::Elemental::Transformer::Pod5>, and should probably have had
its C<=head1> elements L<nested|Pod::Elemental::Transformer::Nester>.

The method will return a new Pod::Elemental::Document.  The input documents may
be destructively altered during the weaving process.  If they should be
untouched, pass in copies.

=head2 new_with_default_config

This method returns a new Pod::Weaver with a stock configuration by using only
L<Pod::Weaver::PluginBundle::Default>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Alex Peters Apocalypse Blabos de Blebe Caleb Cushing Christian Walde Christopher J. Madsen Chris Weyl Dave Houston Rolsky David E. Wheeler Golden Miguel Susano Pinto Zurborg Doug Bell Florian Ragwitz Jonathan "Duke" Leto Joshua Keroes Karen Etheridge Kent Fredric Kivanc Yazan Marcel Gruenauer Randy Stauner Ricardo Signes Sam Graham Shlomi Fish

=over 4

=item *

Alex Peters <lxp@cpan.org>

=item *

Apocalypse <perl@0ne.us>

=item *

Blabos de Blebe <blabos@cpan.org>

=item *

Caleb Cushing <xenoterracide@gmail.com>

=item *

Christian Walde <walde.christian@googlemail.com>

=item *

Christopher J. Madsen <perl@cjmweb.net>

=item *

Chris Weyl <cweyl@alumni.drew.edu>

=item *

Dave Houston <dave.houston@gmail.com>

=item *

Dave Rolsky <autarch@urth.org>

=item *

David E. Wheeler <david@justatheory.com>

=item *

David Golden <dagolden@cpan.org>

=item *

David Miguel Susano Pinto <carandraug+dev@gmail.com>

=item *

David Zurborg <post@david-zurb.org>

=item *

Doug Bell <doug@preaction.me>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Jonathan "Duke" Leto <jonathan@leto.net>

=item *

Joshua Keroes <joshua.keroes@integratelecom.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Kivanc Yazan <kyzn@cpan.org>

=item *

Marcel Gruenauer <hanekomu@gmail.com>

=item *

Randy Stauner <randy@magnificent-tears.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Sam Graham <git@illusori.co.uk>

=item *

Shlomi Fish <shlomif@shlomifish.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
