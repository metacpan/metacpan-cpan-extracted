package Template::Plugin::Devel::StackTrace;
use Devel::StackTrace;
use Template::Plugin;

use warnings;
use strict;

=head1 NAME

Template::Plugin::Devel::StackTrace - A Template Plugin To Use Devel::StackTrace objects

=head1 VERSION

Version 0.01

=cut
use vars qw($VERSION @ISA);
BEGIN
{
	$VERSION = '0.02';
    @ISA     = qw(Template::Plugin);
}


=head1 SYNOPSIS

[%
	USE Devel.StackTrace;
	Devel.StackTrace.as_string;
%]
 or
[%
	USE Devel.StackTrace({ignore_package => 'Net::Server'});
	Catalyst.log.warn(Devel.StackTrace.as_string);
%]

=head1 DESCRIPTION

Gives you a back an instance of a Devel::StackTrace.

=head1 METHODS

=head2 new

This is used internally. You won't be using it from your templates.

=cut

sub new {
 	shift; #Shift off classname
	shift; #Shift off context
    my %args = ref($_[0]) eq 'HASH' ? %{$_[0]} : ();

    # boolean args: now, today, last_day_of_month
	return Devel::StackTrace->new(%args);
}

=head1 CONSTRUCTOR

The constructor is the same as Devel::StackTrace

=head2 as_string

See L<Devel::StackTrace>

=head1 SEE ALSO

L<Devel::StackTrace>

=head1 AUTHOR

Samuel Kaufman, C<< <skaufman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-plugin-devel-stacktrace at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Devel-StackTrace>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::Devel::StackTrace


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-Devel-StackTrace>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plugin-Devel-StackTrace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Plugin-Devel-StackTrace>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plugin-Devel-StackTrace>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Samuel Kaufman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Template::Plugin::Devel::StackTrace
