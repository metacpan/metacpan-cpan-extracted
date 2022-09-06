use 5.014; use warnings;

my $sc = q<https://github.com/ap/Plack-Middleware-MockProxyFrontend>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Plack-Middleware-MockProxyFrontend>;

our %META = (
	name        => 'Plack-Middleware-MockProxyFrontend',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2015 },
	license     => 'perl_5',
	resources   => {
		license    => [ q<https://dev.perl.org/licenses/> ],
		repository => { type => 'git', url => "$sc.git", web => $sc },
		bugtracker => { web => $bt },
	},
	dynamic_config => 0,
	prereqs => {
		runtime => {
			requires => {qw(
				perl 5.014
				Plack::Middleware 0
				Plack::Util::Accessor 0
				URI::Split 0
				Plack::Util 0
				IO::Socket::SSL 0
				HTTP::Server::PSGI 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
