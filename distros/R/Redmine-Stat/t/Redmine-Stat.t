# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Redmine-Stat.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Data::Dumper;
use Test::More tests => 46;
use File::Slurp;

our $issues_xml; our $projects_xml; our $trackers_xml;


BEGIN { use_ok('Redmine::Stat'); new_ok (Redmine::Stat); };
BEGIN { #internal utils
	use Redmine::Stat;

	my $redmine=new Redmine::Stat;
	$redmine->xml_type('issues_test');

	is( $redmine->xml_type(), 'issues_test', 'Current XML type setting' );

	our $url = 'https://redmine.redmine.ru';
	our $auth_key = 'eec5oZaequo7shahsh8hui5aiyieB1Xo';

	$redmine->auth_key($auth_key);
	is ($redmine->auth_key, $auth_key, 'Setting authentication key');

	$url =~ s/\/$//;
	$redmine->url($url.'/');

	is ($redmine->url, $url, 'Setting redmine url');
	
	is ($redmine->_get_query_url('issues'), 'https://redmine.redmine.ru/issues.xml', 'Issues url generation (without query_id)');

	$redmine->query_id(100500);
	is ($redmine->query_id, 100500, 'Setting query id');

	is ($redmine->_get_query_url('issues'), 'https://redmine.redmine.ru/issues.xml?query_id=100500', 'Issues url generation (with query_id)');

	is ($redmine->_get_query_url('projects'), 'https://redmine.redmine.ru/projects.xml', 'Projects url generation');
	is ($redmine->_get_query_url('trackers'), 'https://redmine.redmine.ru/trackers.xml', 'Trackers url generation');

}
BEGIN { #new constructor
	use Redmine::Stat;
	use Data::Dumper;
	$url = 'https://redmine1.redmine1.ru';
	$auth_key = 'Aiv6vaiph7ooVeew';
	my $redmine = Redmine::Stat->new (
		url		=> $url,
		auth_key	=> $auth_key,
		query_id	=> 100501,
	);
	is ($redmine->url, $url, 'Setting redmine url via constructor');
	is ($redmine->auth_key, $auth_key, 'Setting auth key via constructor');
	is ($redmine->query_id, 100501, 'Setting query id via constructor');

}
BEGIN { #Issues tests
	use Redmine::Stat;
	use utf8;
	my $redmine = new Redmine::Stat;
	
	ok( open(my $FFH, './t/fixtures/issues.xml'), 'Issues fixture presence' );
	binmode $FFH;
	my $xml;
	
	$xml .= $_ while( <$FFH> );

	$issues_xml = $xml;

	$redmine->_parse_xml ($xml);
	my $doc=$redmine->raw_xml();
	my $rootNode=$doc->documentElement;
	
	is ($rootNode->getAttribute('total_count'), 64, 'XML Parsing (issues)' );

	$redmine->xml_type('issues');

	is ($redmine->total_issues, 64, 'Total issues count' );

	is ($redmine->issues_by_tracker('SEO'), 12, 'Issues by tracker name' );
	is ($redmine->issues_by_tracker(4), 12, 'Issues by tracker id' );

	is ($redmine->issues_by_author('ieFaiheir7ze'), 4, 'Issues by author name' );
	is ($redmine->issues_by_author(35), 4, 'Issues by author id');

	is ($redmine->issues_by_status('Новая'), 25, 'Issues by status name' );
	is ($redmine->issues_by_status(1), 25, 'Issues by status id' );

	is ($redmine->issues_by_project('wah0uu8Ohnoonu5'), 6, 'Issues by project name' );
	is ($redmine->issues_by_project('50'), 6, 'Issues by project id' );

	is( $redmine->total_projects, 16, 'Total projects (by issues) count' );

	$redmine->_parse_projects;
	my %prj=%{$redmine->project(50)};
	is( $prj{issues_count}, 6, 'Issues by project count' );

	$redmine->_parse_trackers;
	my %trk=%{$redmine->tracker(4)};
	is( $trk{issues_count}, 12, 'Issues by tracker count' );

}

BEGIN { #Project tests
	use Redmine::Stat;
	use utf8;

	my $redmine=new Redmine::Stat;

	ok (open(my $FFH, './t/fixtures/projects.xml'). 'Projects fixture presence' );
	binmode $FFH;
	my $xml;

	$xml .= $_ while( <$FFH> );

	$projects_xml = $xml;

	$redmine->_parse_xml ($xml);
	
	my $doc=$redmine->raw_xml();
	my $rootNode=$doc->documentElement;

	is ($rootNode->getAttribute('total_count'), 25, 'XML Parsing (projects)' );

	$redmine->xml_type('projects');

	is ($redmine->total_projects, 25, 'Total projects count' );
	$redmine->_parse_projects;

	$test_hash={
		'name'		=> 'paef6ez0iePhu2e',
		'redmine_path'	=> 'ahph5Tho6iTh9la',
		'description'	=> 'Российское представительство канадской компании paef6ez0iePhu2e. Сайт полностью на нас.',
	};

	is_deeply ($redmine->project(66), $test_hash, 'Projects parsing from projects.xml' );
	is_deeply ($redmine->project('paef6ez0iePhu2e'), $test_hash, 'Projects parsing from projects.xml (by name)' );
	is_deeply ($redmine->project('ahph5Tho6iTh9la'), $test_hash, 'Projects parsing from projects.xml (by path)' );

}

