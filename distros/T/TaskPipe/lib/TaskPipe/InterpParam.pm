package TaskPipe::InterpParam;

use Moose;
use Try::Tiny;
use Module::Runtime 'require_module';
use TaskPipe::InterpParam::Parts;
use Log::Log4perl;
use Data::Dumper;

has input => (is => 'rw', isa => 'HashRef');
has input_history => (is => 'rw', isa => 'ArrayRef');
has param => (is => 'rw', isa => 'HashRef');
has param_history => (is => 'rw', isa => 'ArrayRef');
has parts => (is => 'rw', isa => 'TaskPipe::InterpParam::Parts', default => sub{
    TaskPipe::InterpParam::Parts->new;
});


sub interp{
    my $self = shift;

    my @ih = ( $self->input, @{$self->input_history} );

    return +$self->interp_hash( $self->param );
}



sub interp_kv{
    my ($self,$key,$val) = @_;

    my $interp;
    if ( ref $val eq ref {} ){
        $interp = $self->interp_hash( $val );
    } elsif ( ref $val eq ref [] ){
        $interp = $self->interp_array( $val );
    } else {
        $interp = $self->interp_string( $key, $val );
    }
    return $interp;
}


    

sub interp_hash{
    my ($self,$h) = @_;

    my $interp = {};
    foreach my $key (keys %$h){

        $key =~ s/^\s+//;
        next if $key =~ /^_/;
        $key =~ s/\s+$//;
        
        my $val = $h->{$key};

        $interp->{$key} = $self->interp_kv($key,$val);

    }

    return $interp;
}


sub interp_array{
    my ($self,$arr) = @_;

    my $interp = [];
    foreach my $val ( @$arr ){
        push @$interp,+$self->interp_kv(undef,$val);
    }
    return $interp;
}



sub interp_string{
    my ($self,$key,$val) = @_;

    $val =~ s/^\s*//;
    $val =~ s/\s*$//;

    return $val unless $val =~ m{^\$};

    $self->parts->param_key( $key ) if $key;
    $self->parts->param_val( $val );
    $self->parts->load;

    confess "Error in param set ".Dumper( $self->param ).": Could not determine a label key from '$val'" unless $self->parts->label_key;

    my $mh_module = __PACKAGE__.'::MatchHandler_'.$self->parts->label_key;

    try {

        require_module( $mh_module );

    } catch {

        confess "Error in param set ".Dumper( $self->param ).": Failed to find a match handler for label '".$self->parts->label_key."': module $mh_module missing or broken. Error reported was: $_";

    };

    my $mh = $mh_module->new(
        input => $self->input,
        input_history => $self->input_history,
        param => $self->param,
        param_history => $self->param_history,
        parts => $self->parts
    );

    confess "Error in param set ".Dumper( $self->param ).': Invalid format for variable $'.$self->parts->label_key unless $mh->format_valid;

    return $mh->interp;
}



=head1 NAME

TaskPipe::InterpParam - Parameter value interpolator for TaskPipe

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

