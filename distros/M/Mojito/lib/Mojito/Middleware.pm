use strictures 1;
package Mojito::Middleware;
{
  $Mojito::Middleware::VERSION = '0.24';
}
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw/config/;
use Mojito;
use DateTime::TimeZone;

=head1 Name

Mojito::Middleware - gather some environment variables

=cut

# Let's gather some stuff from the environment
# that we'd like to have access to in our app.
sub call {
    my ( $self, $env ) = @_;

    my $config = $self->config;
    my $base_url = $env->{SCRIPT_NAME} || '/';
    $base_url =~ s/([^\/])$/$1\//;
    $config->{base_url} = $base_url;
    my @my_env = qw/REMOTE_USER PATH_INFO URI_REQUEST HTTP_REFERER HTTP_HOST/;
    @{$config}{qw/username PATH_INFO URI_REQUEST HTTP_REFERER HTTP_HOST/} = @{$env}{@my_env};
    $config->{local_timezone} ||= DateTime::TimeZone->new(name => 'local')->name;
    # TODO?: Just use a hash instead of an object
    $env->{"mojito"} = Mojito->new( 
        base_url    => $base_url, 
        config      => $config, 
    );

    $self->app->($env);
}

1;
