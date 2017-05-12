use Plack::Builder;


sub check_pass {
    my( $username, $pass ) = @_;
    return $username eq $pass;
}

sub my_app {
    my $env = shift; 
    my $page = '<html><body>' . $env->{PATH_INFO} . '<br>';
    if( $env->{'psgix.session'}{user_id} ){
        $page .= <<END;
        Hi $env->{'psgix.session'}{user_id}<br>
        <form id="logout_form" name="logout_form" method="post" action="/logout">
        <input type="submit" name="submit" id="submit" value="Logout" />
        </form>
END
    }
    else{
        $page .= '<a href="/login">login</a>';
    }
    $page .= '</body></html>';
    return [ 200, [ 'Content-Type' => 'text/html', ], [ $page ] ];
}

builder {
    enable 'Session';
    enable 'Auth::Form', authenticator => \&check_pass;
    \&my_app
}


