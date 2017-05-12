package Spoon::Installer;
use Spiffy -Base; 
use IO::All;
use Spoon::Base -mixin => qw(hub);

const extract_to => '.';
field quiet => 0;

sub compress_from {
    $self->extract_to;
}

sub extract_files {
    my @files = $self->get_packed_files;
    while (@files) {
        my ($file_name, $file_contents) = splice(@files, 0, 2);
        my $locked = $file_name =~ s/^!//;
        my $file_path = join '/', $self->extract_to, $file_name;
        my $file = io->file($file_path)->assert;
        if ($locked and -f $file_path) {
            warn "  Skipping $file (already exists)\n" unless $self->quiet;
            next;
        }
        my $content = $self->set_file_content($file_path, $file_contents);
        if ($file->exists and $file->all eq $content) {
            warn "  Skipping $file (unchanged)\n" unless $self->quiet;
            next;
        }
        warn "  - $file\n" unless $self->quiet;
        $file->binary if $self->file_is_binary($file_path);
        $file->assert->print($content);
    }
}

sub set_file_content {
    my $path = shift;
    my $content = shift;
    $content = $self->base64_decode($content)
      if $self->file_is_binary($path);
    $content = $self->fix_hashbang($content)
      if $self->file_is_executable($path);
    $content = $self->wrap_html($content, $path)
      if $self->file_is_html($path);
    return $content;
}

sub file_is_binary {
    my $path = shift;
    $path =~ /\.(gif|jpg|png)$/;
}

sub file_is_executable {
    my $path = shift;
    $path =~ /\.(pl|cgi)$/;
}

sub file_is_html {
    my $path = shift;
    $path =~ /\.html$/;
}

sub fix_hashbang {
    require Config;
    my $content = shift;
    $content =~ s/^#!.*\n/$Config::Config{startperl} -w\n/;
    return $content;
}

sub wrap_html {
    my ($content, $path) = @_;
    $path =~ s/^.*\/(.*)$/$1/;
    $path =~ s/\.html$//;
    $content = $self->strip_html($content);
    $content = "<!-- BEGIN $path -->\n$content"
      unless $content =~ /^\s/;
    $content = "$content<!-- END $path -->\n"
      unless $content =~ /\s\n\z/;
    return $content;
}

sub get_packed_files {
    my %seen;
    my @return;
    for my $class (@{Spiffy::all_my_bases(ref $self)}) {
        next if $class =~ /-/;
        last if $class =~ /^Spoon/;
        my $data = $self->data($class)
          or next;
        my @files = split /^__(.+)__\n/m, $data;
        shift @files;
        while (@files) {
            my ($name, $content) = splice(@files, 0, 2);
            $name = $self->resolve_install_path($name)
              if $self->can('resolve_install_path');
            my $name2 = $name;
            $name2 =~ s/^\!//;
            next if $seen{$name2}++;
            $content ||= '';
            push @return, $name, $content
              if length $content;
        }
    }
    return @return;
}

sub get_local_packed_files {
    my @return;
    my $class = ref $self;
    my $data = $self->data($class)
      or return;
    my @files = split /^__(.+)__\n/m, $data;
    shift @files;
    while (@files) {
        my ($name, $content) = splice(@files, 0, 2);
        $name = $self->resolve_install_path($name)
          if $self->can('resolve_install_path');
        push @return, $name, $content;
    }
    return @return;
}

sub data {
    my $package = shift || ref($self);
    local $SIG{__WARN__} = sub {};
    local $/;
    eval "package $package; <DATA>";
}

sub compress_files {
    require File::Spec;
    my $source_dir = shift;
    my $new_pack = '';
    my @files = $self->get_local_packed_files;
    my $first_file = $files[0]
      or return;
    my $directory = $self->compress_from;
    while (@files) {
        my ($file_name, $file_contents) = splice(@files, 0, 2);
        my $locked = $file_name =~ s/^!// ? '!' : '';
        my $source_path = 
          File::Spec->canonpath("$source_dir/$directory/$file_name");
        die "$file_name does not exist as $source_path" 
          unless -f $source_path;
        my $content = $locked 
        ? $file_contents
        : $self->get_file_content($source_path);
        $content =~ s/\r\n/\n/g;
        $content =~ s/\r/\n/g;
        $new_pack .= "__$locked${file_name}__\n$content";
    }
    my $module = ref($self) . '.pm';
    $module =~ s/::/\//g;
    my $module_path = $INC{$module} or die;
    my $module_text = io($module_path)->all;
    my ($module_code) = split /^__\Q$first_file\E__\n/m, $module_text;
    ($module_code . $new_pack) > io($module_path);
}

sub get_file_content {
    my $path = shift;
    my $content = io($path)->all;
    $content = $self->base64_encode($content)
      if $self->file_is_binary($path);
    $content = $self->unfix_hashbang($content)
      if $self->file_is_executable($path);
    $content = $self->strip_html($content)
      if $self->file_is_html($path);
    $content .= "\n"
      unless $content =~ /\n\z/;
    return $content;
}

sub unfix_hashbang {
    my $content = shift;
    $content =~ s/^#!.*\n/#!\/usr\/bin\/perl\n/;
    return $content;
}

sub strip_html {
    my $content = shift;
    $content =~ s/^<!-- BEGIN .* -->\n//;
    $content =~ s/(?<=\n)<!-- END .* -->\n\z//;
    return $content;
}

sub compress_lib {
    die "Must be run from the module source code directory\n"
      unless -d 'lib' and -f 'Makefile.PL';
    unshift @INC,'lib';
    my $source_dir = shift
      or die "No source directory specified\n";
    die "Invalid source directory '$source_dir'\n"
      unless -d $source_dir;
    map {
        my $class_name = $_;
        my $class_id = $class_name->class_id;
        $self->hub->config->add_config(
            +{ "${class_id}_class" => $class_name }
        );
        warn "Compressing $class_name\n" unless $self->quiet;
        $self->hub->$class_id->compress_files($source_dir);
    }
    grep {
        my $name = $_;
        eval "require $name";
        die $@ if $@;
        UNIVERSAL::can($name, 'compress_files')
          and $name !~ /::(Installer)$/;
    } map {
        my $name = $_->name;
        ($name =~ s/^lib\/(.*)\.pm$/$1/) ? do {
            $name =~ s/\//::/g;
            $name;
        } : ();
    } io('lib')->All_Files;
}

__END__

=head1 NAME 

Spoon::Installer - Spoon Installer Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
