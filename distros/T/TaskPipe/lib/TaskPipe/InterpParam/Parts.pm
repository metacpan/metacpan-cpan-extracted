package TaskPipe::InterpParam::Parts;

use Moose;
use Carp;
use Data::Dumper;

#
#   task:
#       _name: SomeTaskName
#       <param_key>: <param_val>
#
#   where <param_val> breaks down as:
#
#   $<label_key>:<label_val>(<match_count>)[<match_offset>]{input_key}



has param_key => (is => 'rw', isa => 'Str');
has param_val => (is => 'rw', isa => 'Str');

has label_key => (is => 'rw', isa => 'Str');
has label_val => (is => 'rw', isa => 'Str');
has match_count => (is => 'rw', isa => 'Int', default => 0);
has match_offset => (is => 'rw', isa => 'Int', default => 0);
has input_key => (is => 'rw', isa => 'Str');


sub load{
    my $self = shift;

    confess "param_val must be provided" unless $self->param_val;

    my %p;
    ($p{label_key},
    $p{label_val},
    $p{match_count},
    $p{match_offset},
    $p{input_key})
        = $self->param_val =~ /^\$(\w+)(:\w+|)(\(\s*\d+\s*\)|)(\[\s*\d+\s*\]|)(\{\s*(?:\w+|\*)\s*\}|)\s*$/;

    foreach my $k ( keys %p ){
        next unless $p{$k};
        $p{$k} =~ s/\s+//g;
        $p{$k} =~ s/[^\w\*]+//g;
    }

    $p{match_count} ||= 0;
    $p{match_offset} ||= 0;
    $p{input_key} ||= '';

    foreach my $k ( keys %p ){
        $self->$k( $p{$k} ) if defined $p{$k};
    }

}

=head1 NAME

TaskPipe::InterpParam::Parts - module determining the parts of a plan parameter variable

=head1 DESCRIPTION

A class to store the different parts of a parameter variable. It is not recommended to use this module directly. See the general manpages for TaskPipe.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;

1;
