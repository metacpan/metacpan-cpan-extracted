package Spork::Command;
use Spork -Base;

sub boolean_arguments { qw( -new -make -start -compress) }
sub process {
    $self->call_handler(@_);
    $self->hub->remove_hooks;
}

sub call_handler {
    my ($args,@others) = $self->parse_arguments(@_);
    return $self->new_spork if $args->{-new};
    return $self->make_spork if $args->{-make};
    return $self->start_spork if $args->{-start};
    return $self->handle_compress(@others) if $args->{-compress};
    return $self->usage;
}

sub handle_compress {
    eval q{use mixin 'Spoon::Installer'};
    $self->compress_lib(@_);
}

sub new_spork {
    my @files = io('.')->all;
    die "Can't make new spork in a non-empty directory\n"
      if @files;
    warn "Extracting sample slideshow: Spork.slides...\n";
    $self->hub->slides->extract_files;
    warn "Extracting sample configuration file: config.yaml...\n";
    $self->hub->config->extract_files;
    warn "Done. Now edit these files and run 'spork -make'.\n\n"
}

sub make_spork {
    $self->assert_registry;
    unless (-e $self->hub->template->extract_to) {
        warn "Extracting template files...\n";
        $self->hub->template->extract_files;
    }
    {
        use Cwd;
        my $home = cwd;
        chdir io->dir($self->hub->config->slides_directory)->assert->open->name;
        my $kwiki_command = $self->hub->kwiki_command;
        for my $class (@{$self->hub->config->plugin_classes}) {
            eval "use $class; 1" or die $@;
            my $class_id = $class->new->class_id;
            $self->hub->config->add_config({"${class_id}_class" => $class});
            $kwiki_command->install($class_id);
        }
        chdir $home;
    }
    warn "Creating slides...\n";
    $self->hub->slides->make_slides;
    warn "Slideshow created! Now run try running 'spork -start'.\n\n";
}

sub start_spork {
    my $command = $self->hub->config->start_command
      or die "No start_command in configuration";
    warn $command, "\n";
    exec $command;
}

sub usage {
    warn <<END;
usage:
  spork -new                  # Generate a new slideshow in an empty directory
  spork -make                 # Turn the text into html slides
  spork -start                # Start the show in a browser
END
}

sub assert_registry {
    use Kwiki::Plugin;
    {
        no warnings;
        *Kwiki::Plugin::init = sub {};
    }
    $self->hub->registry->load;
}

__END__

=head1 NAME

Spork::Command - Slide Presentations (Only Really Kwiki)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004, 2005. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
