use 5.008;
use strict;
use warnings;

package Pod::Wordlist::hanekomu;
{
  $Pod::Wordlist::hanekomu::VERSION = '1.132680';
}
# ABSTRACT: Add words for spell checking POD (DEPRECATED)
use Test::Spelling;
set_spell_cmd 'aspell list';
use utf8;
our @person_names = qw(
  Achim
  Adam
  Cushing
  Damian Conway
  Doherty
  Doran
  Eilam
  Ekker
  Florian
  Marcel Gruenauer
  Heinz
  Helmberger
  Hofstetter
  Lapworth
  Mark
  Metheringham
  Ran
  Ricardo Signes rjbs
  Takesako
  Tatsuhiko Miyagawa
  mst
);
our @tech_names = qw(
  AES
  AnyEvent
  AOP
  API
  AspectJ
  Babelfish
  CamelCase
  Coro
  CPAN
  CPANPLUS
  DateTime
  DBI
  Django
  DSL
  EINTR
  EPP
  Firefox
  FirePHP
  FIXME
  GraphViz
  GUID
  GUIDs
  HTTP
  HTTPS
  IETF
  IP
  IPv4
  IPv6
  IRC
  ISP
  ISP's
  JSON
  MakeMaker
  Markdown
  Middleware
  MongoDB
  mkdn
  modulino
  MVC
  OO
  OOP
  PARC
  PHP
  Plack
  PSGI
  RDBMS
  README
  ShipIt
  SMTP
  Spiffy
  SQL
  SQLite
  SSL
  STDERR
  STDIN
  STDOUT
  svk
  TIMTOWTDI
  Unicode
  URI
  URI's
  URIs
  UTC
  UTF
  UUID
  UUIDs
  W3CDTF
  wiki
  XS
  YAML
  YAML's
);
our @stopwords = qw(
  adaptee
  adaptees
  administrativa
  afterwards
  aggregator
  aggregators
  analyses
  array's
  backend
  behaviour
  benchmarked
  blog
  blogs
  breakpoint
  breakpoints
  bugtracker
  bundle's
  callback
  callbacks
  callee
  chomp
  chomps
  chunked
  configurator
  configurators
  crosscutting
  debugger's
  denormalized
  deserialized
  distname
  dotfile
  dotfiles
  filename
  filenames
  formatter
  github
  hash's
  homepage
  hostname
  indices
  init
  iteratively
  japanese
  Joseki
  kwalitee
  locator
  lookup
  lookups
  marshalling
  metadata
  middleware
  mixin
  monkeypatch
  monkeypatches
  monkeypatching
  multi
  multi-value
  multi-valued
  munge
  munger
  munging
  namespace
  namespaces
  nestable
  ok
  op
  parameterizable
  pipe's
  placeholders
  pluggable
  plugin's
  plugins
  pointcut
  pointcuts
  pre
  precompute
  precomputes
  prepends
  preprocessed
  prereq
  prereqs
  probe's
  redirections
  redispatch
  ref
  reusability
  runtime
  san
  searchable
  seekable
  segment's
  shipit
  sigils
  startup
  stopword
  stopwords
  storable
  storages
  stringification
  stringifications
  stringifies
  stringify
  subclass
  subclasses
  subdirectories
  subdirectory
  subobjects
  symlinked
  terminal's
  timestamp
  tokenizes
  toolchain
  tuple
  unblessed
  unshifts
  username
  uuid
  value's
  variable's
  vim
  wellformedness
  whitelist
  whitelists
  workflow
  workflows
  wormhole
  yml
);

# dedup
my %words = map { $_ => 1 } @person_names, @tech_names, @stopwords;
add_stopwords(sort keys %words);
$ENV{LANG} = 'C';
1;

__END__

=pod

=head1 NAME

Pod::Wordlist::hanekomu - Add words for spell checking POD (DEPRECATED)

=head1 VERSION

version 1.132680

=head1 SYNOPSIS

    use Test::Spelling;
    use Pod::Wordlist::hanekomu;
    all_pod_files_spelling_ok('lib');

=head1 DESCRIPTION

When loaded, this module automatically adds Test::Spelling stopwords for POD
spell checking, that is, words that should be ignored by the spell check.

The stopword list includes some CPAN author names, technical terms (e.g.  JSON,
URI) and other commonly-used words not included in the default word list (e.g.
mixin, munging).

=head1 DEPRECATION

All non-name words from this list have been merged into the master L<Pod::Wordlist>
module.  Names are often grabbed directly from author and contributor metadata
by relevant tools and are unlikely to be as necessary.

Therefore, this list is no longer maintained.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Wordlist-hanekomu>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Pod::Wordlist::hanekomu/>.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

David Golden <dagolden@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
