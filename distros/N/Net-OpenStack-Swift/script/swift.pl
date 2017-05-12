#!/usr/bin/env perl

use strict;
use warnings;
use App::Rad;
use Path::Tiny;
use File::Basename;
use Text::ASCIITable;
use Net::OpenStack::Swift;
use Parallel::Fork::BossWorkerAsync;
use Sys::CPU;
use JSON qw/encode_json decode_json/;


sub setup {
    my $c = shift;

    $c->register_commands({
        'version'  => 'Net::OpenStack::Swift version.',
        'list'     => 'Show container/object.',
        'get'      => 'Get object content.',
        'put'      => 'Create or replace object and container.',
        'post'     => 'Create or update metadata.',
        'delete'   => 'Delete container/object.',
        'download' => 'Download container/object.',
        'upload'   => 'Upload container/object.',
    });

    $c->stash->{storage_url} = undef;
    $c->stash->{token}       = undef;

    my $config_path = path($ENV{HOME}, '.swift.pl.conf');
    if ($config_path->exists) {
        $c->load_config($config_path);
        $c->config->{workers} ||= Sys::CPU::cpu_count();
    }
 
    $c->stash->{sw} ||= _sw_instance($c);
}

sub _sw_instance {
    my $c = shift; 
    my $sw = Net::OpenStack::Swift->new;
    $sw->agent_options({
        timeout    => $c->config->{timeout},
        user_agent => $c->config->{user_agent},
    });
    $sw->auth_url($c->config->{os_auth_url})       unless $sw->auth_url;
    $sw->user($c->config->{os_username})           unless $sw->user;
    $sw->password($c->config->{os_password})       unless $sw->password;
    $sw->tenant_name($c->config->{os_tenant_name}) unless $sw->tenant_name;
    return $sw;
}

sub _auth {
    my $c = shift; 
    unless ($c->stash->{token}) {
        my ($storage_url, $token) = $c->stash->{sw}->get_auth();
        $c->stash->{storage_url} = $storage_url;
        $c->stash->{token}       = $token;
    }
}

sub _path_parts {
    my $target = shift;
    my $path = path($target);
    my ($container_name, $object_name);
    my $prefix    = '';
    my $delimiter = '/';
    my $top_level = 0;

    # directory
    if ($target =~ /\/$/) {
        my @parts = split '/', $path->stringify, 2;
        $container_name = $parts[0] || '/';
        unless ($path->dirname eq '.' || $path->dirname eq '/') {
            $prefix = sprintf "%s/", $parts[1];
        }
    }
    # object
    else {
        # top level container
        if ($path->dirname eq '.') {
            $container_name = $path->basename;
            $top_level = 1;
        }
        # other objects
        else {
            my @parts = split '/', $path->stringify, 2;
            $container_name = $parts[0];
            $object_name    = $parts[1];
        }
    }
    return ($container_name, $object_name, $prefix, $delimiter, $top_level);
}

App::Rad->run;

sub version {
    sprintf "Net::OpenStack::Swift %s", $Net::OpenStack::Swift::VERSION;
}

sub list {
    _auth(@_);
    my $c = shift;
    my $target = $ARGV[0] ||= '/';
    my ($container_name, $object_name, $prefix, $delimiter, $top_level) = _path_parts($target);

    my $t;
    # head object
    if ($object_name) {
        my $headers = $c->stash->{sw}->head_object(container_name => $container_name, object_name => $object_name);
        $t = Text::ASCIITable->new({headingText => "${object_name} object"});
        $t->setCols('key', 'value');
        for my $key (sort keys %{ $headers }) {
            $t->addRow($key, $headers->{$key});
        }
    }
    # head container
    elsif ($top_level) {
        my $headers = $c->stash->{sw}->head_container(container_name => $container_name);
        $t = Text::ASCIITable->new({headingText => "${object_name} object"});
        $t->setCols('key', 'value');
        for my $key (sort keys %{ $headers }) {
            $t->addRow($key, $headers->{$key});
        }
    }
    # get container
    else {
        my ($headers, $containers) = $c->stash->{sw}->get_container(
            container_name => $container_name,
            delimiter      => $delimiter,
            prefix         => $prefix
        );
        if (scalar @{ $containers } == 0) {
            return "container ${target} is empty.";
        }
        my $heading_text = "${container_name} container";
        my @label;
        if ($container_name eq '/') {
            @label = ('name', 'bytes', 'count');
        }
        else {
            @label = ('name', 'bytes', 'content_type', 'last_modified');
        }
        $t = Text::ASCIITable->new({headingText => $heading_text});
        my $total_bytes = 0;
        my $total_files = 0;
        for my $container (@{ $containers }) {
            $t->setCols(@label);
            $t->addRow(map { $container->{$_} } @label);
            $total_bytes += int($container->{bytes} || 0);
            $total_files++;
        }
        $t->addRowLine();
        $t->addRow(sprintf("%s files, Total bytes", $total_files), $total_bytes);
    }
    return $t;
}

