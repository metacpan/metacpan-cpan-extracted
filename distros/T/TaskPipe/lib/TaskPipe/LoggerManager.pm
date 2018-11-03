package TaskPipe::LoggerManager;

use Moose;
with 'MooseX::ConfigCascade';

use Log::Log4perl;
use TaskPipe::PathSettings;
use TaskPipe::LoggerManager::Settings;
use Template::Nest;
use TaskPipe::RunInfo;
use Data::Dumper;
use DateTime;
use Try::Tiny;
use File::Path 'make_path';
use Carp;

has path_settings => (is => 'ro', isa => 'TaskPipe::PathSettings', default => sub{
    TaskPipe::PathSettings->new;
});
has settings => (is => 'ro', isa => 'TaskPipe::LoggerManager::Settings', default => sub{
    TaskPipe::LoggerManager::Settings->new;
});
has foreground => (is => 'rw', isa => 'Bool', default => 1);

sub init_logger{
	my $self = shift;

    Log::Log4perl->init( $self->logging_settings );

}

has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});

#has job_id => (is => 'rw', isa => 'Int');
#has run_id => (is => 'rw', isa => 'Int');
#has thread_id => (is => 'rw', isa => 'Int',default => 1);
#has task_name => (is => 'rw', isa => 'Str');

has custom_cspecs => (is => 'ro', isa => 'HashRef', default => sub{{
    J => 'job_id',
    #i => 'run_id',
    h => 'thread_id',
    N => 'task_name'
}});

#has name => (is => 'rw', isa => 'Maybe[Str]', lazy => 1, default => sub{
#    my $self = shift;
#    my $tid = $self->path_settings->project->task_identifier;
#    my ($name) = ref($self) =~ /$tid(\w+)$/;
#    return $name;
#});




sub logging_settings{
    my $self = shift;

    my %c;

    my $c = $self->settings;

    my %s;
    $s{rootLogger} = $c->log_level;

    my $log_methods = $self->get_log_methods;


    if ( $log_methods->{screen} ){
        $s{'rootLogger'}.=', SCREEN';
        $s{'appender.SCREEN'} = 'Log::Log4perl::Appender::Screen';
        $s{'appender.SCREEN.color.DEBUG'} = 'white';
        $s{'appender.SCREEN.color.INFO'} = 'bold white';
        $s{'appender.SCREEN.stderr'}  = '0';
        $s{'appender.SCREEN.layout'} = 'Log::Log4perl::Layout::ColoredPatternLayout';

        $s{'appender.SCREEN.layout.ConversionPattern'}=$c->log_screen_pattern;
        $s{'appender.SCREEN.layout.ColorMap'} = $self->build_color_map;
        $s{'appender.SCREEN.layout.ColorMap'} =~ s/\n//g;
        $s{'appender.SCREEN.layout.ColorStyle'} = 'continuous';
        $self->add_custom_cspecs( \%s,'SCREEN' );
    } 

    if ( $log_methods->{file} ){

        $s{'rootLogger'}.=', LOGFILE';
        $s{'appender.LOGFILE'}='Log::Log4perl::Appender::File';
        $s{'appender.LOGFILE.filename'}= $self->get_log_path;
        $s{'appender.LOGFILE.mode'}= $c->log_file_access;
        $s{'appender.LOGFILE.layout'}='PatternLayout';
        $s{'appender.LOGFILE.layout.ConversionPattern'} = $c->log_file_pattern;
        $self->add_custom_cspecs( \%s, 'LOGFILE' );
    } 

#    print "s: ".Dumper( \%s )."\n";
    return \%s;

}


sub get_log_methods{
    my ($self) = @_;

    my $log_mode = $self->settings->log_mode;
    my $log_methods = {'screen' => 1 };
    $log_methods = {'file' => 1 } if $log_mode eq 'file';
    $log_methods = {'file' => 1 } if ( $log_mode eq 'shell' && $self->run_info->shell eq 'background');
    $log_methods->{'file'} = 1 if $log_mode eq 'both';
    $log_methods = {} if $log_mode eq 'none';

    return $log_methods;
}
 


sub add_custom_cspecs{
    my ($self,$s,$appender) = @_;

    foreach my $cspec (keys %{$self->custom_cspecs}){
        my $method = $self->custom_cspecs->{$cspec};
        my $var = $self->run_info->$method || '?';
        $s->{"appender.$appender.layout.cspec.$cspec"} = "sub{ return '$var'; }";
    }
}


sub get_log_path{
    my ($self) = @_;

    my $dt = DateTime->now;

    my $nest = Template::Nest->new( template_hash => {
        log_dir_format => +$self->settings->log_dir_format,
        filename_format => +$self->settings->log_filename_format
    });

    my @cmd;

    my $dir = $self->path_settings->path(
        'log', $dt->ymd, 
        +$nest->render({ 
            NAME => 'log_dir_format',
            job_id => $self->run_info->job_id,
            cmd => +join('-',@{$self->run_info->cmd})
        })
    );

    if ( ! -d $dir ){

        try {

            make_path( $dir );

        } catch {

            confess "Could not create directory $dir: $_";

        };

    }

    my $filename = $nest->render({ 
        NAME => 'filename_format',
        thread_id => +$self->run_info->thread_id || 1
    });
    
    my $log_path = +File::Spec->catdir( $dir, $filename );
    #print "log path is: ".$log_path."\n";
    return $log_path;

}
    


sub build_color_map{
    my ($self) = @_;

    local $Data::Dumper::Terse = 1;

    my @kv;
    my %sc = %{$self->settings->log_screen_colors};
    foreach my $cspec ( keys %sc ){
        my $cspec_str;
        if ( ref $sc{$cspec} eq ref {} ){
            $cspec_str = $cspec
                .' => sub { my($val) = @_; my $case = '
                .Dumper( $sc{$cspec} )
                .'; return +$case->{ $val }; }';
            $cspec_str =~ s/\n//gs;
        } else {
            $cspec_str = "'".$cspec."' => '".$sc{$cspec}."',";
        }
        push @kv,$cspec_str;
    }

    my $color_map = 'sub { return { '.join( ', ', @kv ).'}}';
    return $color_map;
}
    

=head1 NAME

TaskPipe::LoggerManager - Logging manager for TaskPipe

=head1 DESCRIPTION

It is not recommended to use this module directly. See the general manpages for TaskPipe

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
	
	
