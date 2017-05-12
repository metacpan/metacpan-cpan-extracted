package Mojolicious::Plugin::Redis;

use warnings;
use strict;

=head1 NAME

Mojolicious::Plugin::Redis - Simply use Redis in Mojolicious 

=head1 VERSION

Version 0.03

=cut

BEGIN {
  $Mojolicious::Plugin::Redis::VERSION = '0.03';
}

use Mojo::Base 'Mojolicious::Plugin';

use Redis;

=head1 INSTALLATION

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=head1 SYNOPSIS

Provides a few helpers to ease the use of Redis in your Mojolicious application.

	use Mojolicious::Plugin::Redis
	
	sub startup {
	  my $self = shift;
		
	  $self->plugin('redis', { 
		  server => 'localhost:6379',
		  debug => 0,
		  encoding => undef, # Disable the automatic utf8 encoding => much more performance
		  helper => 'db'
		});
	}

=head1 CONFIGURATION OPTIONS

    helper      (optional)  The name to give to the easy-access helper if you want to change it's name from the default
    no_helper   (optional)  When set to true, no helper will be installed.

All other options passed to the plugin are used to connect to Redis. In other words ANY option can be sended to Redis module.

=head1 HELPERS/ATTRIBUTES

=head2 redis_connection

This plugin attribute holds the Redis::Connection object, use this if you need to access it for some reason. 

=head2 db

This helper will return the database handler. If you have renamed the helper, use that name instead of 'db' in the example below :)

    sub someaction {
      my $self = shift;
	  
	  # ping Redis server
	  $self->db->PING();
	  
	  # get value of 'foo' named key
	  $self->db->GET('foo');

    }

=cut

sub register {
    my $self = shift;
    my $app  = shift;
    my $conf = shift || {}; 

    $conf->{helper} ||= 'db';
    
    $app->attr('redis_connection' => sub { Redis->new(%$conf) });

    $app->helper($conf->{helper} => sub {
        my $self = shift;
        return $self->app->redis_connection;
    }) unless($conf->{nohelper});

}

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/Meettya/Mojolicious-Plugin-Redis

=head1 AUTHOR

Meettya, C<meettya@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-redis at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-Redis>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::Redis


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-Redis>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-Redis>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-Redis>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-Redis/>

=back


=head1 ACKNOWLEDGEMENTS

Ben van Staveren (inspiration from L<Mojolicious::Plugin::Mongodb>), so I didn't have to write it myself, just copy-paste.
Sergey Zasenko for test fix.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Meettya, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Mojolicious::Plugin::Redis
