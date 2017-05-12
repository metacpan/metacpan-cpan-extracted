package Slackware::Slackget::SpecialFiles::CHECKSUMS;

use warnings;
use strict;

use Slackware::Slackget::File;
use Slackware::Slackget::Package;

=head1 NAME

Slackware::Slackget::SpecialFiles::CHECKSUMS - An interface for the special file CHECKSUMS.md5

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

This class contain all methods for the treatment of the CHECKSMUMS.md5 file

    use Slackware::Slackget::SpecialFiles::CHECKSUMS;

    my $spec_chk = Slackware::Slackget::SpecialFiles::CHECKSUMS->new('CHECKSUMS.md5','slackware');
    $spec_chk->compile();
    my $ref = $spec_chk->get_checksums('glibc-profile-2.3.4-i486-1');
    print "Checksum for glibc-profile-2.3.4-i486-1.tgz : $ref->{checksum}\n";
    print "Checksum for glibc-profile-2.3.4-i486-1.tgz.asc : $ref->{'signature-checksum'}\n";

=head1 WARNINGS

All classes from the Slackware::Slackget::SpecialFiles:: namespace need the followings methods :

	- a contructor new()
	- a method compil()
	- a method get_result(), which one can be an alias on another method of the class.

Moreover, the get_result() methode need to return a hashref. Keys of this hashref are the filenames.

Classes from ths namespace represent an abstraction of the special file they can manage so informations stored in the returned hashref must have a direct link with this special file.

=head1 CONSTRUCTOR

=head2 new

The constructor take three argument : the file CHECKSUMS.md5 with his all path, a Slackware::Slackget::Config object and an id name.

	my $spec_chk = Slackware::Slackget::SpecialFiles::CHECKSUMS->new('/home/packages/CHECKSUMS.md5',$config,'slackware');

The constructor return undef if the file does not exist.

=cut

sub new
{
	my ($class,$file,$config,$root) = @_ ;
	return undef if(!defined($config) && ref($config) ne 'Slackware::Slackget::Config') ;
	my $self={};
	$self->{ROOT} = $root;
	$self->{config}=$config;
	return undef unless(defined($file) && -e $file);
# 	print "[debug CHECKSUMS] Loading $file as CHECKSUMS\n";
	$self->{FILE} = new Slackware::Slackget::File ($file,'file-encoding' => $config->{common}->{'file-encoding'});
	$self->{DATA} = {};
	bless($self,$class);
	return $self;
}

=head1 FUNCTIONS

=head2 compile

This method take no arguments, and extract the list of couple (file/checksum). Those couple are store into an internal data structure.

	$spec_chk->compile();

=cut

sub compile {
	my $self = shift;
	foreach ($self->{FILE}->Get_file()){
		if($_=~/^([0-9a-f]*)\s+\.\/(.*)\/([^\/\s\n]*)\.tgz\.asc$/i){
			next if ($2=~ /source\//);
			unless(defined($self->{DATA}->{$3})){
				$self->{DATA}->{$3} = new Slackware::Slackget::Package ($3) ;
				$self->{DATA}->{$3}->setValue('package-source',$self->{ROOT}) if($self->{ROOT});
				$self->{DATA}->{$3}->setValue('package-location',$2);
			}
			$self->{DATA}->{$3}->setValue('signature-checksum',$1);
		}
		elsif($_=~/^([0-9a-f]*)\s+\.\/(.*)\/([^\/\s\n]*)\.tgz$/i){
			next if ($2=~ /source\//);
			unless(defined($self->{DATA}->{$3})){
				$self->{DATA}->{$3} = new Slackware::Slackget::Package ($3) ;
				$self->{DATA}->{$3}->setValue('package-source',$self->{ROOT}) if($self->{ROOT});
				$self->{DATA}->{$3}->setValue('package-location',$2);
			}
# 			$self->{DATA}->{$3}->{checksum} = $1;
			$self->{DATA}->{$3}->setValue('checksum',$1);
		}
	}
	$self->{FILE}->Close();
	### DEBUG ONLY
# 	$self->{FILE}->Write("debug/checksums_$self->{ROOT}.xml",$self->to_XML);
# 	$self->{FILE}->Close ;
}

=head2 get_checksums

This method return a Slackware::Slackget::Package object containing 2 keys : checksum and signature-checksum, wich are respectively the file checksum and the GnuPG signature (.asc) checksum. The object can contain more inforations (like the package-source and package-location). This method is the same that get_package().

	my $ref = $spec_chk->get_checksums($package_name) ;

This method return undef if $package_name doesn't exist in the data structure.

=cut

sub get_checksums {
	my ($self,$package) = @_;
	return $self->{DATA}->{$package};
}

=head2 get_package

Return informations relative to a packages as a Slackware::Slackget::Package object.

	my $package_object = $spec_chk->get_package($package_name) ;

=cut

sub get_package {
	my ($self,$pack_name) = @_ ;
	return $self->{DATA}->{$pack_name} ;
}

=head2 get_result

Alias for get_checksums()

=cut

sub get_result {
	my $self = shift;
	return $self->get_checksums(@_);
}

=head2 to_XML (deprecated)

Same as to_xml(), provided for backward compatibility.

=cut

sub to_XML {
	return to_xml(@_);
}

=head2 to_xml

Translate the internale data structure into a single XML string. 

WARNING: this method is for debug ONLY, YOU NEVER HAVE TO CALL IT IN NORMAL USE.

=cut

sub to_xml {
	my $self = shift;
	my $xml = "<checksums>\n";
	foreach (keys(%{$self->{DATA}})){
		$xml.=$self->{DATA}->{$_}->to_xml ;
	}
	$xml .= "</checksums>\n";
	return $xml;
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


=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Slackware::Slackget::SpecialFiles::CHECKSUMS
