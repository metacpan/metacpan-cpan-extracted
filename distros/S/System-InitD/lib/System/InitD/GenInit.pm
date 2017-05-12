package System::InitD::GenInit;

use strict;
use warnings;
use Getopt::Long;
use Carp;


sub new {
    my $class = shift;

    return bless {}, $class;
}


sub run {
    my $self = shift;

    $self->parse_args();
    
    if (!$self->{options}->{provides}) {
        $self->ask('provides', "Which service this script provides?");
    }

    if (!$self->{options}->{provides}) {
        print "Missing provides section.";
        exit 1;
    }

    eval {
        my $os = ucfirst lc $self->{options}->{os};

        my $module = 'System::InitD::GenInit' . '::' . $os;

        (my $file = $module) =~ s|::|/|g;
        require $file . '.pm';
        $module->import();
        $module->generate($self->{options});
        1;
    } or do {
        croak "Unknown OS: $@";
    };

    1;
};


sub parse_args {
    my $self = shift;

    my $opts = $self->{options} = {
        author          =>  getlogin,
        os              =>  'debian',
        process_name    =>  '',
        start_cmd       =>  '',
        pid_file        =>  '',
        target          =>  '',
        provides        =>  '',
        service         =>  'system_initd_script',
        description     =>  '',
        user            =>  '',
        bare            =>  0,
    };

    GetOptions(
        'os=s'              =>    \$opts->{os},
        'target=s'          =>    \$opts->{target},
        'author=s'          =>    \$opts->{author},
        'pid-file=s'        =>    \$opts->{pid_file},
        'pid_file=s'        =>    \$opts->{pid_file},
        'pidfile=s'         =>    \$opts->{pid_file},
        'process_name=s'    =>    \$opts->{process_name},
        'process-name=s'    =>    \$opts->{process_name},
        'start_cmd=s'       =>    \$opts->{start_cmd},
        'start-cmd=s'       =>    \$opts->{start_cmd},
        'provides=s'        =>    \$opts->{provides},
        'service=s'         =>    \$opts->{service},
        'description=s'     =>    \$opts->{description},
        'user=s'            =>    \$opts->{user},
        'bare'              =>    \$opts->{bare},
    );

    if (scalar @ARGV == 1 && !$self->{options}->{target}) {
        $self->{options}->{target} = $ARGV[0];
    }

    return 1;
}

sub ask {
    my ($self, $field, $question) = @_;

    print $question . ' > ';
    my $res = <STDIN>;
    chomp $res;
    if (!$res || $res =~ m/^\s+$/s) {
        return $self->ask($field, $question);
    }
    $self->{options}->{$field} = $res;

    return 1;
}

1;

__END__

