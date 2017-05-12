use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %config = (
    'NAME'         => 'Socialtext-Resting',
    'VERSION_FROM' => 'lib/Socialtext/Resting.pm',
    'PREREQ_PRINT' => 1,
    'EXE_FILES'    => [
        'bin/strut', 'bin/st-webhook',
    ],
    'PREREQ_PM' => {
        'URI::Escape'     => 1.31,
        'LWP::UserAgent'  => 0,
        'HTTP::Request'   => 0,
        'Class::Field'    => 0,
        'Readonly'        => 0,
        'Pod::Usage'      => 0,
        'App::Options'    => 0,
        'IPC::Run'        => 0,
        'Test::Mock::LWP' => '0.05',
        'JSON::XS'        => '2.1',
        'Net::SSLeay'     => 0,
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT => 'Simple tool to use Socialtext RESTful API',
            AUTHOR   =>
                'Chris Dent <chris.dent@socialtext.com>, Kirsten Jones <kirsten.jones@socialtext.com>'
            )
        : ()
    ),
);

my $response = prompt("Perform tests against Socialtext servers?", "y");
my $files;
if ($response !~ /^y/i) {
    $files = join ' ', (grep {$_ !~ /resting\.t/} glob("t/*.t"));
}
else {
    $files = 't/*.t';
}

$config{test} = { TESTS => $files };

WriteMakefile(%config);