sub get {
    _auth(@_);
    my $c = shift;
    my $target = $ARGV[0] ||= '';
    my ($container_name, $object_name, $prefix, $delimiter) = _path_parts($target);
    die "object name is required." unless $object_name;

    my $fh = *STDOUT;
    my $etag = $c->stash->{sw}->get_object(container_name => $container_name, object_name => $object_name,
        write_file => $fh,
    );
    return undef;
}

sub put {
    _auth(@_);
    my $c = shift;
    my $target = $ARGV[0] ||= '';
    my $local_path = $ARGV[1] ||= '';
    my ($container_name, $object_name, $prefix, $delimiter) = _path_parts($target);
    die "container name is required." unless $container_name;

    # put object
    my $t;
    my ($headers, $containers);
    if ($local_path) {
        my $basename = basename($local_path);
        open my $fh, '<', "./$local_path" or die "failed to open: $!";
        my $etag = $c->stash->{sw}->put_object(
            container_name => $target, object_name => $basename, 
            content => $fh, content_length => -s $local_path);
        my $headers = $c->stash->{sw}->head_object(container_name => $target, object_name => $basename);
        $t = Text::ASCIITable->new({headingText => "${basename} object"});
        $t->setCols('key', 'value');
        for my $key (sort keys %{ $headers }) {
            $t->addRow($key, $headers->{$key});
        }
    }
    # put container
    else {
        ($headers, $containers) = $c->stash->{sw}->put_container(container_name => $target);
        my $t = Text::ASCIITable->new({headingText => 'response header'});
        $t->setCols(sort keys %{ $headers });
        $t->addRow(map { $headers->{$_} } sort keys %{ $headers });
    }
    return $t;
}

sub post {
    _auth(@_);
    my $c = shift;
    my $target = $ARGV[0] ||= '';
    my $x_headers = decode_json($ARGV[1] ||= '{}');
    my ($container_name, $object_name, $prefix, $delimiter) = _path_parts($target);
    die "container name is required." unless $container_name;

    my $t;
    my ($headers, $containers);
    # post object
    if ($object_name) {
        $headers = $c->stash->{sw}->post_object(container_name => $container_name, 
            object_name => $object_name,
            headers => $x_headers);
    }
    # post container
    else {
        $headers = $c->stash->{sw}->post_container(container_name => $container_name, 
            headers => $x_headers);
    }
    $t = Text::ASCIITable->new({headingText => 'response header'});
    $t->setCols('key', 'value');
    for my $key (sort keys %{ $headers }) {
        $t->addRow($key, $headers->{$key});
    }
    return $t;
}

sub delete {
    _auth(@_);
    my $c = shift;
    my $target = $ARGV[0] ||= '';
    my ($container_name, $object_name, $prefix, $delimiter) = _path_parts($target);

    # find objects matche pattern
    my @matche_objects    = ();
    my @matche_containers = ();
    if ($object_name) {
        $object_name =~ s/\*/\(\.\*\?\)/g; 
        my ($headers, $containers) = $c->stash->{sw}->get_container(container_name => $container_name);
        for my $container (@{ $containers }) {
            if ($container->{content_type} eq 'application/directory') {
                push @matche_containers, {
                    container_name => $container_name, 
                    object_name    => $container->{name},
                    content_type   => $container->{content_type}
                };
            } 
            elsif ($container->{name} =~ /$object_name/) {
                push @matche_objects, {
                    container_name => $container_name, 
                    object_name    => $container->{name},
                    content_type   => $container->{content_type}
                };
            }
        }
    }

    my $t;
    # delete object
    if (scalar @matche_objects) {
        for my $obj (@matche_objects) {
            my ($headers, $containers) = $c->stash->{sw}->delete_object(
                container_name => $obj->{container_name},
                object_name    => $obj->{object_name}
            );
            printf "deleted object %s/%s\n", $obj->{container_name}, $obj->{object_name};
        }
    }
    if (scalar @matche_containers) {
        for my $obj (reverse @matche_containers) {
            my ($headers, $containers) = $c->stash->{sw}->delete_object(
                container_name => $obj->{container_name},
                object_name    => $obj->{object_name}
            );
            printf "deleted object %s/%s\n", $obj->{container_name}, $obj->{object_name};
        }
    }

    # delete container
    unless (scalar(@matche_objects) || scalar(@matche_containers)) {
        my ($headers, $containers) = $c->stash->{sw}->delete_container(
            container_name => $container_name
        );
        printf "deleted container %s\n", $container_name;
    }
    return undef;
}

