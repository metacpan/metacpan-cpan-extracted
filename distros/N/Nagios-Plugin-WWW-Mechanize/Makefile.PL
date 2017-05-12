use inc::Module::Install;

name	"Nagios-Plugin-WWW-Mechanize";
all_from	"lib/Nagios/Plugin/WWW/Mechanize.pm";

requires	"Nagios::Plugin";
requires	"WWW::Mechanize";
requires	"Time::HiRes";

WriteAll;
