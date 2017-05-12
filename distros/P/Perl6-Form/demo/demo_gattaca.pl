use Perl6::Form;

$diagram = do{ local $/; <DATA> };

$definition = <<EOTEXT;
Men at some time are masters of their fates: / the fault, dear Brutus, is not in our genes, / but in ourselves, that we are underlings. / Brutus and Caesar: what should be in that 'Caesar'?  / Why should that DNA be sequenced more than yours? / Extract them together, yours is as fair a genome; / transcribe them, it doth become mRNA as well; / recombine them, it is as long; clone with 'em, / Brutus will start a twin as soon as Caesar. / Now, in the names of all the gods at once, / upon what proteins doth our Caesar feed, / that he is grown so great?
EOTEXT

print form
     '{[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]}       {[[[[[[[[[[[[[[[}',
     $definition,                                       $diagram;

print "\n\n";

print form
     '{[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]}       {IIIIIIIIIIIIIII}',
     $definition,                                       $diagram;

print "\n\n";

print form
     '{[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]}       {"""""""""""""""}',
     $definition,                                       $diagram;

print "\n\n";

print form
     '{[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]}       {""""""}',
     $definition,                                       $diagram;

print "\n\n";

$diagram =~ s/ /./gm;
$diagram = form '{[[[[[[}', $diagram;
$diagram =~ s/\./ /g;

print form
     '{[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]}       {""""""}',
     $definition,                                       $diagram;


__DATA__
   G==C
     A==T
       T=A
       A=T
     T==A
   G===C
  T==A
 C=G
TA
AT
 A=T
  T==A
    G===C
      T==A
