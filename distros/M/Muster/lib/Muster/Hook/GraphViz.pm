package Muster::Hook::GraphViz;
$Muster::Hook::GraphViz::VERSION = '0.62';
use Mojo::Base 'Muster::Hook::Directives';
use Muster::LeafFile;
use Muster::Hooks;
use Digest::SHA;

use Carp 'croak';

=head1 NAME

Muster::Hook::GraphViz - Muster graph directive using GraphViz.

=head1 VERSION

version 0.62

=head1 DESCRIPTION

L<Muster::Hook::GraphViz> directed graphs with graphviz.
This supports a subset of the IkiWiki plugin's functionality.

=head1 METHODS

L<Muster::Hook::GraphViz> inherits all methods from L<Muster::Hook::Directives>.

=head2 register

Do some intialization.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{metadb} = $hookmaster->{metadb};

    # place to store and serve cached graphs
    $self->{cache_dir} = $conf->{cache_dir};
    $self->{graphs_dir} = File::Spec->catdir($self->{cache_dir}, 'graphs');
    if (!-d $self->{graphs_dir})
    {
        mkdir $self->{graphs_dir};
    }
    $self->{img_url} = $conf->{route_prefix} . 'graphs/';

    my $callback = sub {
        my %args = @_;

        return $self->process(%args);
    };
    $hookmaster->add_hook('graph' => sub {
            my %args = @_;

            return $self->do_directives(
                directive=>'graph',
                call=>$callback,
                %args,
            );
        },
    );
    return $self;
} # register

=head2 process

Process graph formatting.

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};
    my @p = @{$args{params}};
    my %params = @p;
    my $pagename = $leaf->pagename;

    # don't show anything if we aren't building
    if ($phase ne $Muster::Hooks::PHASE_BUILD)
    {
        return "";
    }

    $params{type} = "digraph" unless defined $params{type};
    $params{prog} = "dot" unless defined $params{prog};
    croak "prog '$params{prog}' not a valid graphviz program" unless $params{prog} =~ /^(dot|neato|fdp|twopi|circo)$/o;

    my $src = "charset=\"utf-8\";\n";
    $src .= "ratio=compress;\nsize=\"".($params{width}+0).", ".($params{height}+0)."\";\n"
    if defined $params{width} and defined $params{height};
    $src .= $params{src};
	
    # Use the sha1 of the graphviz code as part of its filename,
    # and as a unique identifier
    my $sha=Digest::SHA::sha1_hex($params{type}.$src);
    $src = "$params{type} graph$sha {\n".$src."}\n";

    my $dest = $pagename;
    $dest =~ s!/!-!g;
    $dest=$dest."-graph-".$sha.".png";

    my $outfile = File::Spec->catfile($self->{graphs_dir}, $dest);
    if (! -e $outfile)
    {
        my $cmd="$params{prog} -Tpng -o '$outfile'";
        my $fh;
        open($fh, "|-", $cmd) or die "ERROR: $cmd : $!";

        print $fh $src;
        close $fh;
    }
    my $imglink = $self->{img_url} . $dest;

    return <<EOT;
<img src="$imglink" alt="$sha"/>
EOT
} # process

1;
