package TaskPipe::Tool;

use Moose;
use Getopt::Long;
use TaskPipe::PathSettings;
use TaskPipe::PathSettings::Global;
use TaskPipe::Tool::Options;
use TaskPipe::PodReader::Settings;
use TaskPipe::PodReader;
use MooseX::ConfigCascade::Util;
use TaskPipe::LoggerManager;
use Log::Log4perl;
use File::Spec;
use File::Save::Home;
use Clone 'clone';
use Hash::Merge 'merge';
use Module::Runtime 'require_module';
use Data::Dumper;
use Try::Tiny;
use Array::Utils;
use Pod::Term;
use String::CamelCase qw(wordsplit camelize);
use Cwd 'abs_path';
use Term::ANSIColor 'colored';
use POSIX qw(isatty);

with 'MooseX::ConfigCascade';

our $VERSION = '0.03';


has cmd => (is => 'rw', isa => 'ArrayRef');

has options => (is => 'rw', isa => 'TaskPipe::Tool::Options', default => sub{
    TaskPipe::Tool::Options->new;
});
has pod_reader => (is => 'ro', isa => 'TaskPipe::PodReader', lazy => 1, default => sub{
    TaskPipe::PodReader->new;
});
has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});
has path_settings => (is => 'ro', isa => 'TaskPipe::PathSettings', default => sub{
    TaskPipe::PathSettings->new;
});


sub get_cmd{
    my ($self) = @_;

    my @orig = @ARGV;
    $self->run_info->orig_cmd( \@orig );

    my @cmd = ();
    while( $ARGV[0] && $ARGV[0] !~ /^\-/ ){
        push @cmd, lc( +shift @ARGV );
    }

    $self->run_info->cmd( \@cmd );
    $self->options->get_args;
}


sub get_conf{
    my ($self) = @_;

    my $ps = TaskPipe::PathSettings->new( scope => 'global' );

    my $root_dir;

    try {

        $root_dir = $ps->root_dir;
        
    } catch {

        $self->message( qq|=pod

Failed to retrieve the path to the taskpipe root directory from the file ${\$ps->home_filepath}. The following error was reported: $_

=cut
|);
        exit;
    };

    my %conf;

    foreach my $conf_type ( qw(system global) ){
        my $method = $conf_type.'_conf_filename';
        my $path = $ps->path('conf', $ps->global->$method );

        if ( ! -f $path ){
            $self->print_intro;
            $self->print_setup_help;
            exit;
        }    

        $conf{$conf_type} = MooseX::ConfigCascade::Util->parser->( $path );
    }
    my $conf = merge( $conf{global}, $conf{"system"} );
    MooseX::ConfigCascade::Util->conf( $conf );

    $self->pod_reader->settings( TaskPipe::PodReader::Settings->new );


    $self->options->add_specs([{
        module => 'TaskPipe::PathSettings::Global',
        is_config => 1,
        items => [
            'root_dir',
            'global_dir',
            'global_conf_dir',
            'global_conf_filename',
            'system_conf_filename',
            'project'
        ]
    }, {
        module => 'TaskPipe::LoggerManager::Settings',
        is_config => 1,
        items => [
            'log_mode',
            'log_level',
            'log_file_access',
            'log_file_pattern',
            'log_screen_pattern'
        ]
    }]);

    $self->options->load;
    $ps = TaskPipe::PathSettings->new( scope => 'global' );

    my $global_lib_path = $ps->path('lib');

    confess "Could not find global lib dir. Looked in $global_lib_path" unless -d $global_lib_path;
    push @INC, $global_lib_path;
    
    return unless $ps->global->project;
    $ps->scope('project');
    my $project_conf_path = $ps->path('conf', $ps->filename('conf') );
    
    return unless -f $project_conf_path;

    my $global_conf = clone +MooseX::ConfigCascade::Util->conf;
    my $project_conf = MooseX::ConfigCascade::Util->parser->( $project_conf_path );

    $conf = merge( $project_conf, $global_conf );
    MooseX::ConfigCascade::Util->conf( $conf );

    my $path_settings = TaskPipe::PathSettings->new( project_name => $ps->global->project );
    my $lib_dir = $path_settings->path('lib');

    return unless $lib_dir && -d $lib_dir;

    push @INC, $lib_dir;

}



