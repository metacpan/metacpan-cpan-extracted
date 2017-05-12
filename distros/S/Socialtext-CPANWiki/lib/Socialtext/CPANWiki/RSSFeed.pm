package Socialtext::CPANWiki::RSSFeed;
use strict;
use warnings;
use XML::Liberal;
use LWP::Simple qw/get/;

sub new {
    my $class = shift;
    my $self = {
        rdf_uri => 'http://search.cpan.org/uploads.rdf',
        @_,
    };
    bless $self, $class;
    return $self;
}

=for comment

{ # example
    'link' => 'http://search.cpan.org/~dmaki/XML-RSS-LibXML-0.30_01/',
    'desc' => 'XML::RSS with XML::LibXML',
    'version'  => '0.30_01',
    'name'     => 'XML-RSS-LibXML',
    'author'   => 'Daisuke Maki',
    'pause_id' => 'dmaki'
}

=cut

sub parse_feed {
    my $self = shift;

    my $uri = $self->{rdf_uri};
    my $rdf = get($uri);
    die "Couldn't get rdf" unless $rdf;
    my $parser = XML::Liberal->new( 'LibXML' );
    my $doc = $parser->parse_string($rdf);

    print "Fetching latest cpan rss ...\n";
    my @items = $doc->getElementsByTagName('item');
    die "No items in $uri!\n" unless @items;
    my @releases;
    for my $i (@items) {
        my $r = _parse_release($i);
        next unless $r;
        push @releases, $r;
    }
    return \@releases;
}

sub _parse_release {
    my $i = shift;
    my ($title_elem) = $i->getElementsByTagName('title');
    my $package_string = $title_elem->textContent;
    return if $package_string eq 'search.cpan.org';
    unless ($package_string =~ m/(.+)-(v?\d+(?:\.[\d_]+)+)$/) {
        warn "Couldn't parse version: $package_string";
        return;
    }
    my %release = (
        name => $1,
        version => $2,
    );

    my ($link_elem)  = $i->getElementsByTagName('link');
    $release{link} = $link_elem->textContent;
    $release{pause_id} = $1 if $release{link} =~ m#search\.cpan\.org/~(\w+)/#;

    my ($desc_elem) = $i->getElementsByTagName('description');
    $release{desc} = $desc_elem ? $desc_elem->textContent : 'No description';
    my ($author_elem) = $i->getElementsByTagName('dc:creator');
    $release{author} = $author_elem->textContent;
    return \%release;
}

1;
