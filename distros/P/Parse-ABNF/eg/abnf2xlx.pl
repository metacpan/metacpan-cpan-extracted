#!perl -w
use strict;
use warnings;
use Parse::ABNF;
use XML::Writer;
use Data::Dumper;

our $NS = 'http://example.org/grammar';

my %hash = (
    Rule => sub {
      my ($w, $n) = @_;
      my @combine = ($n->{combine} and $n->{combine} eq 'choice') ?
                      (combine => 'choice') : ();

      $w->startTag([$NS, 'define'], name => $n->{name}, @combine);
      Conv($w, $n->{value});
      $w->endTag([$NS, 'define']);
    },

    Choice => sub {
      my ($w, $n) = @_;
      $w->startTag([$NS, 'choice']);
      Conv($w, $n->{value});
      $w->endTag([$NS, 'choice']);
    },

    Group => sub {
      my ($w, $n) = @_;
      $w->startTag([$NS, 'group']);
      Conv($w, $n->{value});
      $w->endTag([$NS, 'group']);
    },

    Reference => sub {
      my ($w, $n) = @_;
      $w->startTag([$NS, 'ref'], name => $n->{name});
      $w->endTag([$NS, 'ref']);
    },

    ProseValue => sub {
      my ($w, $n) = @_;
      $w->startTag([$NS, 'ref'], name => $n->{value});
      $w->endTag([$NS, 'ref']);
      warn "Warning: Turning prose value <$n->{value}> into <ref/> pattern\n";
    },

    Literal => sub {
      my ($w, $n) = @_;
      $w->startTag([$NS, 'value'], type => 'ascii-insensitive-string');
      $w->characters($n->{value});
      $w->endTag([$NS, 'value']);
    },

    Repetition => sub {
      my ($w, $n) = @_;
      $w->startTag([$NS, 'repetition'], min => $n->{min}, max =>
        defined $n->{max} ? $n->{max} : 'unbounded');
      Conv($w, $n->{value});
      $w->endTag([$NS, 'repetition']);
    },

    String => sub {
      my ($w, $n) = @_;
      my @value = $n->{type} eq 'hex' ? map hex, @{$n->{value}} :
          @{$n->{value}};

      $w->startTag([$NS, 'group']);

      foreach my $val (@value) {
        $w->startTag([$NS, 'data'], type => 'class');
        $w->startTag([$NS, 'param'], name => 'range');
        $w->characters(sprintf qq(#%04X-#%04X), $val, $val);
        $w->endTag([$NS, 'param']);
        $w->endTag([$NS, 'data']);
      }

      $w->endTag([$NS, 'group']);
    },

    Range => sub {
      my ($w, $n) = @_;

      my ($min, $max) = $n->{type} eq 'hex'
        ? (map hex, ($n->{min}, $n->{max}))
        : ($n->{min}, $n->{max});
      
      $w->startTag([$NS, 'data'], type => 'class');
      $w->startTag([$NS, 'param'], name => 'range');
      $w->characters(sprintf qq(#%04X-#%04X), $min, $max);
      $w->endTag([$NS, 'param']);
      $w->endTag([$NS, 'data']);
    },
);

sub Conv {
  my ($w, $n) = @_;
  return $hash{$n->{class}}->($w, $n) if ref $n ne 'ARRAY';
  return map $hash{$_->{class}}->($w, $_), @$n;
}

printf STDERR "Reading ABNF grammar from STDIN\n";

my $text = join '', <>;

# remove some offending leading white space
$text =~ s/^\s+(?=[\w-]+\s*=)//mg;

my $rules = Parse::ABNF->new->parse($text, 0);

die unless $rules;

my $w = XML::Writer->new(NAMESPACES => 1);

$w->addPrefix($NS);
$w->startTag([$NS, 'grammar']);
Conv($w, $rules);
$w->endTag([$NS, 'grammar']);
