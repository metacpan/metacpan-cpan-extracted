package Sleep;
use strict;
use warnings;

our $VERSION = '0.0.4';

1;

__END__


=head1 NAME

Sleep - A library for making REST web applications.

=head1 DESCRIPTION

Sleep is a web application that is used together with mod_perl. Sleep let's you
write a Sleep::Resource class on top of a actual resource. This way it will
catch get, post, put and delete requests to it.

=head1 SYNOPSYS


=head1 VERSION

0.0.4

=head1 LIMITATIONS

Currently the only supported mime-type is application/json.

=head1 SEE ALSO

L<Sleep::Handler|Sleep::Handler>, L<Sleep::Resource|Sleep::Resource>,
L<Sleep::Request|Sleep::Request>, L<Sleep::Response|Sleep::Response>,
L<Sleep::Routes|Sleep::Routes>.

=head1 BUGS

If you find a bug, please let the author know.

=head1 COPYRIGHT

Copyright (c) 2008 Peter Stuifzand.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Peter Stuifzand E<lt>peter@stuifzand.euE<gt>

