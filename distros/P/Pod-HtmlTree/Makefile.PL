use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

#     # Generate documentation?
# if (prompt("Generate HTML documentation?", "n") =~ /^y/) {
#     require "lib/Pod/HtmlTree.pm";
#     Pod::HtmlTree::pod2htmltree("/perldoc/Pod-HtmlTree");
#     print Pod::HtmlTree::banner(
#         "Make sure http://localhost/perldoc/Pod-HtmlTree points to ", `pwd`);
# }

WriteMakefile(
    'NAME'		=> 'Pod::HtmlTree',
    'VERSION_FROM'	=> 'lib/Pod/HtmlTree.pm', # finds $VERSION
    'EXE_FILES'         => ['eg/pod2htmltree'],
    'PREREQ_PM'		=> { File::Path     => 0,
                             Pod::Html      => 0,
                             Exporter       => 0,
                             Text::Wrap     => 0,
                             File::Find     => 0,
                             File::Spec     => 0,
                             File::Basename => 0,
                             Cwd            => 0,
                           }, # e.g., Module::Name => 1.1
     clean              => {FILES => "docs/html"},
);
