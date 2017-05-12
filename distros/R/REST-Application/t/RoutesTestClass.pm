package RoutesTestClass;
use strict;
use warnings;
use lib 't/';
use base 'REST::Application::Routes';

sub foo { "foo" }
sub barMethod { shift; shift; return join(":", @_) }
sub GET { "xAbC" }
sub PUT { "xAbC" }
sub POST { "xAbC" }
sub DELETE { "xAbC" }
sub getRepresentation { "qWeRtY" }
sub preRun { shift->{preRun} = 1 }
sub postRun { 
    my ($self, $outputRef) = @_; 
    $self->{postRun} = $$outputRef 
}

sub getMatchText {
    my $self = shift;

    if ($self->{TEST_TEXT}) {
        return $self->{TEST_TEXT};
    }

    return $self->getPathInfo();
}

sub checkMatch {
    my $self = shift;
    my ($a, $b) = @_;

    if ($self->{TEST_MATCH}) {
        return ($a eq $b);
    }

    return $self->SUPER::checkMatch($a, $b);
}

sub preHandler {
    my $self = shift;
    my $args = shift;
    return if not $self->{TEST_PRE};
    shift @$args;  # drop the ref to the REST::Application object
    shift @$args;  # drop the variable args
    $self->{preHandler} = join(":", @$args);
}

sub postHandler {
    my ($self, $outputRef, $args) = @_;
    return if not $self->{TEST_POST};
    shift @$args;  # drop the ref to the REST::Application object
    shift @$args;  # drop the variable args
    $self->{postHandler} = $$outputRef . join(":", @$args);
}

sub callHandler {
    my $self = shift;
    if (not $self->{TEST_CALL}) {
        return $self->SUPER::callHandler(@_);
    } elsif ($self->{TEST_CALL_ERROR}) {
        my $handler = shift;
        $handler->();
    }

    my ($handler, $v, @extraArgs) = @_;

    return ref($handler) . join(":", @extraArgs);
}

1;
