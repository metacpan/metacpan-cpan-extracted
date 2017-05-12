package Strehler::Element::RSS::RSSChannel;
$Strehler::Element::RSS::RSSChannel::VERSION = '1.1.2';
use strict;
use Cwd 'abs_path';
use Moo;
use Dancer2 0.154000;
use Strehler::Helpers;
use File::Copy;

extends 'Strehler::Element';
with 'Strehler::Element::Role::Slugged';
with 'Strehler::Element::Role::Maintainer';

my $module_file_path = __FILE__;
my $root_path = abs_path($module_file_path);
$root_path =~ s/RSSChannel\.pm//;
my $form_path = $root_path . "../../forms";
my $views_path = $root_path . "../../views";

sub metaclass_data 
{
    my $self = shift;
    my $param = shift;
    my %element_conf = ( item_type => 'rsschannel',
                         ORMObj => 'Rsschannel',
                         category_accessor => 'rsschannels',
                         multilang_children => 'rsschannel_headers' );
    return $element_conf{$param};
}
sub form { return "$form_path/RSS/rsschannel.yml" }
sub multilang_form { return "$form_path/RSS/rsschannel_multilang.yml" }
sub categorized { return 1; }
sub publishable  { return 1; }
sub add_main_column_span { return 8; }
sub entity_js { return '/strehler/js/rsschannel.js'; }

sub main_title
{
    my $self = shift;
    my @contents = $self->row->rsschannel_headers->search({ language => config->{Strehler}->{default_language} });
    if($contents[0])
    {
        return $contents[0]->title;
    }
    else
    {
        #Should not be possible
        return "*** no title ***";
    }

}
sub fields_list
{
    my $self = shift;
    my @fields = ( { 'id' => 'id',
                     'label' => 'ID',
                     'ordinable' => 1 },
                   { 'id' => 'rsschannel_headers.title',
                     'label' => 'Title',
                     'ordinable' => 1 },
                   { 'id' => 'category',
                       'label' => 'Category',
                       'ordinable' => 0 },
                   { 'id' => 'entity_type',
                       'label' => 'Entity',
                       'ordinable' => 1 },
                   { 'id' => 'published',
                     'label' => 'Status',
                     'ordinable' => 1 }
               );
    return \@fields;
}
sub custom_list_template
{
    return $views_path . "/admin/rss/rss_list_block.tt";
}
sub custom_snippet_add_position
{
    return "right";
}
sub custom_add_snippet
{
    my $self = shift;
    if(ref($self))
    {
        my @languages;
        if(config->{Strehler}->{languages})
        {
            @languages = @{config->{Strehler}->{languages}};
        }
        else
        {
            @languages = ('en');
        }
        my $explain = q{
        <p>Link to RSS, you can copy them from here and use them on the frontend</p>
        <p>If you want to click them, remember that they'll work only if the RSS Channel is published.</p>
        };
        my $explain_default = q{
            <p>Default RSS is the RSS in the default language</p>
        };
        my $default_language =  config->{Strehler}->{default_language};
        my $default_link = "/rss/" . $self->get_attr_multilang('slug',  $default_language) . ".xml";
        my $out = "<h3>Links to RSS</h3>" . $explain .
                  "<h5>Default</h5>" . $explain_default .
                  "<ul><li><a href=\"$default_link\">$default_link</a></li></ul>" .
                  "<h5>By language</h5><ul>";
        foreach my $lang (@languages)
        {
            if($self->get_attr_multilang('slug',  $lang))
            {
                my $link = "/rss/$lang/" . $self->get_attr_multilang('slug',  $lang) . ".xml";
                $out .= "<li>$lang: <a href=\"$link\">$link</a></li>"
            }
        }
        $out .= "</ul>";
        return $out; 
    }
    else
    {
        return undef;
    }
}

sub install
{
    my $self = shift;
    my $dbh = shift;
    $self->deploy_entity_on_db($dbh, ["Strehler::Schema::RSS::Result::Rsschannel", "Strehler::Schema::RSS::Result::RsschannelHeader"]);
    my $package_root = __FILE__;
    $package_root =~ s/RSSChannel\.pm$//;
    my $statics = $package_root . "../../public";
    my $configured_public_directory = Strehler::Helpers::public_directory();
    my $resource_file = 'rsschannel.js';
    my $copy_from = $statics . "/strehler/js/" . $resource_file;
    my $copy_to = $configured_public_directory . "/strehler/js/" . $resource_file;
    if(-f $copy_to)
    {
        chmod 777, $copy_to;
        unlink $copy_to;
    }
    copy($copy_from, $copy_to) || print "Failing copying from $copy_from to $copy_to\nError: " . $! . "\n";
    return "RSS Channel entity available!\n\nJavascript resources copied under public directory!\n\nDeploy of database tables completed\n\nCheck above for errors\n\nRun strehler schemadump to update your model\n\n";
}
sub get_link
{
    my $self = shift;
    my $entity = shift;
    my $category = shift;
    my $lang = shift;
    my $result = $self->get_list({ search => { entity_type => $entity }, 
                      category => $category,
                      language => $lang,
                     ext => 1 });
    if(exists $result->{'to_view'}->[0])
    {
        my $rss = $result->{'to_view'}->[0];
        my $out = "/rss";
        if($lang)
        {
            $out .= "/" . $lang;
        }
        $out .= "/" . $rss->{'slug'} . ".xml";
        return $out;
    }
    else
    {
        return undef;
    }
}

=encoding utf8

=head1 NAME

Strehler::Element::RSS::RSSChannel - RSS Channel

=head1 DESCRIPTION

RSS Channel, configuration of a RSS Channel to erogate a feed based on Strehler entity.

=head1 INSTALLATION

    strehler initentity Strehler::Element::RSS::RSSChannel

Entity installation will create two new database tables to store channels. You'll need a schemadump.

A new javascript will be added to your public directory.

=head1 ATTRIBUTES

Many attributes are related to RSS 2.0 attributes, as defined by RSS 2.0 Specification: L<http://www.rssboard.org/rss-specification>

=over 4

=item B<link>

Link for the Channel

=item B<entity_type>

The entity that will be used to generate the RSS

=item B<category>

The category of the contents of the RSS

=item B<deep>

If true will be retrieved contens from the category and from its subcategories.

=item B<title_field>

The field (from selected entity) that will be used as title of the feed.

=item B<description_field>

The field (from selected entity) that will be used as description of the feed. This content will be encoded and used for the field <content:encoded>

=item B<link_field>

The field (from selected entity) that will be used in the link_template (see below) to build the content link

=item B<link_template>

The way the content is reached in the site is indepentent from Strehler, based on how the frontend has been designed. You can write here the template to build a link to the content. Where the link_field will be used write just '%%'.

=item B<order_by>

The way contents will be ordered (to decide most recent).

=item B<title>

Multilanguage field.

The title of the channel

=item B<description>

Multilanguage field.

The description of the channel.

=back

RSS Channel is a Slugged entity. (see L<Strehler::Element::Role::Slugged>).

=head1 METHODS

=over 4

=item get_link

Arguments: $entity, $category, $language

Return Values: $link

Class method that can be used to retrieve a link to a RSS, considering an entity and a category. If no language is provided the default link is returned.

Warning: using $entity and $category a unique result is not guarantee. The method will however return the first value found in the database.

Link structure is the one from L<Strehler::RSS>.

=back

=cut




