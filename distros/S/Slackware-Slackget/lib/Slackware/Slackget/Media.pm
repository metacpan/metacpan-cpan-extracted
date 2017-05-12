package Slackware::Slackget::Media;

use warnings;
use strict;

=head1 NAME

Slackware::Slackget::Media - A class to represent a Media from the medias.xml file.

=head1 VERSION

Version 0.9.9

=cut

our $VERSION = '0.9.9';

=head1 SYNOPSIS

This class is used by slack-get to represent a media store in the medias.xml file. In this class (and in the related MediaList), the word "media" is used to describe an update source, a media entity of the medias.xml file.

    use Slackware::Slackget::Media;

    my $Media = Slackware::Slackget::Media->new('slackware');
    my $xml = XML::Simple::XMLin($medias_file,,KeyAttr => {'media' => 'id'});
    $media->fill_object_from_xml($xml->{'slackware'});
    $media->set_value('description','The official Slackware web site');

This class' usage is mostly the same that the Slackware::Slackget::Package one. There is one big difference with the package class : you must use the accessors for setting the fast and slow medias list.

=head1 CONSTRUCTOR

=head2 new

The constructor require the following argument :

	- an id (stricly needed)

Additionnaly you can pass the followings :

	description => a string which describe the mirror
	web-link => a web site URL for the mirror.
	update-repository => A hash reference build on the model of the medias.xml file. For example for the faster mirror (the one you want you use for this Media object) :
	
	my $media = Slackware::Slackget::Media->new('slackware','update-repository' => {faster => http://ftp.belnet.be/packages/slackware/slackware-10.1/}); 

Some examples:

	# the simpliest and recommended way
	my $media = Slackware::Slackget::Media->new('slackware'); 
	$media->fill_object_from_xml($xml_simple_hashref);
	
	or 
	
	# The harder and realy not recommended unless you know what you are doing.
	
	my $media = Slackware::Slackget::Media->new('slackware',
		'description'=>'The official Slackware web site',
		'web-link' => 'http://www.slackware.com/',
		'update-repository' => {faster => 'http://ftp.belnet.be/packages/slackware/slackware-10.1/'}
		'files' => {
			'filelist' => 'FILELIST.TXT',
			'checksums' => 'CHECKSUMS.md5',
			'packages' => 'PACKAGES.TXT.gz'
		}
	);

=cut

sub new
{
	my ($class,$id,%args) = @_ ;
	return undef unless(defined($id));
	my $self={};
	$self->{ID} = $id ;
	$self->{DATA} = {%args};
	$self->{DATA}->{hosts}->{old} = [] ;
	bless($self,$class);
	$self->set_value('host',$args{'update-repository'}->{'faster'}) if(defined($args{'update-repository'}->{'faster'}));
	return $self;
}

=head1 FUNCTIONS

=head2 set_value

Set the value of a named key to the value passed in argument.

	$package->set_value($key,$value);

Return the value you just tried to set (usefull for integrity checks).

=cut

sub set_value {
	my ($self,$key,$value) = @_ ;
# 	print "Setting $key=$value for $self\n";
	$self->{DATA}->{$key} = $value ;
	return $self->{DATA}->{$key};
}

=head2 setValue (deprecated)

Same as set_value(), provided for backward compatibility.

=cut

sub setValue {
	return set_value(@_);
}

=head2 getValue (deprecated)

Same as get_value(), provided for backward compatibility.

=cut

sub getValue {
	return get_value(@_);
}

=head2 get_value

Return the value of a key :

	$string = $media->get_value($key);

=cut

sub get_value {
	my ($self,$key) = @_ ;
	return $self->{DATA}->{$key};
}

=head2 fill_object_from_xml

Fill the data section of the Slackware::Slackget::Media object with information from a medias.xml section.

	$media->fill_object_from_xml($xml->{'slackware'});

=cut

sub fill_object_from_xml {
	my ($self,$xml) = @_ ;
# 	require Data::Dumper ;
# 	print Data::Dumper::Dumper($xml);
	
	defined($xml->{'description'}) ? $self->set_value('description',$xml->{'description'}) : $self->set_value('description','no description for this media.') ;
	defined($xml->{'web-link'}) ? $self->set_value('web-link',$xml->{'web-link'}) : $self->set_value('web-link','no website for this media.');
	defined($xml->{'download-signature'}) ? $self->set_value('download-signature',$xml->{'download-signature'}) : $self->set_value('download-signature',0);
	if(defined($xml->{'files'}))
	{
		$self->set_value('filelist',$xml->{'files'}->{'filelist'});
		$self->set_value('packages',$xml->{'files'}->{'packages'});
		$self->set_value('checksums',$xml->{'files'}->{'checksums'});
	}
	else
	{
		$self->set_value('filelist','FILELIST.TXT');
		$self->set_value('packages','PACKAGES.TXT');
		$self->set_value('checksums','CHECKSUMS.md5');
	}
	if(defined($xml->{'update-repository'}))
	{
		if(defined($xml->{'update-repository'}->{faster})){
			require Slackware::Slackget::Network::Connection;
			unless(Slackware::Slackget::Network::Connection::is_url(undef,$xml->{'update-repository'}->{faster})){
				warn "[Slackware::Slackget::Media] the faster host of the update-repository section will not be accepted as a valid URL by Slackware::Slackget::Connection class !\n";
			}
			return undef unless(defined($xml->{'update-repository'}->{faster}));
			$self->set_value('host',$xml->{'update-repository'}->{faster});
		}
		if(defined($xml->{'update-repository'}->{fast}) && defined($xml->{'update-repository'}->{fast}->{li}) && ref($xml->{'update-repository'}->{fast}->{li}) eq 'ARRAY')
		{
			$self->_fill_fast_host_section($xml->{'update-repository'}->{fast});
		}
		else
		{
			$self->{DATA}->{hosts}->{fast} = [] ;
		}
		if(defined($xml->{'update-repository'}->{slow}) && defined($xml->{'update-repository'}->{slow}->{li}) && ref($xml->{'update-repository'}->{slow}->{li}) eq 'ARRAY')
		{
			$self->_fill_slow_host_section($xml->{'update-repository'}->{slow});
		}
		else
		{
			$self->{DATA}->{hosts}->{slow} = [] ;
		}
	}
	else
	{
		warn "[Slackware::Slackget::Media] no update-repository found for the update source '$self->{ID}'\n";
		return undef;
	}
	return 1;
}

=head2 _fill_fast_host_section [PRIVATE]

fill the DATA section of the object (sub-section fast host), with a part of the XML tree of a medias.xml file.

In normal use you don't have to use this method. In all case prefer pass all required argument to the constructor, and call the fill_object_from_xml() method.

	$self->_fill_fast_host_section($xml->{'update-repository'}->{fast});

=cut

sub _fill_fast_host_section 
{
	my ($self,$xml) = @_ ;
	if(defined($xml->{li}) && ref($xml->{li}) eq 'ARRAY')
	{
		$self->{DATA}->{hosts}->{fast} = $xml->{li} ;
	}
	else
	{
		$self->{DATA}->{hosts}->{fast} = [] ;
	}
}

=head2 _fill_slow_host_section [PRIVATE]

fill the DATA section of the object (sub-section slow host), with a part of the XML tree of a medias.xml file.

In normal use you don't have to use this method. In all case prefer pass all required argument to the constructor, and call the fill_object_from_xml() method.

	$self->_fill_slow_host_section($xml->{'update-repository'}->{slow});

=cut

sub _fill_slow_host_section 
{
	my ($self,$xml) = @_ ;
	if(defined($xml->{li}) && ref($xml->{li}) eq 'ARRAY')
	{
		$self->{DATA}->{hosts}->{slow} = $xml->{li} ;
	}
	else
	{
		$self->{DATA}->{hosts}->{slow} = [] ;
	}
}

=head2 add_slow_host( <string> )

Add an host to the slow section of the current media.

	$media->add_slow_host("ftp://ftp.fe.up.pt/disk1/ftp.slackware.com/pub/slackware/slackware-current/");

=cut

sub add_slow_host {
	my ($self,$url) = @_;
	$self->{DATA}->{hosts}->{slow} = [] unless(exists($self->{DATA}->{hosts}->{slow}));
	push @{$self->{DATA}->{hosts}->{slow}}, $url;
}

=head2 add_fast_host( <string> )

Add an host to the fast section of the current media.

	$media->add_fast_host("http://mirror.switch.ch/ftp/mirror/slackware/slackware-current/");

=cut

sub add_fast_host {
	my ($self,$url) = @_;
	$self->{DATA}->{hosts}->{fast} = [] unless(exists($self->{DATA}->{hosts}->{fast}));
	push @{$self->{DATA}->{hosts}->{fast}}, $url;
}

=head2 next_host

This method have 3 functionnalities : return the next fastest host, set it as the current host, and add the old host to the old hosts list.

	my $host = $media->next_host ;

return undef if no new host is found

=cut

sub next_host
{
	my $self = shift;
	push @{$self->{DATA}->{hosts}->{old}}, $self->host;
	$self->{DATA}->{host} = undef ;
	if(defined(my $host = shift(@{$self->{DATA}->{hosts}->{fast}})))
	{
		$self->{DATA}->{host} = $host ;
	}
	else
	{
		warn "[Slackware::Slackget::Media] no more host in the 'fast' category for update source '$self->{ID}'\n";
		if(defined(my $host = shift(@{$self->{DATA}->{hosts}->{slow}})))
		{
			$self->{DATA}->{host} = $host ;
		}
		else
		{
			warn "[Slackware::Slackget::Media] no more host in the 'slow' category for update source '$self->{ID}'\n";
			return undef;
		}
	}
	return $self->host ;
}

=head2 print_info

This method is used to print the content of the current Media object.

	$media->print_info ;

=cut

sub print_info 
{
	my $self = shift ;
	print "Information for the '$self->{ID}' update source :\n";
	if(defined($self->getValue('description')))
	{
		print "\tDescription: ".$self->getValue('description')."\n";
	}
	else
	{
		print "\tDescription: no descrition found\n";
	}
	if(defined($self->getValue('web-link')))
	{
		print "\tWeb site: ".$self->getValue('web-link')."\n";
	}
	else
	{
		print "\tWeb site: no link found\n";
	}
	if(defined($self->getValue('host')))
	{
		print "\tCurrent host: ".$self->getValue('host')."\n";
	}
	else
	{
		print "\tCurrent host: no current host configured !\n";
	}
}

=head2 to_string

return the same information that the print_info() method as a string.

	my $string = $media->to_string ;

=cut

sub to_string 
{
	my $self = shift ;
	my $str = "Information for the '$self->{ID}' update source :\n";
	if(defined($self->getValue('description'))){
		$str .= "\tDescription: ".$self->getValue('description')."\n";
	}
	else
	{
		$str .= "\tDescription: no descrition found\n";
	}
	if(defined($self->getValue('web-link'))){
		$str .= "\tWeb site: ".$self->getValue('web-link')."\n";
	}
	else
	{
		$str .= "\tWeb site: no link found\n";
	}
	if(defined($self->getValue('host'))){
		$str .= "\tCurrent host: ".$self->getValue('host')."\n";
	}
	else
	{
		$str .= "\tCurrent host: no current host configured !\n";
	}
	return $str ;
}

=head1 ACCESSORS

Some accessors for the current object.

=cut

=head2 host

return the current host :

	my $host = $media->host

=cut

sub host {
	return $_[0]->{DATA}->{host};
}

=head2 description

return the description of the media.

	my $descr = $media->description ;

=cut

sub description {
	return $_[0]->{DATA}->{description};
}

=head2 url

return the URL of the website for the media.

	system("$config->{common}->{'default-browser'} $media->url &");

=cut

sub url {
	return $_[0]->{DATA}->{'web-link'};
}

=head2 shortname

Return the shortname of the media. The shortname is the name of the id attribute of the media tag in medias.xml => <media id="the_shortname">

	my $id = $media->shortname ;

=cut

sub shortname {
	return $_[0]->{ID};
}



=head2 set_fast_medias_array

...not yet implemented...

=cut

sub set_fast_medias_array {1;}

=head1 FORMATTED OUTPUT

Different methods to properly output a media.

=cut

=head2 to_XML (deprecated)

Same as to_xml(), provided for backward compatibility.

=cut

sub to_XML {
	return to_xml(@_);
}

=head2 to_xml

return the media info as an XML encoded string.

	$xml = $media->to_xml();

=cut

sub to_xml
{
	my $self = shift;
	return undef unless(defined($self->{ID}));
	if($self->{DATA}->{hosts}->{old})
	{
		$self->{DATA}->{hosts}->{slow} = [@{$self->{DATA}->{hosts}->{slow}},@{$self->{DATA}->{hosts}->{old}}] ;
		$self->{DATA}->{hosts}->{old} = undef;
		delete($self->{DATA}->{hosts}->{old});
	}
	
	my $xml = "\t<media id=\"$self->{ID}\">\n";
	$xml .= "\t\t<web-link>".$self->url."</web-link>\n";
	$xml .= "\t\t<description>".$self->description."</description>\n";
	$xml .= "\t\t<update-repository>\n";
	$xml .= "\t\t\t<faster>".$self->host."</faster>\n";
	if(defined($self->{DATA}->{hosts}->{fast}) && defined($self->{DATA}->{hosts}->{fast}->[0]))
	{
		$xml .= "\t\t\t\t<fast>\n";
		foreach my $serv (@{$self->{DATA}->{hosts}->{fast}})
		{
			$xml .= "\t\t\t\t\t<li>$serv</li>\n";
		}
		$xml .= "\t\t\t\t</fast>\n";
	}
	if(defined($self->{DATA}->{hosts}->{slow}) && defined($self->{DATA}->{hosts}->{slow}->[0]))
	{
		$xml .= "\t\t\t\t<slow>\n";
		foreach my $serv (@{$self->{DATA}->{hosts}->{slow}})
		{
			$xml .= "\t\t\t\t\t<li>$serv</li>\n";
		}
		$xml .= "\t\t\t\t</slow>\n";
	}
	$xml .= "\t\t</update-repository>\n";
# 	foreach my $key (keys(%{$self->{DATA}})){
# 		if($key eq 'update-repository')
# 		{
# 			foreach my $key2 (keys(%{$self->{DATA}->{'update-repository'}}))
# 			{
# 				if($key2 eq 'fast' or $key2 eq 'slow' && ref($self->{DATA}->{'update-repository'}->{$key2}) eq 'HASH' && defined($self->{DATA}->{'update-repository'}->{$key2}->{li}) && ref($self->{DATA}->{'update-repository'}->{$key2}->{li}) eq 'ARRAY' ) {
# 					$xml .= "\t\t<$key2>\n";
# 					foreach (@{$self->{DATA}->{'update-repository'}->{$key2}->{li}}){
# 						$xml .= "\t\t\t<li>$_</li>\n";
# 					}
# 					$xml .= "\t\t</$key2>\n";
# 				}
# 			}
# 		}
# 		else
# 		{
# 			$xml .= "\t\t<$key>$self->{DATA}->{$key}</$key>\n";
# 		}
# 	}
	$xml .= "\t</media>\n";
	return $xml;
}

=head2 to_HTML (deprecated)

Same as to_html(), provided for backward compatibility.

=cut

sub to_HTML {
	return to_html(@_);
}

=head2 to_html

return the media info as an HTML encoded string.

	$xml = $media->to_html();

=cut

sub to_html
{
	my $self = shift;
	return undef unless(defined($self->{ID}));
	my $host = $self->host ;
	$host = "<font color='red'>not reachable</font>" unless($host);
	return "<li>current host for <a href='".$self->url."' target='_blank' title='".$self->description."'>$self->{ID}</a> is $host</li><br/>\n";
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

    perldoc Slackware::Slackget::Media


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

1; # End of Slackware::Slackget::Media
