use strictures 2;
use Devel::Dwarn;

BEGIN { package Lexicality;
  use Exporter 'import'; our @EXPORT = qw(wrap suspend resume);

  use B qw(svref_2object);

  sub wrap {
    my ($sub) = @_;
    my $padlist = svref_2object($sub)->PADLIST;
    my @b_pn = $padlist->ARRAYelt(0)->ARRAY;
    my %padnames = map +($b_pn[$_]->PV => $_),
                     grep $b_pn[$_]->can('PV')
                          && defined($b_pn[$_]->PV)
                          && $b_pn[$_]->PV ne '&',
                       0..$#b_pn;
::Dwarn \%padnames;
    return sub {
      local our $Current_Sub = $sub;
      local our %Padnames = %padnames;
      $sub->(@_);
    };
  }

  sub suspend {
    my ($label) = @_;
    die "Not in a suspendable sub" unless my $sub = our $Current_Sub;
    my %padvalues; my %padnames = our %Padnames;
    my @curpad = (svref_2object($sub)->PADLIST->ARRAY)[-1]->ARRAY;
    @padvalues{keys %padnames}
      = map $_->object_2svref, @curpad[values %padnames];
::Dwarn \%padvalues;
    return sub {
      local our $Current_Sub = $sub;
      local our %Padnames = %padnames;
      local our %Padvalues = %padvalues;
      local our $Resume_Label = $label;
      $sub->();
    };
  }

  sub resume {
    die "Not in a suspendable sub" unless my $sub = our $Current_Sub;
    return unless my $label = our $Resume_Label;
    my %padvalues = our %Padvalues; my %padnames = our %Padnames;
    my @curpad = (svref_2object($sub)->PADLIST->ARRAY)[-1]->ARRAY;
    foreach my $name (keys %padnames) {
      my $padvalue = $curpad[$padnames{$name}]->object_2svref;
      if ($name =~ /^\$/) {
        ${$padvalue} = ${$padvalues{$name}};
      } elsif ($name =~ /^\@/) {
        @{$padvalue} = @{$padvalues{$name}};
      } elsif ($name =~ /^\%/) {
        %{$padvalue} = %{$padvalues{$name}};
      }
    }
    no warnings 'exiting';
    goto $label;
  }

  $INC{'Lexicality.pm'} = __FILE__;
}

use Lexicality;

sub foo {
  resume;
  my ($x, $y, @z) = @_;
  warn "here";
  return suspend 'FOO';
  FOO:
  Dwarn { x => $x, y => $y, z => \@z };
}

my $foo = wrap \&foo;

my $res = $foo->('foo', 'bar', 1..3);

$res->();
