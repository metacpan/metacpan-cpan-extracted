package Slackware::Slackget::SpecialFiles::FILELIST;

use warnings;
use strict;

use Slackware::Slackget::File;
use Slackware::Slackget::Date;
use Slackware::Slackget::Package;

=head1 NAME

Slackware::Slackget::SpecialFiles::FILELIST - An interface for the special file FILELIST.TXT

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

This class contain all methods for the treatment of the FILELIST.TXT file

    use Slackware::Slackget::SpecialFiles::FILELIST;

    my $spec_file = Slackware::Slackget::SpecialFiles::FILELIST->new('FILELIST.TXT');
    $spec_file->compil();
    my $ref = $spec_file->get_file_list() ;

This class care about package-namespace, which is the root set of a package (slackware, extra or pasture for packages from Slackware)

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

	my $spec_chk = Slackware::Slackget::SpecialFiles::CHECKSUMS->new('/home/packages/FILELIST.TXT',$config,'slackware');

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
# 	print "[debug FILELIST] Loading $file as FILELIST\n";
	$self->{FILE} = new Slackware::Slackget::File ($file,'file-encoding' => $config->{common}->{'file-encoding'});
	$self->{DATA} = {};
	bless($self,$class);
	return $self;
}

=head1 FUNCTIONS

=head2 compile

This method take no arguments, and extract the list of couple (file/package-namespace). Those couple are store into an internal data structure.

	$list->compile();

=cut

sub compile {
	my $self = shift;
	if($self->{FILE}->Get_line(0)=~ /(\w+) (\w+)  (\d+) ([\d:]+) \w+ (\d+)/)  # match a date like : Tue Apr  5 12:56:29 PDT 2005
	{
		$self->{METADATA}->{'date'} = new Slackware::Slackget::Date (
			'day-name' => $1,
			'day-number' => $3,
			'month' => $2,
			'hour' => $4,
			'year' => $6
			
		);
	}
	foreach ($self->{FILE}->Get_file()){
		chomp;
		next if($_=~ /\.asc\s*\n*$/i);
		
		if(my @m=$_=~/^([^\s]+)\s+(\d+)\s+(\w+)\s+(\w+)\s+(\d+)\s+(\d+)-(\d+)-(\d+)\s+(\d+):(\d+)\s+\.\/(.*)\/(.*)\.tgz\s*\n*$/gi){#(\d+)-(\d+)-(\d+)\s+(\d+):(\d+)\s+\.\/(.*)\/([^\/\s\n]*)\.tgz
			#        1          2       3       4       5       6     7      8      9     10         11    12
			$m[10].='/'; # a fucking bad hack :(
			next if ($m[10]=~ /(source|src)\//);
# 			print "matching $m[11] : \n\t",join ' ; ',@m,"\n\n";
			$self->{DATA}->{$m[11]} = new Slackware::Slackget::Package ( $m[11] );
			$self->{DATA}->{$m[11]}->setValue('package-source',$self->{ROOT}) if($self->{ROOT});
			$self->{DATA}->{$m[11]}->setValue('package-location',$m[10]);
			$self->{DATA}->{$m[11]}->setValue('compressed-size',int($m[4]/1024));
			$self->{DATA}->{$m[11]}->setValue('package-date',new Slackware::Slackget::Date (
				'year' => $m[5],
				'month-number' => $m[6],
				'day-number' => $m[7],
				'hour' => $m[8].':'.$m[9].':00'
			));
# 			$self->{FILE}->Write("packages/$m[11]_$self->{ROOT}.xml",$self->{DATA}->{$m[11]}->to_XML);
# 			print "\nPAUSE\n";<STDIN>;
		}
		elsif($_=~/\.tgz/i){
			warn "Skipping $_ even if it's a .tgz (source: $self->{ROOT})\n";
		}
	}
	$self->{FILE}->Close();
	
	# DEBUG ONLY
# 	unlink("filelist_$self->{ROOT}.xml") if(-e "filelist_$self->{ROOT}.xml");
# 	print "saving filelist_$self->{ROOT}.xml\n";
# 	$self->{FILE}->Write("debug/filelist_$self->{ROOT}.xml",$self->to_XML);
# 	$self->{FILE}->Close();
}

=head2 get_file_list

Return a hashref build on this model 

	$ref = {
		filename => Slackware::Slackget::Package
	}

	my $ref = $list->get_file_list ;

=cut

sub get_file_list {
	my $self = shift;
	return $self->{DATA} ;
}

=head2 get_package

Return informations relative to a packages as a hashref.

	my $hashref = $list->get_package($package_name) ;

=cut

sub get_package {
	my ($self,$pack_name) = @_ ;
	return $self->{DATA}->{$pack_name} ;
}

=head2 get_result

Alias for get_file_list().

=cut

sub get_result {
	my $self = shift;
	return $self->get_file_list();
}

=head2 get_date

return a Slackware::Slackget::Date object, which is the date of the FILELIST.TXT

	my $date = $list->get_date ;

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

return a string containing all packages name carriage return separated.

WARNING: ONLY FOR DEBUG

	my $string = $list->to_xml();

=cut

sub to_xml {
	my $self = shift;
	my $xml = "<filelist>\n";
	foreach (keys(%{$self->{DATA}})){
		$xml .= $self->{DATA}->{$_}->to_XML ;
	}
	$xml .= "</filelist>\n";
	return $xml;
}

=head2 meta_to_XML (deprecated)

Same as meta_to_xml(), provided for backward compatibility.

=cut

sub meta_to_XML {
	return meta_to_xml(@_);
}

=head2 meta_to_xml

Return an XML encoded string which represent the meta informations of the FILELIST.TXT file.

	my $xml_string = $list->meta_to_xml ;

=cut

sub meta_to_xml
{
	my $self = shift;
	my $xml = "\t<filelist>\n";
	$xml .= "\t\t".$self->get_date()->to_XML()."\n" if(defined($self->get_date));
	$xml = "\t</filelist>\n";
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

1; # End of Slackware::Slackget::SpecialFiles::FILELIST
