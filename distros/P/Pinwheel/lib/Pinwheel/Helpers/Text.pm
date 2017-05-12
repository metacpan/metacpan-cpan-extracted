package Pinwheel::Helpers::Text;

use strict;
use warnings;

use Exporter;

use Pinwheel::Context;
use Pinwheel::View::String;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(h p lc uc tc join simple_format cycle pluralize ordinal_text);


sub h
{
    return $_[0];
}

sub lc
{
    return CORE::lc($_[0]);
}

sub uc
{
    return CORE::uc($_[0]);
}

sub tc
{
    my $t = CORE::lc($_[0]);
    $t =~ s/\b(\w)/CORE::uc $1/eg;
    $t;
}

sub join
{
    my ($array, $s1, $s2) = @_;
    my ($last);

    return '' unless @$array > 0;
    $last = pop @$array;
    return $last unless @$array > 0;

    $s2 = $s1 if !defined($s2);
    return CORE::join($s2, CORE::join($s1, @$array), $last);
}

sub simple_format
{
    my ($s) = @_;
    my ($parts, $p, $line, $i, $j);

    $s =~ s{^\s+}{};
    $s =~ s{\s+$}{};

    $parts = [['<p>']];
    foreach $p (split(/ *(?:\r?\n *){2,} */, $s)) {
        push @$parts, ["</p>\n<p>"] if $i++;
        $j = 0;
        foreach $line (split(/(?<=[^\r\n])\r?\n(?=[^\r\n])/, $p)) {
            push @$parts, ["<br />\n"] if $j++;
            push @$parts, $line;
        }
    }
    push @$parts, ['</p>'];

    return Pinwheel::View::String->new($parts);
}
*p = *simple_format;

sub cycle
{
    my ($ctx, $key, $i);
    $key = (caller)[2] . "\t" . CORE::join("\t", @_);
    $ctx = Pinwheel::Context::get('render');
    $i = $ctx->{cycle}{$key}++;
    return $_[$i % scalar(@_)];
}

sub pluralize
{
    my ($count, $singular, $plural) = @_;
    return $singular if $count == 1;
    return $plural if defined($plural);
    return $singular . 's';
}

sub ordinal_text
{
    my $i = (0 + shift) % 100;
    return 'th' if ($i >= 10 && $i < 20);
    return qw(th st nd rd th th th th th th)[$i % 10];
}

=head1 SYNOPSIS

  use Pinwheel::Helpers::Text;

  # The following are listed in @EXPORT_OK, but nothing is exported by default

  $text = h($text); # ?

  $text = uc($text); # UPPER CASE
  $text = lc($text); # lower case
  $text = tc($text); # Title Case (uses \b to detect words)

  # Joins the items of @list using $sep, except for the last item which is
  # joined using $last_sep
  $text = join(\@list, $sep, $last_sep);
  join(["Dave Dee", "Dozy", "Beaky", "Mick", "Tich"], ", ", " & ") -> "Dave Dee, Dozy, Beaky, Mick & Tich"

  simple_format; # ?
  # p is an alias for simple_format

  cycle; # ?

  $text = pluralize($count, $singular[, $plural]);
  pluralize(1, "mouse", "mice") -> "mouse"
  pluralize(2, "mouse", "mice") -> "mice"
  pluralize(1, "dog")           -> "dog"
  pluralize(2, "dog")           -> "dogs"

  $text = ordinal_text($n); # One of: st nd rd th
                            # depending on $n

=pod

1;
