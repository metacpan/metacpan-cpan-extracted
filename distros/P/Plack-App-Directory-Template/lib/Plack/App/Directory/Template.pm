use strict;
use warnings;
package Plack::App::Directory::Template;
#ABSTRACT: Serve static files from document root with directory index template
our $VERSION = '0.27'; #VERSION
use v5.10;

use parent qw(Plack::App::Directory);

use Plack::Middleware::TemplateToolkit;
use Plack::Util::Accessor qw(filter templates);

use File::ShareDir qw(dist_dir);
use File::stat;
use DirHandle;
use Cwd qw(abs_path);
use URI::Escape;

sub prepare_app {
    my $self = shift;

    $self->{_default_vars} = delete $self->{VARIABLES} // { };
    $self->{templates} = delete $self->{INCLUDE_PATH} if $self->{INCLUDE_PATH};
}

sub serve_path {
    my($self, $env, $dir, $fullpath) = @_;

    if (-f $dir) {
        return $self->SUPER::serve_path($env, $dir, $fullpath);
    }

    if (defined $self->{dir_index}) {
        my $index_file = "$dir/".$self->{dir_index};
        if (-f $index_file) {
            return $self->SUPER::serve_path($env, $index_file, $fullpath);
        }
    }

    my $urlpath = $env->{SCRIPT_NAME} . $env->{PATH_INFO};

    if ($urlpath !~ m{/$}) {
        return $self->return_dir_redirect($env);
    }

    $urlpath = join('/', map {uri_escape($_)} split m{/}, $urlpath).'/';

    my $dh = DirHandle->new($dir);
    my @children;
    while (defined(my $ent = $dh->read)) {
        next if $ent eq '.' or $ent eq '..';
        push @children, $ent;
    }

    my $files = [ ];
    my @special = ('.');
    push @special, '..' if $env->{PATH_INFO} ne '/';

    foreach ( @special, sort { $a cmp $b } @children ) {
        my $name = $_;
        my $file = "$dir/$_";
        my $stat = stat($file);
        my $url  = $urlpath . uri_escape($_);

        my $is_dir = -d $file; # TODO: use Fcntl instead ?

        push @$files, bless {
            name        => $is_dir ? "$name/" : $name,
            url         => $is_dir ? "$url/" : $url,
            mime_type   => $is_dir ? 'directory' : ( Plack::MIME->mime_type($file) || 'text/plain' ),
            stat        => $stat,
        }, 'Plack::App::Directory::Template::File';
    }

    $files = [ map { $self->filter->($_) || () } @$files ] if $self->filter;

    my $default_vars = {
        %{ $self->{_default_vars} },
        path    => $env->{PATH_INFO},
        urlpath => $urlpath,
        root    => abs_path($self->root),
        dir     => abs_path($dir),
    };

    my $tt_vars = $self->template_vars( %$default_vars, files => $files );
    if ($env->{'tt.vars'}) {
        $env->{'tt.vars'}->{$_} = $tt_vars->{$_} for keys %$tt_vars; 
    } else {
        $env->{'tt.vars'} = $tt_vars;
    }

    $env->{'tt.template'} = ref $self->templates ? $self->templates 
                          : ($self->{PROCESS} // 'index.html');

    $self->{tt} //= Plack::Middleware::TemplateToolkit->new(
        INCLUDE_PATH => $self->templates
                        // eval { dist_dir('Plack-App-Directory-Template') }
                        // 'share',
        VARIABLES    => $default_vars,
        request_vars => [qw(scheme base parameters path user)],
        map { $_ => $self->{$_} } grep { $_ =~ /^[A-Z_]+$/ } keys %$self
    )->to_app;

    return $self->{tt}->($env);
}

sub template_vars {
    my ($self, %args) = @_;
    return { files => $args{files} };
}

package Plack::App::Directory::Template::File;

our $AUTOLOAD;
sub can { $_[0]->{$_[1]}; }

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*://;
    $self->{$attr};
}

sub permission {
    ## no critic
    $_[0]->{stat} ? ($_[0]->{stat}->mode & 07777) : undef;
}

