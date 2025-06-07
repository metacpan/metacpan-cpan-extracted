use strict;
use warnings;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/home/brad/BPS/work/rts/rt6-plugin-testing/local/lib /home/brad/BPS/work/rts/rt6-plugin-testing/lib);

package RT::Extension::CommandByMail::Test;
require RT::Test;
our @ISA = 'RT::Test';

sub import {
    my $class = shift;
    my %args  = @_;

    $args{'requires'} ||= [];
    if ( $args{'testing'} ) {
        unshift @{ $args{'requires'} }, 'RT::Extension::CommandByMail';
    } else {
        $args{'testing'} = 'RT::Extension::CommandByMail';
    }

    $class->SUPER::import( %args );
    $class->export_to_level(1);

    require RT::Extension::CommandByMail;
}

sub bootstrap_more_config{
    my $self = shift;
    my $config = shift;
    my $args_ref = shift;

    require RT::Handle;
    if ( RT::Handle::cmp_version($RT::VERSION,'4.4.0') >= 0 ){
        print $config "Set( \@MailPlugins, qw(Auth::MailFrom Action::CommandByMail));\n";
    }
    else{
        print $config "Set( \@MailPlugins, qw(Auth::MailFrom Filter::TakeAction));\n";
    }
    return;
}

1;
