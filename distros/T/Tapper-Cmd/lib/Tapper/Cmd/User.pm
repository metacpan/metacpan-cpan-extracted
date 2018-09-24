package Tapper::Cmd::User;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Cmd::User::VERSION = '5.0.9';
use Moose;

use Tapper::Model 'model';
use YAML::Syck;
use 5.010;

use parent 'Tapper::Cmd';



sub add
{
        my ($self, $data) = @_;

        my $contacts = $data->{contacts};
        delete $data->{contacts};

        $data->{login} ||= $ENV{USER};

        if (not $data->{name}) {
                # Try to guess the real name. Since UNIX has no idea of a real name, this is extremly error prone.
                my @userdata = getpwnam($data->{login});
                $data->{name} = $userdata[6];
                $data->{name} =~ s/,//g;
        }


        my $owner = model('TestrunDB')->resultset('Owner')->new($data);
        $owner->insert;

        foreach my $contact (@{$contacts || []}) {
                $contact->{owner_id} = $owner->id;
                my $contact_result = model('TestrunDB')->resultset('Contact')->new($contact);
                $contact_result->insert;
        }

        return $owner->id;
}


sub list
{
        my ($self, $search) = @_;
        my @users;
        my $owner_rs = model('TestrunDB')->resultset('Owner')->search($search);
        while (my $owner_result = $owner_rs->next) {
                my $user = { id => $owner_result->id, name => $owner_result->name, login => $owner_result->login };
                $user->{contacts} = [ map { { address => $_->address, protocol => $_->protocol } } $owner_result->contacts->all ];
                push @users, $user;
        }
        return @users;
}




sub del
{
        my ($self, $id) = @_;
        my $owner;
        if ($id =~ /^\d+$/) {
                $owner = model('TestrunDB')->resultset('Owner')->find($id);
        } else {
                $owner = model('TestrunDB')->resultset('Owner')->find({login => $id});
        }
        die qq(User "$id" not found) if not $owner;;
        $owner->delete();
        return 0;
}


sub contact_add
{
        my ($self, $user, $data) = @_;

        $user //= $ENV{USER};

        if ( $user !~ m/^\d+$/ ) {
                my $owner_result = model('TestrunDB')->resultset('Owner')->find({login => $user});
                die "User $user does not exist in database\n" if not $owner_result;
                $user = $owner_result->id;
        }
        $data->{owner_id} ||= $user;

        my $contact = model('TestrunDB')->resultset('Contact')->new($data);
        $contact->insert;

        return $contact->id;
}


1; # End of Tapper::Cmd::Testrun

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Cmd::User

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
users in the database.

    use Tapper::Cmd::User;

    my $user = Tapper::Cmd::User->new();
    my $details = {login => "anton",
                   name  => 'Anton Gorodetzky',
                   contacts => [{
                                 protocol => 'Mail',
                                 address  => 'anton@nightwatch.ru',
                               }]
              };
    my $id = $user->add($details);
    $details->{name} = "Anton Gorodetsky";
    my $error = $user->update($id, $details);
    $error = $user->delete($id);

    $details = {login => "anton", name  => 'Anton Gorodetzky'};
    $id = $user->add_in_testrun($details);
    $details->{name} = "Anton Gorodetsky";
    my $error = $user->update_in_testrun($id, $details);
    $error = $user->delete_in_testrun($id);

=head1 NAME

Tapper::Cmd::User - Backend functions for manipluation of user subscriptions in the database

=head1 FUNCTIONS

=head2 add

Add a new user to testrundb. Expects all details as a hash reference.

@param hash ref  - user data

@return success - user id
@return error   - undef

@throws Perl die

=head2 list

Get a list of users with all information we have about them.

@param hash ref - search as understand by DBIx::Class

@return list of user information (hash refs)

@throws die

=head2 del

Delete a user subscription with given id. Its named del instead of
delete to prevent confusion with the buildin delete function. The first
parameter can be either the users database id (not the UNIX id!) or the
login name.

@param int|string - user id|user login name

@return success - 0

@throws die

=head2 contact_add

Add a contact to an existing owner in testrundb. Expects all details as a hash
reference.

@param int|string - owner as id or login
@param hash ref   - contact data

@return success - owner id
@return error   - undef

@throws Perl die

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
