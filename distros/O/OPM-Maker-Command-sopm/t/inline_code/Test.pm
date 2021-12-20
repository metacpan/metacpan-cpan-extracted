package Test;

sub MethodToInline {
    my ($Self, %Params) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request';
    my $Test = $ParamObject->GetParam('Test');

    if ( $Test ) {
        for ( 0 .. 10 ) {
            warn $_;
        }
    }

    for ( 0 .. 10 ) {
        warn $_;
    }

    return 1;
}

1;
