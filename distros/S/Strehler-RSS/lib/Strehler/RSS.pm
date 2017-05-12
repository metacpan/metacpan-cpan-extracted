package Strehler::RSS;
$Strehler::RSS::VERSION = '1.1.2';
# ABSTRACT: RSS management using Strehler

use strict;
use Dancer2 0.160000;
use Strehler::Element::RSS::RSSChannel;
use Strehler::Helpers;
use XML::Feed;
use XML::Feed::Entry;

prefix '/rss';

get '/:lang/:slug' => sub
{
    my $language = params->{lang};
    my $slug = params->{slug};
    $slug =~ s/\.xml$//;
    my $rss = Strehler::Element::RSS::RSSChannel->get_by_slug($slug, $language);
    my %rss_data = $rss->get_ext_data();
    my $entity = Strehler::Helpers::class_from_entity($rss_data{'entity_type'});
    my $query;
    $query->{'order'} = 'desc';
    $query->{'order_by'} = $rss->get_attr("order_by");
    $query->{'entries_per_page'} = config->{Strehler}->{RSS}->{entries} || 6;
    $query->{'language'} = $language;
    $query->{'published'} = 1;
    $query->{'ext'} = 1;
    if($rss->get_attr("deep") && $rss->get_attr("deep") == 1)
    {
        $query->{'ancestor'} = $rss->get_attr("category", 1);
    }
    else
    {
        $query->{'category'} = $rss->get_attr("category");
    }
    my $elements = $entity->get_list($query);
    my $rss_items = [];
    my $link_template = $rss->get_attr('link_template');
    my $feed = XML::Feed->new('RSS', version => '2.0');
    $feed->title($rss->get_attr_multilang('title', $language)); 
    $feed->description($rss->get_attr_multilang('description', $language)); 
    $feed->link($rss->get_attr('link')); 
    $feed->language($language); 
    $feed->generator("Strehler::RSS " . $Strehler::RSS::VERSION); 
    foreach my $e (@{$elements->{'to_view'}})
    {
        my $item = XML::Feed::Entry->new('RSS', version => '2.0');
        $item->title($e->{$rss->get_attr('title_field')});
        $item->content($e->{$rss->get_attr('description_field')});
        
        my $link_value = $e->{$rss->get_attr('link_field')};
        my $link = $link_template;
        $link =~ s/%%/$link_value/;
        $link =  $link;
        $item->link($link);
        $feed->add_entry($item);

    }

    content_type('application/rss+xml');
    return $feed->as_xml;
};

get '/:slug' => sub
{
    forward "/" . dancer_app->prefix . "/" . config->{Strehler}->{default_language} . "/" . params->{slug};
};

=encoding utf8

=head1 NAME

Strehler::RSS - RSS Feed created using Strehler contents

=head1 DESCRIPTION

Strehler::RSS gives a Strehler site possibility to have automatic RSS feed, based on contents published using Strehler.

=head1 INSTALLATION

In your Strehler-based site directory, do

    strehler initentity Strehler::Element::RSS::RSSChannel

As said by installation procedure, then do

    strehler schemadump

Add Strehler::RSS module to your app.psgi.

Remember to verify also that the module L<Strehler::API> (from Strehler main package) is in your app.psgi because it's used by backend form.

=head1 CONFIGURATION

There's only a configuration key available that you can manage from your config.yml.

    Strehler:
        RSS:
            entries: 10

Default value is 6, it means that, when the RSS feed is generated, latest six contents are retrieved and used as items. You can change it as you like. Using -1 will make Strehler::RSS to use all the configured contents in the feed.

=head1 USE

Look at the documentation of L<Strehler::Element::RSS::RSSChannel> to see how to configure an RSS Channel and how to retrieve link to it. Put the link on your site to make RSS available to your users.

=cut

1;
