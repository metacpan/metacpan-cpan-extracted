use strict;
use warnings;

use Test::More;

use Pod::Elemental::Selectors -all;

use Pod::Elemental::Element::Generic::Command;
use Pod::Elemental::Element::Generic::Text;

use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;

my %elem;
my %sel;

$elem{g_head1} = Pod::Elemental::Element::Generic::Command->new({
  command => 'head1',
  content => "\n",
});

$elem{g_head2} = Pod::Elemental::Element::Generic::Command->new({
  command => 'head2',
  content => "\n",
});

$elem{g_text} = Pod::Elemental::Element::Generic::Text->new({
  content => "Generic text.\n",
});

$elem{p5_head1} = Pod::Elemental::Element::Pod5::Command->new({
  command => 'head1',
  content => "\n",
});

$elem{p5_head2} = Pod::Elemental::Element::Pod5::Command->new({
  command => 'head2',
  content => "\n",
});

$elem{p5_ord} = Pod::Elemental::Element::Pod5::Ordinary->new({
  content => "Ordinary text.\n",
});

$sel{head1} = s_command('head1');
$sel{cmd}   = s_command;
$sel{msc1}  = s_command([ qw(head1) ]);
$sel{msc2}  = s_command([ qw(over head1) ]);
$sel{msc3}  = s_command([ qw(head1 head2) ]);

my @test = (
  head1 => g_head1  => 1,
  head1 => g_head2  => 0,
  head1 => g_text   => 0,
  head1 => p5_head1 => 1,
  head1 => p5_head2 => 0,
  head1 => p5_ord   => 0,

  cmd   => g_head1  => 1,
  cmd   => g_head2  => 1,
  cmd   => g_text   => 0,
  cmd   => p5_head1 => 1,
  cmd   => p5_head2 => 1,
  cmd   => p5_ord   => 0,

  msc1  => g_head1  => 1,
  msc1  => g_head2  => 0,
  msc1  => g_text   => 0,
  msc1  => p5_head1 => 1,
  msc1  => p5_head2 => 0,
  msc1  => p5_ord   => 0,

  msc2  => g_head1  => 1,
  msc2  => g_head2  => 0,
  msc2  => g_text   => 0,
  msc2  => p5_head1 => 1,
  msc2  => p5_head2 => 0,
  msc2  => p5_ord   => 0,

  msc3  => g_head1  => 1,
  msc3  => g_head2  => 1,
  msc3  => g_text   => 0,
  msc3  => p5_head1 => 1,
  msc3  => p5_head2 => 1,
  msc3  => p5_ord   => 0,
);

plan tests => scalar(@test/3);

for my $i (0 .. @test/3 - 1) {
  my ($sel_name, $elem_name, $expect) = splice @test, 0, 3;

  my $str = $expect ? "matches" : "doesn't match";

  die "unknown element '$elem_name'" unless my $elem = $elem{ $elem_name };
  die "unknown selector '$sel_name'" unless my $sel  = $sel{   $sel_name };

  my $ok = $sel->($elem);
     $ok = not $ok if ! $expect;

  ok($ok, "expect that $elem_name $str $sel_name");
}

1;
