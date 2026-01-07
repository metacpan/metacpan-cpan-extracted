# Templates for ExtUtils::ModuleMaker::ASPEER

These templates are for use with ExtUtils::ModuleMaker::ASPEER, which generates skeleton Perl modules
or scripts. To use them clone to a directory and reference via the -t command line option.

`git clone https://github.com/aspeer/pl-modulemaker.templates.git ~/my.templates`

Then (from ExtUtils::ModuleMaker::ASPEER):

`modulemaker_aspeer.pl -n App::Foobar -a  -s foobar.pl -t ~/my.templates`
