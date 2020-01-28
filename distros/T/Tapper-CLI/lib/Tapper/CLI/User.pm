package Tapper::CLI::User;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::User::VERSION = '5.0.6';
use 5.010;
use warnings;
use strict;

use Try::Tiny;
use UNIVERSAL;


sub get_contacts
{
        my ($contacts) = @_;
        my @contacts;

        require YAML::XS;

        foreach my $contact (@{$contacts || []}) {
                if ($contact !~ m/\n/ and -e $contact) {
                        try {
                                my @newcontacts = YAML::XS::LoadFile($contact);
                                push @contacts, @newcontacts;
                        } catch {
                                say STDERR "Can not load file '$contact'. Will ignore it. Error message was: $_";
                        }
                } else {
                        try{
                                my @newcontacts = YAML::XS::Load($contact);
                                push @contacts, @newcontacts;
                        } catch {
                                say STDERR "I can not load '$contact' as YAML and there is no file with that name. Will ignore it. Error message was: $_";
                        }
                }
        }
        return @contacts;
}




sub usernew
{
        my ($c) = @_;
        $c->getopt( 'contact|c=s@', 'login|l=s', 'name|n=s', 'quiet|q', 'default|d','help|?' );

        if ($c->options->{help}  or not %{$c->options}) {
                say STDERR "Usage: $0 user-add [--default|d] [ --login=login ] [ --name=name ] [ --contact='type:type\\naddress:address' | --contact=filename ]*";
                say STDERR "\n  Optional arguments:";
                say STDERR "         --login           login name for the user (default is $ENV{USER})";
                say STDERR "         --name            real name of the user (try to get from system if empty)";
                say STDERR "         --contact         contact information in YAML or name of a file containing this information (can be given multiple times)";
                say STDERR "         --quiet           Stay silent when adding user succeeded";
                say STDERR "         --default         Use default values for all parameters";
                say STDERR "         --help            print this help message and exit";
                exit -1;
        }

        my @contacts = get_contacts($c->options->{contact});

        my $data;
        $data   = { login => $c->options->{login}, name => $c->options->{name} , contacts => \@contacts};

        require YAML::XS;
        require Tapper::Cmd::User;

        my $cmd = Tapper::Cmd::User->new();
        my $id  = $cmd->add($data);
        if (not $c->options->{quiet}) {
                my @users = $cmd->list({id => $id});
                print YAML::XS::Dump($users[0]);
        }
        return;
}


sub contactadd
{
        my ($c) = @_;
        $c->getopt( 'contact|c=s@', 'login|l=s', 'quiet|q', 'help|?' );

        if ($c->options->{help} or not $c->options->{contact} ) {
                say STDERR "Usage: $0 contact-add [ --login=login ] [ --contact=YAML | --contact=filename ]* [ --quiet ]";
                say STDERR "\n  Optional arguments:";
                say STDERR "         --login           login name for the user (default is $ENV{USER})";
                say STDERR "         --contact         contact information in YAML or name of a file containing this information (can be given multiple times)";
                say STDERR "         --quiet           Stay silent when adding user succeeded";
                say STDERR "         --help            print this help message and exit";
                exit -1;
        }

        my $login = $c->options->{login} || $ENV{USER};

        require Tapper::Cmd::User;
        my $cmd = Tapper::Cmd::User->new();

        my @contacts = get_contacts($c->options->{contact});
        foreach my $contact (@contacts) {
                my $id  = $cmd->contact_add($login, $contact);
        }

        require YAML::XS;
        if (not $c->options->{quiet}) {
                my @users = $cmd->list({login => $login});
                print YAML::XS::Dump($users[0]);
        }

        return;
}


sub userlist
{
        my ($c) = @_;

        require YAML::XS;
        require Tapper::Cmd::User;

        my $cmd = Tapper::Cmd::User->new();
        my @users = $cmd->list();
        foreach my $user (@users) {
                print YAML::XS::Dump($user);
        }
        return;
}


