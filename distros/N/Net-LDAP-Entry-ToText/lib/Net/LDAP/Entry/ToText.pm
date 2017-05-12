package Net::LDAP::Entry::ToText;

use warnings;
use strict;
use Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

our @ISA         = qw(Exporter);
our @EXPORT      = qw(NetLDAPEntryToText);
our @EXPORT_OK   = qw(NetLDAPEntryToText);
our %EXPORT_TAGS = (DEFAULT => [qw(NetLDAPEntryToText)]);


=head1 NAME

Net::LDAP::Entry::ToText - Conterts a Net::LDAP::Entry object to text.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Net::LDAP::Entry::ToText;

    my $foo = NetLDAPEntryToText($entry);
    ...

=head1 EXPORT

NetLDAPEntryToText

=head1 FUNCTIONS

=head2 NetLDAPEntryToText

=cut

sub NetLDAPEntryToText {
	my $entry=$_[0];

	my $dn=$entry->dn();
	#return undef if it fails
	#if this fails it means 
	if (!$dn) {
		return undef;
	}

	my $text='dn: '.$dn."\n";

	foreach my $attr ( $entry->attributes ) {
		my @values=$entry->get_value($attr);
		my $valuesInt=0;
		while (defined($values[$valuesInt])) {
			$text=$text.$attr.': '.$values[$valuesInt]."\n";
			$valuesInt++;
		}
	}

	return $text;
}


=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ldap-totext at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-Entry-ToText>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::Entry::ToText


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-Entry-ToText>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-Entry-ToText>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-Entry-ToText>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-Entry-ToText>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::LDAP::Entry::ToText
