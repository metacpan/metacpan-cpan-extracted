package RWDE;
use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 573 $ =~ /(\d+)/;

1;

__END__

=pod

=head1 NAME

RWDE - Rapid Web Development Framework

=head1 SYNOPSIS

Subclass the RWDE::Web::AppServer module to supply your handler method
based on your CGI invocation choice (SCGI or FastCGI) then call the
Launch() method to start your application server.

=head1 DESCRIPTION

=head2 How it's different

RWDE is an application framework which is extremely small, very easy
to install because it only depends on a handful of other CPAN modules,
and quick to learn.  Unlike the other frameworks, it is designed to
work with database-based business logic -- it does not treat the DB as
a dumb store.  It is fully compatible with foreign keys, trigger-based
updates, I<etc.>, and works best with a properly normalized database
design.

=over 4

=item Ease of installation

Simple install via CPAN: B<install RWDE> will pull in all necessary
dependencies (which are minimal).

=item Ease of use

See the example applications at http://www.rwde.org/

=back

=head1 METHODS

=head1 SEE ALSO

Come visit us at http://www.rwde.org (coming soon)

=head1 SUPPORT

Send email to rwde-support@RWDE.org

=head1 SPONSOR

This code has been developed under sponsorship of MailerMailer LLC,
http://www.mailermailer.com/

=head1 AUTHORS

Kevin Kamel <kamelkev@mailermailer.com>,
Damjan Pelemis <damjan@mailermailer.com>,
Vivek Khera <vivek@mailermailer.com>

=head1 COPYRIGHT & LICENSE

Copyright MailerMailer LLC 2005-2008. All rights reserved.  This code
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
