package Mojolicious::Command::generate::qx_mojo_app;
use Mojo::Base 'Mojolicious::Command';
use File::Basename;
use Mojo::Util qw(class_to_file class_to_path slurp);
use POSIX qw(strftime);

our $VERSION = '0.2.2';

has description => 'Generate Qooxdoo Mojolicious web application directory structure.';
has usage => sub { shift->extract_usage };

sub run {
    my ($self, $class) = @_;
    $class ||= 'MyMojoQxApp';

    # Prevent bad applications
    die <<EOF unless $class =~ /^[A-Z](?:\w|::)+$/;
Your application name has to be a well formed (CamelCase) Perl module name
like "MyApp".
EOF

    my $name = class_to_file $class;
    my $class_path = class_to_path $class;
    my $controller = "${class}::Controller::RpcService";
    my $controller_path = class_to_path $controller;

    # Configure Main Dir
    my $file = {
        'configure.ac' => 'configure.ac',
        'bootstrap' => 'bootstrap',
        'PERL_MODULES' => 'PERL_MODULES',
        'VERSION' => 'VERSION',
        'README' => 'README',
        'AUTHORS' => 'AUTHORS',
        'LICENSE' => 'LICENSE',
        'COPYRIGHT' => 'COPYRIGHT',
        'CHANGES' => 'CHANGES',
        'Makefile.am' => 'Makefile.am',
        'backend/Makefile.am' => 'backend/Makefile.am',
        'backend/bin/script.pl' => 'backend/bin/'.$name.'.pl',
        'backend/bin/source-mode.sh' => 'backend/bin/'.$name.'-source-mode.sh',
        'backend/lib/App.pm' => 'backend/lib/'.$class_path,
        'backend/lib/App/Controller/RpcService.pm' => 'backend/lib/'.$controller_path,
        'frontend/Makefile.am' => 'frontend/Makefile.am',
        'frontend/Manifest.json' => 'frontend/Manifest.json',
        'frontend/config.json' => 'frontend/config.json',
        'frontend/source/class/app/Application.js' => 'frontend/source/class/'.$name.'/Application.js',
        'frontend/source/index.html' => 'frontend/source/index.html',
        'frontend/source/class/app/data/RpcService.js'  => 'frontend/source/class/'.$name.'/data/RpcService.js',
        't/basic.t' => 't/basic.t',
    };

    my ($userName,$fullName) = (getpwuid $<)[0,6];
    $fullName =~ s/,.+//g;
    chomp(my $domain = `hostname -d`);
    my $email = $userName.'@'.$domain;

    if ( -r $ENV{HOME} . '/.gitconfig' ){
        my $in = slurp $ENV{HOME} . '/.gitconfig';
        $in =~ /name\s*=\s*(\S.+\S)/ and $fullName = $1;
        $in =~ /email\s*=\s*(\S+)/ and $email = $1;
    }

    for my $key (keys %$file){
        $self->render_to_rel_file($key, $name.'/'.$file->{$key}, {
            class => $class,
            name => $name,
            class_path => $class_path,
            controller => $controller,
            controller_path => $controller_path,
            year => (localtime time)[5]+1900,
            email => $email,
            fullName => $fullName,
            userName => $userName,
            date => strftime('%Y-%M-%D',localtime(time)),
        });
    }

    $self->chmod_rel_file("$name/bootstrap", 0755);
    $self->chmod_rel_file("$name/backend/bin/".$name.".pl", 0755);
    $self->chmod_rel_file("$name/backend/bin/".$name."-source-mode.sh", 0755);

    $self->create_rel_dir("$name/backend/log");
    $self->create_rel_dir("$name/backend/public");
    $self->create_rel_dir("$name/frontend/source/resource/$name");
    $self->create_rel_dir("$name/frontend/source/translation");
    chdir $name;
    system "./bootstrap";
}

sub render_data {
  my ($self, $name) = (shift, shift);
    Mojo::Template->new->name("template $name")
    ->render(slurp(dirname($INC{'Mojolicious/Command/generate/qx_mojo_app.pm'}).'/qx_mojo_app/'.$name), @_);
}
1;
