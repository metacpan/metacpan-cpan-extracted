#!perl
# This test file has been automatically generated. Any change made here will be lost.
# Edit the script in ./build/build_modules.pl instead
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use Module::Generic;
    use Scalar::Util ();
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Net::API::CPAN::Release' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Release->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Release' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Release->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Release.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'abstract' );
can_ok( $obj, 'archive' );
can_ok( $obj, 'author' );
can_ok( $obj, 'authorized' );
can_ok( $obj, 'changes_file' );
can_ok( $obj, 'checksum_md5' );
can_ok( $obj, 'checksum_sha256' );
can_ok( $obj, 'date' );
can_ok( $obj, 'dependency' );
can_ok( $obj, 'deprecated' );
can_ok( $obj, 'distribution' );
can_ok( $obj, 'download_url' );
can_ok( $obj, 'first' );
can_ok( $obj, 'id' );
can_ok( $obj, 'license' );
can_ok( $obj, 'main_module' );
can_ok( $obj, 'maturity' );
can_ok( $obj, 'metadata' );
can_ok( $obj, 'name' );
can_ok( $obj, 'object' );
can_ok( $obj, 'provides' );
can_ok( $obj, 'resources' );
can_ok( $obj, 'stat' );
can_ok( $obj, 'status' );
can_ok( $obj, 'tests' );
can_ok( $obj, 'version' );
can_ok( $obj, 'version_numified' );

is( $obj->abstract, $test_data->{abstract}, 'abstract' );
is( $obj->archive, $test_data->{archive}, 'archive' );
is( $obj->author, $test_data->{author}, 'author' );
$this = $obj->authorized;
if( defined( $test_data->{authorized} ) )
{
    is( $this => $test_data->{authorized}, 'authorized returns a boolean value' );
}
else
{
    ok( !$this, 'authorized returns a boolean value' );
}
is( $obj->changes_file, $test_data->{changes_file}, 'changes_file' );
is( $obj->checksum_md5, $test_data->{checksum_md5}, 'checksum_md5' );
is( $obj->checksum_sha256, $test_data->{checksum_sha256}, 'checksum_sha256' );
$this = $obj->date;
is( $this => $test_data->{date}, 'date' );
if( defined( $test_data->{date} ) )
{
    isa_ok( $this => 'DateTime', 'date returns a DateTime object' );
}
$this = $obj->dependency;
isa_ok( $this => 'Module::Generic::Array', 'dependency returns an array object' );
$this = $obj->deprecated;
if( defined( $test_data->{deprecated} ) )
{
    is( $this => $test_data->{deprecated}, 'deprecated returns a boolean value' );
}
else
{
    ok( !$this, 'deprecated returns a boolean value' );
}
is( $obj->distribution, $test_data->{distribution}, 'distribution' );
$this = $obj->download_url;
is( $this => $test_data->{download_url}, 'download_url' );
if( defined( $test_data->{download_url} ) )
{
    isa_ok( $this => 'URI', 'download_url returns an URI object' );
}
$this = $obj->first;
if( defined( $test_data->{first} ) )
{
    is( $this => $test_data->{first}, 'first returns a boolean value' );
}
else
{
    ok( !$this, 'first returns a boolean value' );
}
is( $obj->id, $test_data->{id}, 'id' );
$this = $obj->license;
ok( ( Scalar::Util::reftype( $this ) eq 'ARRAY' && Scalar::Util::blessed( $this ) ), 'license returns an array object' );
if( defined( $test_data->{license} ) )
{
    ok( scalar( @$this ) == scalar( @{$test_data->{license}} ), 'license -> array size matches' );
    for( my $i = 0; $i < @$this; $i++ )
    {
        is( $this->[$i], $test_data->{license}->[$i], 'license -> value offset $i' );
    }
}
else
{
    ok( !scalar( @$this ), 'license -> array is empty' );
}
is( $obj->main_module, $test_data->{main_module}, 'main_module' );
is( $obj->maturity, $test_data->{maturity}, 'maturity' );
$this = $obj->metadata;
ok( Scalar::Util::blessed( $this ), 'metadata returns a dynamic class' );
is( $obj->name, $test_data->{name}, 'name' );
$this = $obj->provides;
ok( ( Scalar::Util::reftype( $this ) eq 'ARRAY' && Scalar::Util::blessed( $this ) ), 'provides returns an array object' );
if( defined( $test_data->{provides} ) )
{
    ok( scalar( @$this ) == scalar( @{$test_data->{provides}} ), 'provides -> array size matches' );
    for( my $i = 0; $i < @$this; $i++ )
    {
        is( $this->[$i], $test_data->{provides}->[$i], 'provides -> value offset $i' );
    }
}
else
{
    ok( !scalar( @$this ), 'provides -> array is empty' );
}
$this = $obj->resources;
ok( Scalar::Util::blessed( $this ), 'resources returns a dynamic class' );
$this = $obj->stat;
ok( Scalar::Util::blessed( $this ), 'stat returns a dynamic class' );
is( $obj->status, $test_data->{status}, 'status' );
$this = $obj->tests;
ok( Scalar::Util::blessed( $this ), 'tests returns a dynamic class' );
$this = $obj->version;
is( $this, $test_data->{version}, 'version' );
$this = $obj->version_numified;
is( $this => $test_data->{version_numified}, 'version_numified' );
if( defined( $test_data->{version_numified} ) )
{
    isa_ok( $this => 'Module::Generic::Number', 'version_numified returns a number object' );
}

