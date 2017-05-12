package Module::MakeMaker;

use strict;
use warnings;

# TODO Use ScanDeps to scan deps.
use Getopt::Long;
use Template::Toolkit::Simple;
use YAML::XS;
use Cwd;
use File::Find::Rule;
use File::ShareDir;

our $VERSION = '0.03';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub _run_command {
    my $class = shift;
    my $self = $class->new;

    $self->check_sanity;
    $self->init;

    my $called = 0;

    my $call_method = sub {
        my ($name, $value) = @_;
        my $method = lc($name);
        $method =~ s/-/_/g;
        $self->$method($value);
        $called = 1;
    };

    GetOptions(
        map {
            my $option = $_;
            my $option2 = $option;
            $option .= "|$option2"
                if $option2 =~ s/_/-/g;
            ($option, $call_method);
        } qw(
            tt_yaml
            make_makefile
            create_config
            cpan_makefile
            commit
        )
    );

    return if $called;

    $self->ask_create_config and return;

    $self->make_makefile();
}

sub check_sanity {
    my $cwd = Cwd::cwd();
    my $home = $ENV{HOME};
    $cwd =~ s/\/$//;
    $home =~ s/\/$//;
    die "Don't run 'mmm' from your home directory, silly.\n"
        if $cwd eq $home;
}

sub get_path {
    my $self = shift;
    my $type = shift;
    my @path = ();
    my $path = Cwd::cwd();
    die "Don't support path '$path'"
        unless $path =~ m!^/!;
    while ($path) {
        if ($type eq 'config.yaml') {
            my $template = "$path/MMM.yaml";
            push @path, $template if -e $template;
        }
        
        my $template = "$path/MMM/$type";
        push @path, $template if -e $template;

        $template = "$path/.mmm/$type";
        push @path, $template if -e $template;
        
        $path =~ s!(.*)/.*!$1!
            or die "Reduction failure for '$path'";
    }

#     $INC{'Module/MakeMaker.pm'} = '/usr/local/lib/perl5/site_perl/5.10.0/Module/MakeMaker.pm';
    my $template = File::ShareDir::module_dir('Module::MakeMaker') . "/$type";
    push @path, $template if -e $template;

    return @path;
}

sub init {
    my $self = shift;
    $self->get_config;
}

sub get_config {
    my $self = shift;

    my $config = {};
    for (reverse $self->get_path('config.yaml')) {
        my $config_next = eval { YAML::XS::LoadFile($_) };
        if ($@ or ref($config_next) ne 'HASH') {
            warn "Failed to load '$_' as a hash: $@\n";
            $config_next = {};
        }
        $config = { %$config, %$config_next };
    }

    $config->{mmm_path} ||= [ $self->get_path('template') ];
    my $cwd = Cwd::cwd();
    $cwd =~ s/.*[\/\\](.+)[\/\\]?$/$1/;
    $config->{name} ||= $cwd;
    $config->{module_name} ||= $config->{name};
    $config->{module_libpath} ||= 'lib/' . $config->{name} . '.pm';
    $config->{dist_name} ||= $config->{name};
    $config->{module_name} =~ s/[\-\/\\]/::/g;
    $config->{module_libpath} =~ s/(-|::)/\//g;
    $config->{dist_name} =~ s/([\/\\]|::)/-/g;
    $config->{copy_files} ||= [];
    $config->{copy_files} =
        [File::Find::Rule->file->in(@{$config->{copy_files}})];
    $config->{template_files} ||= [ grep { -e } qw( Changes lib t bin) ];
    $config->{template_files} =
        [File::Find::Rule->file->in(@{$config->{template_files}})];
    $config->{include_path} ||= [];
    if (defined $config->{requires} and ref($config->{requires}) ne 'ARRAY') {
        $config->{requires} = [$config->{requires}];
    }
    $config->{requires} ||= [];
    for (my $i = 0; $i < @{$config->{requires}}; $i++) {
        if (not ref($config->{requires}[$i])) {
            $config->{requires}[$i] = {$config->{requires}[$i] => 0};
        }
    }
    push @{$config->{include_path}},
        $self->get_path('template'),
        '..';
    $config->{config_yaml} =
        -e 'MMM.yaml' ? Cwd::abs_path('MMM.yaml') :
        -e 'MMM/config.yaml' ? Cwd::abs_path('MMM/config.yaml') :
        '';

    $config->{gmtime} = gmtime (). ' GMT';

    $self->{config} = $config;
}

sub make_makefile {
    my $self = shift;
    $self->render_template('Makefile', $self->{config}, 'Makefile');
    print "Makefile created.\n";
}

sub cpan_makefile {
    my $self = shift;
    $self->render_template('mmm.mk', $self->{config}, 'cpan/mmm.mk');
    print "cpan/mmm.mk created.\n";
}

