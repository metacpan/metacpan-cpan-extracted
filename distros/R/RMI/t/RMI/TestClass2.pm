
package RMI::TestClass2;
use base 'RMI::TestClass';

sub create_and_return_arrayref {
    my $self = shift;
    my $a = $self->{last_arrayref} = [@_];
    Scalar::Util::weaken($self->{last_arrayref});
    return $a;
}

sub last_arrayref {
    my $self = shift;
    return $self->{last_arrayref};    
}

sub last_arrayref_as_string {
    my $self = shift;
    my $s = join(":", @{ $self->{last_arrayref} });
    return $s;
}

sub create_and_return_hashref {
    my $self = shift;
    my $a = $self->{last_hashref} = {@_};
    Scalar::Util::weaken($self->{last_hashref});
    return $a;
}

sub last_hashref_as_string {
    my $self = shift;
    my $s = join(":", map { $_ => $self->{last_hashref}{$_} } sort keys %{ $self->{last_hashref} });
    return $s;
}

sub create_and_return_scalarref {
    my $self = shift;
    my $s = shift;
    my $r = $self->{last_scalarref} = \$s;
    Scalar::Util::weaken($self->{last_scalarref});
    return $r;
}

sub last_scalarref_as_string {
    my $self = shift;
    return ${$self->{last_scalarref}};
}

sub create_and_return_coderef {
    my $self = shift;
    my $src = shift;
    my $sub = eval $src;
    die "bad source: $src\n$@\n" if $@;
    die "source did not return a CODE ref: $src" unless ref($sub) eq 'CODE';
    $self->{last_coderef} = $sub;
    Scalar::Util::weaken($self->{last_coderef});
    return $sub;
}

sub call_my_sub {
    my $self = shift;
    my $sub = shift;
    return $sub->(@_);
}

sub increment_array {
    my $self = shift;
    return map { $_+1 }@_;
}

sub remember_wantarray {
    my $self = shift;
    $self->{last_wantarray} = wantarray;
    return 1;
}
sub return_last_wantarray {
    my $self = shift;
    return $self->{last_wantarray};
}

1;