package Sentry::Severity;
use Mojo::Base -base, -signatures;

sub Fatal   {'fatal'}
sub Error   {'error'}
sub Warning {'warning'}
sub Info    {'info'}
sub Debug   {'debug'}

1;
