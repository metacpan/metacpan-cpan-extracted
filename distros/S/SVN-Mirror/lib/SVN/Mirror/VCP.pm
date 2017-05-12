package SVN::Mirror::VCP;
@ISA = ('SVN::Mirror');
$VERSION = '0.50';
use strict;
use File::Spec;

BEGIN {
    $ENV{VCPLOGFILE} ||= File::Spec->devnull;
    # This can be removed with the next version of vcp released
    {
	my $ofh = select;
	require VCP;
	select $ofh;
    }

    if ($^O eq 'MSWin32') {
        require Win32API::GUID;
    }
    else {
        require Data::UUID;
    }
}
eval { require VCP::Dest::svk; 1 } or
    do { warn "VCP::Dest::svk not installed\n"; die };
use Getopt::Long qw(:config no_ignore_case);

sub pre_init {
    my ($self, $new) = @_;
    $self->{options} ||= [];
    if ($new) {
	# append the annoying literal /... if there's none.
	$self->{source} =~ s{(?:/?(?:\.\.\.)?)$}{/...};
    }
    else {
	($self->{source}, @{$self->{options}}) =
	    (split (/ /, $self->{source}), @{$self->{options}});
    }

    local @ARGV = @{$self->{options}};
    die unless GetOptions ('source-trunk=s' => \$self->{source_trunk},
			   'source-branches=s' => \$self->{source_branches},
			   'branch-only=s' => \$self->{branch_only});
    my ($scheme) = $self->{source} =~ /^(\w{2,}):/;
    $self->{source_scheme} = $scheme = lc($scheme);
    my $name = "VCP::Source::$scheme";
    my $filename = $name;
    $filename =~ s{::}{/}g ;

    my $v = eval "require '$filename.pm';" ;
    die "$v not supported" unless $v;
    $self->{vcp_source} = $name;
    @{$self}{qw/source_root source_path/} = $self->{source} =~ m/^(.+):([^:]+)$/;
}

sub map_filter_p4 {
    my $self = shift;
    require VCP::Filter::map;
    if ($self->{branch_only} || !$self->{source_trunk}) {
	my $trunk = $self->{source_trunk};
	$self->{branch_only} ||= 'trunk';
	$trunk .= '/(...)' if $trunk;
	return VCP::Filter::map->new
	    ("", [ ($self->{branch_only} eq 'trunk' ?
		    ($trunk || '(...)', '$1<>') :
		    ("$self->{source_branches}$self->{branch_only}/(...)", '$1<>')),
		   '...', '<<delete>>' ]);
    }

    return VCP::Filter::map->new
	("", ["$self->{source_trunk}/(...)", '$1<>',
	      "$self->{source_branches}(*)/(...)", '$2<$1>']);
}

sub map_filter_cvs {
    my $self = shift;
    require VCP::Filter::map;
    if ($self->{branch_only}) {
	my @branches = map {$_ eq 'trunk' ? '' : $_ } split (',', $self->{branch_only});
	return VCP::Filter::map->new
	    ("", [ (map { ("(...)<$_>", "\$1<$_>") } @branches),
		   '...', '<<delete>>' ]);
    }
}

sub map_filter_cvsbk {
    my $self = shift;
    return $self->map_filter_cvs;
}

sub map_filter {
    my ($self, $scheme) = @_;
    my ($func, $filter) = ("map_filter_$scheme");
    $filter = $self->$func if $self->can ($func);
    return $filter ? $filter : ();
}

sub init_state {
    my ($self) = @_;
    use Sys::Hostname;
    my $uuid_src = $self->{source_root};
    $uuid_src .= hostname if $self->{source_scheme} eq 'cvs';
    $self->{source_uuid} = lc($self->make_uuid($uuid_src));
    return join (' ', $self->{source}, @{$self->{options}});
}

sub make_uuid {
    return Win32API::GUID::CreateGuid() if ($^O eq 'MSWin32');
    Data::UUID->new->create_from_name_str(&Data::UUID::NameSpace_DNS, $_[0]);
}

sub load_state {
    my ($self) = @_;
    $self->{source_uuid} = $self->{root}->node_prop ($self->{target_path}, 'svm:uuid');
    $self->load_fromrev;
}

sub run {
    my $self = shift;
    my $dbdir = File::Spec->catdir ($self->{repospath}, 'vcp_state');
    my $source = $self->{vcp_source}->new
	($self->{source}, ['--continue', '--db-dir', $dbdir, '--repo-id', $self->{source_uuid}]);

    my $layout = !$self->{branch_only} || index ($self->{branch_only}, ',') >= 0;
    my $dest = VCP::Dest::svk->new ("svk:$self->{repospath}:$self->{target_path}",
				    ['--db-dir', $dbdir, '--repo-id', 'svk',
				     $layout ? () : '--nolayout']);
    $dest->{SVK_REPOS} = $self->{repos};
    $dest->{SVK_REPOSPATH} = $self->{repospath};
    $dest->{SVK_COMMIT_CALLBACK} = sub {
	my ($rev, $rrev) = @_;
	$self->{fs}->change_rev_prop ($rev, 'svm:headrev', "$self->{source_uuid}:$rrev\n");
    };

    my @plugins = ($source, $self->map_filter ($self->{source_scheme}), $dest);

    $_->init for @plugins;
    my $cp = VCP->new( @plugins );
    $cp->insert_required_sort_filter;

    # XXX: special case that the plugin needs to be inserted after changeset
    if ($self->{source_scheme} eq 'cvsbk') {
	require VCP::Filter::cvsbkchangeset;
	splice @{$cp->{PLUGINS}}, -1, 0, VCP::Filter::cvsbkchangeset->new;
    }
    my $header = {} ;
    my $footer = {} ;
    $cp->copy_all( $header, $footer ) ;
    undef $self->{plugins};
}

sub get_merge_back_editor {
    my ($self, $path, $msg, $committed) = @_;
    die "merge back editor for VCP not implemented yet";
}

use File::Path qw(rmtree);
sub delete {
    my $self = shift;
    rmtree [VCP::Dest::svk::_db_store_location
	    ({SVK_REPOSPATH => $self->{repospath},
	      SVK_TARGETPATH => $self->{target_path},
	     })];
    $self->SUPER::delete (@_);

}

1;
