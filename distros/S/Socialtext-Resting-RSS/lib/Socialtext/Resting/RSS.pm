package Socialtext::Resting::RSS;
use strict;
use warnings;
use Carp qw/croak/;
use JSON;
use XML::RSS;
use Text::Diff;
use File::Path qw/mkpath/;

=head1 NAME

Socialtext::Resting::RSS - Create rss feeds for a Socialtext workspace

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Socialtext::Resting::RSS;
  my $rss = Socialtext::Resting::RSS->new(
      rester => $rester, output => 'foo.rss',
  );
  my $num_changes = $rss->generate;

=head1 DESCRIPTION

C<Socialtext::Resting::RSS> uses the Socialtext REST API to create a
RSS feed that features diffs from the previous version.

Patches welcome.  Or take over this module! :)

=cut

sub new {
    my $class = shift;
    my $self = { 
        cache_dir => "$ENV{HOME}/.st-rss",
        max_feed_entries => 20,
        @_,
    };
    if ($self->{output_dir}) {
        $self->{output} = "$self->{output_dir}/" 
            . $self->{rester}->workspace . ".rss";
    }
    for my $m (qw/rester output/) {
        croak("$m is mandatory!") unless $self->{$m};
    }
    bless $self, $class;
    return $self;
}

sub generate {
    my $self = shift;

    $self->_load_page_cache;
    $self->_load_latest_pages;
    $self->_calculate_changed_pages;

    if (@{ $self->{_changes} }) {
        $self->_write_new_rss;
        $self->_rewrite_cache;
    }
    return @{ $self->{_changes} };
}

sub _load_page_cache {
    my $self = shift;
    my $r = $self->{rester};
    my $dir = $self->_page_cache_dir;
    print "Loading page cache from $dir ...\n";

    my %cache;
    my @pages = glob("$dir/*");
    for my $p (@pages) {
        open(my $fh, $p) or die "Can't open $p: $!";
        my $json_text;
        { local $/; $json_text = <$fh> }
        close $fh;
        my $json = jsonToObj($json_text);
        $cache{$json->{page_id}} = $json;
        print "  Loaded $json->{page_id}\n";
    }
    $self->{_page_cache} = \%cache;
}

sub _load_latest_pages {
    my $self = shift;
    my $r = $self->{rester};
    my $cache = $self->{_page_cache};;
    print "Loading the latest pages ...\n";

    $r->accept('perl_hash');
    my $pages = $r->get_taggedpages('Recent Changes');
    @$pages = splice @$pages, 0, $self->{max_feed_entries};

    my %latest;
    for my $p (@$pages) {
        $latest{$p->{page_id}} = $p;
    }
    $self->{_latest_cache} = \%latest;
}

sub _calculate_changed_pages {
    my $self = shift;
    my $r   = $self->{rester};
    my $old = $self->{_page_cache};
    my $new = $self->{_latest_cache};

    my @changes;
    for my $p (keys %$new) {
        my $obj = $new->{$p};
        my $desc;
        if (!exists $old->{$p}) {
            warn "  $p is new!\n";
            $desc = $obj->{wikitext} = _fetch_wikitext($r, $obj->{page_id});
        }
        elsif ($obj->{revision_id} != $old->{$p}{revision_id}) {
            warn "  $p has changed!\n";
            $obj->{wikitext} = _fetch_wikitext($r, $obj->{page_id});
            $desc = $self->_diff_content($old->{$p}, $obj);
            $desc = "Differences between revision $old->{$p}{revision_count} and $obj->{revision_count}:\n$desc";
        }
        next unless $desc;

        $self->_wikitext_to_html($desc);
        my $workspace_url = join '/', $r->server, $r->workspace;
        push @changes, {
            title => "$obj->{name} - Revision $obj->{revision_count}",
            link => "$workspace_url/?$obj->{page_id}",
            description => $desc,
            modified_time => $obj->{modified_time},
        };
    }

    @changes = sort { $b->{modified_time} <=> $a->{modified_time} } @changes;
    $self->{_changes} = \@changes;
}

sub _wikitext_to_html {
    my $self = shift;
    $_[0] =~ s#\n#<br />\n#g;
    $_[0] =~ s#^(\+.+)$#<span style="color: green">$1</span>#mg;
    $_[0] =~ s#^(\-.+)$#<span style="color: red">$1</span>#mg;
}

sub _diff_content {
    my $self = shift;
    my $old = shift;
    my $new = shift;

    my $old_wt = $old->{wikitext};
    my $new_wt = $new->{wikitext};
    return diff( \$old_wt, \$new_wt, {
            FILENAME_A => $old->{revision_count},
            MTIME_A => $old->{modified_time},
            FILENAME_B => $new->{revision_count},
            MTIME_B => $new->{modified_time},
        },
    );
}

sub _rewrite_cache {
    my $self = shift;
    my $r = $self->{rester};
    my $dir = $self->_page_cache_dir;
    my $new = $self->{_latest_cache};;
    print "Writing page cache to $dir ...\n";

    my @cached_pages = glob("$dir/*");

    # Write new and changed pages
    for my $p (keys %$new) {
        warn "  writing cache - $p\n";
        my $filename = "$dir/$new->{$p}{page_id}";
        open(my $fh, ">$filename") or die "Can't write $filename: $!";
        print $fh objToJson($new->{$p});
        close $fh or die "Can't write $filename: $!";
    }

    # Pages will never be pruned from this cache, as we never know when
    # pages get deleted
}

sub _write_new_rss {
    my $self = shift;
    my $r   = $self->{rester};
    my $changes = $self->{_changes};
    my $filename = $self->{output};;

    my $rss = new XML::RSS (version => '2.0');
    $rss->channel(
        title          => 'Socialtext Feed - ' . $r->workspace,
        link           => $r->server . '/' . $r->workspace,
        language       => 'en',
        description    => 'Socialtext Diff Feed',
        lastBuildDate  => scalar(localtime),
    );
    for my $c (@$changes) {
        $rss->add_item(%$c);
    }

    $rss->save($filename);
    print "Wrote $filename\n";
}

sub _page_cache_dir {
    my $self = shift;
    my $r = $self->{rester};
    my $dir = "$self->{cache_dir}/" . $r->workspace;
    -d $dir or mkpath $dir or die "Can't mkpath: $dir: $!";
    return $dir;
}

sub _fetch_wikitext {
    my $r = shift;
    my $page = shift;
    print "  Fetching wikitext for $page\n";
    $r->accept('text/x.socialtext-wiki');
    return $r->get_page($page);
}

=head1 KNOWN ISSUES

It rewrites the rss feed every time it is run, losing previous entries.  It should keep some count of entries in the rss feed at all time.

It could also only check pages with a given tag.

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
