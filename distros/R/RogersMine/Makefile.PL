use inc::Module::Install '1.0';
name 'RogersMine';
license 'MIT';
version_from 'lib/RogersMine.pm';
all_from qw(lib/RogersMine.pm lib/RogersMine/MineField.pm lib/RogersMine/Cell.pm lib/RogersMine/App.pm);
no_index directory => 'data';
install_script 'script/rogers_mine.pl';
cpanfile;

WriteAll;
