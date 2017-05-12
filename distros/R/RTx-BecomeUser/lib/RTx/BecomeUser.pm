package RTx::BecomeUser;
$RTx::BecomeUser::VERSION = "0.01";

require 5.003;

1;

__END__

=head1 NAME

RTx::BecomeUser - Become any user

=head1 VERSION

This document describes version 0.01 of RTx::BecomeUser, released
February 22, 2008.

=head1 DESCRIPTION

This RT extension provides a web interface for becoming any user i.e simulating
logging in as any other user other than yourself. This privilege is provided only
to the users with SuperUser privilege. 

After installation, log in as superuser, and click on Configuration->Tools->Become User,
choose the user you want to become from the list and click submit. It will redirect you
to the home page with logged on user as the user you selected.

=head1 AUTHORS

Amit Poddar<lt>amit_poddark@yahoo.com<gt>

=head1 COPYRIGHT

Copyright 2008 by Amit Poddar <lt>amit_poddark@yahoo.com<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

