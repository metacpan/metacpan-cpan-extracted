#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::Elasticsearch;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::Elasticsearch - Elasticsearch client plugin for the Nile framework.

=head1 SYNOPSIS
    
    my $client = $app->plugin->elasticsearch;
    
    $app->dump($client->nodes->info);
    
    $app->dump($client->nodes->stats);

    $client->index(
        index   => 'my_index',
        type    => 'blog_post',
        id      => 123,
        body    => {
            title   => "Elasticsearch clients",
            content => "Interesting content...",
            date    => "2013-09-23"
        }
    );

    my $doc = $client->get(
            index   => 'my_index',
            type    => 'blog_post',
            id      => 123,
			ignore => [404,409],
    );

    $app->dump($doc);

    my $results = $client->search(
        index   => 'my_index',
        body    => {
            query => {
                match => {
                    title => "elasticsearch"
                }
            }
        }
    );

    $app->dump($results);

=head1 DESCRIPTION
    
Nile::Plugin::Elasticsearch - Elasticsearch client plugin for the Nile framework.

Returns L<Search::Elasticsearch> object. All methods of L<Search::Elasticsearch> are supported.

Plugin settings in th config file under C<plugin> section.

    <plugin>

        <elasticsearch>
            <nodes>localhost:9200</nodes>
        </elasticsearch>

    </plugin>

=cut

use Nile::Plugin;
use Search::Elasticsearch;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub main {
    my ($self, $arg) = @_;
    my $app = $self->app;
    my $setting = $self->setting();
    if (defined($setting->{nodes}) && (ref($setting->{nodes}) ne "ARRAY")) {
        $setting->{nodes} = [$setting->{nodes}];
    }
    rebless => Search::Elasticsearch->new(%{$setting});
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