done_testing();

__END__
{
   "abstract" : "Japan Folklore Object Class",
   "archive" : "Folklore-Japan-v1.2.3.tar.gz",
   "author" : "MOMOTARO",
   "authorized" : true,
   "changes_file" : "CHANGES",
   "checksum_md5" : "71682907d95a4b0a4b74da8c16e88d2d",
   "checksum_sha256" : "27d4da9e772bc1922618b36fdefa768344d92c3d65a5e3cc427218cfc8d7491d",
   "date" : "2023-07-29T05:10:12",
   "dependency" : [
      {
         "module" : "ExtUtils::MakeMaker",
         "phase" : "configure",
         "relationship" : "requires",
         "version" : "0"
      },
      {
         "module" : "ExtUtils::MakeMaker",
         "phase" : "build",
         "relationship" : "requires",
         "version" : "0"
      },
      {
         "module" : "Module::Generic",
         "phase" : "runtime",
         "relationship" : "requires",
         "version" : "v0.30.6"
      },
      {
         "module" : "DateTime::Format::JP",
         "phase" : "runtime",
         "relationship" : "requires",
         "version" : "v0.1.3"
      },
      {
         "module" : "Mock::Person::JP",
         "phase" : "runtime",
         "relationship" : "requires",
         "version" : "0.07"
      },
      {
         "module" : "Net::Airline::ANA",
         "phase" : "runtime",
         "relationship" : "requires",
         "version" : "2.34"
      },
      {
         "module" : "Transport::Limousine::Bus",
         "phase" : "runtime",
         "relationship" : "requires",
         "version" : "3.45"
      },
      {
         "module" : "Net::Reservation::KorakuenGarden",
         "phase" : "runtime",
         "relationship" : "requires",
         "version" : "v0.2.3"
      },
      {
         "module" : "Net::Reservation::OkayamaCastle",
         "phase" : "runtime",
         "relationship" : "requires",
         "version" : "4.03"
      },
      {
         "module" : "strict",
         "phase" : "runtime",
         "relationship" : "requires",
         "version" : "0"
      },
      {
         "module" : "warnings",
         "phase" : "runtime",
         "relationship" : "requires",
         "version" : "0"
      },
      {
         "module" : "parent",
         "phase" : "runtime",
         "relationship" : "requires",
         "version" : "0"
      },
      {
         "module" : "perl",
         "phase" : "runtime",
         "relationship" : "requires",
         "version" : "5.026001"
      },
      {
         "module" : "Test::Pod",
         "phase" : "test",
         "relationship" : "requires",
         "version" : "1.52"
      },
      {
         "module" : "Test::More",
         "phase" : "test",
         "relationship" : "requires",
         "version" : "1.302162"
      }
   ],
   "deprecated" : false,
   "distribution" : "Folklore-Japan",
   "download_url" : "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v0.30.5.tar.gz",
   "first" : false,
   "id" : "Wo09n3d3er4s_56Of7_J8ap9an",
   "license" : [
      "perl_5"
   ],
   "main_module" : "Folklore::Japan",
   "maturity" : "released",
   "metadata" : {
      "abstract" : "Japan Folklore Object Class",
      "author" : [
         "Taro Momo <momo.taro@example.jp>"
      ],
      "dynamic_config" : 1,
      "generated_by" : "ExtUtils::MakeMaker version 7.64, CPAN::Meta::Converter version 2.150010, CPAN::Meta::Converter version 2.150005",
      "license" : [
         "perl_5"
      ],
      "meta-spec" : {
         "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
         "version" : 2
      },
      "name" : "Folklore-Japan",
      "no_index" : {
         "directory" : [
            "t",
            "inc",
            "t",
            "xt",
            "inc",
            "local",
            "perl5",
            "fatlib",
            "example",
            "blib",
            "examples",
            "eg"
         ]
      },
      "prereqs" : {
         "build" : {
            "requires" : {
               "ExtUtils::MakeMaker" : "0"
            }
         },
         "configure" : {
            "requires" : {
               "ExtUtils::MakeMaker" : "0"
            }
         },
         "runtime" : {
            "requires" : {
               "DateTime::Format::JP" : "v0.1.3",
               "ExtUtils::MakeMaker" : "0",
               "Mock::Person::JP" : "0.07",
               "Module::Generic" : "v0.30.6",
               "Net::Airline::ANA" : "2.34",
               "Net::Reservation::KorakuenGarden" : "v0.2.3",
               "Net::Reservation::OkayamaCastle" : "4.03",
               "Test::More" : "1.302162",
               "Test::Pod" : "1.52",
               "Transport::Limousine::Bus" : "3.45",
               "parent" : "0",
               "perl" : "5.026001",
               "strict" : "0",
               "warnings" : "0"
            }
         },
         "test" : {
            "requires" : {
               "Test::More" : "1.302162",
               "Test::Pod" : "1.52",
            }
         }
      },
      "release_status" : "stable",
      "resources" : {
         "bugtracker" : {
            "web" : "https://gitlab.com/momotaro/Folklore-Japan/issues"
         },
         "repository" : {
            "type" : "git",
            "web" : "https://gitlab.com/momotaro/Folklore-Japan"
         },
         "homepage" : {
            "web" : "https://www.okayama-japan.jp/en/feature/momotaro"
         }
      },
      "version" : "v1.2.3",
   },
   "name" : "Folklore-Japan-v1.2.3",
   "provides" : [
      "Folklore::Japan",
      "Folklore::Japan::AmaterasuOmikami",
      "Folklore::Japan::Izumo",
      "Folklore::Japan::Kintaro",
      "Folklore::Japan::Kitsune",
      "Folklore::Japan::Kojiki",
      "Folklore::Japan::MomoTaro",
      "Folklore::Japan::NihonShoki",
      "Folklore::Japan::Okayama",
      "Folklore::Japan::Susanoo",
      "Folklore::Japan::Tanuki",
      "Folklore::Japan::Tengu",
      "Folklore::Japan::UrashimaTaro",
   ],
   "resources" : {
      "bugtracker" : {
         "web" : "https://gitlab.com/momotaro/Folklore-Japan/issues"
      },
      "repository" : {
         "type" : "git",
         "web" : "https://gitlab.com/momotaro/Folklore-Japan"
      }
   },
   "stat" : {
      "gid" : 12345,
      "mode" : 33188,
      "mtime" : 1690618397,
      "size" : 10240,
      "uid" : 16790
   },
   "status" : "latest",
   "version" : "v1.2.3",
   "version_numified" : 1.002003
}
