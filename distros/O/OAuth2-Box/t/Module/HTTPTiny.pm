package t::Module::HTTPTiny;

no warnings 'redefine';

sub HTTP::Tiny::test { "test" };

sub HTTP::Tiny::last_request {
    my ($self,$data) = @_;

    $self->{last_request} = $data if @_ == 2;
    return $self->{last_request};
};

sub HTTP::Tiny::post_form {
    my ($self, $url, $data) = @_;

    my $request_data = "";
    for my $key ( sort keys %{$data} ) {
        $request_data .= sprintf "%s=%s\n", $key, $data->{$key};
    }

    $self->last_request( sprintf "%s\n%s", $url, $request_data );

    return {
        success       => 1,
        access_token  => 'yes',
        refresh_token => 123,
        expires       => 1352,
    };
};

1;
