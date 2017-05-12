#!perl
# -*- perl -*-
#
# DO NOT EDIT, created automatically by mkprereqinst.pl

# on Sat Aug  2 00:42:30 2003
#

use Getopt::Long;
my $require_errors;
my $use = 'cpan';

if (!GetOptions("ppm"  => sub { $use = 'ppm'  },
		"cpan" => sub { $use = 'cpan' },
	       )) {
    die "usage: $0 [-ppm | -cpan]\n";
}

if ($use eq 'ppm') {
    require PPM;
    do { print STDERR 'Install URI-Escape'.qq(\n); PPM::InstallPackage(package => 'URI-Escape') or warn ' (not successful)'.qq(\n); } if !eval 'require URI::Escape';
    do { print STDERR 'Install LWP-UserAgent'.qq(\n); PPM::InstallPackage(package => 'LWP-UserAgent') or warn ' (not successful)'.qq(\n); } if !eval 'require LWP::UserAgent';
    do { print STDERR 'Install HTTP-Request'.qq(\n); PPM::InstallPackage(package => 'HTTP-Request') or warn ' (not successful)'.qq(\n); } if !eval 'require HTTP::Request';
    do { print STDERR 'Install Text-ParseWords'.qq(\n); PPM::InstallPackage(package => 'Text-ParseWords') or warn ' (not successful)'.qq(\n); } if !eval 'require Text::ParseWords; Text::ParseWords->VERSION(3.2)';
    do { print STDERR 'Install HTML-TreeBuilder'.qq(\n); PPM::InstallPackage(package => 'HTML-TreeBuilder') or warn ' (not successful)'.qq(\n); } if !eval 'require HTML::TreeBuilder';
    do { print STDERR 'Install URI-URL'.qq(\n); PPM::InstallPackage(package => 'URI-URL') or warn ' (not successful)'.qq(\n); } if !eval 'require URI::URL';
    do { print STDERR 'Install WWW-Search'.qq(\n); PPM::InstallPackage(package => 'WWW-Search') or warn ' (not successful)'.qq(\n); } if !eval 'require WWW::Search; WWW::Search->VERSION(2.35)';
    do { print STDERR 'Install LWP'.qq(\n); PPM::InstallPackage(package => 'LWP') or warn ' (not successful)'.qq(\n); } if !eval 'require LWP; LWP->VERSION(5.48)';
    do { print STDERR 'Install LWP-RobotUA'.qq(\n); PPM::InstallPackage(package => 'LWP-RobotUA') or warn ' (not successful)'.qq(\n); } if !eval 'require LWP::RobotUA';
    do { print STDERR 'Install HTML-Form'.qq(\n); PPM::InstallPackage(package => 'HTML-Form') or warn ' (not successful)'.qq(\n); } if !eval 'require HTML::Form; HTML::Form->VERSION(0.02)';
    do { print STDERR 'Install HTTP-Status'.qq(\n); PPM::InstallPackage(package => 'HTTP-Status') or warn ' (not successful)'.qq(\n); } if !eval 'require HTTP::Status';
    do { print STDERR 'Install HTTP-Cookies'.qq(\n); PPM::InstallPackage(package => 'HTTP-Cookies') or warn ' (not successful)'.qq(\n); } if !eval 'require HTTP::Cookies';
    do { print STDERR 'Install HTTP-Response'.qq(\n); PPM::InstallPackage(package => 'HTTP-Response') or warn ' (not successful)'.qq(\n); } if !eval 'require HTTP::Response';
    do { print STDERR 'Install URI'.qq(\n); PPM::InstallPackage(package => 'URI') or warn ' (not successful)'.qq(\n); } if !eval 'require URI';
    do { print STDERR 'Install User'.qq(\n); PPM::InstallPackage(package => 'User') or warn ' (not successful)'.qq(\n); } if !eval 'require User; User->VERSION(1.05)';
    do { print STDERR 'Install Tie-Persistent'.qq(\n); PPM::InstallPackage(package => 'Tie-Persistent') or warn ' (not successful)'.qq(\n); } if !eval 'require Tie::Persistent; Tie::Persistent->VERSION(0.901)';
    do { print STDERR 'Install URI-http'.qq(\n); PPM::InstallPackage(package => 'URI-http') or warn ' (not successful)'.qq(\n); } if !eval 'require URI::http';
    do { print STDERR 'Install Storable'.qq(\n); PPM::InstallPackage(package => 'Storable') or warn ' (not successful)'.qq(\n); } if !eval 'require Storable; Storable->VERSION(0.6)';
    do { print STDERR 'Install XML-XPath'.qq(\n); PPM::InstallPackage(package => 'XML-XPath') or warn ' (not successful)'.qq(\n); } if !eval 'require XML::XPath';
} else {
    use CPAN;
    install 'URI::Escape' if !eval 'require URI::Escape';
    install 'LWP::UserAgent' if !eval 'require LWP::UserAgent';
    install 'HTTP::Request' if !eval 'require HTTP::Request';
    install 'Text::ParseWords' if !eval 'require Text::ParseWords; Text::ParseWords->VERSION(3.2)';
    install 'HTML::TreeBuilder' if !eval 'require HTML::TreeBuilder';
    install 'URI::URL' if !eval 'require URI::URL';
    install 'WWW::Search' if !eval 'require WWW::Search; WWW::Search->VERSION(2.35)';
    install 'LWP' if !eval 'require LWP; LWP->VERSION(5.48)';
    install 'LWP::RobotUA' if !eval 'require LWP::RobotUA';
    install 'HTML::Form' if !eval 'require HTML::Form; HTML::Form->VERSION(0.02)';
    install 'HTTP::Status' if !eval 'require HTTP::Status';
    install 'HTTP::Cookies' if !eval 'require HTTP::Cookies';
    install 'HTTP::Response' if !eval 'require HTTP::Response';
    install 'URI' if !eval 'require URI';
    install 'User' if !eval 'require User; User->VERSION(1.05)';
    install 'Tie::Persistent' if !eval 'require Tie::Persistent; Tie::Persistent->VERSION(0.901)';
    install 'URI::http' if !eval 'require URI::http';
    install 'Storable' if !eval 'require Storable; Storable->VERSION(0.6)';
    install 'XML::XPath' if !eval 'require XML::XPath';
}
if (!eval 'require URI::Escape;') { warn $@; $require_errors++ }
if (!eval 'require LWP::UserAgent;') { warn $@; $require_errors++ }
if (!eval 'require HTTP::Request;') { warn $@; $require_errors++ }
if (!eval 'require Text::ParseWords; Text::ParseWords->VERSION(3.2);') { warn $@; $require_errors++ }
if (!eval 'require HTML::TreeBuilder;') { warn $@; $require_errors++ }
if (!eval 'require URI::URL;') { warn $@; $require_errors++ }
if (!eval 'require WWW::Search; WWW::Search->VERSION(2.35);') { warn $@; $require_errors++ }
if (!eval 'require LWP; LWP->VERSION(5.48);') { warn $@; $require_errors++ }
if (!eval 'require LWP::RobotUA;') { warn $@; $require_errors++ }
if (!eval 'require HTML::Form; HTML::Form->VERSION(0.02);') { warn $@; $require_errors++ }
if (!eval 'require HTTP::Status;') { warn $@; $require_errors++ }
if (!eval 'require HTTP::Cookies;') { warn $@; $require_errors++ }
if (!eval 'require HTTP::Response;') { warn $@; $require_errors++ }
if (!eval 'require URI;') { warn $@; $require_errors++ }
if (!eval 'require User; User->VERSION(1.05);') { warn $@; $require_errors++ }
if (!eval 'require Tie::Persistent; Tie::Persistent->VERSION(0.901);') { warn $@; $require_errors++ }
if (!eval 'require URI::http;') { warn $@; $require_errors++ }
if (!eval 'require Storable; Storable->VERSION(0.6);') { warn $@; $require_errors++ }
if (!eval 'require XML::XPath;') { warn $@; $require_errors++ }warn "Autoinstallation of prerequisites completed\n" if !$require_errors;
