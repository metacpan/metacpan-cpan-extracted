package Socialtext::CPANWiki;
use strict;
use warnings;
use Socialtext::CPANWiki::RSSFeed;
use Data::Dumper;

=head1 NAME

Socialtext::CPANWiki - Update a wiki with info from the CPAN RSS Feed

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    Socialtext::CPANWiki->new(
        rester => $rester,
        filter_page => 'CPAN Module Filter',
    )->update;

=cut

sub new {
    my $class = shift;
    my $self = {
        @_,
        pause_id => {},
        author   => {},
    };
    die 'rester is mandatory!' unless $self->{rester};
    bless $self, $class;
    return $self;
}

sub update {
    my $self = shift;

    $self->{releases} = Socialtext::CPANWiki::RSSFeed->new->parse_feed;

    $self->_filter_packages if $self->{filter_page};

    $self->_update_releases;
    $self->_update_pause_ids;
    $self->_update_authors;
}

sub _filter_packages {
    my $self = shift;
    my $package_filter = $self->load_package_list;
    my $releases = $self->{releases};
    if (%$package_filter) {
        @$releases = grep { $package_filter->{$_->{name}} }
                     @$releases;
    }
}

sub _update_releases {
    my $self = shift;

    print "Putting releases onto the wiki ...\n";
    for my $r (@{ $self->{releases} }) {
        my $continue = 1;
        eval { 
            $continue = $self->_put_release_on_wiki($r);
        };
        warn $@ if $@;
        last unless $continue;
    }
}

sub _update_pause_ids {
    my $self = shift;

    my $pause_id = $self->{pause_id};
    print "\nUpdating PAUSE ID pages ...\n" if %$pause_id;
    for my $id (keys %$pause_id) {
        my $author = $pause_id->{$id};
        put_author_page($id, <<EOT, 'pause_id');
[$author]

{include: [$author]}
EOT
    }
}

sub _update_authors {
    my $self = shift;

    my $author = $self->{author};
    print "\nUpdating author pages ...\n" if %$author;
    for my $id (keys %$author) {
        my $releases = $author->{$id};
        my $pause_id = $releases->[0]->{pause_id};
        $self->_put_author_page($id, <<EOT, 'author');
* "CPAN Page" <http://search.cpan.org/~$pause_id/>

^^ Packages

{search: tag: package AND tag: $pause_id}

EOT
    }
}

sub load_package_list {
    my $self      = shift;
    my $page_name = $self->{filter_page};
    my $rester    = $self->{rester};
    print "Loading '$page_name' from " . $rester->workspace . "\n";
    my $page = $rester->get_page($page_name);
    my %packages;
    while ($page =~ m/^\*\s+(.+)$/mg) {
        $packages{$1}++;
    }
    return \%packages;
}

sub _put_release_on_wiki {
    my $self = shift;
    my $r    = shift;
    my $rester = $self->{rester};

    my $release_page = "$r->{name}-$r->{version}";
    print sprintf('%50s ', $release_page);
    $rester->get_page($release_page);
    my $code = $rester->response->code;
    if ($code eq '200') {
        print "skipping ...\n";
        return 0;
    }

    $rester->put_page($release_page, <<EOT);
^^ Release Details

*Package:* [$r->{name}]
*Version:* "$r->{version}" <$r->{link}>
*Description:* $r->{desc}
*Author:* "$r->{author}" <http://search.cpan.org/~$r->{pause_id}/>
*PAUSE ID:* "$r->{pause_id}" <http://search.cpan.org/~$r->{pause_id}/>

"$release_page on CPAN" <$r->{link}>

^^ Comments
EOT

    my @release_tags = ('release', $r->{name}, $r->{pause_id}, $r->{version});
    print 'tags: ', join(', ', @release_tags);
    for my $p (@release_tags) {
        $rester->put_pagetag($release_page, $p);
    }

    my $package_page = $r->{name};
    print "\n", sprintf('%50s ', $package_page);
    my $package_page_text = $rester->get_page($r->{name});
    my $comments = "^^ Comments:\n";
    if ($package_page_text =~ m/\Q$comments\E(.+)/s) {
        $comments .= $1;
    }

    $rester->put_page($r->{name}, <<EOT);
*Package:* $r->{name}
*Latest release:* [$release_page]
*Version:* "$r->{version}" <$r->{link}>
*Description:* $r->{desc}
*Author:* "$r->{author}" <http://search.cpan.org/~$r->{pause_id}/>
*PAUSE ID:* {category: $r->{pause_id}}

"Latest release on CPAN: $release_page" <$r->{link}>

^^ All Releases

{category: $r->{name}}


$comments
EOT
    my @package_tags = ('package', $r->{name}, $r->{pause_id}, $r->{version});
    print 'tags: ', join(', ', @package_tags);
    for my $p (@package_tags) {
        $rester->put_pagetag($package_page, $p);
    }

    print "\n";

    # Update author tables
    $self->{pause_id}{$r->{pause_id}} = $r->{author};
    push @{ $self->{author}{$r->{author}} }, $r;

    return 1;
}

sub _put_author_page {
    my $self    = shift;
    my $page    = shift;
    my $content = shift;
    my $rester  = $self->{rester};
    my @tags    = @_;
    my $code    = '';
    eval {
        my $existing_page = $rester->get_page($page);
        $code = $rester->response->code;
    };
    warn "Error: get_page($page, 'pause_id'): $@" if $@;
    return unless $code eq '404';

    print "  $page\n";
    eval {
        $rester->put_page($page, $content);
    };
    warn "Error: put_page($page, <content>): $@" if $@;
    for my $t (@tags) {
        eval {
            $rester->put_pagetag($page, $t);
        };
        warn "Error: put_pagetag($page, $t): $@" if $@;
    };
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006, 2007 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
