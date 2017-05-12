package Mojolicious::Plugin::WWWSession;

use strict;
use warnings;

=head1 NAME

Mojolicious::Plugin::WWWSession - Use WWWW::Session with Mojolicious

=head2 DESCRIPTION

An alternative session implementation for Mojolicious based on WWW::Session

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.06';


=head1 SYNOPSIS

This module allows you to overwrite the standard Mojolicious session with a WWW::Session object and enjoy all the goodies it provides

Example :

=head2 Storage backends

You can use one or more of the fallowing backends : 

=head3 File storage

In you apllication module add the fallowing lines 

    use Mojolicious::Plugin::WWWSession;

    sub startup {
    
        ...
    
        #Overwrite session
        $self->plugin( WWWSession => { storage => [File => {path => '.'}] } );

        ...
    }

See WWW::Session::Storage::File for more details

=head3 Database storage

In you apllication module add the fallowing lines 

    use Mojolicious::Plugin::WWWSession;

    sub startup {
    
        ...
    
        #Overwrite session
        $self->plugin( WWWSession => { storage => [ MySQL => { 
                                                            dbh => $dbh,
                                                            table => 'sessions',
                                                            fields => {
                                                                    sid => 'session_id',
                                                                    expires => 'expires',
                                                                    data => 'data'
                                                            }
                                                    ] 
                                      } );

        ...
    }

The "fields" hasref contains the mapping of session internal data to the column names from MySQL. 
The keys are the session fields ("sid","expires" and "data") and must all be present. 

The MySQL types of the columns should be :

=over 4

=item * sid => varchar(32)

=item * expires => DATETIME or TIMESTAMP

=item * data => text

=back

See WWW::Session::Storage::MySQL for more details

=head3 Memcached storage

In you apllication module add the fallowing lines 

    use Mojolicious::Plugin::WWWSession;

    sub startup {
    
        ...
    
        #Overwrite session
        $self->plugin( WWWSession => { storage => ['Memcached' => {servers => ['127.0.0.1:11211']}] } );

        ...
    }

See WWW::Session::Storage::Memcached for more details


=head1 Using the session

This session can be used in the exact same way the strandard Mojolicious session is used

=head1 Possible options for the plugin

Here is an exmple containing the options you can pass to the plugin:

    {
    storage => [ 'File' => { path => '/tmp/sessions'},
                 'Memcached' => { servers => ['127.0.0.1'] }
               ],
    serialization => 'JSON',
    expires => 3600,
    fields => {
              user => {
                      inflate => sub { return Some::Package->new( $_[0] ) },
                      deflate => sub { $_[0]->id() },
                      }
              age => {
                     filter => [21..99],
                     }
    }
    
See WWW:Session for more details on possible options and on how you can use the session

If you use the "Storable" serialization engine you can store objects in the session. 
Also multiple session storage backends can be used simultaneously

=cut

use base 'Mojolicious::Plugin';

use WWW::Session;
use Digest::MD5 qw(md5_hex);

=head1 METHODS

=head2 register

Called by Mojo when you register the plugin

=cut

sub register {
    my ($self, $app, $args) = @_;

    $args ||= {};
    
    WWW::Session->import(%$args);

    $app->hook(
        before_dispatch => sub {
            my $self = shift;

            my $sid = $self->cookie('sid') || md5_hex($$ + time() + rand(time()));

            $self->cookie(sid => $sid);

            my %session;

			tie %session, 'WWW::Session' , $sid, {sid => $sid}, $args->{expires};

            $self->stash('mojo.session' => \%session);
        }
    );

}


=head1 AUTHOR

Gligan Calin Horea, C<< <gliganh at gmail.com> >>

Also thanks to Florian Adamsky for contributting with patches.

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-wwwsession at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-WWWSession>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::WWWSession


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-WWWSession>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-WWWSession>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-WWWSession>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-WWWSession/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Gligan Calin Horea.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Mojolicious::Plugin::WWWSession