sub tt_yaml {
    my $self = shift;
    YAML::XS::DumpFile('tt.yaml', $self->{config});
    print "tt.yaml created.\n";
}

sub render_template {
    my $self = shift;
    my ($template, $data, $output, %options) = @_;
    my $tt = tt
        ->output($output)
        ->path($self->{config}{mmm_path})
        ->data($data);
    for my $option (keys %options) {
        $tt->$option($options{$option});
    }
    $tt->render($template);
}

sub ask_create_config {
    my $self = shift;
    return if -f 'MMM.yaml' || -f 'MMM/config.yaml';
    print "Module::MakeMaker has determined that you have no MMM.yaml\n";
    my $answer = '';
    while ($answer !~ /^[yn]$/) {
    print "Would you like to create that now? [Yn] ";
        $answer = <>;
        chomp $answer;
        $answer ||= 'y';
        $answer =~ s/y(es)?/y/i;
        $answer =~ s/n(o)?/n/i;
    }
    return 1 if $answer eq 'n';
    $self->create_config($self->default_data);;
    return 1;
}

sub default_data {
    my $self = shift;
    my $name = Cwd::cwd();
    $name =~ s/[\/\\]*$//;
    $name =~ s/.*[\/\\]//;
    return {
        name => $name,
        dist_name => $name,
        version => '0.01',
    };
}

sub create_config {
    my $self = shift;
    my $data = shift;
    $self->render_template('MMM.yaml', $data, 'MMM.yaml');
    print <<'...';
MMM.yaml has been created.
Please edit it now.
Then run `mmm` to generate a Makefile.
Then run `make test`, etc.
...
    return 1;
}

sub commit {
    my $self = shift;
    my $vcs = $self->{config}{vcs} || 'svn';
    die "'$vcs' is unsupported VCS" unless $vcs =~ /^(svn|svk)$/;
    print "make clean\n";
    system("make clean") == 0 or die;
    print "$vcs st\n";
    my @lines = `$vcs status`;
    print @lines;
    if (not @lines) {
        print "Nothing to commit.\n\n";
        system("mmm; make init");
        return;
    }
    if (grep /^\?/, @lines) {
        print "You have unaccounted files.\n";
        if ($self->_prompt("Would you like to add them?", 'y')) {
            for (grep /^\?/, @lines) {
                chomp;
                s/\?\s*//;
                print "$vcs add $_\n";
                system("$vcs add $_") == 0 or die;
            }
        }
    }
    else {
        $self->_next() or return;
    }
    system("$vcs diff | vim -");
    $self->_next() or return;
    print "$vcs commit\n";
    system("$vcs commit");
    print "$vcs commit complete!\n\n";
    system("mmm; make init");
}

sub _next {
    print "Press ENTER to continue";
    return <>;
}

sub _prompt {
    my $self = shift;
    my $prompt = shift;
    my $default = shift;
    $prompt .= ($default eq 'y') ? ' [Yn] ' : ' [yN] ';
    my $answer = '';
    while (not $answer) {
        print $prompt;
        my $answer = <>;
        chomp $answer;
        $answer ||= $default;
        $answer = lc($answer);
        $answer =~ s/^yes$/y/;
        $answer =~ s/^no$/y/;
        $answer = '' unless $answer =~ /^[yn]$/;
    }
    return ($answer eq 'y');
}


1;

=head1 NAME

Module::MakeMaker - A New Way to Make Modules

=head1 SYNOPSIS

    > mmm
    > vim Mmm.yaml
    > make
    > make test
    > make install
    > make dist

=head1 DESCRIPTION

Module::MakeMaker (MMM) is a new way to make modules. It builds on the
the old, tried and true method, but automates the repetitive,
cumbersome and error prone steps involved. It leverages YAML,
Makefiles and templating, to do the right things you want to do, when
they need to be done. This means you can apply a simple patch to your
module, and then run:

    make upload

and know that all the appropriate actions need will be performed, and if
they are all successful, your module will be on its way to CPAN, and you
can move on to your next task.

MMM bootstraps a module environment from meta information that you
specify in C<MMM.yaml> or C<MMM/config.yaml> files. You can spread this
data over local and general yaml files to eliminate duplication.

The main difference between MMM and the traditional style is that none
of the files that you create in your module directory are used in the
actual distribution. These files are all copied (or templated or
generated) into a C<cpan/> subdirectory and that is the final place for
testing and building the CPAN distribution.

You never need to edit the files in the C<cpan/> directory. Also you can
run all the common make commands:

    > make
    > make test
    > make install
    > make dist

without needing to cd into the C<cpan/> directory. The MMM Makefile has
targets to run these commands from the top level for you.

To get started, run the C<mmm> command in your new or existing module
directory. It will set up things for you and tell you what you need
to do next.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2008. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

