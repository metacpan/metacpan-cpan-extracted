use strictures 1;
package Mojito::Filter::Shortcuts;
{
  $Mojito::Filter::Shortcuts::VERSION = '0.24';
}
use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);
use Mojito::Model::MetaCPAN;
use 5.010;
use Data::Dumper::Concise;

with('Mojito::Role::Config');

has shortcuts => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    builder => '_build_shortcuts',
);
sub _build_shortcuts {
    my $self = shift;
    my @shortcuts = qw( 
        cpan_URL
        metacpan_module_URL
        metacpan_author_URL
        internal_URL
        gist_URL
        cpan_recent_synopses
        cpan_synopsis);
    push @shortcuts, 'fonality_ticket' if ($self->config->{fonality_ticket_url});
    return \@shortcuts;
}

=head1 Methods

=head2 expand_shortcuts

Expand the available shortcuts into the content.

=cut

sub expand_shortcuts {
    my ($self, $content) = @_;
    foreach my $shortcut ( @{$self->shortcuts} ) {
        $content = $self->${shortcut}(${content});
    }
    return $content;
}

=head2 cpan_URL

Expand the cpan abbreviated shortcut.

=cut

sub cpan_URL {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s/\{\{cpan\s+([^}]*)}}/<a href="http:\/\/search.cpan.org\/perldoc?$1">$1<\/a>/sig;
    return $content;
}

=head2 gist_URL

Expand the gist.github.com abbreviated shortcut.

=cut

sub gist_URL {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s/\{\{gist\s+([^}]*)}}/<script src="https:\/\/gist.github.com\/$1.js"><\/script>/sig;
    return $content;
}

has metacpan => (
    is => 'ro',
    lazy => 1,
    default => sub { Mojito::Model::MetaCPAN->new },
);

=head2 cpan_synopsis

Show the CPAN SYNOPSIS for a Perl Module

=cut

sub cpan_synopsis {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s/\{\{cpan.synopsis\s+([^}]*)}}/$self->metacpan->get_synopsis_formatted($1, 'presentation')/esig;
    return $content;
}

=head2 cpan_recent_synopses

Show the synopses of the CPAN recent releases

=cut

sub cpan_recent_synopses {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s/\{\{cpan.synopses.recent\s*(\d+)}}/$self->metacpan->get_recent_synopses($1)/esig;
    return $content;
}
=head2 metacpan_module_URL

Expand the cpan abbreviated shortcut.

=cut

sub metacpan_module_URL {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s|\{\{metacpan\s+([^}]*)}}|<a href="http://metacpan.org/module/$1">$1</a>|sig;
    return $content;
}
=head2 metacpan_module_URL

Expand the cpan abbreviated shortcut.

=cut

sub metacpan_author_URL {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s|\{\{metacpan.author\s+([^}]*)}}|<a href="http://metacpan.org/author/$1">$1</a>|sig;
    return $content;
}


=head2 internal_URL

Expand an internal URL

=cut

sub internal_URL {
    my ($self, $content) = @_;
    return if !$content;
    my ($base_url, $path_info, $http_referer, $http_host) = @{$self->config}{qw/base_url PATH_INFO HTTP_REFERER HTTP_HOST/};
    my $add_link = sub {
        my ($link, $title) = @_;
        # Strip ending slash as we only append the base_url to link starting with a slash
        $base_url =~ s|/$||;
        if ($link !~ m|^/|) {
            # If we have a path_info of /preview then we want to use the
            # referred instead as the path_info.
            if ($path_info eq '/preview') {
                # create path info from where the post came
                ($path_info) = $http_referer =~ m|${http_host}${base_url}(.*)/edit$|;
            } 
            $path_info = ($path_info =~ m|/$|) ? $path_info : $path_info . '/'; 
            $base_url .= $path_info;
        }
        return "<a href='${base_url}${link}'>${title}</a>";
    };
    $content =~ s/\[\[([^\|]*)\|([^\]]*)\]\]/$add_link->($1,$2)/esig;
    return $content;
}

1