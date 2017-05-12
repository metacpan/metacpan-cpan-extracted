#!/usr/bin/perl 
package CalcActions;
use warnings;
use base NoacInh;

sub NUM {
  return $_[1];
}

sub PLUS {
  $_[1]+$_[3];
}

sub TIMES {
  $_[1]*$_[3];
}

my $parser = __PACKAGE__->new(); 
$parser->slurp_file('', "Write an expression: ","\n"); 
my $t = $parser->Run();

print "$t\n" unless $parser->YYNberr;

=head1 SYNOPSIS

Both C<icalcu.pl> and C<ipostf.pl> inherit and recycle
the grammar in C<NoacInh.eyp>

Do:

       eyapp NoacInh
       icalcu.pl
       ipostf.pl
