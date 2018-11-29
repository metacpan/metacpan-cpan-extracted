package TaskPipe::PodReader;

use Moose;
use Cwd 'abs_path';
use Pod::POM;
use Data::Dumper;
use POSIX qw(isatty);
use Module::Runtime 'require_module';
use Pod::Term;


has settings => (is => 'rw', isa => __PACKAGE__.'::Settings', default => sub{
    my $module = __PACKAGE__.'::Settings';
    require_module( $module );
    $module->new;
});


sub read_pod{

    my ($self,$module) = @_;

    confess "Need a module name" unless $module;

    my $parser = Pod::POM->new;

    $module ||= ref( $self );
    require_module( $module );

    my $filename = $module;

    #my $delim = File::Spec->catdir(''); # %INC seems to have unix style delims, even on windows
    my $delim = '/';

    $filename=~ s{::}{$delim}g;    
    $filename.='.pm';

    my $path = abs_path( $INC{ $filename } );
    my $pod = $parser->parse_file( $path );

    return $pod;
}


sub message{
    my ($self,$pod) = @_;

    my $parser = Pod::Term->new;
    $parser->globals({
        max_cols => 76,
        base_color => undef
    });

    if (isatty(*STDOUT)){
        $parser->prop_map( $self->settings->pod_format );
    } else {
        $parser->prop_map( $self->settings->pod_format_mono );
    }

    $parser->parse_string_document( "=pod\n\n$pod\n\n=cut\n\n" );
}


        
sub format_error_message{
    my ($self,$err) = @_;

    my $trace;
    my $at;

    if ( $err =~ /^\[/ ){
        ($err,$at,$trace) = $err =~ /\[([^\]]+?)\]\s*([^\n]+)\n(.*?)$/s;
    }

    if ($trace){
        $trace =~ s/^\s*//s;
        $trace =~ s/\n\s*/\n\n/g;
        $err .= "B<($at)>\n\nI<Stack trace follows (most recent call first):>\n\n$trace\n";
    } else {

        $err = "B<$err";
        $err =~ s/\s*$//s;

        if ( $err =~ /\n/ ){
            $err =~ s/\n/>\nI<Stack trace follows (most recent call first):>\n/;
        } else {
            $err .= '>';
        }
        $err =~ s/\n\s*/\n\n/g;

    }

    return $err;
}

=head1 NAME

TaskPipe::PodReader - read POD for TaskPipe

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
