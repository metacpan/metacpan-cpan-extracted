use strict;
use inc::Module::Install;

name "RSSycklr";
license "perl";
all_from "lib/RSSycklr.pm";
resources repository => 'git@github.com:pangyre/p5-rssycklr.git';

requires "Mouse";
requires "XML::LibXML";
requires "XML::Feed";
requires "Template";
requires "YAML";
requires "HTML::Truncate";
requires "HTML::Entities";
requires "HTML::TokeParser::Simple";
requires "DateTime";
requires "URI";
requires "Encode";
requires "Pod::Usage";
requires "Getopt::Long";
requires "File::ShareDir";
requires "Hash::Merge::Simple";
requires "Capture::Tiny";

system('pod2text lib/RSSycklr.pm > README');

install_script "bin/rssycklr";
install_share "dtd";

auto_install;
WriteAll;

__END__
