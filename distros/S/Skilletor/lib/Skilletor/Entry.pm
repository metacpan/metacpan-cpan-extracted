package Skilletor::Entry;
# ABSTRACT: Install entries ([type:]name@source, patterns, bundles) and the names they hold

use strict;
use warnings;

use Exporter qw( import );
use Skilletor::Error::Config;
use Skilletor::JSString qw( js_lc );

our $VERSION = '0.001';

our @EXPORT_OK = qw(
  ITEM_TYPES HARNESSES WILDCARD SOURCE_NAME_RULE INSTALL_KEYS INSTALL_KEY_OF BUNDLES_KEY
  name_key is_source_name is_pattern
  parse_entry parse_bundle_entry seen_key
);

use constant ITEM_TYPES => qw( skill agent rule );
use constant HARNESSES  => qw( claude codex hermes );
use constant WILDCARD   => '*';
use constant BUNDLES_KEY => 'bundles';
use constant SOURCE_NAME_RULE => 'ASCII letters, digits, ".", "_" and "-", starting with a letter or digit';

# Config install keys and their item types, in the reference's order.
use constant INSTALL_KEYS => ( skills => 'skill', agents => 'agent', rules => 'rule' );
use constant INSTALL_KEY_OF => { skill => 'skills', agent => 'agents', rule => 'rules' };

sub name_key {
  my ( $name ) = @_;
  return js_lc($name);
}

sub is_source_name {
  my ( $name ) = @_;
  return ( defined $name && $name =~ /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/ ) ? 1 : 0;
}

sub is_pattern {
  my ( $name ) = @_;
  return index( $name, WILDCARD ) >= 0 ? 1 : 0;
}

# `[type:]name@source` under one type's list. The list's type wins; a prefix must match it.
sub parse_entry {
  my ( $entry, $type, $path, $where ) = @_;
  my $at = rindex $entry, '@';
  if ( $at <= 0 || $at == length($entry) - 1 ) {
    Skilletor::Error::Config->throw( $path.': '.$where.' "'.$entry.'" must be name@source' );
  }
  my $source = substr $entry, $at + 1;
  my $name   = substr $entry, 0, $at;
  my $colon  = index $name, ':';
  if ( $colon != -1 ) {
    my $prefix = substr $name, 0, $colon;
    if ( $prefix ne $type ) {
      Skilletor::Error::Config->throw(
        $path.': '.$where.' "'.$entry.'" declares type "'.$prefix.'" but is under '.$type.'s' );
    }
    $name = substr $name, $colon + 1;
  }
  Skilletor::Error::Config->throw( $path.': '.$where.' "'.$entry.'" has an empty name' ) unless length $name;
  return { type => $type, name => $name, source => $source, target => $type.'s/'.$name, raw => $entry };
}

# `[bundle:]name@source` under install.bundles; no patterns.
sub parse_bundle_entry {
  my ( $entry, $path, $where ) = @_;
  my $at = rindex $entry, '@';
  if ( $at <= 0 || $at == length($entry) - 1 ) {
    Skilletor::Error::Config->throw( $path.': '.$where.' "'.$entry.'" must be name@source' );
  }
  my $name  = substr $entry, 0, $at;
  my $colon = index $name, ':';
  if ( $colon != -1 ) {
    my $prefix = substr $name, 0, $colon;
    if ( $prefix ne 'bundle' ) {
      Skilletor::Error::Config->throw( $path.': '.$where.' "'.$entry.'" declares type "'.$prefix.'" but is under bundles' );
    }
    $name = substr $name, $colon + 1;
  }
  Skilletor::Error::Config->throw( $path.': '.$where.' "'.$entry.'" has an empty name' ) unless length $name;
  if ( is_pattern($name) ) {
    Skilletor::Error::Config->throw( $path.': '.$where.' "'.$entry.'": patterns over bundle names are not supported' );
  }
  return { name => $name, source => substr( $entry, $at + 1 ), raw => $entry };
}

# The duplicate key of an entry: a name per type, ignoring case; a pattern per type and source.
sub seen_key {
  my ( $item ) = @_;
  return is_pattern( $item->{name} )
    ? $item->{type}.'/'.$item->{name}.'@'.$item->{source}
    : $item->{type}.'/'.name_key( $item->{name} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Entry - Install entries ([type:]name@source, patterns, bundles) and the names they hold

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Entry qw( parse_entry parse_bundle_entry name_key is_source_name );

  my $item = parse_entry( 'skill:perl-moo@shared', 'skill', $file, 'install.skills[0]' );
  # { type => 'skill', name => 'perl-moo', source => 'shared',
  #   target => 'skills/perl-moo', raw => 'skill:perl-moo@shared' }

  my $bundle = parse_bundle_entry( 'bundle:perl@shared', $file, 'install.bundles[0]' );
  # { name => 'perl', source => 'shared', raw => 'bundle:perl@shared' }

=head1 DESCRIPTION

The pieces of the reference's C<config.ts> that read one install entry and the
names in it. The last C<@> splits name and source; a C<type:> prefix must name
the list's type (C<bundle:> under C<install.bundles>); a name holding C<*> is a
pattern. Every error is a L<Skilletor::Error::Config> worded as the reference
words it, starting with the file and the entry's place
(C<install.skills[2]>).

=head2 parse_entry

  parse_entry( $entry, $type, $file, $where );

An entry of C<install.skills>, C<install.agents> or C<install.rules>. A
pattern comes back the same way; L</is_pattern> on its C<name> tells it apart.

=head2 parse_bundle_entry

  parse_bundle_entry( $entry, $file, $where );

=head2 seen_key

The key under which two entries of one scope are the same declaration.

=head2 name_key

An item name as a key: names equal ignoring case are one name, on every
platform (they install into one directory on macOS and Windows).

=head2 is_source_name

C<^[A-Za-z0-9][A-Za-z0-9._-]*$>.

=head2 is_pattern

True when a name contains C<*>.

=head2 ITEM_TYPES

C<skill>, C<agent>, C<rule>.

=head2 HARNESSES

C<claude>, C<codex>, C<hermes>.

=head2 INSTALL_KEYS

The config keys C<skills>, C<agents>, C<rules> with their types, as a list of
pairs in this order; L</INSTALL_KEY_OF> maps a type back.

=head2 INSTALL_KEY_OF

C<< { skill => 'skills', agent => 'agents', rule => 'rules' } >>.

=head2 WILDCARD

C<*>, the character that makes a name a pattern.

=head2 BUNDLES_KEY

C<bundles>, the C<install> key listing bundle entries.

=head2 SOURCE_NAME_RULE

The source name rule in words, as error messages give it.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
