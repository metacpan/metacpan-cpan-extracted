# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
package TestPW;
use strict;
use warnings;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  slurp_file
  test_basic weaver_input
  compare_pod_ok
);
our $Data = do { local $/; <DATA> };

use Test::More 0.96;
use Test::Differences 0.500;
use Test::MockObject 1.09;

use PPI;

use Pod::Elemental 0.102360;
use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Nester;

use Pod::Weaver;
require Software::License::Perl_5;

my $zilla = Test::MockObject->new();
$zilla->set_always(is_trial => 0);
$zilla->set_always(license => Software::License::Perl_5->new({ holder => 'DZHolder', year => 2010, }) );
$zilla->set_always(authors => ['DZAuth Stauner <rwstauner@cpan.org>']);
$zilla->set_always(stash_named => undef);
$zilla->mock(copyright_holder => sub { $_[0]->license->holder });
# proposed changes to Pod::Weaver::Section::Legal look for a license file.  we can ignore that for these tests.
$zilla->set_always(files => []);

sub slurp_file { local (@ARGV, $/) = @_; <> }

sub test_basic {
  my ($weaver, $input, $stopwords) = @_;
  my $expected = $input->{expected};

  my ($paragraphs, $versionp, @nestedh1s) = ( 9, 1, qw(0 1 3 4 5   7 8));

  # Back-Compatibilty: Pod::Weaver 4 has -SingleEncoding in @Default.
  # All our tests now have TestPWEncoding but not for the @Default test.
  if( grep { ref($_) =~ /Encoding$/ } @{ $weaver->plugins } ){
    ++$_ for $paragraphs, $versionp, @nestedh1s;
    $expected =~ s/\A(=pod\n\n)(=encoding (.+?)\n\n)?/$1=encoding UTF-8\n\n/;
  }

  if( $stopwords ){
    ++$_ for $paragraphs, $versionp, @nestedh1s;
    $expected =~ s/\A(=pod\n\n)(=encoding (.+?)\n\n)?/$1$2=for :stopwords $stopwords\n\n/;
  }

  # copied/modified from Pod::Weaver tests (Pod-Weaver-3.101632/t/basic.t)
  my $woven = $weaver->weave_document($input);

  is(scalar(@{ $woven->children }), $paragraphs,
    "we end up with a $paragraphs-paragraph document");

  for ( @nestedh1s ) {
    my $para = $woven->children->[ $_ ];
    isa_ok($para, 'Pod::Elemental::Element::Nested', "element $_")
      and # only check command if isa Nested
    is($para->command, 'head1', "... and is =head1");
  }

  is(
    $woven->children->[$versionp]->children->[0]->content,
    'version 1.002003',
    "the version is in the version section",
  );

  compare_pod_ok(
    $woven->as_pod_string,
    $expected,
    "exactly the pod string we wanted after weaving!",
  );
}

sub compare_pod_ok {
  my ($got, $exp, $desc) = @_;
  # As it says in the pod weaver tests:
  # XXX: This test is extremely risky as things change upstream.

  eq_or_diff( normalize($got), normalize($exp), $desc );
}

sub normalize {
  local $_ = $_[0];
  # Pod::Elemental 0.103003 has a bug that produces an extra newline...
  # It was fixed in the next version, but who cares about an extra newline...
  s/\n+/\n/sg;
  return $_;
}

sub weaver_input {
  my ($dir) = @_;
  my $base = $dir ? "$dir/" : 't/eg/';

  # copied/modified from Pod::Weaver tests (Pod-Weaver-3.101632/t/basic.t)
  my $in_pod   = slurp_file("${base}in.pod");
  my $expected = slurp_file("${base}out.pod");
  my $document = Pod::Elemental->read_string($in_pod);

  my $perl_document = $Data;
  my $ppi_document  = PPI::Document->new(\$perl_document);

  return {
    pod_document => $document,
    ppi_document => $ppi_document,
    # below configuration modified by rwstauner
    expected => $expected,

    version  => '1.002003',
    authors  => [
    'Randy Stauner <rwstauner@cpan.org>',
    ],
    license  => Software::License::Perl_5->new({
    holder => 'PWHolder',
    year   => 2010,
    }),
    zilla => $zilla,
  };
}

1;

__DATA__

package Module::Name;
# ABSTRACT: abstract text

my $this = 'a test';
