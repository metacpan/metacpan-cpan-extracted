package Mojolicious::Plugin::DirectoryHandler;
use Mojo::Base qw{Mojolicious::Plugin};
use Cwd ();
use Encode ();
use DirHandle;
use Mojolicious::Types;
use Mojo::JSON qw(encode_json);
use Mojo::Darkpan::Config;

my $dir_page = <<'PAGE';
<html>
<head>
    <title>Index of <%= $cur_path %></title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <style>

        table { width:100%; }

        td, th{ padding: 0 5px 0 5px }

        .name { text-align:left; }

        .size, .mtime { text-align:right; }

        .type { width:11em;text-align:left; }

        .mtime { width:15em; }

    </style>
</head>
<body>
<h1>Index of <%= $cur_path %></h1>
<hr />
<table>
    <tr>
        <th class='name'>Name</th>
        <th class='size'>Size</th>
        <th class='type'>Type</th>
        <th class='mtime'>Last Modified</th>
    </tr>
    % for my $file (@$files) {
    <tr>
        <td class='name'><a href='<%= $file->{url} %>'><%== $file->{name} %></a></td>
        <td class='size'><%= $file->{size} %></td>
        <td class='type'><%= $file->{type} %></td>
        <td class='mtime'><%= $file->{mtime} %></td></tr>
    % }
</table>
<hr />
</body></html>
PAGE

my $types = Mojolicious::Types->new;

sub register {
    my $self = shift;
    my ($app, $args) = @_;

    my $root = Mojo::Home->new($args->{root} || Mojo::Darkpan::Config->new->directory);
    my $handler = $args->{handler};
    my $auto_index = $args->{auto_index} // 1;
    my $json = $args->{json};
    my $delivery_path = $args->{delivery_path} || $root;
    $dir_page = $args->{dir_page} if ($args->{dir_page});

    $app->hook(
        before_dispatch => sub {
            my $c = shift;
            my $req_path = $c->req->url->path;

            return render_file($c, $root, $handler) if (-f $root->to_string());


            if ($req_path =~ m/^\/$delivery_path/) {
                my $root_string = $root->to_string();
                $req_path =~ s/\/$delivery_path//;

                my $path;
                if ($req_path ne $root_string) {
                    $path = $root->rel_file(Mojo::Util::url_unescape($req_path));
                }

                if (-d $path) {
                    render_indexes($c, $path, $json) unless not $auto_index;
                    return;
                }
                if (-f $path) {
                    render_file($c, $path, $handler);
                    return;
                }
                $c->reply->not_found;
                return;
            }
        },
    );
    return $app;
}

sub render_file {
    my $c = shift;
    my $path = shift;
    my $handler = shift;
    $handler->($c, $path) if (ref $handler eq 'CODE');
    return if ($c->tx->res->code);
    my $data = Mojo::File::slurp($path);
    $c->render(data => $data, format => get_ext($path) || 'txt');
}

sub render_indexes {
    my $c = shift;
    my $dir = shift;
    my $json = shift;

    my @files = ($c->req->url->path eq '/') ? ()
        : ({ url => '../', name => 'Parent Directory', size => '', type => '', mtime => '' });
    my $children = list_files($dir);

    my $cur_path = Encode::decode_utf8(Mojo::Util::url_unescape($c->req->url->path));
    for my $basename (sort {$a cmp $b} @$children) {
        my $file = "$dir/$basename";
        my $url = Mojo::Path->new($cur_path)->trailing_slash(0);
        push @{$url->parts}, $basename;

        my $is_dir = -d $file;
        my @stat = stat _;
        if ($is_dir) {
            $basename .= '/';
            $url->trailing_slash(1);
        }

        my $mime_type = $is_dir ? 'directory'
            : ($types->type(get_ext($file) || 'txt') || 'text/plain');
        my $mtime = Mojo::Date->new($stat[9])->to_string();

        push @files, {
            url   => $url,
            name  => $basename,
            size  => $stat[7] || 0,
            type  => $mime_type,
            mtime => $mtime,
        };
    }

    my $any = { inline => $dir_page, files => \@files, cur_path => $cur_path };
    if ($json) {
        $c->respond_to(
            json => { json => encode_json(\@files) },
            any  => $any,
        );
    }
    else {
        $c->render(%$any);
    }
}

sub get_ext {
    $_[0] =~ /\.([0-9a-zA-Z]+)$/ || return;
    return lc $1;
}

sub list_files {
    my $dir = shift || return [];
    my $dh = DirHandle->new($dir);
    my @children;
    while (defined(my $ent = $dh->read)) {
        next if $ent eq '.' or $ent eq '..';
        push @children, Encode::decode_utf8($ent);
    }
    return [ @children ];
}

1;

__END__