BEGIN { #tracker tests
	use Redmine::Stat;
	use utf8;

	my $redmine=new Redmine::Stat;

	ok (open(my $FFH, './t/fixtures/trackers.xml'). 'Trackers fixture presence' );
	binmode $FFH;
	my $xml;

	$xml .= $_ while( <$FFH> );

	$trackers_xml = $xml;

	$redmine->xml_type('trackers');
	$redmine->_parse_xml ($xml);
	is ($redmine->total_trackers, 6, 'Total trackers count' );

	$redmine->_parse_trackers;

	$redmine->xml_type('bad_test_xml_type');

	is ($redmine->total_trackers, 6, 'Total trackers count for coverage' );

	$test_hash={
		'name'		=> 'SEO',
		'issues_count'	=> 12,
	};

	is_deeply ($redmine->tracker(4), $test_hash, 'Tracker parsing from trackers.xml' );
	is_deeply ($redmine->tracker('SEO'), $test_hash, 'Tracker parsing from trackers.xml (by name)' );


}	

BEGIN { #more complex tests through fixtures
	use Redmine::Stat;
	use utf8;

	
	SKIP: {
		skip 'Complex internal tests through fixtures', 4 unless $projects_xml and $trackers_xml and $issues_xml;

		my $redmine=new Redmine::Stat;

		$redmine->xml_type('issues'); 
		$redmine->_parse_xml ($issues_xml);
		
		$redmine->_parse_projects; 
		$redmine->_parse_trackers;

		$redmine->xml_type('projects');
	       	$redmine->_parse_xml ($projects_xml);
		
		$redmine->_parse_projects;

		$redmine->xml_type('trackers'); 
		$redmine->_parse_xml ($trackers_xml);
		
		$redmine->_parse_trackers;
		
		#is ($redmine->total_issues, 64, 'Issues count. One more time with xml type unset' );
	        $test_hash={
			'name'          => 'wah0uu8Ohnoonu5',
			'issues_count'	=> 6,
		};
		is_deeply ($redmine->project('wah0uu8Ohnoonu5'), $test_hash, 'Issues by project count (project not in projects.xml' );

		$test_hash={
			'name'		=> 'oovooSeejeer9da',
			'redmine_path'	=> 'zejahz1Uqu5uNgi',
			'description'	=> 'Интернет-магазин телефонов, коммуникаторов и пр. электроники.',
			'issues_count'	=> 1,
		};
		is_deeply ($redmine->project(68), $test_hash, 'Issues by project count (project in projects.xml' );


		$test_hash={
			'name'		=> 'Bug',
			'issues_count'	=> 5,
		};
		
		is_deeply ($redmine->tracker(1), $test_hash, 'Issues by tracker count (complex)' );

		cmp_ok ($redmine->total_projects, '>=', scalar $redmine->projects, 'Projects count versus $self->projects()');

	}

}

BEGIN { #complex test in real environment
	use Redmine::Stat;
	use utf8;

	SKIP: {
		eval {
			our $url	= read_file ('./t/real_auth_data/url'); chomp $url;
			our $auth_key	= read_file ('./t/real_auth_data/auth_key'); chomp $auth_key;
			our $query_id	= read_file ('./t/real_auth_data/query_id'); chomp $query_id;
		};
		skip 'Real environment tests', 4 if $@ or ( not length $url or not length $auth_key or not length $query_id);
		my $redmine=new Redmine::Stat;
		$redmine->auth_key($auth_key);
		$redmine->url($url);
		$redmine->query_id($query_id);
		
		$redmine->query();

		$total_issues = $redmine->total_issues;
		cmp_ok ($total_issues, '>=', 1, 'Non-zero issues count (real environment)');
		cmp_ok ($redmine->total_projects, '>=', scalar $redmine->projects, 'Projects count versus $self->projects() in real environment');

		$total_issues_from_projects=0;
		foreach($redmine->projects)
		{
			my $prj = $redmine->project($_);
			$total_issues_from_projects += $prj->{issues_count} if exists $prj->{issues_count};
		}
	
		cmp_ok ($total_issues_from_projects, '==', $total_issues, 'Issues by redmine meta versus issues got by parsing projects');
		
		$total_issues_from_trackers=0;
		foreach($redmine->trackers)
		{
			my $trk = $redmine->tracker($_);
			$total_issues_from_trackers += $trk->{issues_count} if exists $trk->{issues_count};
		}

		cmp_ok($total_issues_from_trackers, '==', $total_issues, 'Issues by redmine meta versus issues got by parsing trackers');
	}
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

