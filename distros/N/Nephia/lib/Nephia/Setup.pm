package Nephia::Setup;
use strict;
use warnings;
use Archive::Extract;
use Carp;
use Data::Section::Simple;
use File::Basename 'fileparse';
use File::Fetch;
use File::Spec;
use File::Temp 'tempdir';
use Module::Load ();
use Nephia::Chain;
use Nephia::Context;
use Nephia::MetaTemplate;
use URI;

our $NEXT;

sub new {
    my ($class, %opts) = @_;
    $opts{nest}           = 0;
    $opts{approot}      ||= $class->_resolve_approot($opts{appname});
    $opts{classfile}    ||= $class->_resolve_classfile($opts{appname});
    $opts{action_chain}   = Nephia::Chain->new(namespace => 'Nephia::Setup::Action');
    $opts{plugins}      ||= [];
    $opts{deps}         ||= $class->_build_deps;
    $opts{meta_tmpl}      = Nephia::MetaTemplate->new($opts{meta_tmpl} ? %{$opts{meta_tmpl}} : ());
    my $self = bless {%opts}, $class;
    $self->_load_plugins;
    return $self
}

sub _resolve_approot {
    my ($class, $appname) = @_;
    return ['.', $class->_normalize_appname($appname)];
}

sub _normalize_appname {
    my ($class, $appname) = @_;
    my $rtn = $appname;
    $rtn =~ s|\:\:|\-|g;
    return $rtn;
}

sub _resolve_classfile {
    my ($class, $appname) = @_;
    return ['lib', split('::', $appname.'.pm')];
}

sub _build_deps {
    {
        requires => ['Nephia' => 0],
        test => {
            requires => ['Test::More' => 0],
        },
    };
}

sub _deparse_deps {
    my $nest_level = shift;
    my $nest = $nest_level > 0 ? join('', map{' '} 1 .. $nest_level*4) : '';
    my %val = @_;
    my $data = "";
    for my $key (keys %val) {
        my $v = $val{$key};
        if (ref($v) eq 'ARRAY') {
            my @mods = @$v;
            while (@mods) {
                my $name    = shift(@mods);
                my $version = shift(@mods);
                $data .= "$nest$key '$name' => $version;\n";
            }
        }
        elsif (ref($v) eq 'HASH') {
            $data .= "on '$key' => sub {\n";
            $data .= &_deparse_deps($nest_level + 1, %$v);
            $data .= "};\n";
        }
    }
    return $data;
}

sub appname {
    my $self = shift;
    return $self->{appname};
}

sub approot {
    my $self = shift;
    return ref($self->{approot}) eq 'ARRAY' ? @{$self->{approot}} : ( $self->{approot} );
}

sub classfile {
    my $self = shift;
    return @{$self->{classfile}};
}

sub action_chain {
    my $self = shift;
    return wantarray ? $self->{action_chain}->as_array : $self->{action_chain};
}

sub deps {
    my $self = shift;
    return $self->{deps};
}

sub meta_tmpl {
    my $self = shift;
    return $self->{meta_tmpl};
}

sub makepath {
    my ($self, @in_path) = @_;
    my $path = File::Spec->catdir($self->approot, @in_path);
    my $level = 0;
    while ( ! -d $path ) {
        my $_path = File::Spec->catdir($self->approot, @in_path[0..$level]);
        unless (-d $_path) {
            $self->diag("Create directory %s", $_path);
            mkdir $_path or $self->stop("could not create path %s - %s", $path, $!);
        }
        $level++;
    }
}

sub spew {
    my $self     = shift;
    my $data     = pop;
    my $filename = pop;
    my @in_path  = @_;
    my $path     = File::Spec->catfile($self->approot, @in_path, $filename);
    $self->makepath( @in_path );
    if (-e $path) {
        return;
    }
    $self->diag('Create file %s', $path);
    open my $fh, '>', $path or $self->stop("could not open file %s - %s", $path, $!);
    print $fh $data;
    close $fh;
}