sub print_intro{
    my ($self) = @_;

    my $max_cols = 76;

    my $items = [{
        text => "TaskPipe Utility v".$VERSION,
        color => 'bright_white'
    }, {
        text => "Tom Gracey (c) Virtual Blue LTD 2018",
        color => 'bright_magenta'
    }];

    print "\n";
    foreach my $item (@$items){
        my $spaces = int( 0.5 * ( $max_cols - length( $item->{text} ) ) );

        my $text;
        if ( isatty(*STDOUT) ){
            $text = colored( $item->{text}, $item->{color} );
        } else {
            $text = $item->{text}
        }

        print ' ' x $spaces;
        print $text."\n";
    }

    print "\n";
}


sub print_setup_help{
    my ($self) = @_;

    my $home_dir = File::Save::Home::get_home_directory();
    my $suggested_global_root = File::Spec->catdir( $home_dir, 'taskpipe' );
    my $ps = TaskPipe::PathSettings->new( scope => 'global' );

    my $message = qq|B<STOP!> 

I couldn't find a path to one or more of the global configuration files. These files are named: |;

    $message.="\n\n   ".$ps->global->global_conf_filename;
    $message.="\n\n   ".$ps->global->system_conf_filename;
    $message.="\n\nI looked in the following directory:";
    $message.="\n\n   ".$ps->path('conf');

    $self->pod_reader->message( $message );

}





sub dispatch{
    my $self = shift;

    $self->get_cmd;
    my $cmd = lc($self->run_info->cmd->[0]);

    if ( ! @{$self->run_info->cmd} || $cmd eq 'help' ){

        $self->get_conf;
        $self->help;

    } elsif( $cmd eq 'options' ){

        $self->get_conf;
        $self->options;

    } else {

        $self->get_conf unless $cmd eq 'setup';
        $self->run_cmd;

    }
}



sub init_logger{
    my ($self,$job_id) = @_;

#    my $run_info = TaskPipe::RunInfo->new(
#        orig_cmd => $self->orig_cmd,
#        job_id => $job_id,
#        thread_id => 1
#    );      

    my $lm = TaskPipe::LoggerManager->new;
    $lm->init_logger;
}


sub run_cmd{
    my $self = shift;

    my $module = $self->require_handler( @{$self->run_info->cmd} );
    my $handler = $module->new;

    if ( $handler->can('option_specs') ){

        $self->options->add_specs( $handler->option_specs );

    }

    $self->options->load;

    $handler = $module->new;

    my $cmd = lc($self->run_info->cmd->[0]);
    $handler->job_manager->init_job;
    $self->init_logger;
    $handler->execute;
    $handler->job_manager->end_job;

}



sub require_handler{
    my ($self,@cmd) = @_;

    confess "Need a command" unless @cmd;

    my @filenames = @{$self->list_of_command_filenames};

    my $frag = camelize(join('_',@cmd));
    my ($filename) = grep{ $_ =~ /_$frag\.pm$/ } @filenames;

    confess "Could not find a handler for command '@cmd'" unless $filename;
    my $module = $self->command_filename_to_module( $filename );

    try {

        require_module( $module );

    } catch {

        confess "Handler for command '@cmd' ($module) appears to be broken: $_";

    };

    return $module;
}



