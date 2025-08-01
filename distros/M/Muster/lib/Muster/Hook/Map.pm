package Muster::Hook::Map;
$Muster::Hook::Map::VERSION = '0.93';
=head1 NAME

Muster::Hook::Map - Muster map and pmap directive.

=head1 VERSION

version 0.93

=head1 DESCRIPTION

L<Muster::Hook::Map> creates two directives, map and pmap (pretty map),
used to make lists of pages.

=cut

use Mojo::Base 'Muster::Hook::Directives';
use Muster::LeafFile;
use Muster::Hooks;
use Muster::Hook::Links;
use File::Basename qw(basename);
use File::Spec;
use HTML::LinkList;
use YAML::Any;

use Carp 'croak';

=head1 METHODS

L<Muster::Hook::Map> inherits all methods from L<Muster::Hook::Directives>.

=head2 register

Do some intialization.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{metadb} = $hookmaster->{metadb};

    $hookmaster->add_hook('map' => sub {
            my %args = @_;

            return $self->do_directives(
                no_scan=>1,
                directive=>'map',
                call=>sub {
                    my %args2 = @_;

                    return $self->process(directive=>'map',%args2);
                },
                %args,
            );
        },
    );
    $hookmaster->add_hook('pmap' => sub {
            my %args = @_;

            return $self->do_directives(
                no_scan=>1,
                directive=>'pmap',
                call=>sub {
                    my %args2 = @_;

                    return $self->process(directive=>'pmap',%args2);
                },
                %args,
            );
        },
    );
    return $self;
} # register

=head2 process

Process maps.
If there are no matching pages, returns an empty string.

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $directive = $args{directive};
    my $leaf = $args{leaf};
    my $phase = $args{phase};
    my @p = @{$args{params}};
    my %params = @p;
    my $pagename = $leaf->pagename;
    my $show = $params{show};
    delete $params{show};
    my $map_type = (defined $params{map_type} ? $params{map_type} : '');

    if (! exists $params{pages}
            and ! exists $params{pagenames}
            and ! exists $params{titles}
            and ! exists $params{where})
    {
	return "ERROR: missing pages/pagenames/where parameter";
    }
    if ($phase eq $Muster::Hooks::PHASE_SCAN)
    {
        return "";
    }

    my @matching_pages = ();
    if (exists $params{pages})
    {
        my $pages = $self->{metadb}->query_pagespec($params{pages});
        @matching_pages = @{$pages} if $pages;
    }
    elsif (exists $params{titles} and exists $params{relto})
    {
        # titles are separated by | and may have spaces which should be _
        $params{titles} =~ s/ /_/g;
	@matching_pages =
	    map { $self->{metadb}->bestlink($params{relto}, $_) } split /\|/, $params{titles};
    }
    elsif (exists $params{pagenames})
    {
	@matching_pages =
	    map { $self->{metadb}->bestlink($pagename, $_) } split ' ', $params{pagenames};
    }
    elsif (exists $params{where})
    {
        my $pages = $self->{metadb}->query("SELECT page FROM flatfields WHERE " . $params{where});
        @matching_pages = @{$pages} if $pages;
    }
    if (!scalar @matching_pages)
    {
        return "";
    }

    my $result = '';
    if ($directive eq 'map')
    {
        my %labels = ();
        my @urls = ();
        foreach my $pn (@matching_pages)
        {
            $labels{$pn} = basename($pn);
            # top-level index page is treated differently
            my $relpage = ($leaf->pagename eq 'index'
                ? $pn
                : File::Spec->abs2rel($pn, $leaf->pagename));
            push @urls, $relpage;
        }
        $result = HTML::LinkList::link_list(
            urls=>\@urls,
            labels=>\%labels,
        );
    }
    else # pmap
    {
        my @link_list = ();
        my %page_labels = ();
        my %page_desc = ();
        my $count = ($params{count}
            ? ($params{count} < @matching_pages
                ? $params{count}
                : scalar @matching_pages
            )
            : scalar @matching_pages);
        my $min_depth = 100;
        my $max_depth = 0;
        for (my $i=0; $i < $count; $i++)
        {
            my $page = $matching_pages[$i];
            my $page_info = $self->{metadb}->page_or_file_info($page);
            my $pd = page_depth($page);
            if ($pd < $min_depth)
            {
                $min_depth = $pd;
            }
            if ($pd > $max_depth)
            {
                $max_depth = $pd;
            }
            my $urlto = ($leaf->pagename eq 'index'
                ? $page
                : File::Spec->abs2rel($page, $leaf->pagename));
            push @link_list, $urlto;

            if (defined $show)
            {
                if (defined $show
                        and defined $page_info
                        and $show =~ /title/o)
                {
                    $page_labels{$urlto}=$page_info->{title};
                    $page_labels{$urlto} =~ s/ & / &amp; /go;
                }
                if (defined $show
                        and defined $page_info
                        and $show =~ /desc/o)
                {
                    if ($page_info->{description})
                    {
                        $page_desc{$urlto}=$page_info->{description};
                    }
                }
            }
        } # for the pages

        my $current_url = "/$pagename/";

        # if all the pages are at the same depth, and the map_type is
        # not set, then set the map_type to 'list'
        $map_type = 'list' if (!$map_type and $min_depth == $max_depth);

        my $tree = ($map_type eq 'nav'
            ? HTML::LinkList::nav_tree(paths=>\@link_list,
                preserve_paths=>1,
                labels=>\%page_labels,
                descriptions=>\%page_desc,
                current_url=> $current_url,
                %params)
            : ($map_type eq 'breadcrumb'
                ? HTML::LinkList::breadcrumb_trail(current_url=>$current_url,
                    labels=>\%page_labels)
                : ($map_type eq 'list'
                    ? HTML::LinkList::link_list(urls=>\@link_list,
                        labels=>\%page_labels,
                        descriptions=>\%page_desc,
                        current_url => $current_url,
                        %params)
                    : HTML::LinkList::full_tree(paths=>\@link_list,
                        preserve_paths=>1,
                        labels=>\%page_labels,
                        descriptions=>\%page_desc,
                        current_url => $current_url,
                        %params)
                )));

        $result = ($params{no_div} 
            ? $tree
            : ($map_type eq 'nav'
                ? "<nav>$tree</nav>\n"
                : ($params{class}
                    ? "<div class='$params{class}'>$tree</div>\n"
                    : "<div class='map'>$tree</div>\n")
            )
        );
    } # else pmap

    if ($params{prepend})
    {
        $result = $params{prepend} . $result;
    }
    return $result;
} # process

=head2 page_depth

Calculate the page depth of the given page.

=cut
sub page_depth {
    my $page = shift;

    return 0 if ($page eq 'index'); # root is zero
    return scalar ($page =~ tr!/!/!) + 1;
} # page_depth
1;
