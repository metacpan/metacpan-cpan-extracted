package TaskPipe::InterpParam::MatchHandler;

use Moose;
use Clone 'clone';
use Carp;

has input => (is => 'rw', isa => 'HashRef', required => 1);
has input_history => (is => 'rw', isa => 'ArrayRef', required => 1);
has param => (is => 'rw', isa => 'HashRef', required => 1);
has param_history => (is => 'rw', isa => 'ArrayRef', required => 1);
has parts => (is => 'rw', isa => 'TaskPipe::InterpParam::Parts', required => 1);

sub name{ my ($n) = ref($_[0]) =~ /^${\__PACKAGE__}_(\w+)$/; $n; }

sub interp{
    my $self = shift;

    my $i = $self->match_index;

    return undef unless defined $i;

    $i += $self->parts->match_offset;
    $i += $self->match_adjustment if $self->can('match_adjustment');
 
    return undef if ($i > scalar(@{$self->param_history}) || $i < 0 );

    my $input_i;

    if ( $i == 0 ){

        $input_i = $self->input;

    } else {

        $input_i = $self->input_history->[ $i - 1 ];

    }

    my $key = $self->parts->input_key;

    if ( $key && $key eq '*' ){
        return +clone $input_i;
    }

    $key ||= $self->parts->param_key;

    confess "Can't determine which input to get interp result from (no key name specified)" unless $key;

    return $input_i->{$key};

}



sub match_index{
    my $self = shift;

    my $match_count = $self->parts->match_count;

    my @param = ( $self->param, @{$self->param_history} );

    my $match_i;
    for my $i (0..$#param){

        if ( $self->match_condition( $param[$i] ) ){

            if ( $match_count == 0 ){
                $match_i = $i;
                last;
            }

            $match_count--;

        }

    }

    return $match_i;
}


sub match_condition{
    my ($self,$param) = @_;

    confess "No name" unless $self->name;
    my $pval = $param->{'_'.$self->name};
    $pval && $pval eq $self->parts->label_val?1:0;
        
}      


sub format_valid{
    my $self = shift;

    my $valid = 1;
    $valid = 0 unless $self->parts->label_val;
    return $valid;

}

=head1 NAME

TaskPipe::InterpParam::MatchHandler - handling matching of parameter values in the plan

=head1 DESCRIPTION

L<TaskPipe::MatchHandler> is the base class responsible for interpolating parameters in the plan which are set as a particular variable (e.g. C<$this>). To create a match handler for a new variable, this class should be inherited from. The minimum package to create a new plan variable is the empty package which inherits from L<TaskPipe::MatchHandler>:

    package TaskPipe::InterpParam::MatchHandler_myvar;
    use Moose;
    extends 'TaskPipe::InterpParam::MatchHandler';
    1;

This defines a parameter variable C<$myvar> which behaves just like C<$id>. The variable is taken from the name of the package. 

If you add this module and TaskPipe sees C<$myvar> in the plan, it will look for the label C<_myvar> and replace the input in the same way as it would for C<_id>.

Why would you want to do this? I have no idea. It's probably more likely that, if you are wanting to create a new parameter variable, you want it to have some unique behaviour.

In this case you may want to override one or more of the methods C<match_condition>, C<format_valid> and/or C<match_index>.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;

1;
