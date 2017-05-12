% my $p = shift;
#!/bin/sh
export QX_SRC_MODE=1
export MOJO_MODE=development
export MOJO_LOG_LEVEL=debug
exec ./<%= $p->{name} %>.pl prefork --listen 'http://*:<%= int(rand()*5000+3024) %>'

