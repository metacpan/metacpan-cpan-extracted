package News::Article::NoCeM;

$VERSION = '0.08';

# -*- Perl -*- Sat Dec  4 21:11:45 CST 2004
#############################################################################
# Written by Yen-Ming Lee <leeym@leeym.com>
# Based on a module by Tim Skirvin <tskirvin@killfile.org>, and relying almost
# exclusively on the News::Article package written by Andrew Gierth
# <andrew@erlenstar.demon.co.uk>.  Thanks, folks.
#
# Copyright 2004-2005 Yen-Ming Lee.  Redistribution terms are in the
# documentation, and I'm sure you can find them.
#############################################################################

=head1 NAME

News::Article::NoCeM - a module to generate accurate nocem notices

=head1 SYNOPSIS

  use News::Article::NoCeM;
  my $nocem = new News::Article::NoCeM();

  $nocem->hide($type, $spam);
  $nocem->make_notice($type, $name, $issuer, $group, $prefix);
  $nocem->sign($keyid, $passphrase);
  $nocem->issue($conn, $ihave);

=head1 DESCRIPTION

Creates a nocem notice on the Usenet articles, which may be posted
normally to hide the messages.

=head1 USAGE

=over 2

=item use News::Article::NoCeM;

=back

News::Article::NoCeM is class that inherits News::Article and adds four
new functions: hide(), make_notice(), sign() and issue(),
redefine to disable two functions: post() and ihave().

=cut

require 5;    # Requires Perl 5

use News::Article;
use PGP::Sign;
use Exporter;
use strict;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );

@ISA = qw( Exporter News::Article );

=head2 Article Methods

=over 4

=item hide ( TYPE, ARTICLE, [ARTICLE, ...] )

Hide one or more articles in the given C<TYPE>.  C<ARTICLE> is an
News::Article object that going to be hid. hide() will skip
the articles without Newsgroup or Message-ID and skip the ones
already hid.

hide() returns the number of the articles hid.

=cut

sub hide
{
  my $self     = shift;
  my $type     = shift;
  my @articles = @_;
  my $num;

  foreach my $article (@articles)
  {
    my $newsgroups = $article->header('newsgroups');
    my $message_id = $article->header('message-id');
    next if !$newsgroups || !$message_id;
    next if $self->{'NoCeM'}->{$type}->{$message_id};
    $self->{'NoCeM'}->{$type}->{$message_id} = $newsgroups;
    ++$num;
  }
  return $num;
}
push @EXPORT, qw( hide );

=item post

=item ihave

post() and ihave() is disabled in News::Article::NoCeM.
Please use issue() instead.

=cut

sub post
{
  my $self = shift;
  die "You should use issue(conn, 0) instead of post() in " . ref($self) . "\n";
}
push @EXPORT, qw( post );

sub ihave
{
  my $self = shift;
  die "You should use issue(conn, 1) instead of ihave() in " . ref($self) . "\n";
}
push @EXPORT, qw( ihave );

=item make_notice ( TYPE, NAME, GROUP, ISSUER, [ PREFIX ] )

Retrive articles marked by hide with C<TYPE>, and make a notice
fot them. If there's only one type within a container, then the container
itself can be a notice. C<NAME> is the identifier of the issuer. C<GROUP> is
the newsgroup the you will post nocem notice to. C<ISSUER> is the email address
of the issuer. C<PREFIX> is the announcement before the nocem notice, which may
explain the criteria of this notice, or where to find your public key for
PGP verification.

make_notice() returns a News::Article::NoCeM object if success, and return undef
if no article is hid.

=cut

sub make_notice
{
  my $self = shift;
  my $type = shift;
  my $name = shift;
  my $group = shift;
  my $issuer = shift;
  my $prefix = shift;

  my $now   = time();
  my $ncmid = "$name-$type.$now";
  my $count = scalar keys %{ $self->{'NoCeM'}->{$type} };

  return if !$count;

  $self->set_body();
  $self->add_body($prefix);
  $self->add_body("");
  $self->add_body("\@\@BEGIN NCM HEADERS
Version: 0.9
Issuer: $issuer
Type: $type
Action: hide
Count: $count
Notice-ID: $ncmid
\@\@BEGIN NCM BODY");
  foreach my $msgid (keys %{ $self->{'NoCeM'}->{$type} })
  {
    my @groups = split(',', $self->{'NoCeM'}->{$type}->{$msgid});
    $self->add_body("$msgid\t" . shift(@groups));
    foreach my $g (@groups) { $self->add_body("\t$g"); }
  }
  $self->add_body("\@\@END NCM BODY");
  $self->set_headers('Subject',    "\@\@NCM $name-$type NoCeM notice $now");
  $self->set_headers('Newsgroups', $group);
  $self->set_headers('From',       $issuer);
  $self->set_headers('X-Issued-By', ref($self) . "-" . $VERSION);
  $self->set_headers('Path',       "nocem!not-for-mail");
  $self->add_date();
  delete($self->{Headers}{'message-id'});
  $self->add_message_id();
  return $self;
}
push @EXPORT, qw( make_notice );

=item sign ( KEYID, PASSPHRASE )

Sign the content of the nocem notice with C<KEYID> and C<PASSPHRASE>.
Please make sure that the issuer's public/secret keyring is ready.

sign() returns a News::Article::NoCeM object if success, and return undef
if no article is hid, or pgp_sign failed.

=cut

sub sign
{
  my $self = shift;
  my $keyid = shift;
  my $passphrase = shift;

  return if !scalar(@{$self->body()});

  my $body = join("\n", @{$self->body()}) . "\n";
  my ($signature, $version) = pgp_sign($keyid, $passphrase, $body);

  return if !$signature;

  $self->set_body();
  $self->add_body("-----BEGIN PGP SIGNED MESSAGE-----");
  $self->add_body("Hash: SHA1");
  $self->add_body("");
  $self->add_body($body);
  $self->add_body("");
  $self->add_body("-----BEGIN PGP SIGNATURE-----");
  $self->add_body("Version: $version");
  $self->add_body("");
  $self->add_body($signature);
  $self->add_body("-----END PGP SIGNATURE-----");

  return $self;
}
push @EXPORT, qw( sign );

=item issue ( [ CONN, IHAVE ] )

Take optional C<CONN> as a Net::NNTP object and issue the nocem notice.
C<IHAVE> indicates that call Net::NNTP::ihave() for submitting the notice,
otherwise issue() will call News::Article::post() by default.

issue() return the result of News::Article::post() or issue().

=back

=cut

sub issue
{
  my $self  = shift;
  my $conn  = shift;
  my $ihave = shift;

  return if !scalar(@{$self->body()});
  return $ihave ? $self->SUPER::ihave($conn) : $self->SUPER::post($conn);
}
push @EXPORT, qw( issue );

=head1 NOTES

Standard article manipulation information can be read in the News::Article
manpages.

NoCeM FAQ is available on the web at <URL:http://www.cm.org/faq.html>.

=head1 AUTHOR

Written by Yen-Ming Lee <leeym@leeym.com>, based on a module by
Tim Skirvin <tskirvin@killfile.org>.

=head1 COPYRIGHT

Copyright 2004-2005 by Yen-Ming Lee <leeym@leeym.com>.
This code may be redistributed under the same terms as Perl itself.

=cut

1;
