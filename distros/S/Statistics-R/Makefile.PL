use inc::Module::Install 1.04;

use lib 'lib';
if ( $^O =~ m/^(?:.*?win32|dos)$/i ) {
    require Statistics::R::Win32;
}


name           'Statistics-R';
all_from       'lib/Statistics/R.pm';

resources
   homepage    'http://search.cpan.org/search?query=statistics%3A%3AR&mode=dist';
   bugtracker  'http://rt.cpan.org/Dist/Display.html?Name=Statistics-R';
   repository  'git@github.com:bricas/statistics-r.git';

build_requires 'Test::More'      => '0.47';

requires       'IPC::Run'        => '0.1'; # availability of $self->{STATE}
requires       'Regexp::Common'  =>  0;
requires       'Text::Balanced'  => '1.97';
requires       'Text::Wrap'      =>  0;
requires       'version'         => '0.77';

requires_external_bin 'R';

WriteAll;

if ( -e 'MANIFEST.SKIP' ) {
   generate_readme( 'lib/Statistics/R.pm', 'README' ); 
}



sub generate_readme {
   my ($in, $out) = @_;
   `pod2text $in $out`;
   warn "Warning: Could not generate $out.\n$!\n" if $? == -1;
   return $?; # exit status
}
