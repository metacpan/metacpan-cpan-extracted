use inc::Module::Install;

use Cwd;
use File::Copy;

use lib 'lib';
# use OPUS::Tools;

name          'OPUS-Tools';
license       'mit';
author        'Joerg Tiedemann';
include       'Module::AutoInstall';
version       '0.2.2';

install_script 'scripts/opus-cat';
install_script 'scripts/opus-read';
install_script 'scripts/opus-index';
install_script 'scripts/opus-udpipe';

install_script 'scripts/admin/opus-make-website';
install_script 'scripts/admin/opus-website';
install_script 'scripts/admin/opusinfo-set';
install_script 'scripts/admin/opusinfo-refresh';
install_script 'scripts/admin/opusinfo-delete';

install_script 'scripts/alignments/opus-pt2dic';
install_script 'scripts/alignments/opus-pt2dice';
install_script 'scripts/alignments/opus-merge-align';
install_script 'scripts/alignments/opus-split-align';
install_script 'scripts/alignments/opus-swap-align';
install_script 'scripts/alignments/opus-pivoting';

install_script 'scripts/convert/opus-iso639';
install_script 'scripts/convert/opus2text';
install_script 'scripts/convert/opus2moses';
install_script 'scripts/convert/moses2opus';
install_script 'scripts/convert/tmx2opus';
install_script 'scripts/convert/tmx2moses';
install_script 'scripts/convert/opus2multi';
install_script 'scripts/convert/xml2opus';
install_script 'scripts/convert/opus2tmx';
install_script 'scripts/convert/bitext2tmx';


requires 'Archive::Zip'     => 0;
requires 'CGI'              => 0;
requires 'Cwd'              => 0;
requires 'DB_File'          => 0;
requires 'HTML::Entities'   => 0;
requires 'Lingua::Sentence' => 0;
requires 'Test::More'       => 0;
requires 'Ufal::UDPipe'     => 0;
requires 'XML::Parser'      => 0;
requires 'XML::Writer'      => 0;


auto_install;
WriteAll;
