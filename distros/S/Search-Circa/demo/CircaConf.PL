 use Config;
 use File::Basename qw(basename dirname);

$VERSION = ('$Revision: 1.3 $ ' =~ /(\d+\.\d+)/)[0];

 open(O,".m") or die "Can't found circa information:$!\n";
 my $l =<O>;
 close(O);
 my @l=split(/\t/,$l);
 $l[6].="/lib";

 if ($ARGV[0] and $ARGV[0] ne '../blib/lib/CircaConf.pm') {
   remplace_use_lib($ARGV[0], $l[6]);
 }
 elsif ($ARGV[0] and $ARGV[0] eq '../blib/lib/CircaConf.pm') {
 chdir(dirname($0));
 ($file = basename($0)) =~ s/\.PL$//;
 $file.=".pm";
 $file = "../blib/lib/".$file;
 $file =~ s/\.pl$//
   if ($Config{'osname'} eq 'VMS' or $config{'osname'} eq 'OS2'); 

 open OUT,">$file" or die "Can't create $file: $!";
 chmod(0755, $file);
 print "Extracting $file (with variable substitutions)\n";


 print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w
package CircaConf;

use vars qw(\$VERSION \@ISA \@EXPORT \@EXPORT_OK);
require Exporter;
\@ISA = qw(Exporter);
\@EXPORT = qw();

#-------- A MODIFIER --------#

# Utilisateur Mysql
\$CircaConf::User     = "$l[0]";

# Password Mysql
\$CircaConf::Password = "$l[1]";

# Adresse DNS du serveur DNS
\$CircaConf::Host     = "$l[2]";

# Nom de la base de donnée
\$CircaConf::Database = "$l[3]";

# Repertoire ou creer / lire les fichier d'export / import
# (droit en ecriture pour user apache necessaire si export en mode cgi)
\$CircaConf::export = "$l[4]";

# Repertoire des masques HTML
\$CircaConf::TemplateDir = "$l[5]";

# Repertoire des librairies de Circa si non installe par root
\$CircaConf::CircaDir = "$l[6]";

# optional now. Circa can run without change this
# some values ...
%CircaConf::conf=
  (
   'author'            => 'circa@alianwebserver.com', # Responsable du moteur
   'temporate'         => 0,  # Temporise les requetes sur le serveur de 8s.
   'facteur_keyword'   => 15, # <meta name="KeyWords"
   'facteur_description'  => 10, # <meta name="description"
   'facteur_titre'     => 10, # <title></title>
   'facteur_full_text' => 1,  # reste
   'facteur_url'       => 10, #
   'nb_min_mots'       => 3,  # facteur min pour garder un mot
   'niveau_max'        => 10,  # Niveau max à indexer
   'indexCgi'          => 0   # follow link for CGI (ex: ?nom=toto&riri=eieiei
   );

# HTML Template for display
# Warning: all HTML '"' must be translate to '\"'

# For link, you can use :
# - \$url         : ?
# - \$titre       : (<title></title>)
# - \$description : (<meta name=..)
# - \$facteur     : ratio
# - \$langue      : From HTTP header field
# - \$last_update : From HTTP header field
\$CircaConf::templateS ='"
<!-- Link item -->
<div class=\\"item\\">\$indiceG - <a href=\\"\$url\\" target=\\"_blank\\"> \$titre </a> 
    \$description <br>
          <b>Url:</b> \$url <br>
          <b>Score:</b> \$facteur
          <b>Last update:</b> \$last_update 
</div>
"';

# For categorie, you can use:
# - \$links       : Url to print this categorie
# - \$nom_complet : Name with other categorie
# - \$nom         : Short name
\$CircaConf::templateC='"
<!-- categorie item -->
<p><a href=\\"\$links\\">\$nom_complet</a><br></p>
"';


# Fin
!GROK!THIS!

close(OUT);
 `cp ../blib/lib/CircaConf.pm ../lib`;
 chmod 0755, "../blib/lib/CircaConf.pm";
}

sub remplace_use_lib {
  my ($file, $path)=@_;
  $file.=".PL";
  my $dest=$file;
  $dest =~ s/\.PL$//;
  print "Extracting $dest (with variable substitutions) from $file\n";
  my $regexp = "use lib '/path/to/circa';";
  open(F,$file) || die "Can't read $file:$!\n";
  my @l = <F>;
  close(F);
  my $l=join("",@l);
  $l=~s/$regexp/use lib '$path';/gm;
  open(F,">$dest") || die "Can't write $dest:$!\n";
  print F $l;
  close(F);
}
