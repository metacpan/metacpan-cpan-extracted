package PortageXS::Version;
BEGIN {
  $PortageXS::Version::AUTHORITY = 'cpan:KENTNL';
}
{
  $PortageXS::Version::VERSION = '0.3.1';
}

# ABSTRACT: Gentoo version object

use strict;
use warnings;



use Scalar::Util ();

use overload (
 '<=>' => \&_spaceship,
 '""'  => \&_stringify,
);

my $int_rx        = qr/[0-9]+/;
my $letter_rx     = qr/[a-zA-Z]/;
my $dotted_num_rx = qr/$int_rx(?:\.$int_rx)*/o;

my @suffixes  = qw<alpha beta pre rc normal p>;
my $suffix_rx = join '|', grep !/^normal$/, @suffixes;
$suffix_rx    = qr/(?:$suffix_rx)/o;

our $version_rx = qr{
 $dotted_num_rx $letter_rx?
 (?:_$suffix_rx$int_rx?)*
 (?:-r$int_rx)?
}xo;

my $capturing_version_rx = qr{
 ($dotted_num_rx) ($letter_rx)?
 ((?:_$suffix_rx$int_rx?)*)
 (?:-r($int_rx))?
}xo;


sub new {
 my $class = shift;
 $class = ref($class) || $class;

 my $vstring = shift;
 if (defined $vstring) {
  $vstring =~ s/^[._]+//g;
  $vstring =~ s/[._]+$//g;

  if ($vstring =~ /^$capturing_version_rx$/o) {
   return bless {
    string   => $vstring,
    version  => [ split /\.+/, $1 ],
    letter   => $2,
    suffixes => [ map /_($suffix_rx)($int_rx)?/go, $3 ],
    revision => $4,
   }, $class;
  }

  require Carp;
  Carp::croak("Couldn't parse version string '$vstring'");
 }

 require Carp;
 Carp::croak('You must specify a version string');
}

my @parts;
BEGIN {
 @parts = qw<version letter suffixes revision>;
 eval "sub $_ { \$_[0]->{$_} }" for @parts;
}


my %suffix_grade = do {
 my $i = 0;
 map { $_ => ++$i } @suffixes;
};

sub _spaceship {
 my ($v1, $v2, $r) = @_;

 unless (Scalar::Util::blessed($v2) and $v2->isa(__PACKAGE__)) {
  $v2 = $v1->new($v2);
 }

 ($v1, $v2) = ($v2, $v1) if $r;

 {
  my @a = @{ $v1->version };
  my @b = @{ $v2->version };

  {
   my $x = shift @a;
   my $y = shift @b;
   my $c = $x <=> $y;
   return $c if $c;
  }

  while (@a and @b) {
   my $x = shift @a;
   my $y = shift @b;
   my $c;
   if ($x =~ /^0/ or $y =~ /^0/) {
    s/0+\z// for $x, $y;
    $c = $x cmp $y;
   } else {
    $c = $x <=> $y;
   }
   return $c if $c;
  }

  return  1 if @a;
  return -1 if @b;
 }

 {
  my ($l1, $l2) = map { defined() ? ord : 0 } map $_->letter, $v1, $v2;

  my $c = $l1 <=> $l2;
  return $c if $c;
 }

 {
  my @a = @{ $v1->suffixes };
  my @b = @{ $v2->suffixes };

  while (@a or @b) {
   my $x = $suffix_grade{ shift(@a) || 'normal' };
   my $y = $suffix_grade{ shift(@b) || 'normal' };
   my $c = $x <=> $y;
   return $c if $c;

   $x = shift(@a) || 0;
   $y = shift(@b) || 0;
   $c = $x <=> $y;
   return $c if $c;
  }
 }

 {
  my ($r1, $r2) = map { defined() ? $_ : 0 } map $_->revision, $v1, $v2;

  my $c = $r1 <=> $r2;
  return $c if $c;
 }

 return 0;
}

sub _stringify {
 my ($v) = @_;

 my ($version, $letter, $suffixes, $revision) = map $v->$_, @parts;
 my @suffixes = @$suffixes;

 $version   = join '.', @$version;
 $version  .= $letter if defined $letter;
 while (my @suffix = splice @suffixes, 0, 2) {
  my $s = $suffix[0];
  my $n = $suffix[1];
  $version .= "_$s" . (defined $n ? $n : '');
 }
 $version .= "-r$revision" if defined $revision;

 $version;
}


1; # End of PortageXS::Version

__END__

=pod

=encoding utf-8

=head1 NAME

PortageXS::Version - Gentoo version object

=head1 VERSION

version 0.3.1

=head1 DESCRIPTION

This class models Gentoo versions as described in L<http://devmanual.gentoo.org/ebuild-writing/file-format/index.html>.

This specific class is a deviation of L<CPANPLUS::Dist::Gentoo::Version>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"PortageXS::Version",
    "interface":"class"
}


=end MetaPOD::JSON

=head1 METHODS

=head2 C<new $vstring>

Creates a new L<PortageXS::Version> object from the version string C<$vstring>.

=head2 C<version>

Read-only accessor for the C<version> part of the version object.

=head2 C<letter>

Read-only accessor for the C<letter> part of the version object.

=head2 C<suffixes>

Read-only accessor for the C<suffixes> part of the version object.

=head2 C<revision>

Read-only accessor for the C<revision> part of the version object.

This class provides overloaded methods for numerical comparison and stringification.

=head1 SEE ALSO

L<PortageXS>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PortageXS

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHORS

=over 4

=item *

Christian Hartmann <ian@gentoo.org>

=item *

Torsten Veller <tove@gentoo.org>

=item *

Kent Fredric <kentnl@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Christian Hartmann.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
