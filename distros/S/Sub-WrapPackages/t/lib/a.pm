package a;

sub a_scalar  { return 'in sub a_scalar'; }
sub a_list    { return qw(in sub a_list); }
sub a_context_sensitive {
    $main::voidcontext = 1 if(!defined(wantarray()));
    my @rval = qw(in sub a_context_sensitive);
    wantarray() ? @rval : \@rval;
}
sub a_caller {
    return caller(shift()) if(@_);
    return caller();
}
sub a_caller_caller {
    a_caller(@_);
}
1;
