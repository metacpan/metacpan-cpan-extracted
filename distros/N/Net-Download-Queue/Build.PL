use strict;
use warnings;
use Module::Build;
use Data::Dumper;

my $builder = Module::Build->new(
    module_name         => 'Net::Download::Queue',
    license             => 'perl',
    dist_author         => 'Johan Lindstrom <johanl@cpan.org>',
    dist_version_from   => 'lib/Net/Download/Queue.pm',
    requires => {
        'Test::More' => 0,

        "File::Path" => 0,
        "File::Basename" => 0,
        "File::Slurp" => 0,

        "LWP::UserAgent" => 0,
        "HTTP::Response" => 0,
        "HTTP::Request::Common" => 0,

        "Time::Progress" => 0,

        "DBI::Shell" => 0,
        "Class::DBI" => 0.96,
        "Class::DBI::SQLite" => 0,
    },
    script_files => [
        "bin/download_queue",
       ],
    pm_files => {
        "lib/Net/Download/Queue/Download.pm" => "lib/Net/Download/Queue/Download.pm",
        "lib/Net/Download/Queue/DownloadStatus.pm" => "lib/Net/Download/Queue/DownloadStatus.pm",
        "lib/Net/Download/Queue/DBI.pm" => "lib/Net/Download/Queue/DBI.pm",
        "lib/Net/Download/Queue.pm" => "lib/Net/Download/Queue.pm",

        "lib/Net/Download/Queue/database/sqlite/create.sql" => "lib/Net/Download/Queue/database/sqlite/create.sql",
    },
    add_to_cleanup      => [ 'Net-Download-Queue-*' ],
    create_readme => 1,
    create_makefile_pl => 'traditional',
);


$builder->create_build_script();
