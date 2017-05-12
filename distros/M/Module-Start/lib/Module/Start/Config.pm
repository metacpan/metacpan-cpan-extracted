package Module::Start::Config;
use strict;
use warnings;

use base 'Module::Start::Base';

use Class::Field 'field';
use IO::All;
use Config;
use XXX;

field 'base_dir',       -init => '$self->get_base_dir';
field 'is_configured' => 0;

# Template variables
field 'flavor'                  => 'UNDEFINED';
field 'module_name'             => 'UNDEFINED';
field 'module_dist_name'        => 'UNDEFINED';
field 'module_dist_name_version' => 'UNDEFINED';
field 'module_dist_name_lower'  => 'UNDEFINED';
field 'module_lib_path'         => 'UNDEFINED';
field 'module_pm'               => 'UNDEFINED';
field 'module_all_lib_paths'    => 'UNDEFINED';
field 'author_full_name'        => 'UNDEFINED';
field 'author_email_address'    => 'UNDEFINED';
field 'author_email_masked'     => 'UNDEFINED';
field 'date_time_human'         => scalar(gmtime);
field 'date_time_year'          => (gmtime)[5] + 1900;
field 'perl_config'             => { %Config::Config };

# Short/compatibility template variables
field 'module',         -init => '$self->module_name';
field 'main_module',    -init => '$self->module_dist_name';
field 'main_pm_file',   -init => '$self->module_lib_path';
field 'rtnname',        -init => '$self->module_dist_name_lower';
field 'build_instructions' => '';
field 'modules',        -init => '$self->module_all_lib_paths';
field 'year',           -init => '$self->date_time_year';
field 'author',         -init => '$self->author_full_name';
field 'email',          -init => '$self->author_email_address';
field 'distro',         -init => '$self->module_dist_name_version';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->is_configured(1)
      if -e $self->config_path;
    return $self;
}

sub initialize {
    my ($self, $args) = @_;
    $self->read_config;
    if ($self->author_email_address ne 'UNDEFINED') {
        my $email = $self->author_email_address;
        $email =~ s/\@/ at /;
        $self->author_email_masked($email);
    }
    if (my $module_name = $args->{target}) {
        $module_name =~ s/-/::/g;
        $module_name =~ s/\.pm$//;
        $self->module_name($module_name);
        local $_ = $module_name;
        $self->module_dist_name(do { s/::/-/g; $_ });
        $self->module_dist_name_lower(do { lc($_) });
        $self->module_lib_path(
            do { s/-/\//g; $_ = "lib/$_.pm" }
        );
        $self->module_pm(do { s/.*\///g; $_ });
    }
    if (my $flavor = $args->{flavor}) {
        $self->flavor($flavor);
    }
    $self->set_all;
    return $self;
}

sub set_all {
    my $self = shift;
    map { $self->$_ } qw(
        author_full_name
        author_email_address
        author_email_masked
        date_time_human
        date_time_year
        perl_config
        module
        main_module
        main_pm_file
        rtnname
        build_instructions
        modules
        year
        author
        email
        distro
    );
}

sub get_base_dir {
    return $ENV{MODULE_START_BASE} || 
        defined $ENV{HOME}
        ? "$ENV{HOME}/.module-start"
        : die "HOME environment variable not set";
}

sub templates_path {
    my $self = shift;
    my $path =
        $self->base_dir . '/templates/' . $self->flavor;
    die "Templates path '$path' does not exist!!"
        unless -e $path;
    return $path;
}

sub read_config {
    my $self = shift;
    my $file_path = $self->config_path;
    my $config_content = io($file_path)->all;
    for my $line ($config_content =~ /(.*\n)/g) {
        next if $line =~ /^(#|\s*$)/;
        $line =~ /^(\w+)\s*:\s+(.*)/ or die "Error in $file_path";
        $self->{$1} = $2;
    }
}

sub write_config {
    my ($self, $template) = @_;
    my $file_content = $self->render_template(\ $template,
        author_full_name => $self->author_full_name,
        author_email_address => $self->author_email_address,
    );
    io->file($self->config_path)->assert->print($file_content);
}

sub config_path {
    my $self = shift;
    return $self->base_dir . "/config";
}

1;
