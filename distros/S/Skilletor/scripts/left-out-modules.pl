#!/usr/bin/env perl
# The families every build leaves out, and their members.
#   perl -Ilib scripts/left-out-modules.pl [--inc DIR] -- MODULE...
# prints each member found in @INC (with --inc: in DIR only, an unpacked archive's lib/, say),
# less the MODULEs given (the loaded set, which always stays), one per line: a module as
# Foo::Bar, any other code file as its path (unicore/Name.pl). binary-pp-args.sh turns each line
# into `pp -X`; binary-verify.sh runs it on the archive, where it must print nothing. One list,
# so build and verify cannot drift.
#
# A family is what pp's scanner reaches through a require the CLI never runs. `pp -X Name` drops
# exactly Name.pm (no wildcard) and stops the scan there, so a family takes one -X per member
# (Name::** = every module below Name). Each family costs archive size and cold-start
# extraction:
#   Moose      Moo::HandleMoose inflates Moo classes into Moose once Moose is loaded, which the
#              CLI never does; with it go Moose's own dependencies, Perl::Tidy (Eval::Closure's
#              debug output) and Unicode::LineBreak behind it (links libthai where the host has it).
#   CryptX     Math::BigInt's backend list names Math::BigInt::LTM and so CryptX's 6 MB shared
#              object; only JSON::PP's allow_bignum reaches Math::BigInt, which nothing turns on.
#   Test       unicore/TestNorm.pl names Test::More; with it go Test::Builder and Test2.
#   unicore    the Unicode tables, preloaded for Unicode::Normalize (its XS carries its own) and
#              charnames; Perl 5.40 compiles the property tables in, and the CLI reads none of
#              these files (no \N{NAME} at run time). The .txt files stay: -X takes code only.
#   LWP        IO::Socket::SSL::PublicSuffix names LWP::UserAgent for updating its list, which
#              only its maintainer does; with it go HTTP::Message, its codecs (Brotli, Bzip2),
#              URI, HTML::Parser and Net::HTTP. HTTP::Tiny and URI::_idna stay (loaded set).
#   Pod        Getopt::Long's Pod::Usage, reached through Perl::Tidy.
use strict;
use warnings;

my @FAMILIES = qw(
  Moo::HandleMoose Moose Moose::** Class::MOP Class::MOP::** metaclass
  Specio Specio::** Eval::Closure Perl::Tidy Perl::Tidy::** Devel::OverloadInfo
  Devel::StackTrace Devel::StackTrace::** Package::DeprecationManager Params::Validate
  Params::Validate::** Class::Load Class::Load::** Dist::CheckConflicts
  Unicode::LineBreak Unicode::GCString MIME::Charset MIME::Charset::**
  Math::BigInt Math::BigInt::** Math::BigFloat Math::BigFloat::** Math::BigRat Math::Complex
  CryptX Crypt::**
  Test Test::** Test2 Test2::**
  unicore/**
  LWP LWP::** HTTP::** HTML::** URI URI::** Net::HTTP Net::HTTP::** Net::HTTPS Net::FTP
  Net::FTP::** Net::NNTP Net::Cmd Net::Config Net::Domain Net::Netrc Net::IDN::** Net::LibIDN
  IO::HTML File::Listing Encode::Locale Time::Zone Clone IO::Compress::** IO::Uncompress::**
  Compress::Raw::Bzip2
  Pod::**
);

my @inc = grep { !ref && -d } @INC;
if ( @ARGV >= 2 && $ARGV[0] eq '--inc' ) { shift; @inc = ( shift @ARGV ) }
shift @ARGV if @ARGV && $ARGV[0] eq '--';
my %keep = map { ( $_ => 1 ) } @ARGV;

# Every code file below $dir/$rel, relative to $dir.
sub files_under {
  my ( $dir, $rel ) = @_;
  opendir my $dh, "$dir/$rel" or return;
  my @out;
  for my $e ( sort grep { !/\A\./ } readdir $dh ) {
    if    ( -d "$dir/$rel/$e" )             { push @out, files_under( $dir, "$rel/$e" ) }
    elsif ( $e =~ /\.p[ml]\z/ && -f _ ) { push @out, "$rel/$e" }
  }
  return @out;
}

my %out;
for my $fam (@FAMILIES) {
  my ( $base, $deep ) = $fam =~ /\A(.*?)((?:::|\/)\*\*)?\z/;
  ( my $path = $base ) =~ s{::}{/}g;
  for my $dir (@inc) {
    my @files = $deep ? files_under( $dir, $path ) : ( -f "$dir/$path.pm" ? ("$path.pm") : () );
    for my $f (@files) {
      my $name = $f =~ /\.pm\z/ ? ( $f =~ s/\.pm\z//r =~ s{/}{::}gr ) : $f;
      $out{$name} = 1 unless $keep{$name};
    }
  }
}
print "$_\n" for sort keys %out;