sub userupdate
{
        my ($c) = @_;
        $c->getopt( 'file|f=s', 'id|i=i','quiet|q', 'help|?' );

        if (not %{$c->options} or $c->options->{help} ) {
                say STDERR "Usage: $0 user-update --file=filename --id=id [ --quiet ]";
                say STDERR "\n\  Required Arguments:";
                say STDERR "         --file            name of file containing the user subscriptions in YAML";
                say STDERR "         --id              id of the user subscriptions";
                say STDERR "\n  Optional arguments:";
                say STDERR "         --quiet           stay silent when updating succeeded";
                say STDERR "         --help            print this help message and exit";
                exit -1;
        }

        require Tapper::Cmd::User;
        my $cmd = Tapper::Cmd::User->new();

        require YAML::XS;
        my $subscription =  YAML::XS::LoadFile($c->options->{file});
        my $id = $cmd->update($c->options->{id}, $subscription);

        return "The user subscription was updated: $id" unless $c->options->{quiet};
        return;
}


sub userdel
{
        my ($c) = @_;
        $c->getopt( 'id|i=i', 'login|l=s', 'quiet|q', 'help|?' );

        if (not %{$c->options} or $c->options->{help} ) {
                say STDERR "Usage: $0 user-del --user=login | --id=i [ --quiet ]";
                say STDERR "\n\  Required Arguments (one of):";
                say STDERR "         --login           login name of the user to delete";
                say STDERR "         --id              database id of the user to delete. Note: This is not the UNIX id!";
                say STDERR "\n  Optional arguments:";
                say STDERR "         --quiet           Stay silent when deleting succeeded";
                say STDERR "         --help            print this help message and exit";
                exit -1;
        }

        require Tapper::Cmd::User;
        my $cmd = Tapper::Cmd::User->new();

        if ($c->options->{login}) {
                if ( $c->options->{id}) {
                        return "Please choose either login or id. Both are present and I don't know which one to use";
                }
                $cmd->del($c->options->{login});
        } else {
                $cmd->del($c->options->{id});
        }

        return "The user was deleted." unless $c->options->{quiet};
        return;
}




sub setup
{
        my ($c) = @_;
        $c->register('user-add', \&usernew, 'Register a new user');
        $c->register('user-new', \&usernew, 'Alias for user-add');
        $c->register('user-list', \&userlist, 'Show all users');
        $c->register('user-update', \&userupdate, 'Update an existing user');
        $c->register('user-del', \&userdel, 'Delete an existing user');
        $c->register('contact-add', \&contactadd, 'Add contact information to an existing user');
        if ($c->can('group_commands')) {
                $c->group_commands('User commands', 'user-add', 'user-new', 'user-list', 'user-update', 'user-del', 'contact-add');
        }
        return;
}

1; # End of Tapper::CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::User

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::User;
    Tapper::CLI::User::setup($c);
    App::Rad->run();

=head1 NAME

Tapper::CLI::User - Tapper - user handling commands for the tapper CLI

=head1 FUNCTIONS

=head2 get_contacts

Get contacts from YAML. Errors are printed out instead of returned. This
seems to be ok for a CLI function.

@param array ref - containing YAML strings or file names

@return list of contacts that could be parsed

=head2 usernew

Create a new user.

@optparam login   - login name for the user (default is $ENV{USER})
@optparam name    - real name of the user (try to get from system if empty)
@optparam contact - contact information in YAML or name of a file containing this information (can be given multiple times)
@optparam help    - print out help message and die

=head2 contactadd

Add contacts to an existing user.

@param contact  - contact information in YAML or name of a file containing this information (can be given multiple times)
@optparam login - login name for the user (default is $ENV{USER})
@optparam quiet - stay silent when adding contacts succeeded
@optparam help  - print out help message and die

=head2 userlist

Show all or a subset of user subscriptions

@optparam

=head2 userupdate

Update an existing user subscription.

@param file     - name of the file containing the new data for subscription user in YAML
@param id       - id of the user subscription to update
@optparam quiet - stay silent when updating succeeded
@optparam help  - print out help message and die

=head2 userdel

Delete an existing user subscription.

@param id       - id of the user subscription to delete
@optparam quiet - stay silent when deleting user succeeded
@optparam help  - print out help message and die

=head2 setup

Initialize the user functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