sub process_template {
    my ($self, $data) = @_;
    local $NEXT = '\{\{$NEXT\}\}'; ### for minilla friendly
    while (my ($code) = $data =~ /\{\{(.*?)\}\}/) {
        my $replace = eval "$code";
        $self->stop($@) if $@;
        $data =~ s/\{\{(.*?)\}\}/$replace/x;
    }
    $data =~ s/\\\{/{/g;
    $data =~ s/\\\}/}/g;
    $data =~ s/\:\:\:/=/g;
    return $data;
}

sub do_task {
    my $self = shift;
    $self->diag("\033[44m\033[1;36mBegin to setup %s\033[0m", $self->appname);
    my $context = Nephia::Context->new(
        data_section => sub { Data::Section::Simple->new($_[0]) },
    );
    $self->{nest}++;
    for my $action ( $self->action_chain ) {
        my $name = ref($action);
        $self->diag("\033[1;34m[Action]\033[0m \033[0;35m%s\033[0m - provided by \033[0;32m%s\033[0m", $name, $self->action_chain->from($name));
        $self->{nest}++;
        $context = $action->($self, $context);
        $self->{nest}--;
        $self->diag("Done.");
    }
    $self->{nest}--;
    $self->diag("\033[44m\033[1;36mSetup finished.\033[0m");
}

sub diag {
    my ($self, $str, @params) = @_;
    my $spaces = $self->_spaces_for_nest;
    printf STDERR $spaces.$str."\n", @params;
}

sub stop {
    my ($self, $str, @params) = @_;
    my $spaces = $self->_spaces_for_nest;
    croak( sprintf($spaces."\033[41m\033[1;33m[! SETUP STOPPED !]\033[0m \033[1;31m".$str."\033[0m", @params) );
}

sub _spaces_for_nest {
    my $self = shift;
    my $spaces = '';
    if ($self->{nest}) {
        $spaces .= ' ' for 1 .. $self->{nest} * 2;
    }
    return $spaces;
}

sub _load_plugins {
    my $self = shift;
    for my $plugin_name ( @{$self->{plugins}} ) {
        $self->_load_plugin($plugin_name);
    }
}

sub _load_plugin {
    my ($self, $plugin_name) = @_;
    my $plugin_class = $self->_plugin_name_normalize($plugin_name);
    Module::Load::load($plugin_class) unless $plugin_class->can('new');
    my $plugin = $plugin_class->new(setup => $self);
    $plugin->fix_setup;
    for my $bundle ($plugin->bundle) {
        $self->diag("\033[1;36m[bundle]\033[0m \033[0;35m%s\033[0m for \033[0;32m%s\033[0m", $self->_plugin_name_normalize($bundle), $plugin_class);
        $self->_load_plugin($bundle);
    }
    return $plugin;
}

sub _plugin_name_normalize {
    my ($self, $plugin_name) = @_;
    my $plugin_class = $plugin_name =~ /^Nephia::Setup::Plugin::/ ? $plugin_name : 'Nephia::Setup::Plugin::'.$plugin_name;
    return $plugin_class;
}

sub cpanfile {
    my $self = shift;
    &_deparse_deps(0, %{$self->deps});
}

sub assets {
    my ($self, $url, @in_path) = @_;
    my $path = File::Spec->catfile($self->approot, @in_path);
    unless ( -e $path ) {
        $self->diag('Fetching content from url %s', $url);
        my $fetcher = File::Fetch->new( uri => $url );
        my $content ;
        $fetcher->fetch(to => \$content) or $self->stop('Could not fetch url %s : %s', $url, $!);
        $self->spew(@in_path, $content);
    }
}

