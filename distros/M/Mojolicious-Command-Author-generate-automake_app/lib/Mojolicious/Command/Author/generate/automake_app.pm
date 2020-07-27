package Mojolicious::Command::Author::generate::automake_app;
use Mojo::Base 'Mojolicious::Command';
use File::Basename qw(basename dirname);
use Mojo::Util qw(class_to_file class_to_path);
use Mojo::File;

use POSIX qw(strftime);
use Cwd 'getcwd';
use File::Spec::Functions qw(catdir catfile);
our $VERSION = '0.7.0';
has description => 'Generate Mojolicious web application with Automake';
has usage => sub { shift->extract_usage };

has cwd => sub {
    getcwd();
};

has package => 'automake';

has defaultName => 'MyMojoliciousApp';

has class => sub {
    die "class must be initialized in run."
};

has class_file => sub {
    class_to_file shift->class;
};

has class_path => sub {
    class_to_path shift->class;
};

has filename => sub {
    my $filename = shift->class_file;
    $filename =~ s/_/-/g;
    return $filename;
};

sub rel_dir  {
    my $self=shift;
    catdir $self->cwd,  split('/', pop)
}

sub rel_file {
    my $self =shift;
    catfile $self->cwd, split('/', pop);
}

sub file {
    my $self = shift;
   
    # Configure Main Dir
    return {
        'configure.ac' => 'configure.ac',
        'bootstrap' => 'bootstrap',
        'cpanfile' => 'cpanfile',
        'VERSION' => 'VERSION',
        'README.md' => 'README.md',
        'AUTHORS' => 'AUTHORS',
        '.gitignore' => '.gitignore',
        '.github/workflows/unit-tests.yaml' => '.github/workflows/unit-tests.yaml',
        'LICENSE' => 'LICENSE',
        'COPYRIGHT' => 'COPYRIGHT',
        'CHANGES' => 'CHANGES',
        'Makefile.am' => 'Makefile.am',
        'bin/Makefile.am' => 'bin/Makefile.am',
        'thirdparty/Makefile.am' => 'thirdparty/Makefile.am',
        'etc/Makefile.am' => 'etc/Makefile.am',
        'etc/app.cfg' => 'etc/'.$self->filename.'.cfg',
        'bin/app.pl' => 'bin/'.$self->filename.'.pl',
        'lib/App.pm' => 'lib/'.$self->class_path,
        'lib/Makefile.am' => 'lib/Makefile.am',
        'lib/App/Controller/Example.pm' 
            => 'lib/'.$self->class.'/Controller/Example.pm',
        'public/index.html' 
            => 'public/index.html',
        'templates/layouts/default.html.ep' 
            => 'templates/layouts/default.html.ep',
        'templates/example/welcome.html.ep'
            => 'templates/example/welcome.html.ep',
        't/basic.t' => 't/basic.t',
    };
}

sub finalize {
    my $self = shift;
    my $name = $self->filename;
    $self->chmod_rel_file("$name/bootstrap", 0755);
    $self->chmod_rel_file("$name/bin/".$name.".pl", 0755);
    $self->create_rel_dir("$name/public");
    $self->create_rel_dir("$name/templates");
    chdir $self->cwd.'/'.$name;
    system "./bootstrap";

}
sub run {
    my ($self, $app) = @_;
    $app ||= $self->defaultName;
    my @dir = split /\//, $app;
    $self->class(pop @dir);

    die <<EOF unless $self->class =~ /^[A-Z](?:\w|::)+$/;
Your application name has to be a well formed (CamelCase) Perl module name
like "MyApp".
EOF
    $self->cwd(join '/', @dir) if @dir;

    my $file = $self->file;

    my ($userName,$fullName) = (getpwuid $<)[0,6];
    $fullName =~ s/,.+//g;
    chomp(my $domain = `hostname -d`);
    my $email = $userName.'@'.$domain;

    if ( -r $ENV{HOME} . '/.gitconfig' ){
        my $in = Mojo::File->new($ENV{HOME} . '/.gitconfig')->slurp;
        $in =~ /name\s*=\s*(\S.+\S)/ and $fullName = $1;
        $in =~ /email\s*=\s*(\S+)/ and $email = $1;
    }

    for my $key (keys %$file){
        $self->render_to_rel_file($key, $self->filename.'/'.$file->{$key}, {
            class => $self->class,
            'package' => $self->package,
            filename => $self->filename,
            class_file => $self->class_file,
            class_path => $self->class_path,
            year => (localtime time)[5]+1900,
            email => $email,
            fullName => $fullName,
            userName => $userName,
            date => strftime('%Y-%m-%d',localtime(time)),
        });
    }

    $self->finalize;

    say "** Generated App ".$self->class." in ".$self->cwd.'/'.$self->filename;

}

has search_path => sub {
    my $self = shift;
    my $src = $INC{class_to_path __PACKAGE__};
    return [ dirname($src).'/'.basename($src,'.pm').'/' ];
};

sub render_data {
    my ($self, $name, $vars) = @_;
    for my $path (@{$self->search_path}) {
        next unless -f $path.$name;
        my $data = Mojo::Template
        ->new(vars => 1)
        ->name("template $name")
        ->render(
            Mojo::File->new($path.$name)->slurp, $vars);
        if (ref $data and $data->isa('Mojo::Exception')) {
            warn "  [ERROR] $path$name did not render properly!\n";
        }
        return $data;
    }
    warn " [ERROR] $name not found\n";
    return "";
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::Author::generate::automake_app - Mojolicious App generator command

=head1 SYNOPSIS

  Usage: mojo generate automake_app [OPTIONS] [NAME]

    mojo generate automake_app
    mojo generate automake_app [/full/path/]TestApp

  Options:
    -h, --help   Show this summary of available options

=head1 DESCRIPTION

L<Mojolicious::Command::Authos::generate::automake_app> generates application directory structures for fully functional L<Mojolicious> applications.

=head1 SEE ALSO

L<Mojolicious>, L<https://www.gnu.org/software/automake/>.

=cut
