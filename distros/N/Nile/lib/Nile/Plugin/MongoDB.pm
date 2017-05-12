#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::MongoDB;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::MongoDB - MongoDB plugin for the Nile framework.

=head1 SYNOPSIS
    
    # connect to MongoDB server
    $client = $app->plugin->MongoDB;
    
    # connect to database
    my $db = $client->get_database("db_name");

    # connect to collection/table
    my $table = $db->get_collection("users");

    my $id = $table->insert({ some => 'data' });
    my $data = $table->find_one({ _id => $id });

=head1 DESCRIPTION
    
Nile::Plugin::MongoDB - MongoDB plugin for the Nile framework.

    # connect to MongoDB server
    $client = $app->plugin->MongoDB;
    
Returns the L<MongoDB::MongoClient> object. All L<MongoDB::MongoClient> methods are supported.

Plugin settings in th config file under C<plugin> section.

    <plugin>

        <mongodb>
            <server>localhost</server>
            <port>27017</port>
            <database></database>
            <collection></collection>
        </mongodb>

    </plugin>

=cut

use Nile::Plugin;
use MongoDB;
use MongoDB::MongoClient;
use MongoDB::OID;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub main {
    my ($self, $arg) = @_;
    my $app = $self->app;
    my $setting = $self->setting();
    $setting->{host} ||= "localhost:27017";
    rebless => MongoDB::MongoClient->new(%{$setting});
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
