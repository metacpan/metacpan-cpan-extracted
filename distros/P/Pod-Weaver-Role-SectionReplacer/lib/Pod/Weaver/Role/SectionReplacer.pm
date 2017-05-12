package Pod::Weaver::Role::SectionReplacer;

# ABSTRACT: A Pod::Weaver section that will replace itself in the original document.

use Moose::Role;
with 'Pod::Weaver::Role::Transformer';

use Moose::Autobox 0.11;
use Pod::Elemental::Selectors -all;

our $VERSION = '1.00';

has original_section => (
  is  => 'rw',
);

has section_name => (
  is  => 'ro',
  isa => 'Str',
  default => sub { $_[ 0 ]->default_section_name },
);

requires 'default_section_name';

has section_aliases => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub { $_[ 0 ]->default_section_aliases },
);

sub default_section_aliases { []; }

sub transform_document {
  my ( $self, $document ) = @_;

  #  Build a selector for a =head1 with the correct content text.
  my $command_selector = s_command('head1');
  my $aliases = [ $self->section_name, @{ $self->section_aliases } ];
  my $named_selector = sub {
      my ( $node ) = @_;

      my $content = $node->content;
      $content =~ s/^\s+//;
      $content =~ s/\s+$//;

      return( $command_selector->( $_[ 0 ] ) &&
        $aliases->any() eq $content );
    };

  return unless $document->children->grep($named_selector)->length;

  #  Take the first matching section found...
  $self->original_section($document->children->grep($named_selector)->first);

  #  ...and prune it from the document.
  my $in_node = $document->children;
  for ( my $i = 0; $i <= $#{ $in_node }; $i++ ) {
    next unless $in_node->[ $i ] == $self->original_section;

    splice @{ $in_node }, $i, 1;
    last;
  }
};

sub mvp_aliases { { section_alias => 'section_aliases', }; }
sub mvp_multivalue_args { ( 'section_aliases', ); }

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Pod::Weaver::Role::SectionReplacer - A Pod::Weaver section that will replace itself in the original document.

=head1 VERSION

version 1.00

=head1 SYNOPSIS

A role for L<Pod::Weaver> plugins, allowing them to replace a named
section of the input document rather than appending a potentially
duplicate section.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=end readme

=for readme stop

=head1 IMPLEMENTING

This role is used by plugins that will find an existing section in the input
document.
It will prune the first existing section from the input document and make it
available under C<original_section> method:

  $section_plugin->original_section();

The plugin could then choose to keep the original, by inserting it
into the document again, or to write something new instead, or some
combination of the two.

=head2 REQUIRED METHODS

=over

=item B<< $plugin->default_section_name() >>

The plugin must provide a method, C<default_section_name> which will return
the default name of the section, as used in the =head1 line, this is
available for later query via the C<section_name> accessor:

  $section_plugin->section_name

It is recommended that you use this accessor for generating the section
title rather than hard-coding a value directly, because it then allows
the end-user to configure the section name in their weaver.ini, eg:

  [ReplaceLegal]
  section_name = MY CUSTOMIZED LICENSE AND COPYRIGHT HEADING

=back

=head2 OPTIONAL METHODS

=over

=item B<< $plugin->default_section_aliases >>

The plugin may also provide a C<default_section_aliases> method, which
should return an arrayref of alternative section names to match.
Like C<section_name> this allows the end-user to override the default
section aliases:

  [ReplaceLegal]
  section_name  = MY CUSTOMIZED LICENSE AND COPYRIGHT HEADING
  section_alias = LICENSE AND COPYRIGHT
  section_alias = COPYRIGHT AND LICENSE
  section_alias = LICENCE AND COPYRIGHT
  section_alias = COPYRIGHT AND LICENCE

=back

=head2 INTERNAL METHODS

These methods are mostly internal to the role, but if you're also using
them in your plugin, you will need reconcile the return values.

=over

=item B<< $plugin->mvp_aliases() >>

Tells L<Config::MVP> that C<section_alias> is a synonym for C<section_aliases>
in the weaver.ini for plugins that use this role.

=item B<< $plugin->mvp_multivalue_args() >>

Tells L<Config::MVP> that C<section_aliases> always takes multiple-values
and should be stored as an arrayref.

=item B<< $plugin->transform_document() >>

L<Pod::Weaver:Role::SectionReplacer> implements the role
L<Pod::Weaver::Role::Transformer>, and as such it provides its own
C<< $plugin->tranform_document() >> method in order to prune the original
section from the input document before any further weaving is done.

If your plugin wishes to implement a C<< transform_document() >> of its
own, you will need to reconcile the two.

=back

=for readme continue

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

  perldoc Pod::Weaver::Role::SectionReplacer

You can also look for information at:

=over

=item RT, CPAN's request tracker

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Weaver-Role-SectionReplacer

=item AnnoCPAN, Annotated CPAN documentation

http://annocpan.org/dist/Pod-Weaver-Role-SectionReplacer

=item CPAN Ratings

http://cpanratings.perl.org/d/Pod-Weaver-Role-SectionReplacer

=item Search CPAN

http://search.cpan.org/dist/Pod-Weaver-Role-SectionReplacer/

=back

=head1 AUTHOR

Sam Graham <libpod-weaver-role-sectionreplacer-perl BLAHBLAH illusori.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Sam Graham <libpod-weaver-role-sectionreplacer-perl BLAHBLAH illusori.co.uk>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
