package Sentry::Tracing::SamplingMethod;
use Mojo::Base -base, -signatures;

sub Explicit    {'explicitly_set'}
sub Sampler     {'client_sampler'}
sub Rate        {'client_rate'}
sub Inheritance {'inheritance'}

1;
