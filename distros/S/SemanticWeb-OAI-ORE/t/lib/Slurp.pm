package Slurp;

=head1 NAME 

Slurp - read file to string

=head1 SYNOPSIS

To read file:

 use Slurp;
 my $ex=slurp("file.ex");

or with Test::More

 use Test::More;
 use Slurp;
 is( $result, slurp('testfile'), "output as expected" );

=cut

use strict;
use base qw(Exporter);
our @EXPORT=qw(slurp);

sub slurp {
  my ($file)=@_;
  my $str='';
  if (open(my $fh,'<',$file)) {
    local $/=undef;
    $str=<$fh>;
    close($fh);
  } else {
    warn "# Failed to slurp test file '$file'\n";
  }
  return($str);
}

1;
