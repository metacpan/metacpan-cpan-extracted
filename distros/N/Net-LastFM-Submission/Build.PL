use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Net::LastFM::Submission',
	dist_abstract       => 'Perl interface to the Last.fm Submissions Protocol',
	license             => 'perl',
	dist_author         => 'Anatoly Sharifulin <sharifulin@gmail.com>',
	dist_version_from   => 'lib/Net/LastFM/Submission.pm',
	build_requires => {
		'Test::More'      => 0,
		'Test::Exception' => 0,
		'LWP::UserAgent'  => 0,
		'HTTP::Response'  => 0,
		'Encode'          => 0,
	},
	requires => {
		'perl'                  => '5.008',
		'LWP::UserAgent'        => 0,
		'HTTP::Request::Common' => 0,
		'Encode'                => 0,
		'Digest::MD5'           => 0,
		'Carp'                  => 0,
		'Exporter'              => 0,
		
		'POE'                          => 0,
		'POE::Component::Client::HTTP' => 0,
	},
	meta_merge => {
		resources => {
			repository => 'http://github.com/sharifulin/net-lastfm-submission/tree',
		},
		keywords => [
			'last.fm',
			'submission',
		],
	},
    add_to_cleanup     => [],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
