#===============================================================================
#
#  DESCRIPTION:  Test Soy clases
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$
package Plosurin::To::Perl5;
use strict;
use warnings;
use v5.10;
use vars qw($AUTOLOAD);
use Data::Dumper;
package main;
use strict;
use warnings;

use Test::More tests => 3;    # last test to print
use Plosurin::SoyTree;
use Data::Dumper;
use Plosurin::Context;
use Plosurin::To::Perl5;
use Plosurin::Writer::Perl5;

use Plosurin;
our $t1 = <<'T1';
{namespace t.test}
/** ok */
{template .1}
 
{/template}

/*
  * ok
  * @param par raw txt
*/
{template .2}
<h1>template2</h1>
{/template}
T1
=pod
#parse base template
my $p1  = new Plosurin::();
my $f   = $p1->parse( $t1, "test" );
my $ctx = new Plosurin::Context($f);
my $p5  = new Plosurin::To::Perl5(
    'context' => $ctx,
    'writer'  => new Plosurin::Writer::Perl5,
    'package' =>"Test",
);
my $st1 =
  new Plosurin::SoyTree(
    src => '{$par}' );
my $t2 = $st1->reduced_tree;
=cut
=head2 code2perl5 $writer, $code_string

  code2perl5 $p5, '{$test}';

=cut
sub code2perl5 {
    my $code = shift;
    my $p1  = new Plosurin::();
    my $f   = $p1->parse( $t1, "test" );
    my $ctx = new Plosurin::Context($f);
    my $p5  = new Plosurin::To::Perl5(
    'context' => $ctx,
    'writer'  => new Plosurin::Writer::Perl5,
    'package' =>"Test",
);
    my $st1 =
        new Plosurin::SoyTree(
    src => $code,
      offset  =>  0,
      srcfile => 'test'
    );
    my $t2 = $st1->reduced_tree;
    $p5->write( @{$t2} );
    return wantarray()  ? ( $p5->wr->{code}, $t2) : $p5->wr->{code};
}


ok code2perl5('{$par}') =~ /\$args{'par'}/, '{$par}';
ok code2perl5('{import file="t/samples/test.pod6"/}')=~/Some text/, 'import';

ok code2perl5('{foreach $i in [1,10]}ok{print $i}{ifempty}les{/foreach}') =~ m/scalar\(\@\$list_i1\)/i, 'foreach';

1;


