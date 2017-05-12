use strict;
use warnings;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt4/local/lib /opt/rt4/lib);

package RT::Extension::MandatoryOnTransition::Test;

our @ISA;
BEGIN {
    local $@;
    eval { require RT::Test; 1 } or do {
        require Test::More;
        Test::More::BAIL_OUT(
            "requires 3.8 to run tests. Error:\n$@\n"
            ."You may need to set PERL5LIB=/path/to/rt/lib"
        );
    };
    push @ISA, 'RT::Test';
}

sub import {
    my $class = shift;
    my %args  = @_;

    $args{'requires'} ||= [];
    if ( $args{'testing'} ) {
        unshift @{ $args{'requires'} }, 'RT::Extension::MandatoryOnTransition';
    } else {
        $args{'testing'} = 'RT::Extension::MandatoryOnTransition';
    }

    $args{'config'} =<<CONFIG;
Set( %MandatoryOnTransition,
    '*' => {
        'open -> resolved' => [qw(TimeWorked TimeTaken)]
    },
    'General' => {
        '* -> resolved' => ['TimeWorked', 'TimeTaken', 'CF.Test Field', 'CF.Test Field3', 'CF.Test Field4'],
        'CF.Test Field3' => { transition => '* -> resolved', must_be => ['normal', 'restored'] },
        'CF.Test Field4' => { transition => '* -> resolved', must_not_be => ['down', 'reduced'] } },
);
CONFIG

    $class->SUPER::import( %args );
    $class->export_to_level(1);

    require RT::Extension::MandatoryOnTransition;
}

sub RTAtorNewerThan{
    my $version = shift;
    my ($my_major, $my_minor, $my_sub) = split(/\./, $version);
    my ($major, $minor, $sub) = split(/\./, $RT::VERSION);
    return ($my_major >= $major
            and $my_minor >= $minor
            and $my_sub >= $sub)
            ? 1 : 0;
}

1;
