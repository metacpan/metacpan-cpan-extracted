package Tapper::CLI::Cobbler;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::Cobbler::VERSION = '5.0.5';
use 5.010;

use strict;
use warnings;




sub host_new
{
        my ($c) = @_;
        $c->getopt(  'name=s','from=s', 'mac=s', 'quiet|q', 'help|?' );
        if ( $c->options->{help} or not $c->options->{name}) {
                say STDERR "Missing required parameter --name!" unless $c->options->{name};
                say STDERR "$0 cobbler-host-add  --name=s [ --quiet|q ] [ --from=s ]";
                say STDERR "\n\  Required Arguments:";
                say STDERR "        --name             Name of the new system";
                say STDERR "\n  Optional arguments:";
                say STDERR "        --from             Copy values of that system, default value is 'default'";
                say STDERR "        --mac              Provide mac address (will try to fetch from database if empty)";
                say STDERR "        --quit             Stay silent";
                say STDERR "        --help             Print this help message and exit";
                exit -1;
        }
        my $name    = $c->options->{name};
        my %options;
        $options{default} = $c->options->{default};
        $options{mac}     = $c->options->{mac};

        require Tapper::Cmd::Cobbler;
        my $cmd = Tapper::Cmd::Cobbler->new();
        my $output = $cmd->host_new($name, \%options);
        return $output if $output;

        if (not $c->options->{quiet}) {
                return "Added host $name to cobbler";
        }
        return;
}


sub host_del
{
        my ($c) = @_;
        $c->getopt( 'name=s', 'quiet|q', 'help|?' );
        if ( $c->options->{help} or not $c->options->{name}) {
                say STDERR "Missing required parameter --name!" unless $c->options->{name};
                say STDERR "$0 cobbler-host-del  --name=s [ --quiet|q ]";
                say STDERR "\n\  Required Arguments:";
                say STDERR "        --name             Name of the new system";
                say STDERR "\n  Optional arguments:";
                say STDERR "        --quiet            Stay silent";
                say STDERR "        --help             Print this help message and exit";
                exit -1;
        }
        my $name    = $c->options->{name};

        require Tapper::Cmd::Cobbler;
        my $cmd = Tapper::Cmd::Cobbler->new();
        my $output = $cmd->host_del($name);
        die $output if $output;

        if (not $c->options->{quiet}) {
                return "Host $name removed from cobbler";
        }
        return;
}



sub host_list
{
        my ($c) = @_;
        $c->getopt( 'name=s', 'status', 'help|?' );
        if ( $c->options->{help}) {
                say STDERR "\n  Optional arguments:";
                say STDERR "        --name             Show system with that name";
                say STDERR "        --status           Show system with that status (one of development,testing,acceptance,production)";
                say STDERR "        --help             Print this help message and exit";
                exit -1;
        }

        require Tapper::Cmd::Cobbler;
        my $cmd = Tapper::Cmd::Cobbler->new();
        my @output = $cmd->host_list();
        print join "\n",@output;
        return;
}



sub setup
{
        my ($c) = @_;
        $c->register('cobbler-host-add', \&host_new,    'Add a new host to cobbler by copying from existing one');
        $c->register('cobbler-host-new', \&host_new,    'Alias for cobbler-host-add');
        $c->register('cobbler-host-del', \&host_del,    'Remove an existing host from cobbler');
        $c->register('cobbler-host-list', \&host_list,  'Show host known to cobbler');
        if ($c->can('group_commands')) {
                $c->group_commands('Cobbler commands', 'cobbler-host-add', 'cobbler-host-new', 'cobbler-host-del', 'cobbler-host-list' );
        }
        return;
}

1; # End of Tapper::CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Cobbler

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Cobbler;
    Tapper::CLI::Cobbler::setup($c);
    App::Rad->run();

=head1 NAME

Tapper::CLI::Cobbler - Tapper - cobbler related commands for the tapper CLI

=head1 FUNCTIONS

=head2 host_new

Add a new system to cobbler by copying from an existing one.

=head2 host_del

Delete existing system from cobbler.

=head2 host_list

Show all hosts known to cobbler, optionally all matching a given criteria.

=head2 setup

Initialize the testplan functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