sub extract_archive {
    my ($self, $archive_file, @extract_to) = @_;
    my $path = File::Spec->catdir($self->approot, @extract_to);

    $self->makepath(@extract_to);

    $self->diag('Extract Archive %s into %s', $archive_file, $path);
    my $archive = Archive::Extract->new(archive => $archive_file);
    $archive->extract(to => $path);

    $self->diag('Cleanup Archive %s', $archive_file);
    unlink $archive_file;
}

sub assets_archive {
    my ($self, $url, @in_path) = @_;
    my $path = File::Spec->catdir($self->approot, @in_path);
    unless ( -d $path ) {
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;

        my ($filename) = fileparse( URI->new($url)->path );
        $self->assets( $url, $filename );
        my $archive_file = File::Spec->catfile($self->approot, $filename);

        $self->extract_archive( $archive_file, @in_path );
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Nephia::Setup - Base class of setup tool

=head1 DESCRIPTION

This class is used in setup tool internally.

=head1 SYNOPSIS

    my $setup = Nephia::Setup->new(
        appname => 'YourApp::Web',
        plugins => ['Normal'],
    );
    $setup->do_task;

=head1 ATTRIBUTES

=head2 appname

Application name. This attribute is required when instantiate.

=head2 approot

Application root directory. Default is "./Appname".

=head2 plugins

Plugins for using when setup. Default is [] .

=head2 deps

Dependencies for application as hashref. Default is following.

    {
        requires => ['Nephia' => 0],
        test => {
            requires => ['Test::More' => 0],
        },
    };

=head1 METHODS

=head2 appname

Returns application name.

=head2 approot

Returns application root as array.

=head2 deps

Returns dependencies as hashref.

=head2 classfile

Returns path for classfile as array.

Example.

    my $setup = Nephia::Setup->new(appname => 'MyApp::Web');
    my @path = $setup->classfile; # ( 'lib', 'MyApp', 'Web.pm' );

=head2 action_chain

Returns action chain as L<Nephia::Chain> object.

=head2 meta_tmpl

Returns L<Nephia::MetaTemplate> object.

=head2 makepath

Create specified directory recursively.

Example.

    my $setup = Nephia::Setup->new(
        appname => 'MyApp::Web'
    );
    $setup->makepath('misc', 'data', 'xml'); # create ./MyApp-Web/misc/data/xml

=head2 spew

Create specified file with specified content.

Example.

    my $xmldata = ...; # read some xml data...
    $setup->spew('misc', 'data', 'xml', 'foo.xml', $xmldata); # create ./MyApp-Web/misc/data/xml/foo.xml

=head2 process_template

Process file-template.

Example.

    my $setup     = Nephia::Setup->new(appname => 'MyApp::Web');
    my $str       = 'Application name is "{{$self->appname}}"';
    my $processed = $setup->process_template($str); # 'Application name is "MyApp::Web"'

=head2 do_task

Run actions in action chain.

=head2 diag 

Output some message to STDERR.

=head2 stop

Output some message to STDERR and exit setup.

=head2 cpanfile

Output cpanfile script.

Example.

    my $cpanfile_data = $setup->cpanfile;

=head2 assets

Download a file from url and save to specified file.

Example.

    # download somefile-0.1.2.js as ./MyApp-Web/static/js/somefile.js
    $setup->assets(
        'http://example.com/files/somefile-0.1.2.js', 
        qw/static js somefile.js/
    ); 

=head2 assets_archive

Download an archive-file from url and extract into specified path.

Example.

    # download somearch-0.1.2.tar.gz and extract into ./MyApp-Web/static/foo/
    $setup->assets_archive(
        'ftp://example.com/files/somearch-0.1.2.tar.gz',
        qw/static foo/
    );

=head2 extract_archive

Extract an archive-file into specified path.

Example.

    # extract ./somearch-0.1.2.tar.gz into ./MyApp-Web/static/foo/
    $setup->extract_archive(
        './somearch-0.1.2.tar.gz',
        qw/static foo/
    );

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

