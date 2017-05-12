package Spike::Site::Request;

use strict;
use warnings;

use base qw(Plack::Request Spike::Object);

use Spike::Site::Response;
use List::Util qw(min);

sub new_response { shift; Spike::Site::Response->new(@_) }

sub _bind_named_url_parameters {
    my $self = shift;

    my $bind = $self->env->{'spike.request.named_url_parameters'} = [];

    while (@_) {
        my ($name, $value) = splice @_, 0, 2;

        last if !defined $name;
        next if $name !~ s!^#!!;

        push @$bind, $name, $value;
    }

    delete $self->env->{'spike.request.named_url'};
    delete $self->env->{'spike.request.merged'};
}

sub _named_url_parameters {
    my $self = shift;
    $self->env->{'spike.request.named_url_parameters'} ||= [];
}

sub named_url_parameters {
    my $self = shift;
    $self->env->{'spike.request.named_url'} ||= Hash::MultiValue->new(@{$self->_named_url_parameters});
}

sub parameters {
    my $self = shift;

    $self->env->{'spike.request.merged'} ||= Hash::MultiValue->new(
        $self->SUPER::parameters->flatten,
        @{$self->_named_url_parameters},
    );
}

sub safe_path {
    my $self = shift;

    if (!defined $self->env->{'spike.request.safe_path'}) {
        my @parts;

        for my $part (grep { defined && length } split m!/+!, $self->path_info) {
            $part =~ s!\0!!g;

            if ($part eq '.') {
                # do nothing
            }
            elsif ($part eq '..') {
                pop @parts;
            }
            else {
                push @parts, $part;
            }
        }

        $self->env->{'spike.request.safe_path'} = join '/', @parts;
    }
}

1;
