package Slackware::Slackget::SpecialFileContainer;

use warnings;
use strict;

require Slackware::Slackget::SpecialFiles::PACKAGES ;
require Slackware::Slackget::SpecialFiles::FILELIST ;
require Slackware::Slackget::SpecialFiles::CHECKSUMS ;
require Slackware::Slackget::PackageList;
require Slackware::Slackget::Package ;

=head1 NAME

Slackware::Slackget::SpecialFileContainer - A class to class, sort and compil the PACKAGES.TXT, CHECKSUMS.md5 and FILELIST.TXT

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';
our $DEBUG=0;

=head1 SYNOPSIS

This class is a front-end for the 3 sub-class Slackware::Slackget::SpecialFiles::PACKAGES , Slackware::Slackget::SpecialFiles::CHECKSUMS and Slackware::Slackget::SpecialFiles::FILELIST.

Act as a container but also make a treatment (the compilation of the 3 subclasses in one sol object)

=head1 CONSTRUCTOR

=head2 new

take the following arguments :

	a unique id
	FILELIST => the FILELIST.TXT filename
	PACKAGES => the PACKAGES.TXT filename
	CHECKSUMS => the CHECKSUMS.md5 filename
	config => a Slackware::Slackget::Config object.

    use Slackware::Slackget::SpecialFileContainer;

    my $container = Slackware::Slackget::SpecialFileContainer->new(
    	'slackware',
	config => $config,
    	FILELIST => /home/packages/update_files/FILELIST.TXT,
	PACKAGES => /home/packages/update_files/PACKAGES.TXT,
	CHECKSUMS => /home/packages/update_files/CHECKSUMS.md5
    );

=cut

sub new
{
	my ($class,$root,%args) = @_ ;
	print "[Slackware::Slackget::SpecialFileContainer] [debug] about to create a new instance\n" if($DEBUG);
	return undef unless(defined($root));
	my $self={};
	$self->{ROOT} = $root;
	unless($args{FILELIST} or $args{PACKAGES} or $args{CHECKSUMS}){
		warn "[Slackware::Slackget::SpecialFileContainer] Required parameter FILELIST, PACKAGES or CHECKSUMS not found in the contructor\n";
		return undef;
	}
	$self->{DATA}->{config} = $args{config} if(defined($args{config}) && ref($args{config}) eq 'Slackware::Slackget::Config');
	$self->{DATA}->{FILELIST} = Slackware::Slackget::SpecialFiles::FILELIST->new($args{FILELIST},$self->{DATA}->{config},$root) or return undef;
	print "[Slackware::Slackget::SpecialFileContainer] [debug] FILELIST instance : $self->{DATA}->{FILELIST}\n" if($DEBUG);
	$self->{DATA}->{PACKAGES} = Slackware::Slackget::SpecialFiles::PACKAGES->new($args{PACKAGES},$self->{DATA}->{config},$root) or return undef;
	print "[Slackware::Slackget::SpecialFileContainer] [debug] PACKAGES instance : $self->{DATA}->{PACKAGES}\n" if($DEBUG);
	$self->{DATA}->{CHECKSUMS} = Slackware::Slackget::SpecialFiles::CHECKSUMS->new($args{CHECKSUMS},$self->{DATA}->{config},$root) or return undef;
	print "[Slackware::Slackget::SpecialFileContainer] [debug] CHECKSUMS instance : $self->{DATA}->{CHECKSUMS}\n" if($DEBUG);
	bless($self);#,$class
	return $self;
}

=head1 FUNCTIONS

=head2 compile

Mainly call the compile() method of the special files.

	$container->compile();

=cut

sub compile {
	my $self = shift;
# 	printf("compiling FILELIST...");
	$|++;
	$self->{DATA}->{FILELIST}->compile ;
# 	print "ok\n";
# 	printf("compiling PACKAGES...");
	$self->{DATA}->{PACKAGES}->compile ; 
# 	print "ok\n";
# 	printf("compiling CHECKSUMS...");
	$self->{DATA}->{CHECKSUMS}->compile ;
# 	print "ok\n";
# 	printf("merging data...");
	$self->{DATA}->{PACKAGELIST} = undef;
	my $packagelist = Slackware::Slackget::PackageList->new('no-root-tag' => 1) or return undef;
	my $r_list = $self->{DATA}->{FILELIST}->get_file_list ;
	foreach my $pkg_name (keys(%{$r_list})){
# 		print "[DEBUG] Getting info on $pkg_name\n";
		my $r_pack = $self->{DATA}->{PACKAGES}->get_package($pkg_name);
		my $r_chk = $self->{DATA}->{CHECKSUMS}->get_package($pkg_name);
		my $r_list = $self->{DATA}->{FILELIST}->get_package($pkg_name);
		my $pack = new Slackware::Slackget::Package ($pkg_name);
		$pack->merge($r_pack);
		$pack->merge($r_chk);
		$pack->merge($r_list);
		$packagelist->add($pack);
# 		$pack->print_restricted_info ;
	}
	$packagelist->index_list ;
	$self->{DATA}->{PACKAGELIST} = $packagelist ;
# 	my $total_size = 0;
# 	foreach (@{$packagelist->get_all})
# 	{
# 		$total_size += $_->compressed_size ;
# 	}
# 	print "TOTAL SIZE: $total_size ko\n";
	## WARNING: DEBUG ONLY
# 	use Slackware::Slackget::File;
# 	
# 	my $file = new Slackware::Slackget::File ();
# 	$file->Write("debug/specialfilecontainer_$self->{ROOT}.xml",$self->to_XML) ;
# 	$file->Close;
# 	print "ok\n";
}

=head2 id

Return the id of the SpecialFileContainer object id (like: 'slackware', 'linuxpackages', etc.)

	my $id = $container->id ;

=cut

sub id {
	my $self = shift;
	return $self->{ROOT} ;
}

=head2 to_XML (deprecated)

Same as to_xml(), provided for backward compatibility.

=cut

sub to_XML {
	return to_xml(@_);
}

=head2 to_xml

return a string XML encoded which represent the compilation of PACKAGES, FILELIST, CHECKSUMS constructor parameters.

	my $string = $container->to_xml();

=cut

sub to_xml {
	my $self = shift;
	my $xml = "  <$self->{ROOT}>\n";
# 	print "\t[$self] XMLization of the $self->{DATA}->{PACKAGELIST} packagelist\n";
	$xml .= $self->{DATA}->{PACKAGELIST}->to_XML ;
	$xml .= "  </$self->{ROOT}>\n";
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

    perldoc Slackware::Slackget::SpecialFileContainer


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

1; # End of Slackware::Slackget::SpecialFileContainer
