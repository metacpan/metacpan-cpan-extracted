package Muster::Hook::Links;
$Muster::Hook::Links::VERSION = '0.62';
=head1 NAME

Muster::Hook::Links - Muster hook for links

=head1 VERSION

version 0.62

=head1 SYNOPSIS

  # CamelCase plugin name
  package Muster::Hook::Links;
  use Mojo::Base 'Muster::Hook';

=head1 DESCRIPTION

L<Muster::Hook::Links> processes for links.

=cut

use Mojo::Base 'Muster::Hook';
use Muster::LeafFile;
use Muster::Hooks;
use File::Basename;
use File::Spec;
use YAML::Any;

# ---------------------------------------------
# Class Variables

# taken from IkiWiki code
my $Link_Regexp = qr{
		\[\[(?=[^!])            # beginning of link
		(?:
			([^\]\|]+)      # 1: link text
			\|              # followed by '|'
		)?                      # optional
		
		([^\n\r\]#]+)           # 2: page to link to
		(?:
			\#              # '#', beginning of anchor
			([^\s\]]+)      # 3: anchor text
		)?                      # optional
		
		\]\]                    # end of link
	}x;

my $Email_Regexp = qr/^.+@.+\..+$/;
my $Url_Regexp = qr/^(?:[^:]+:\/\/|mailto:).*/i;

=head1 METHODS

=head2 register

Initialize, and register hooks.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    # we need to be able to look things up in the database
    $self->{metadb} = $hookmaster->{metadb};

    $hookmaster->add_hook('links' => sub {
            my %args = @_;

            return $self->process(%args);
        },
    );
    return $self;
} # register

=head2 process

Process (scan or modify) a leaf object.
In scanning phase, it may update the meta-data,
in modify phase, it may update the content.
May leave the leaf untouched.

  my $new_leaf = $self->process(%args);

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};

    if (!$leaf->is_page)
    {
        return $leaf;
    }

    my $content = $leaf->cooked();
    my $page = $leaf->pagename;

    if ($phase eq $Muster::Hooks::PHASE_SCAN)
    {
        my %links = ();

        while ($content =~ /(?<!\\)$Link_Regexp/g)
        {
            my $link = $2;
            my $anchor = $3;
            if (! $self->is_externallink($page, $link, $anchor)) {
                $links{$link}++;
            }
        }
        my @links = sort keys %links;
        if (scalar @links)
        {
            $leaf->{meta}->{links} = \@links;
        }
    }
    else
    {
	$content =~ s{(\\?)$Link_Regexp}{
		defined $2
			? ( $1 
				? "[[$2|$3".(defined $4 ? "#$4" : "")."]]" 
				: $self->is_externallink($page, $3, $4)
					? $self->externallink($3, $4, $2)
					: $self->htmllink($page, $self->linkpage($3),
						anchor => $4, linktext => $2))
			: ( $1 
				? "[[$3".(defined $4 ? "#$4" : "")."]]"
				: $self->is_externallink($page, $3, $4)
					? $self->externallink($3, $4)
					: $self->htmllink($page, $self->linkpage($3),
						anchor => $4))
	}eg;
        $leaf->{cooked} = $content;
    }
    return $leaf;
} # process

=head2 is_externallink

Is this an external link?

=cut
sub is_externallink {
    my $self = shift;
    my $page = shift;
    my $url = shift;
    my $anchor = shift;

    if (defined $anchor) {
        $url.="#".$anchor;
    }

    return ($url =~ /$Url_Regexp|$Email_Regexp/)
}

=head2 linkpage

Convert the link into a page-name.

=cut
sub linkpage {
    my $self = shift;
    my $link=shift;
    #my $chars = defined $config{wiki_file_chars} ? $config{wiki_file_chars} : "-[:alnum:]+/.:_";
    my $chars = "-[:alnum:]+/.:_";
    $link=~s/([^$chars])/$1 eq ' ' ? '_' : "__".ord($1)."__"/eg;
    return $link;
}

=head2 externallink

Process an external link.

=cut
sub externallink {
    my $self = shift;
    my $url = shift;
    my $anchor = shift;
    my $pagetitle = shift;

    if (defined $anchor) {
        $url.="#".$anchor;
    }

    # build pagetitle
    if (! $pagetitle) {
        $pagetitle = $url;
        # use only the email address as title for mailto: urls
        if ($pagetitle =~ /^mailto:.*/) {
            $pagetitle =~ s/^mailto:([^?]+).*/$1/;
        }
    }

    if ($url !~ /$Url_Regexp/) {
        # handle email addresses (without mailto:)
        $url = "mailto:" . $url;
    }

    return "<a href=\"$url\">$pagetitle</a>";
}

=head2 htmllink

Generate the HTML for a link.

=cut
sub htmllink {
    my $self = shift;
    my $page=shift;
    my $link=shift;
    my %opts=@_;

    $link=~s/\/$//;

    my $bestlink;
    if (! $opts{forcesubpage})
    {
        $bestlink=$self->{metadb}->bestlink($page, $link);
    }
    else
    {
        $bestlink="$page/".lc($link);
    }
    # assert: $bestlink contains the page to link to
    my $page_exists = $self->{metadb}->page_exists($bestlink);
    my $bl_info = $page_exists ? $self->{metadb}->page_or_file_info($bestlink) : undef;

    my $linktext;
    if (defined $opts{linktext})
    {
        $linktext=$opts{linktext};
    }
    elsif ($page_exists)
    {
        # use the actual page title
        $linktext=$bl_info->{title};
    }
    else
    {
        $linktext=basename($link);
    }

    return "<span class=\"selflink\">$linktext</span>"
    if length $bestlink && $page eq $bestlink &&
    ! defined $opts{anchor};

    if (!$page_exists or !$bestlink)
    {
        return "<a class=\"createlink\" href=\"$link\">$linktext ?</a>";
    }
    
    $bestlink=File::Spec->abs2rel($bestlink, $page);
    $bestlink=$bl_info->{pagelink};

    if (defined $opts{anchor}) {
        $bestlink.="#".$opts{anchor};
    }

    my @attrs;
    foreach my $attr (qw{rel class title}) {
        if (defined $opts{$attr}) {
            push @attrs, " $attr=\"$opts{$attr}\"";
        }
    }

    return "<a href=\"$bestlink\"@attrs>$linktext</a>";
}

1;