sub mode_string { # not tested or documented
    return '          ' unless $_[0]->{stat};
    my $mode = $_[0]->{stat}->mode;

    # Code copied from File::Stat::Ls by Geo Tiger
    # See also File::Stat::Bits, File::Stat::Ls, Stat::lsMode, File::Stat::ModeString

    my @perms = qw(--- --x -w- -wx r-- r-x rw- rwx);
    my @ftype = qw(. p c ? d ? b ? - ? l ? s ? ? ?);
    $ftype[0] = '';
## no critic
    my $setids = ($mode & 07000)>>9; 
## no critic
    my @permstrs = @perms[($mode&0700)>>6, ($mode&0070)>>3, $mode&0007];
## no critic
    my $ftype = $ftype[($mode & 0170000)>>12];
   
    if ($setids) {
      if ($setids & 01) {         # Sticky bit
        $permstrs[2] =~ s/([-x])$/$1 eq 'x' ? 't' : 'T'/e;
      }
      if ($setids & 04) {         # Setuid bit
        $permstrs[0] =~ s/([-x])$/$1 eq 'x' ? 's' : 'S'/e;
      }
      if ($setids & 02) {         # Setgid bit
        $permstrs[1] =~ s/([-x])$/$1 eq 'x' ? 's' : 'S'/e;
      }
    }

    join '', $ftype, @permstrs;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::Directory::Template - Serve static files from document root with directory index template

=head1 VERSION

version 0.27

=head1 SYNOPSIS

    use Plack::App::Directory::Template;

    my $template = "/path/to/templates"; # or \$template_string

    my $app = Plack::App::Directory::Template->new(
        root      => "/path/to/htdocs",
        templates => $template, # optional
        filter    => sub {
             # hide hidden files
             $_[0]->name =~ qr{^[^.]|^\.+/$} ? $_[0] : undef;
        }
    )->to_app;

=head1 DESCRIPTION

Plack::App::Directory::Template extends L<Plack::App::Directory> by support of
HTML templates (with L<Template::Toolkit>) for better customization of
directory index pages. 

=head1 CONFIGURATION

=over 4

=item root

Document root directory. Defaults to the current directory.

=item templates

Either a template directory that includes the template file C<index.html> or a
template given as string reference.

=item filter

A code reference that is called for each file before files are passed as
template variables  One can use such filter to omit selected files and to
modify and extend file objects. Note that omitted files are not shown in the
directory index but they can still be retrieved.

=item dir_index

Serve an index file (e.g. "index.html") instead of directory listing if the
index file exists.

=item L<Template> configuration

Template Toolkit configuration options (C<PRE_PROCESS>, C<POST_CHOMP>,
C<PROCESS> etc.) are supported as well.

=back

=head1 TEMPLATE VARIABLES

The following variables are passed to the directory index template. Have a look
at the default template, shipped as file C<share/index.html> with this module,
for usage example.

=over 4

=item files

List of files, each given as hash reference with the following properties. All
directory names end with a slash (C</>). The special directory C<./> is
included and C<../> as well, unless the root directory is listed.

=over 4

=item file.name

Local file name without directory.

=item file.url

URL path of the file.

=item file.mime_type

MIME type of the file.

=item file.stat

File status info as given by L<File::Stat> (dev, ino, mode, nlink, uid, gid,
rdev, size, atime, mtime, ctime, blksize, and block).

=item file.permission

File permissions (given by C<< file.stat.mode & 0777 >>). For instance one can
print this in a template with C<< [% file.permission | format("%04o") %] >>.

=back

=item root

The document root directory as configured (given as absolute path).

=item dir

The directory that is listed (given as absolute path).

=item path

The request path (C<request.path>).

=item request

Information about the HTTP request as given by L<Plack::Request>. Includes the
properties C<parameters>, C<base>, C<scheme>, C<path>, and C<user>.

=back

The following example should clarify the meaning of several template variables.
Given a L<Plack::App::Directory::Template> to list directory C</var/files>,
mounted at URL path C</mnt/>:

    builder {
        mount '/mnt/'
            => Plack::App::Directory::Template->new( root => '/var/files' );
        ...
    }

The request C<http://example.com/mnt/sub/> to subdirectory would result in the
following template variables (given a file named C<#foo.txt> in this directory):

    [% root %]       /var/files
    [% dir %]        /var/files/sub
    [% path %]       /sub/
    [% urlpath %]    /mnt/sub/

    [% file.name %]  #foo.txt
    [% file.url %]   /mnt/sub/%23foo.txt

Try also L<Plack::Middleware::Debug::TemplateToolkit> to inspect template
variables for debugging.

=head1 METHODS

=head2 template_vars( %vars )

This method is internally used to construct a hash reference with template
variables. The constructed hash must contain at least the C<files> array.  The
method can be used as hook in subclasses to modify and extend template
variables.

=head1 SEE ALSO

L<Plack::App::Directory>, L<Plack::Middleware::TemplateToolkit>

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
