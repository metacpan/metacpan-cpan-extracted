
package Slackware::Slackget::MD5;

use warnings;
use strict;

=head1 NOM

Slackware::Slackget::MD5 - A simple class to verify files checksums

=head1 VERSION

Version 0.2

=cut

our $VERSION = '0.2';

=head1 SYNOPSIS

A simple class to verify files checksums with md5sum.

    use Slackware::Slackget::MD5;

    my $slackget10_gpg_object = Slackware::Slackget::MD5->new();

IMPORTANT NOTE : This class is not design to be use by herself (the constructor for example is totaly useless). the Slackware::Slackget::Package class inheritate of this class and this is the way is design Slackware::Slackget::MD5 : to be only an abstraction of the MD5 verification operations.

You may prefer to inheritate from this class, but take attention to the fact that I design it to be inheritate by the Slackware::Slackget::Package class !

=cut

=head1 CONSTRUCTOR

new() : The constructor doesn't take any arguments but be sure the md5sum binary is in the PATH !

=cut

sub new
{
	my ($class,%args) = @_ ;
	my $self={};
	bless($self,$class);
	return $self;
}

=head1 METHODS

=head2 verify_md5

This method call the getValue() accessor (from the Slackware::Slackget::Package class) on the 'checksum' or 'signature-checksum' field, and check if it match with the MD5 of the file passed in argument.

If the argument ends with ".tgz" this method use the 'checksum' field and if it ends with ".asc" it use the 'signature-checksum' field.

	$package->verify_md5("/home/packages/update/package-cache/apache-1.3.33-i486-1.tgz") && $sgo->installpkg($packagelist->get_indexed("apache-1.3.33-i486-1")) ;

Returned values :

	undef : if a problem occur (ex: the current instance do not inheritate from Slackware::Slackget::Package, the file is not a package nor a signature, etc.)
	1 : if the MD5 is ok
	0 : if not.

This method also set a 'computed-checksum' and a 'computed-signature-checksum' in the current Slackware::Slackget::Package object.

=cut

sub verify_md5
{
	my ($self,$file) = @_;
	return undef if(ref($self) eq '' || !$self->can("get_value")) ;
	my $out = `2>&1 LANG=en_US md5sum $file`;
	chomp $out;
	if($out=~ /^([^\s]+)\s+.*/)
	{
		my $tmp_md5 = $1;
		print "\$tmp_md5 : $tmp_md5\n";
		if($file =~ /\.tgz$/)
		{
			$self->set_value('computed-checksum',$tmp_md5);
			if($self->get_value('checksum') eq $tmp_md5)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
		elsif($file =~ /\.asc$/)
		{
			$self->set_value('computed-signature-checksum',$tmp_md5);
			if($self->get_value('signature-checksum') eq $tmp_md5)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
		else
		{
			return undef;
		}
	}
	
	return undef;
}

=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis@infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Slackware-Slackget@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Slackware-Slackget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Slackware::Slackget


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org/category/slack-get>

=item * slack-get specific website

L<http://slackget.infinityperl.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Slackware-Slackget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Slackware-Slackget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Slackware-Slackget>

=item * Search CPAN

L<http://search.cpan.org/dist/Slackware-Slackget>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Bertrand Dupuis (yes my brother) for his contribution to the documentation.

=head1 SEE ALSO

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # Fin de Slackware::Slackget::MD5

