use strict;
use warnings;
use Test::More;
use Module::Build::Prereqs::FromCPANfile;

my @testcases = (
    { input => {version => "0.10", cpanfile => "t/mixed.cpanfile"}, ## should we use File::Spec??
      desc => "configure_requires and test_requires is not supported",
      exp => {
        requires => {
            perl => "v5.14.0",
            NoVersion => "0",
            WithVersion => "1.100",
            WithDottedVersion => "v2.9.0",
            WithExactVersion => "== 3.000",
        },
        recommends => {
            RuntimeRecommends => "2",
        },
        conflicts => {
            RuntimeConflicts => 10,
        },
        build_requires => {
            BuildRequires => "2.10",
            TestRequires => "1.10",
            ConfigureRequires => "4.10",
        },
    } },

    { input => {version => "0.35", cpanfile => "t/mixed.cpanfile"},
      desc => "configure_requires is supported, but test_requires is not",
      exp => {
        requires => {
            perl => "v5.14.0",
            NoVersion => "0",
            WithVersion => "1.100",
            WithDottedVersion => "v2.9.0",
            WithExactVersion => "== 3.000",
        },
        recommends => {
            RuntimeRecommends => "2",
        },
        conflicts => {
            RuntimeConflicts => 10,
        },
        build_requires => {
            BuildRequires => "2.10",
            TestRequires => "1.10",
        },
        configure_requires => {
            ConfigureRequires => "4.10",
        },
    } },

    { input => {version => "0.41", cpanfile => "t/mixed.cpanfile"},
      desc => "configure_requires and test_requires are supported",
      exp => {
        requires => {
            perl => "v5.14.0",
            NoVersion => "0",
            WithVersion => "1.100",
            WithDottedVersion => "v2.9.0",
            WithExactVersion => "== 3.000",
        },
        recommends => {
            RuntimeRecommends => "2",
        },
        conflicts => {
            RuntimeConflicts => 10,
        },
        build_requires => {
            BuildRequires => "2.10",
        },
        configure_requires => {
            ConfigureRequires => "4.10",
        },
        test_requires => {
            TestRequires => "1.10",
        },
    } },

    { input => {version => "0.10", cpanfile => "t/minimal.cpanfile"},
      desc => "no param key should be generated if that prereq is not specified. 'test' is merged to 'build'",
      exp => {
          requires => { "Scalar::Util" => "0" },
          build_requires => { "Test::More" => "0" }
      } },

    { input => {version => "0.50", cpanfile => "t/minimal.cpanfile"},
      desc => "test_requires enabled. no build_requires",
      exp => {
          requires => {"Scalar::Util" => "0"},
          test_requires => {"Test::More" => "0"},
      } },

    { input => {version => "0.10", cpanfile => "t/merged.cpanfile"},
      desc => "merged to the highest required version (merge configure, build, test)",
      exp => {
          requires => {"Runtime" => "1.50"},
          build_requires => {"Merged" => "2.10"}
      } },

    { input => {version => "0.35", cpanfile => "t/merged.cpanfile"},
      desc => "merged to the highest required version (merge build, test)",
      exp => {
          requires => {"Runtime" => "1.50"},
          configure_requires => {"Merged" => "0"},
          build_requires => {"Merged" => "2.10"},
      } },

    { input => {version => "0.41", cpanfile => "t/merged.cpanfile"},
      desc => "merged to the highest required version (no merge)",
      exp => {
          requires => {"Runtime" => "1.50"},
          configure_requires => {"Merged" => "0"},
          build_requires => {"Merged" => "1.30"},
          test_requires => {"Merged" => "2.10"},
      }}
);

foreach my $case (@testcases) {
    my %input = %{$case->{input}};
    my %got = mb_prereqs_from_cpanfile(%input);
    is_deeply \%got, $case->{exp}, "MB version $input{version}: file: $input{cpanfile}: $case->{desc}" or do {
        diag("got parameters");
        diag(explain \%got);
    };
}

done_testing;
