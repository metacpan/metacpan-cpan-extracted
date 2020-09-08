use strict;
use warnings;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/Users/sunnavy/bps/git/rt/local/lib /Users/sunnavy/bps/git/rt/lib);

package RT::Extension::TravisCI::Test;

our @ISA;
BEGIN {
    local $@;
    eval { require RT::Test; 1 } or do {
        require Test::More;
        Test::More::BAIL_OUT(
            "requires RT::Test to run tests. Error:\n$@\n"
            ."You may need to set PERL5LIB=/path/to/rt/lib"
            );
    };
    push @ISA, 'RT::Test';
}


sub import
{
    my $class = shift;
    my %args = @_;

    my $token = `travis token`;
    chomp($token);
    if ($token eq '') {
        die("You must log in to travis and create a token to run tests.");
    }
    $args{'config'} =<<"EOF";
Set( %TravisCI,
     APIURL => 'https://api.travis-ci.org',
     WebURL => 'https://travis-ci.org/github',
     APIVersion => '3',
     SlugPrefix => 'bestpractical%2F',
     DefaultProject => 'rt',
     Queues => ['Branch Review'],
     AuthToken => $token,
);
EOF
    $class->SUPER::import( %args );
    $class->export_to_level(1);
}

1;


