package Net::Riak::LinkPhase;
{
  $Net::Riak::LinkPhase::VERSION = '0.1702';
}

use Moose;
use JSON;

has bucket => (is => 'ro', isa => 'Str', required => 1);
has tag    => (is => 'ro', isa => 'Str', required => 1);
has keep   => (is => 'rw', isa => 'JSON::Boolean', required => 1);

sub to_array {
    my $self     = shift;
    my $step_def = {
        bucket => $self->bucket,
        tag    => $self->tag,
        keep   => $self->keep,
    };
    return {link => $step_def};
}

1;

__END__

=pod

=head1 NAME

Net::Riak::LinkPhase

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