sub download {
    _auth(@_);
    my $c = shift;
    die "ARGV" if scalar @ARGV >= 2;
    my $target = $ARGV[0] ||= '';

    my ($container_name, $object_name, $prefix, $delimiter) = _path_parts($target);
    die "container name is required." unless $container_name;
    if ($object_name) {
        $object_name =~ s/\*/\(\.\*\?\)/g; 
    }
    else {
        $object_name = '(.*?)'; 
    }

    if (-d $container_name) {
        print "Directory [${container_name}] already exists. Overwrite? [y/n] ";
        my $yn = lc <STDIN>;
        chomp $yn;
        if ($yn eq 'n') {
            exit(0);
        }
    }
    else {
        path($container_name)->mkpath;
    }
    
    # find matche pattern
    my @matches = ();
    my ($headers, $containers) = $c->stash->{sw}->get_container(container_name => $container_name, full_listing => 1);
    for my $container (@{ $containers }) {
        if ($container->{name} =~ /$object_name/) {
            push @matches, {
                container_name => $container_name, 
                object_name    => $container->{name},
                content_type   => $container->{content_type}
            };
        }
    }

    my $swi;
    my $bwa = Parallel::Fork::BossWorkerAsync->new(
        init_handler => sub {
            $swi = _sw_instance($c);
            $swi->auth_keystone;
        },
        work_handler => sub {
            my ($job) = @_;
            if ($job->{content_type} eq 'application/directory') {
                path($job->{container_name}, $job->{object_name})->mkpath;
            }
            else {
                my $target_path = path($job->{container_name}, $job->{object_name});
                path($target_path->dirname)->mkpath;
                my $fh = $target_path->openw;  #$binmode
                my $etag = $swi->get_object(
                    container_name => $job->{container_name}, 
                    object_name => $job->{object_name},
                    write_file => $fh,
                );
            }
            return $job;
        },  
        result_handler => sub {
            my ($job) = @_; 
            printf "downloaded %s/%s\n", $job->{container_name}, $job->{object_name};
            return $job;
        },  
        worker_count => $c->config->{workers},
    );
    $bwa->add_work(@matches);
    while($bwa->pending) {
        my $ref = $bwa->get_result;
    }
    $bwa->shut_down;

    return undef;
}

sub upload {
    _auth(@_);
    my $c = shift;
    die "ARGV" if scalar @ARGV >= 2;
    my $target = $ARGV[0] ||= '';

    my ($container_name, $object_name, $prefix, $delimiter) = _path_parts($target);
    die "container name is required." unless $container_name;

    if ($object_name) {
        $object_name =~ s/\*/\(\.\*\?\)/g; 
    }
    else {
        $object_name = '(.*?)'; 
    }

    my @matches = ();
    my $iter = path($container_name)->iterator({
        recurse         => 1,
        follow_symlinks => 0,
    }); 
    while (my $local_path = $iter->()) {
        my $partial = "$container_name/$object_name";
        if ($local_path->stringify =~ /$partial/) {
            push @matches, {local_path => $local_path};
        }
    }
    return unless scalar @matches;

    # create top level container
    $c->stash->{sw}->put_container(container_name => $container_name);                

    my ($headers, $containers);
    my $swi;
    my $bwa = Parallel::Fork::BossWorkerAsync->new(
        init_handler => sub {
            $swi = _sw_instance($c);
            $swi->auth_keystone;
        },
        work_handler => sub {
            my ($job) = @_;
            my ($up_container, $up_object) = split '/', $job->{local_path}->stringify, 2;
            $job->{container_name} = $up_container;
            $job->{object_name}    = $up_object;
            if ($job->{local_path}->is_dir) {
                my $res = $swi->put_container(container_name => $job->{local_path}->stringify);                
            }
            else {
                my $fh = $job->{local_path}->openr;  #$binmode
                my $etag = $swi->put_object(
                    container_name => $up_container, object_name => $up_object, 
                    content => $fh, content_length => -s $job->{local_path}->absolute);
            }
            return $job;
        },  
        result_handler => sub {
            my ($job) = @_; 
            printf "uploaded %s/%s\n", $job->{container_name}, $job->{object_name};
            return $job;
        },  
        worker_count => $c->config->{workers},
    );
    $bwa->add_work(@matches);
    while($bwa->pending) {
        my $ref = $bwa->get_result;
    }
    $bwa->shut_down;

    return undef;
} 
