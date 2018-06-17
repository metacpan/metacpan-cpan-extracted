use 5.026002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Mattermost::Bot',
    VERSION_FROM      => 'lib/Net/Mattermost/Bot.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'FindBin'          => 0,
        'JSON::MaybeXS'    => 0,
        'Moo'              => 0,
        'Types::Standard'  => 0,
        'Carp'             => 0,
        'Furl'             => 0,
        'HTTP::Status'     => 0,
        'List::Util'       => 0,
        'Mojo::IOLoop'     => 0,
        'Mojo::UserAgent'  => 0,
        'MooX::HandlesVia' => 0.
    },
    ABSTRACT_FROM     => 'lib/Net/Mattermost/Bot.pm',
    AUTHOR            => 'Mike Jones <mike@netsplit.org.uk>',
    LICENSE           => 'mit',
);
