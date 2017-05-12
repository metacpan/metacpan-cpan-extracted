package TestClass;
use strict;
use warnings;
use lib 't/';
use base 'REST::Application';

sub foo { "foo" }
sub barMethod { shift; return join(":", @_) }
sub GET { "xAbC" }
sub DELETE { "xAbC" }
sub PUT { "xAbC" }
sub POST { "xAbC" }
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
    $self->{preHandler} = join(":", @$args);
}

sub postHandler {
    my ($self, $outputRef, $args) = @_;
    return if not $self->{TEST_POST};
    shift @$args;  # drop the ref to the REST::Application object
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

    my ($handler, @extraArgs) = @_;

    return ref($handler) . join(":", @extraArgs);
}

sub makeHandlerFromClass {
    my $self = shift;
    return $self->SUPER::makeHandlerFromClass(@_) unless $self->{TEST_MHFC};
    my ($class, $method) = @_;
    return sub { "$class $method" };
}

sub makeHandlerFromRef {
    my $self = shift;
    return $self->SUPER::makeHandlerFromRef(@_) unless $self->{TEST_MHFR};
    my ($obj, $method) = @_;
    return sub { "SMOKE " . ref($obj). " $method" };
}

1;
