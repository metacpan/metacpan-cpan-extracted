package Net::Riak::MapReducePhase;
{
  $Net::Riak::MapReducePhase::VERSION = '0.1702';
}

use Moose;
use Scalar::Util;
use JSON;

has type     => (is => 'rw', isa => 'Str',      required => 1,);
has function => (is => 'ro', isa => 'Str',      required => 1);
has arg      => (is => 'ro', isa => 'ArrayRef', default  => 'None');
has language => (is => 'ro', isa => 'Str',      default  => 'javascript');
has keep => (is => 'rw', isa => 'JSON::Boolean', default => sub {JSON::false});

sub to_array {
    my $self = shift;

    my $step_def = {
        keep     => $self->keep,
        language => $self->language,
        arg      => $self->arg
    };

    if ($self->function =~ m!\{!) {
        $step_def->{source} = $self->function;
    }else{
        $step_def->{name} = $self->function;
    }
    return {$self->type => $step_def};
}

1;

__END__

=pod

=head1 NAME

Net::Riak::MapReducePhase

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
