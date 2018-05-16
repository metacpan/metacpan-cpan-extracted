package TaskPipe::Tool::Options;

use Moose;
use Getopt::Long qw(:config pass_through);
use MooseX::ConfigCascade::Util;
use TaskPipe::PodReader;
use Module::Runtime 'require_module';
use Data::Dumper;
use Carp;

has specs => (is => 'rw', isa => 'HashRef', default => sub{{}});
has specs_by_module => (is => 'rw', isa => 'HashRef', default => sub{{}});
has args => (is => 'rw', isa => 'HashRef');

has pod_reader => (is => 'rw', isa => 'TaskPipe::PodReader', default => sub{
    TaskPipe::PodReader->new;
});


sub load{
    my $self = shift;

    confess "args is not defined (call get_args first?)" unless defined $self->args;

    foreach my $name (keys %{$self->specs}){
        

        my $val = $self->args->{$name};
        my $type = $self->specs->{$name}->{type};
        MooseX::ConfigCascade::Util->conf->{ $self->specs->{$name}->{module} }->{$name} = $val if defined $val;

    }

}


sub get_args{
    my ($self) = @_;

    my $arg_sets = [];
    my $arg_set = [];
    foreach my $arg (@ARGV){

        if ( $arg =~ /^--/ ){
            push @$arg_sets,$arg_set if @$arg_set;
            $arg_set = [$arg];
        } else {
            push @$arg_set,$arg if @$arg_set;
        }
    }
    push @$arg_sets,$arg_set if @$arg_set;

    my $arg_strings = [];
    foreach my $arg_set (@$arg_sets){
        my $arg_string = join(' ',@$arg_set);
        push @$arg_strings,$arg_string;
    }

    my $args = {};
    foreach my $arg_string (@$arg_strings ){
        my ($key,$val) = split /[=\s]+/, $arg_string, 2;
        $key =~ s/^\s*--//;
        $key =~ s/\s*$//;
        $val =~ s/^\s*//;
        $val =~ s/\s*$//;
        $args->{$key} = $val;
    }

    $self->args( $args );
    return $args;
}




sub add_specs{
    my ($self,$specs) = @_;

    foreach my $spec (@$specs){

        my %opt;
        if ( ref $spec eq ref {} ){
            %opt = %$spec;
        } elsif ( ref $spec eq ref '') {
            %opt = ( module => $spec );
        }    

        confess "A module name must be specified" unless $opt{module};
        my $is_config = 0;
        $is_config = 1 if $opt{is_config};

        my $options_section;

        if ( $is_config ){
            $options_section = $opt{section} || 'METHODS';
        } else {
            $options_section = $opt{section} || 'OPTIONS';
        }

        
        my $pod = $self->pod_reader->read_pod( $opt{module} );

        my ($head1) = grep { $_->title eq $options_section } $pod->head1;

        confess "No $options_section section found in $opt{module}" unless $head1;
        confess "No 'over' section in $opt{module}" unless $head1->over->[0];

        my @opt_items = $head1->over->[0]->item;


        my $loaded = $opt{module}->new;
        my $defaults = $self->get_defaults( $opt{module} );

        my $module_conf = {};
        foreach my $opt_item (@opt_items){

            next if $opt{items} && ! grep { $_ eq $opt_item->title } @{$opt{items}};
            next if $opt{exclude} && grep { $_ eq $opt_item->title } @{$opt{exclude}};

            my $opt_method = $opt_item->title;
            confess "method $opt_method specfied in pod, but no attribute exists in $opt{module}" unless $opt{module}->can($opt_method);

            my ($attr) = grep { $_->name eq $opt_method } $opt{module}->meta->get_all_attributes;

            my $constraint = $attr->type_constraint;

            
            $module_conf->{$opt_method} = $loaded->$opt_method;
            $self->specs->{$opt_method} = {

                pod => $opt_item,
                default => $defaults->$opt_method,
                module => $opt{module},
                is_config => $opt{is_config} || 0

            };
        
        }

        $self->specs_by_module->{ $opt{module} } = $module_conf;
    }
}
    

sub get_defaults{
    my ($self,$module) = @_;

    my $current_conf = MooseX::ConfigCascade::Util->conf;
    MooseX::ConfigCascade::Util->conf({});
    require_module( $module );
    my $defaults = $module->new;
    MooseX::ConfigCascade::Util->conf( $current_conf );

    return $defaults;
}


=head1 NAME

TaskPipe::Tool::Options - handles command line options for TaskPipe Tool

=head1 DESCRIPTION

This is the module responsible for loading and managing parameters specified at the command line when running the C<taskpipe> script

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
