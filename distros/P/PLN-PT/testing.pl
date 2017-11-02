
use PLN::PT;
use Data::Dumper;
use utf8::all;

#my $txt = 'O  presente  documento  enuncia  as  Normas  de  Participação  do  Orçamento  Participativo  de  Guimarães  para  2015,  a  seguir  designado  por  OP2015,  definindo  os  procedimentos  a  adotar  por  cada  cidadão  no  momento  da  sua  participação,  tendo  sempre  como  normativo  superior  a  Carta  de  Princípios  e  o  Regulamento Geral do OP aprovados pela Câmara Municipal .';
#my $txt = 'As  propostas  podem  ser  apresentadas  por  via  eletrónica,  mediante  registo  a  efetuar  no  portal  criado  pela  Câmara  Municipal  de  Guimarães  para  o  efeito  (http://op.cm-guimaraes.pt)  ou,  presencialmente,  em  Assembleias  Participativas.  No  OP_ESCOLAS’2015,  as  propostas  devem  ser  apresentadas  nas  Direções Escolares, em formulário próprio a disponibilizar para o efeito.';
my $txt = 'A Maria tem razão .';

my $pln = PLN::PT->new('http://api.pln.pt');

my $data = $pln->dep_parser($txt);
print Dumper $data;





#my $data = $nlp->tf($txt, {stopwords=>1, term=>'lemma'});
#print Dumper $data;


__END__
my $data = $nlp->stopwords;
print Dumper $data;

__END__
my @toks;
push @toks, $_->[0] foreach (@$data);

print join(' ', @toks), "\n";;

