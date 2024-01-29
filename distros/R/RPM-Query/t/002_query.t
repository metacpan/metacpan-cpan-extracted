#! -- perl --
use strict;
use warnings;
use Test::More tests => 2 + 17;
BEGIN { use_ok('RPM::Query') };

my $rq   = RPM::Query->new;
isa_ok($rq, 'RPM::Query');

my $skip = 1;
foreach (1) {
  last unless $^O eq 'linux';
  last unless qx{rpm -q perl};
  last if $?;
  $skip = 0;
}

sub rpm {
  my $cmd    = join ' ', rpm => map {"'$_'"} @_;
  my $stdout = qx{$cmd};
  chomp $stdout;
  return $stdout;
}

SKIP: {
  skip 'rpm command not found or perl not installed by rpm', 17 if $skip;
  {
    my $package = $rq->query('perl');
    isa_ok($package, 'RPM::Query::Package');
    is($package->name, 'perl', 'name');
    isa_ok($package->details, 'HASH'                                                    , 'details'    );
    is($package->package_name, rpm('--query', 'perl')                                   , 'package'    );
    is($package->version,      rpm('--query', 'perl', '--queryformat', '%{version}')    , 'version'    );
    is($package->license,      rpm('--query', 'perl', '--queryformat', '%{license}')    , 'license'    );
    is($package->sigmd5,       rpm('--query', 'perl', '--queryformat', '%{sigmd5}')     , 'sigmd5'     );
    is($package->description,  rpm('--query', 'perl', '--queryformat', '%{description}'), 'description');
    is($package->summary,      rpm('--query', 'perl', '--queryformat', '%{summary}')    , 'summary'    );
    is($package->url,          rpm('--query', 'perl', '--queryformat', '%{url}')        , 'url'        );
    is($package->sourcerpm,    rpm('--query', 'perl', '--queryformat', '%{sourcerpm}')  , 'sourcerpm'  );
  }
  {
    my @expect = qx{rpm -q kernel};
    chomp @expect;
    my $list = $rq->query_list('kernel');
    isa_ok($list, 'ARRAY');
    isa_ok($list->[0], 'RPM::Query::Package');
    is(scalar(@$list), scalar(@expect), 'size');
    is($list->[-1]->package_name, $expect[-1], 'query_list->[-1]->package_name');
    is($rq->query('kernel')->package_name, $expect[-1], 'query->package_name')
  }

  {
    my $package = $rq->query('foo-bar-baz-buz');
    is($package, undef);
  }
}

__END__

$ rpm --query --info perl
Name        : perl
Epoch       : 4
Version     : 5.16.3
Release     : 299.el7_9
Architecture: x86_64
Install Date: Wed 10 Feb 2021 01:56:19 PM EST
Group       : Development/Languages
Size        : 23556436
License     : (GPL+ or Artistic) and (GPLv2+ or Artistic) and Copyright Only and MIT and Public Domain and UCD
Signature   : RSA/SHA256, Wed 03 Feb 2021 11:48:28 AM EST, Key ID 24c6a8a7f4a80eb5
Source RPM  : perl-5.16.3-299.el7_9.src.rpm
Build Date  : Tue 02 Feb 2021 11:36:12 AM EST
Build Host  : x86-02.bsys.centos.org
Relocations : (not relocatable)
Packager    : CentOS BuildSystem <http://bugs.centos.org>
Vendor      : CentOS
URL         : http://www.perl.org/
Summary     : Practical Extraction and Report Language
Description :
Perl is a high-level programming language with roots in C, sed, awk and shell
scripting.  Perl is good at handling processes and files, and is especially
good at handling text.  Perl's hallmarks are practicality and efficiency.
While it is used to do a lot of different things, Perl's most common
applications are system administration utilities and web programming.  A large
proportion of the CGI scripts on the web are written in Perl.  You need the
perl package installed on your system so that your system can handle Perl
scripts.

Install this package if you want to program in Perl or enable your system to
handle Perl scripts.
