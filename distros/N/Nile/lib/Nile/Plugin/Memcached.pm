#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::Memcached;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::Memcached - Memcached client plugin for the Nile framework.

=head1 SYNOPSIS
    
    # connect to Memcached servers
    my $client = $app->plugin->memcached;
    
    # store some data
    $client->set("Name"=>"Ahmed Amin Elsheshtawy Gouda");

    # get some data
    my $name = $client->get("Name");
    
    # delete some data
    $client->delete("Name");

	# get the Memcached::Client object used
    $object = $client->client;

=head1 DESCRIPTION
    
Nile::Plugin::Memcached - Memcached client plugin for the Nile framework.

Returns L<Memcached::Client> object. All methods of L<Memcached::Client> are supported.

Plugin settings in th config file under C<plugin> section.

    <plugin>

        <memcached>
            <servers>localhost:11211</servers>
            <namespace></namespace>
        </memcached>

    </plugin>

=cut

use Nile::Plugin;
use Memcached::Client;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub main {
    my ($self, $arg) = @_;
    my $app = $self->app;
    my $setting = $self->setting();
	if (defined($setting->{servers}) && (ref($setting->{servers}) ne "ARRAY")) {
		$setting->{servers} = [$setting->{servers}];
	}
    rebless => Memcached::Client->new($setting);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
