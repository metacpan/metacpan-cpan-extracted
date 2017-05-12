use Modern::Perl;

package Net::OpenXchange;
BEGIN {
  $Net::OpenXchange::VERSION = '0.001';
}

use Moose;
use namespace::autoclean;

# ABSTRACT: Object-oriented interface to OpenXchange groupware

use Carp;
use Net::OpenXchange::Connection;

# Create attributes and builder methods for modules
BEGIN {
    require Module::Pluggable;
    Module::Pluggable->import(
        sub_name    => '_modules',
        search_path => ['Net::OpenXchange::Module'],
        require     => 1,
    );
    foreach my $module (__PACKAGE__->_modules) {
        my $attr;
        if ($module =~ /^.+::(.+?)$/) {
            $attr = lc $1;
        }
        else {
            # perlcritic suggested to only use match variables in conditional
            # blocks
            confess "Module::Pluggable returned wrong module name: $module";
        }

        __PACKAGE__->meta->add_attribute(
            $attr,
            is       => 'ro',
            isa      => $module,
            init_arg => undef,
            lazy     => 1,
            builder  => "_build_$attr",
        );
        __PACKAGE__->meta->add_method(
            "_build_$attr" => sub {
                my ($self) = @_;
                return $module->new(conn => $self->conn);
            }
        );
    }
}

has uri => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has login => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has conn => (
    is       => 'ro',
    isa      => 'Net::OpenXchange::Connection',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_conn',
);

sub _build_conn {
    my ($self) = @_;
    return Net::OpenXchange::Connection->new(
        uri      => $self->uri,
        login    => $self->login,
        password => $self->password,
    );
}

sub BUILD {
    my ($self) = @_;
    $self->conn;    # force connection
    return;
}

__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=head1 NAME

Net::OpenXchange - Object-oriented interface to OpenXchange groupware

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange is new and very unfinished code. Its coverage of the OX API
actions, objects and attributes is limited. However it already proved useful,
so I decided to release this early experimental version. If you choose to use
it, I would really appreciate bug reports, with or without attached patches :-)
I'd also welcome help adding support for more parts of the OpenXchange API.

Net::OpenXchange is the frontend to all packages of Net::OpenXchange.

    use Modern::Perl;
    use Net::OpenXchange;
    use DateTime::Format::Mail;

    my $ox = Net::OpenXchange->new(
        uri      => 'https://ox.example.org/ajax',
        login    => 'myuser',
        password => 'mypassword',
    );

    my $folder = $ox->folder->resolve_path('Public folders', 'Calendar');
    my @appointments = $ox->calendar->all(
        folder => $folder,
        start  => DateTime->new(year => 2010, month =>  1, day =>  1),
        end    => DateTime->new(year => 2010, month => 12, day => 31),
    );

    foreach (@appointments) {
        say 'Start: ', DateTime::Format::Mail->format_datetime($_->start_date);
        say 'End: ',   DateTime::Format::Mail->format_datetime($_->end_date);
        say 'Title: ', $_->title;
        say '';
    }

Net::OpenXchange connects to the server when creating an object instance and
disconnects on object destruction. All errors are raised as exceptions.

All Net::OpenXchange::Module::* packages are available as attributes on this
class - for example
L<Net::OpenXchange::Module::Folder|Net::OpenXchange::Module::Folder> becomes
$ox->folder. See the documentation for these packages.

=head1 ATTRIBUTES

=head2 uri

Required constructor argument. URI to the HTTP API of your OpenXchange server. Please note you have
to add the /ajax manually.

=head2 login

Required constructor argument. Username to log into OpenXchange.

=head2 password

Required constructor argument. Password to log into OpenXchange.

=head2 conn

Read-only. An instance of L<Net::OpenXchange::Connection|Net::OpenXchange::Connection>. You will not have to use this directly.

=head2 calendar

Read-only. An instance of L<Net::OpenXchange::Module::Calendar|Net::OpenXchange::Module::Calendar>. See its documentation for provided methods.

=head2 contact

Read-only. An instance of L<Net::OpenXchange::Module::Contact|Net::OpenXchange::Module::Contact>. See its documentation for provided methods.

=head2 folder

Read-only. An instance of L<Net::OpenXchange::Module::Folder|Net::OpenXchange::Module::Folder>. See its documentation for provided methods.

=head2 user

Read-only. An instance of L<Net::OpenXchange::Module::User|Net::OpenXchange::Module::User>. See its documentation for provided methods.

=head1 METHODS

=head2 new

    my $ox = Net::OpenXchange->new(
        uri      => "https://ox.example.com/ajax",
        login    => $username,
        password => $password,
    );

Connect to OpenXchange server.

=for Pod::Coverage BUILD

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

