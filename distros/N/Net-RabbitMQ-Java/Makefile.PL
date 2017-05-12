use strict;
use warnings;

BEGIN {
    use lib 'inc';
}

use ExtUtils::MakeMaker 6.31;
use File::ShareDir::Install;

my %WriteMakefileArgs = (
    'ABSTRACT' => 'Perl bindings for the RabbitMQ Java AMQP client library',
    'AUTHOR' => 'Alessandro Ranellucci <aar@cpan.org>',
    'BUILD_REQUIRES' => {
        'Test::More' => '0.96',
        'Inline::Java' => '0.53',
        'File::ShareDir' => 0,
        'Data::UUID' => 0,
    },
    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker' => '6.31'
    },
    'DISTNAME' => 'Net-RabbitMQ-Java',
    'EXE_FILES' => [],
    'LICENSE' => 'perl',
    'NAME' => 'Net::RabbitMQ::Java',
    'PREREQ_PM' => {
    },
    'VERSION_FROM' => 'lib/Net/RabbitMQ/Java.pm',
    'test' => {
        'TESTS' => 't/*.t'
    },
    'META_MERGE' => {
        resources => {
            repository => 'git://git@github.com:alexrj/Net-RabbitMQ-Java.git',
        },
    },
);

install_share 'share';

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
    my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
    my $pp = $WriteMakefileArgs{PREREQ_PM};
    for my $mod (keys %$br) {
        if (exists $pp->{$mod}) {
            $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
        }
        else {
            $pp->{$mod} = $br->{$mod};
        }
    }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

package MY;
use File::ShareDir::Install qw(postamble);
