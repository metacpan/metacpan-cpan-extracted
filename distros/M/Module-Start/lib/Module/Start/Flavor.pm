package Module::Start::Flavor;
use strict;
use warnings;

use base 'Module::Start::Base';

use Class::Field qw'field';
use IO::All;
use XXX;

field 'config' => -init => '$self->new_config_object';

sub install_files {
    my $self = shift;
    my $class = ref($self);
    my $flavor = $self->flavor;
    my $base = $self->config->base_dir;
    my $file_map = $self->read_data_files($class);
    for my $file_name (sort keys %$file_map) {
        my $file_content = $file_map->{$file_name};
        io("$base/templates/$flavor/$file_name")
            ->assert->print($file_content);        
    }
}

sub start_module {
    my ($self, $args) = @_;
    $self->config->initialize($args);
    my $dist_name = $self->config->module_dist_name;
    $self->exit("'$dist_name' already exits")
      if -e $dist_name;
    
    my $templates_path = $self->config->templates_path;
    my @files = io($templates_path)->All_Files;
    print "Changing to directory $dist_name\n";
    my $dist = io->dir($dist_name)->mkdir->chdir;
    my $manifest = '';
    for my $file (@files) {
        my $name = './' . $file->abs2rel($templates_path);
        next if $name eq './__config__';
        $name =~ s/\+\+(.*?)\+\+/$self->config->$1/ge;
        if ($name eq './MANIFEST') {
            $manifest = $file;
            io('MANIFEST')->touch;
            next;
        }
        $self->create_file($name, $file);
    }
    if ($manifest) {
        $self->create_file('./MANIFEST', $manifest);
    }
}

sub create_file {
    my ($self, $name, $file) = @_;
    my $template = $file->all;
    my $result = $self->render_template(\ $template,
        %{$self->config},
    );
    print "Creating $name\n";
    io->file($name)->assert->print($result);
}

sub manifest_files {
    my $self = shift;
    my @files = io('.')->All_Files;
    return join "",
        sort {
            lc($a) cmp lc($b)
        }
        map {
            $_->abs2rel . "\n"
        }
        @files;
}

1;
