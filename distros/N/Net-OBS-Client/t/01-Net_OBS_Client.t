use strict;
use warnings;

use FindBin;

BEGIN {
  unshift @::INC, "$FindBin::Bin/../lib";
}

use Test::More tests => 14;
use Data::Dumper;

use Test::HTTP::MockServer;

#osc api /build/OBS:Server:Unstable/images/x86_64/OBS-Appliance:qcow2/_status
#<status package="OBS-Appliance:qcow2" code="succeeded">
#  <details></details>
#</status>

my $project = 'devel:languages:perl';
my $package = 'perl-Net-OBS-Client';
my $repo    = "openSUSE_Leap_15.2";
my $arch    = "x86_64";

my $server = Test::HTTP::MockServer->new();

my $apiurl = $server->url_base();

my $handle_request_phase1 = sub {
  my ($request, $response) = @_;
  my $results = {

      #osc api /build/OBS:Server:Unstable/images/x86_64/OBS-Appliance:qcow2/_status
      "///build/$project/$repo/$arch/$package/_status"
        => sub {
          $response->content('
<status package="'.$package.'" code="succeeded">
    <details></details>
</status>
');
       },

       # osc api "/build/devel:languages:perl/openSUSE_Leap_15.2/x86_64/perl-Net-OBS-Client"
       "///build/$project/$repo/$arch/$package"
         => sub {
           $response->content('
<binarylist>
  <binary filename="_buildenv" size="155913" mtime="1610717523"/>
  <binary filename="_statistics" size="1028" mtime="1610717523"/>
  <binary filename="perl-Net-OBS-Client-0.0.6-lp152.3.1.noarch.rpm" size="22500" mtime="1610717523"/>
  <binary filename="perl-Net-OBS-Client-0.0.6-lp152.3.1.src.rpm" size="19159" mtime="1610717523"/>
  <binary filename="rpmlint.log" size="386" mtime="1610717523"/>
</binarylist>
');
      },

      # osc api "/build/devel:languages:perl/openSUSE_Leap_15.2/x86_64/perl-Net-OBS-Client/perl-Net-OBS-Client-0.0.6-lp152.3.1.noarch.rpm?view=fileinfo"
      "///build/$project/$repo/$arch/$package/perl-Net-OBS-Client-0.0.6-lp152.3.1.noarch.rpm?view=fileinfo"
        => sub {
          $response->content('
<fileinfo filename="perl-Net-OBS-Client-0.0.6-lp152.3.1.noarch.rpm">
  <name>perl-Net-OBS-Client</name>
  <version>0.0.6</version>
  <release>lp152.3.1</release>
  <arch>noarch</arch>
  <source>perl-Net-OBS-Client</source>
  <summary>Simple OBS API calls</summary>
  <description>Net::OBS::Client aims to simplify usage of OBS
(https://openbuildservice.org) API calls in perl.</description>
  <size>22500</size>
  <mtime>1610717523</mtime>
  <provides>perl(Net::OBS::Client) = 0.0.6</provides>
  <provides>perl(Net::OBS::Client::BuildResults)</provides>
  <provides>perl(Net::OBS::Client::DTD)</provides>
  <provides>perl(Net::OBS::Client::Package)</provides>
  <provides>perl(Net::OBS::Client::Project)</provides>
  <provides>perl(Net::OBS::Client::Roles::BuildStatus)</provides>
  <provides>perl(Net::OBS::Client::Roles::Client)</provides>
  <provides>perl-Net-OBS-Client = 0.0.6-lp152.3.1</provides>
  <requires>perl(:MODULE_COMPAT_5.26.1)</requires>
  <requires>perl(Config::INI::Reader)</requires>
  <requires>perl(Config::Tiny)</requires>
  <requires>perl(HTTP::Cookies)</requires>
  <requires>perl(HTTP::Request)</requires>
  <requires>perl(LWP::UserAgent)</requires>
  <requires>perl(Moose)</requires>
  <requires>perl(Moose::Role)</requires>
  <requires>perl(Path::Class)</requires>
  <requires>perl(URI::URL)</requires>
  <requires>perl(XML::Structured)</requires>
</fileinfo>
');
      },
      # /build/devel:languages:perl/_result?package=perl-Net-OBS-Client
      "///build/$project/_result?package=$package"
        => sub {
          $response->content('
<resultlist state="14e39e302c4c6c21e72da11bf5e97888">
  <result project="devel:languages:perl" repository="openSUSE_Leap_15.3" arch="x86_64" code="published" state="published" dirty="true">
    <status package="perl-Net-OBS-Client" code="succeeded"/>
  </result>
  <result project="devel:languages:perl" repository="openSUSE_Leap_15.2" arch="x86_64" code="published" state="published" dirty="true">
    <status package="perl-Net-OBS-Client" code="succeeded"/>
  </result>
  <result project="devel:languages:perl" repository="openSUSE_Leap_15.1" arch="x86_64" code="published" state="published" dirty="true">
    <status package="perl-Net-OBS-Client" code="succeeded"/>
  </result>
  <result project="devel:languages:perl" repository="openSUSE_Leap_15.0" arch="x86_64" code="published" state="published" dirty="true">
    <status package="perl-Net-OBS-Client" code="succeeded"/>
  </result>
</resultlist>
');
      },
  };
  if ($results->{$request->uri}) {
    $results->{$request->uri}->();
  } else {
    $response->code(404);
    $response->message("NOT FOUND");
    $response->content("Result for ".$request->uri." not defined");
  }

};

$server->start_mock_server($handle_request_phase1);

my $got;
my $expected;
################################################################################
# TESTS FOR Net::OBS::Client
use_ok('Net::OBS::Client');

my $obj = Net::OBS::Client->new(
  apiurl     => $apiurl,
  repository => $repo,
  arch       => $arch,
  use_oscrc  => 0,
);

my $obj2 = Net::OBS::Client->new(
  apiurl     => $apiurl,
  repository => 'unknown',
  arch       => 'unknown',
  use_oscrc  => 0,
);

# END Net::OBS::Client->project tests
my $prj = $obj->project(name=>$project);
$expected = {
          'state' => '14e39e302c4c6c21e72da11bf5e97888',
          'result' => [
                        {
                          'dirty' => 'true',
                          'code' => 'published',
                          'project' => 'devel:languages:perl',
                          'state' => 'published',
                          'status' => [
                                        {
                                          'code' => 'succeeded',
                                          'package' => 'perl-Net-OBS-Client'
                                        }
                                      ],
                          'arch' => 'x86_64',
                          'repository' => 'openSUSE_Leap_15.3'
                        },
                        {
                          'state' => 'published',
                          'project' => 'devel:languages:perl',
                          'code' => 'published',
                          'dirty' => 'true',
                          'repository' => 'openSUSE_Leap_15.2',
                          'arch' => 'x86_64',
                          'status' => [
                                        {
                                          'package' => 'perl-Net-OBS-Client',
                                          'code' => 'succeeded'
                                        }
                                      ]
                        },
                        {
                          'status' => [
                                        {
                                          'package' => 'perl-Net-OBS-Client',
                                          'code' => 'succeeded'
                                        }
                                      ],
                          'arch' => 'x86_64',
                          'repository' => 'openSUSE_Leap_15.1',
                          'dirty' => 'true',
                          'code' => 'published',
                          'project' => 'devel:languages:perl',
                          'state' => 'published'
                        },
                        {
                          'state' => 'published',
                          'project' => 'devel:languages:perl',
                          'code' => 'published',
                          'dirty' => 'true',
                          'repository' => 'openSUSE_Leap_15.0',
                          'arch' => 'x86_64',
                          'status' => [
                                        {
                                          'package' => 'perl-Net-OBS-Client',
                                          'code' => 'succeeded'
                                        }
                                      ]
                        }
                      ]
        };

$got = $prj->fetch_resultlist(package => $package);
is_deeply($got, $expected, "Checking Client->project->fetch_resultlist");
is($prj->code, 'published', "Checking Client->project->code");
is($prj->dirty, 1,  "Checking Client->project->dirty");

$prj = $obj2->project(name=>$project, repository=>$repo, arch=>$arch);
$got = $prj->fetch_resultlist(package => $package);
is_deeply($got, $expected, "Checking Client->project->fetch_resultlist (obj2)");
# END Net::OBS::Client->project tests
# TESTS FOR Net::OBS::Client::Project END
################################################################################

################################################################################
# TESTS FOR Net::OBS::Client::Project
use_ok('Net::OBS::Client::Project');

$prj = Net::OBS::Client::Project->new(
  apiurl => $apiurl,
  name   => $project,
);

$got = $prj->fetch_resultlist(package => $package);
is_deeply($got, $expected, "Checking Net::OBS::Client::Project->fetch_resultlist");
is($prj->code($repo, $arch), 'published', "Checking Net::OBS::Client::Project->code");
is($prj->dirty($repo, $arch), 1, "Checking Net::OBS::Client::Project->dirty");

# TESTS FOR Net::OBS::Client::Project END
################################################################################

################################################################################
# TESTS FOR Net::OBS::Client::Package
use_ok('Net::OBS::Client::Package');

my $pkg = Net::OBS::Client::Package->new(
  apiurl     => $apiurl,
  name       => $package,
  project    => $project,
  repository => $repo,
  arch       => $arch,
  use_oscrc  => 0,
);

$pkg->fetch_status;

is($pkg->code, "succeeded", "Checking package status result 'succeeded'") ;

# TESTS FOR Net::OBS::Client::Package END
################################################################################

################################################################################
# TESTS FOR Net::OBS::Client::BuildResults
use_ok('Net::OBS::Client::BuildResults');

# osc api /build/OBS:Server:Unstable/openSUSE_15.2/x86_64/obs-server
my $res = Net::OBS::Client::BuildResults->new(
    apiurl     => $apiurl,
    project    => $project,
    package    => $package,
    repository => $repo,
    arch       => $arch,
  );

$got = $res->binarylist;
$expected = [
          {
            'mtime' => '1610717523',
            'size' => '155913',
            'filename' => '_buildenv'
          },
          {
            'mtime' => '1610717523',
            'filename' => '_statistics',
            'size' => '1028'
          },
          {
            'mtime' => '1610717523',
            'size' => '22500',
            'filename' => 'perl-Net-OBS-Client-0.0.6-lp152.3.1.noarch.rpm'
          },
          {
            'size' => '19159',
            'filename' => 'perl-Net-OBS-Client-0.0.6-lp152.3.1.src.rpm',
            'mtime' => '1610717523'
          },
          {
            'mtime' => '1610717523',
            'filename' => 'rpmlint.log',
            'size' => '386'
          }
        ];

is_deeply($got, $expected, "Checking method 'binarylist'");

$expected = {
          'provides' => [
                          'perl(Net::OBS::Client) = 0.0.6',
                          'perl(Net::OBS::Client::BuildResults)',
                          'perl(Net::OBS::Client::DTD)',
                          'perl(Net::OBS::Client::Package)',
                          'perl(Net::OBS::Client::Project)',
                          'perl(Net::OBS::Client::Roles::BuildStatus)',
                          'perl(Net::OBS::Client::Roles::Client)',
                          'perl-Net-OBS-Client = 0.0.6-lp152.3.1'
                        ],
          'name' => 'perl-Net-OBS-Client',
          'release' => 'lp152.3.1',
          'arch' => 'noarch',
          'version' => '0.0.6',
          'source' => 'perl-Net-OBS-Client',
          'filename' => 'perl-Net-OBS-Client-0.0.6-lp152.3.1.noarch.rpm',
          'description' => 'Net::OBS::Client aims to simplify usage of OBS
(https://openbuildservice.org) API calls in perl.',
          'size' => '22500',
          'mtime' => '1610717523',
          'requires' => [
                          'perl(:MODULE_COMPAT_5.26.1)',
                          'perl(Config::INI::Reader)',
                          'perl(Config::Tiny)',
                          'perl(HTTP::Cookies)',
                          'perl(HTTP::Request)',
                          'perl(LWP::UserAgent)',
                          'perl(Moose)',
                          'perl(Moose::Role)',
                          'perl(Path::Class)',
                          'perl(URI::URL)',
                          'perl(XML::Structured)'
                        ],
          'summary' => 'Simple OBS API calls'
        };

$got = $res->fileinfo('perl-Net-OBS-Client-0.0.6-lp152.3.1.noarch.rpm');
is_deeply($got, $expected, "Checking method 'fileinfo'");

# TESTS FOR Net::OBS::Client::BuildResults END
################################################################################

$server->stop_mock_server();

exit 0;

__END__

