# a small package to capture standard output, so that we can test the
# output of Tangram::Relational->deploy()

{
package Capture;

sub new {
    my $class = shift;
    my $self = { stdout => "" };
    bless $self, $class;
    return $self;
}

sub capture_print {
    my $self = shift;
    $self->{so} = tie(*STDOUT, __PACKAGE__, \$self->{stdout})
        or die "failed to tie STDOUT; $!";
}

sub release_stdout {
    my $self = shift;
    delete $self->{so};
    untie(*STDOUT);
    return $self->{stdout};
}

sub TIEHANDLE {
    my $class = shift;
    my $ref = shift;
    return bless({ stdout => $ref }, $class);
}

sub PRINT {
    my $self = shift;
    ${$self->{stdout}} .= join('', map { defined $_?$_:""} @_); 
}

sub PRINTF {
    my ($self) = shift;
    print STDERR "OUCH @_\n";
    my ($fmt) = shift;
    ${$self->{stdout}} .= sprintf($fmt, @_)
        if (@_);
}

sub glob {
    return \*STDOUT;
}
}
1;
