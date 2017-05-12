=comment

Generates _pbs.exe from the installed PBS copy.
 _pbs.exe should be put on kurdamir.

Generates pbs.exe from run_pbs.pl.
pbs.exe fetches _pbs.exe from kurdamir when run.

=cut

<<`EOC`
pp -d -c -o _pbs.exe c:\Perl\bin\pbs.pl -a "c:\devel\PerlBuildSystem\Plugins;Plugins" -a "c:\devel\PerlBuildSystem\PBSLib;PBSLib" -M PBS::WatchClient -M PBS::Prf -M PBS::Warp1_5 -M File::Slurp -M Devel::Depend::Cl -M Pod::Simple::HTMLBatch -M Devel::Size
pp -d -o pbs.exe run_pbs.pl
EOC

