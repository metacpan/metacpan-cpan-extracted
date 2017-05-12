package Slackware::Slackget::SpecialFiles::PACKAGES;

use warnings;
use strict;

use Slackware::Slackget::File;
use Slackware::Slackget::Date;
use Slackware::Slackget::Package ;

=head1 NAME

Slackware::Slackget::SpecialFiles::PACKAGES - An interface for the special file PACKAGES.TXT

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

This class contain all methods for the treatment of the PACKAGES.TXT file

    use Slackware::Slackget::SpecialFiles::PACKAGES;

    my $pack = Slackware::Slackget::SpecialFiles::PACKAGES->new('PACKAGES.TXT','slackware');
    ...

=head1 WARNINGS

All classes from the Slackware::Slackget::SpecialFiles:: namespace need the followings methods :

	- a contructor new()
	- a method compil()
	- a method get_result(), which one can be an alias on another method of the class.

Moreover, the get_result() methode need to return a hashref. Keys of this hashref are the filenames.

Classes from ths namespace represent an abstraction of the special file they can manage so informations stored in the returned hashref must have a direct link with this special file.

=head1 CONSTRUCTOR

=head2 new

Take a file, a Slackware::Slackget::Config object and an id name :

	my $pack = Slackware::Slackget::SpecialFiles::PACKAGES->new('PACKAGES.TXT',$config,'slackware');

=cut

sub new
{
	my ($class,$file,$config,$root) = @_ ;
	return undef if(!defined($config) && ref($config) ne 'Slackware::Slackget::Config') ;
	my $self={};
	return undef unless(defined($file) && -e $file);
# 	print "[debug PACKAGES] Loading $file as PACKAGES\n";
	$self->{ROOT} = $root;
	$self->{config}=$config;
	$self->{FILE} = new Slackware::Slackget::File ($file,'file-encoding' => $config->{common}->{'file-encoding'});
	$self->{DATA} = {};
	$self->{METADATA} = {};
	bless($self,$class);
	return $self;
}


=head1 FUNCTIONS

=head2 compile

Take no argument, and compile the informations contains in the PACKAGES.TXT file into the internal data structure of slack-get.

	$pack->compile ;

=cut

sub compile {
	my $self = shift;
	$self->get_meta;
	foreach (@{$self->create_entities}){
		my $pack = new Slackware::Slackget::Package (1);
		$pack->setValue('package-source',$self->{ROOT}) if($self->{ROOT});
		$pack->extract_informations($_);
		$pack->grab_info_from_description ;
		print STDERR "Error: informations extraction have failed\n" if(!$pack->get_id);
# 		print "PACKAGING of ",$pack->get_id,"\n";$pack->print_full_info;
		$self->{DATA}->{$pack->get_id} = $pack ;
	}
	$self->{FILE}->Close ;
	### DEBUG ONLY
# 	$self->{FILE}->Write("debug/packages_$self->{ROOT}.xml",$self->to_XML);
# 	$self->{FILE}->Close ;
}

=head2 create_entities

This method take the whole file PACKAGES.TXT and split it into entity (one package or meta informations)

=cut

sub create_entities {
	my $self = shift;
	my @entities = ();
	my $idx = -1;
	foreach ($self->{FILE}->Get_selection($self->{'starting-position'})){
		if($_=~ /^PACKAGE NAME:/){
			$idx++;
		}
		next if($_=~ /^\s*(#|\|-*handy-ruler)/i);
		$entities[$idx] .= $_ ;
	}
	return \@entities ;
}

=head2 get_meta

This method parse the 10 first lines of the PACKAGES.TXT and extract globals informations. It define the 'starting-position' object tag (this information is only for coders).

	$pack->get_meta();

=cut

sub get_meta {
	my $self = shift;
	my $l = 0;
	foreach ($self->{FILE}->Get_selection(0,15)){
		if($_=~ /PACKAGES.TXT;  (\w+) (\w+)  (\d+) ([\d:]+) (\w+) (\d+)/){
			$self->{METADATA}->{'date'} = new Slackware::Slackget::Date (
				'day-name' => $1,
				'day-number' => $3,
				'month' => $2,
				'hour' => $4,
				'year' => $6
			);
		}
		elsif($_=~ /Total size of all packages \(compressed\):\s+(\d+) MB/){
			$self->{METADATA}->{'compressed-size'} = $1;
		}
		elsif($_=~ /Total size of all packages \(uncompressed\):\s+(\d+) MB/){
			$self->{METADATA}->{'uncompressed-size'} = $1;
		}
		elsif($_=~ /^PACKAGE NAME:/)
		{
			$self->{'starting-position'}=$l;
			last;
		}
		$l++;
	}
}

=head2 get_result

Not yet implemented.

=cut

sub get_result {
	my $self = shift;
}

=head2 get_package

Return informations relative to a packages as a hashref.

	my $hashref = $list->get_package($package_name) ;

=cut

sub get_package {
	my ($self,$pack_name) = @_ ;
	return $self->{DATA}->{$pack_name} ;
}

=head2 get_date

return a Slackware::Slackget::Date object, which is the date of the PACKAGES.TXT

	my $date = $pack->get_date ;

=cut

sub get_date {
	my $self = shift;
	return $self->{METADATA}->{'date'} ;
}

=head2 to_XML (deprecated)

Same as to_xml(), provided for backward compatibility.

=cut

sub to_XML {
	return to_xml(@_);
}

=head2 to_xml

return the package as an XML encoded string.

	$xml = $package->to_xml();

=cut

sub to_xml
{
	my $self = shift;
	my $xml = "<packages>\n";
	foreach (keys(%{$self->{DATA}})){
# 		print "XMLization of $_\n";
		$xml .= $self->{DATA}->{$_}->to_xml ;
	}
	$xml .= "</packages>\n";
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

1; # End of Slackware::Slackget::SpecialFiles::PACKAGES