sub help{
    my $self = shift;

    my @cmd = @{$self->run_info->cmd};

    $self->print_intro;

    if ( @cmd <= 1 ){

        my $pod = $self->tool_pod;
        $pod.="\n\n=head1 AVAILABLE COMMANDS\n\n";

        foreach my $li (@{$self->available_commands_list}){
            $pod.="\n\n=head2 ".$li->{cmd}."\n\n".$li->{description};
        }

        $self->pod_reader->message( $pod );
        return;

    }

    my $module = $self->require_handler(@cmd[1..$#cmd]);
    my $handler = $module->new;

    if ( $handler->can('option_specs') ){

        $self->options->add_specs( $handler->option_specs );

    }



    my $print_pod = "=head1 USAGE\n\n taskpipe @cmd[1..$#cmd] <options>\n\nOptions are in B<long> format (space separated and preceded by double dash, e.g. C<--option=value>). See list below for available options\n\n"; 


    foreach my $head1 ( $self->get_pod( $module )->head1 ){
        $print_pod.="\n$head1\n" if $head1->title =~ /^(purpose|description)$/i;
    }


    my $opt_pod = '';
    foreach my $option_name ( sort keys %{$self->options->specs} ){
        my $v = $self->options->specs->{$option_name};

        $opt_pod.="=item --".$v->{pod}->title()."\n\n";
        $opt_pod.=$v->{pod}->content()."\n\n";
        chomp( $opt_pod );

        if ( $v->{module} ){

            my $mod_details = '';
            $mod_details.="\n\n=item *\n\nCan be set in config section \"".$v->{module}.qq|"| if $v->{is_config};

            if ( $v->{default} ){
                $Data::Dumper::Terse = 1;
                my $default = '"'.$v->{default}.'"';
                $default = Dumper( $v->{default} ) if ref $v->{default};
                $mod_details.="\n\n=item *\n\nDefaults to $default if not declared ";
                $mod_details.="in config or " if $v->{is_config};
                $mod_details.="on command line";
            }
    
            $opt_pod.= "\n\n=over$mod_details\n\n=back" if $mod_details;
            
        }
        $opt_pod.="\n\n";

    }
   
    $self->pod_reader->message( $print_pod."\n=head1 OPTIONS\n\n=over\n\n$opt_pod\n\n=back\n\n" );
    
}
    


sub list_of_command_filenames{
    my ($self) = @_;

    my $path = abs_path( __FILE__ );
    $path =~ s/\.pm$//;

    opendir my $dh, $path or confess "Could not open '$path' for reading: $!";

    my $list = [];
    while( my $filename = readdir $dh ){
        next if $filename =~ m/^\./;
        next if $filename !~ /^Command_/;
        next if $filename =~ /__[^_]+\.pm$/;
        push @$list, $filename
    }
    return $list;
}



sub available_commands_list{
    my ($self) = @_;

    my @filenames = @{$self->list_of_command_filenames};

    my $delim = File::Spec->catdir('');

    my $list = [];
    foreach my $filename (@filenames){

        my $command = $filename;
        $command =~ s{^Command_}{};
        $command =~ s{^_[A-Za-z0-9]+}{};
        $command =~ s{\.pm$}{};
        $command =~ s{^\w_}{};

        my @cmd = map {lc} wordsplit($command);
        
        my $module = $self->command_filename_to_module( $filename );

        my $pod = $self->get_pod( $module );
        my $section = 'PURPOSE';
        my ($head1) = grep { $_->title eq $section } $pod->head1;

        my $cmd_str = join(' ',@cmd);
        my $desc = $head1?$head1->content:'';

        my $li = { 
            cmd => $cmd_str,
            description => $desc
        };
        push @$list, $li;
    }
    return $list;
}


sub command_filename_to_module{
    my ($self,$filename) = @_;

    my $module = __PACKAGE__.'::'.$filename;
    $module =~ s/\.pm$//;

    return $module;
}

        
        
sub get_pod{

    my ($self,$module) = @_;

    confess "Need a module name" unless $module;

    my $parser = Pod::POM->new;

    require_module( $module );

    my $filename = $module;
    my $delim = File::Spec->catdir('');
    $filename=~ s{::}{$delim}g;    
    $filename.='.pm';

    my $path = abs_path( $INC{ $filename } );
    my $pod = $parser->parse_file( $path );

    return $pod;
}
    

sub tool_pod{
    my ($self) = @_;

    return qq|=head1 TaskPipe Command Line Utility

Welcome to TaskPipe! TaskPipe is a task-management framework for building scrapers and crawlers.

For more general information about TaskPipe see L<TaskPipe::Manual::Overview>.

A list of available commands is given below. For more detailed information about a specific command, type

    taskpipe help <command>

For example

    taskpipe help setup

|;

}

=head1 NAME

TaskPipe::Tool - the base class for the TaskPipe command line tool

=head1 DESCRIPTION

This class houses the operations needed by the L<taskpipe> script. It is not recommended to use this package directly. See the manpage for L<TaskPipe::Tool::Command> for information on creating a new taskpipe command. 

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;        
1;




            
