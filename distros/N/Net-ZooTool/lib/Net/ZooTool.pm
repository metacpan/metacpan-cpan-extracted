package Net::ZooTool;
# ABSTRACT: a Moose interface to the Zootool API
use Moose;
with 'Net::ZooTool::Utils';

use Carp;

use Net::ZooTool::Auth;
use Net::ZooTool::User;
use Net::ZooTool::Item;

use namespace::autoclean;

our $VERSION = '0.003';

has auth => (
    isa => 'Net::ZooTool::Auth',
    is  => 'ro',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    # Transform normal params to hashref
    if ( !ref $_[0] ) {
        if ( scalar @_ == 1 ) {
            return $class->$orig( apikey => $_[0] );
        }
        elsif ( scalar @_ == 3 ) {
            return $class->$orig( apikey => $_[0], user => $_[1], password => $_[2] );
        }
        else {
            croak "Unaccepted params";
        }
    }

    # Hashref checkings
    if ( ref $_[0] and !$_[0]->{apikey} ) {
        croak "You have to provide at least the apikey as either parameter or hashref";
    }

    # You need to provide username and password
    if ( defined $_[0]->{user} and !defined $_[0]->{password} ) {
        croak "If you provide user you also need to provide password";
    }

    if ( defined $_[0]->{password} and !defined $_[0]->{user} ) {
        croak "If you provide password you also need to provide username";
    }

    # If you have reached here everything is good

    return $class->$orig(@_);
};

sub BUILD {
    my $self = shift;
    my $args = shift;

    $self->{auth} = Net::ZooTool::Auth->new(
        {
            apikey   => $args->{apikey},
            user     => $args->{user},
            password => $args->{password},
        }
    );
}

sub user {
    my $self = shift;
    return Net::ZooTool::User->new({ auth => $self->auth });
}

sub item {
    my $self = shift;
    return Net::ZooTool::Item->new({ auth => $self->auth });
}

sub add {
    my ( $self, $args ) = @_;

    $args->{apikey} = $self->auth->apikey;

    my $data = _fetch('/add/' . _hash_to_query_string($args), $self->auth);
    return $data;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Net::ZooTool - Moose interface to the Zootool API: http://zootool.com

=head1 SYNOPSIS

    my $zoo = Net::ZooTool->new({ apikey   => $config{apikey} });

    my $weekly_popular = $zoo->item->popular({ type => "week" });

    # Info about a specific item
    print Dumper($zoo->item->info({ uid => "6a80z" }));

    # Examples with authenticated calls
    my $auth_zoo = Net::ZooTool->new(
        {
            apikey   => $config{apikey},
            user     => $config{user},
            password => $config{password},
        }
    );

    my $data = $auth_zoo->user->validate({ username => $config{user}, login => 'true' });
    print Dumper($data);

    # In some methods authentication is optional.
    # Public items only
    my $public_items = $auth_zoo->user->items({ username => $config{user} });
    # Include also your private items
    my $all_items = $auth_zoo->user->items({ username => $config{user}, login => 'true' });

=head1 DESCRIPTION

Net::ZooTool is a wrapper to the Zootool bookmarking service. It attempts to follow the api defined in http://zootool.com/api/docs/general as much as possible. Please refer to their API Documentation site for more information.

=head1 PACKAGE METHODS

=over 1

=item new(\%ARGS)

Create a new Net::ZooTool object.

Parameters:

=over 3

=item *

B<apikey>

I<string>. Your Zootool apikey (required)

=item *

B<user>

I<string>. Your Zootool username (optional)

=item *

B<password>

I<string>. Your Zootool password (optional)

=back

=back

=head1 OBJECT METHODS

=over 6

=item $zoo->user()

Net::ZooTool::User object

=item $zoo->item()

Net::ZooTool::Item object

=item $zoo->add(\%ARGS)

Adds a new item to your zoo (authentication is required).

Parameters:

=over 8

=item *

B<apikey>

I<string>. Your Zootool api key (required)

=item *

B<url>

I<string>. Url to add (required)

=item *

B<title>

I<string>. Item title (required)

=item *

B<tags>

I<string>. Comma separated if you want to include more than one (optional)

=item *

B<description>

I<string>. Entry description (optional)

=item *

B<referer>

I<string>. Entry referer, must be a valid url (optional)

=item *

B<public>

I<string>. Whether or not the item is public ('y' or 'n')

=item *

B<login>

I<boolean>. Add method requires authenticated call (required)

=back

=item $zoo->user->items(\%ARGS)

Get the latest items from all users or specify a username to get all items from a specific user. Authenticate to get all private items of a user as well. Use authentication if you want to get private items as well).

Parameters:

=over 6

=item *

B<apikey>

I<string>. Your Zootool api key (required)

=item *

B<username>

I<string>. Zootool username (required)

=item *

B<login>

I<string>. must be true if you want to make an authenticated call via digest (optional).

=item *

B<tag>

I<string>. Tag search (optional)

=item *

B<offset>

I<int>. Search offset (optional)

=item *

B<limit>

I<int>. Search limit (optional)

=item *

B<login>

I<boolean>. Set to true to get private items as well.

=back

=item $zoo->user->info(\%ARGS)

Get info about a certain user. Authentication is optional (if you want to get the email address from the user, you need to sign in).

Parameters:

=over 3

=item *

B<apikey>

I<string>. Your Zootool api key (required)

=item *

B<username>

I<string>. Zootool username (required)

=item *

B<login>

I<boolean>. Set to true to get email address

=back

=item $zoo->user->validate(\%ARGS)

Validate the user credentials. Useful for logins.

Parameters:

=over 2

=item *

B<apikey>

I<string>. Your Zootool api key (required)

=item *

B<username>

I<string>. Your zootool username (required)

=back

=back

=head1 SEE ALSO

http://zootool.com/

http://zootool.com/api/docs

=head1 AUTHOR

Josep Roca, <quelcom@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Josep Roca

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

