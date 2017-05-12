package Slackware::Slackget::Package;

use warnings;
use strict;
use overload
	'cmp' => \&compare_version,
	'<=>' => \&compare_version,
	'fallback' => 1;

require Slackware::Slackget::MD5;
use Data::Dumper;

use constant {
	PKG_VER_EQ => 0,
	PKG_VER_LT => -1,
	PKG_VER_GT => 1,
};

=head1 NAME

Slackware::Slackget::Package - This class is the internal representation of a package for slack-get 1.0

=head1 VERSION

Version 1.0.3

=cut

our @ISA = qw( Slackware::Slackget::MD5 );
our $VERSION = '1.0.3';

=head1 SYNOPSIS

This module is used to represent a package for slack-get

    use Slackware::Slackget::Package;

    my $package = Slackware::Slackget::Package->new('package-1.0.0-noarch-1');
    $package->set_value('description',"This is a test of the Slackware::Slackget::Package object");
    $package->fill_object_from_package_name();

This class inheritate from Slackware::Slackget::MD5, so you can use :

	$sgo->installpkg($package) if($package->verify_md5);

Isn't it great ?

=head1 CONSTRUCTOR

=head2 new

The constructor take two parameters : a package name, and an id (the namespace of the package like 'slackware' or 'linuxpackages')

	my $package = new Slackware::Slackget::Package ('aaa_base-10.0.0-noarch-1','slackware');

The constructor automatically call the fill_object_from_package_name() method.

You also can pass some extra arguments like that :

	my $package = new Slackware::Slackget::Package ('aaa_base-10.0.0-noarch-1', 'package-object-version' => '1.0.0');

The constructor return undef if the id is not defined.

=cut

sub new
{
	my ($class,$id,@args) = @_ ;
	return undef unless($id);
	my %args = ();
	my $self = {};
	if(scalar(@args)%2 == 0){
		%args = @args ;
		$self={%args} ;
	}else{
		$self->{SOURCE} = $args[0];
	}
	$self->{ROOT} = $id ;
	$self->{STATS} = {hw => [], dwc => 0};
	bless($self,$class);
	$self->fill_object_from_package_name();
	return $self;
}

=head1 FUNCTIONS

=head2 merge

This method merge $another_package with $package. 

** WARNING ** : $another_package will be destroy in the operation (this is a collateral damage ;-), for some dark preocupation of memory.

** WARNING 2 ** : the merge keep the id from $package, this mean that an inconsistency can be found between the id and the version number.

This method overwrite existing value.

	$package->merge($another_package);

=cut

sub merge {
	my ($self,$package) = @_ ;
	return unless($package);
	foreach (keys(%{$package->{PACK}})){
		$self->{PACK}->{$_} = $package->{PACK}->{$_} ;
	}
	$self->{STATS} = {hw => [@{ $package->{STATS}->{hw} }], dwc => $package->{STATS}->{dwc}} ;
	$package = undef;
}

=head2 is_heavy_word

This method return true (1) if the first argument is an "heavy word" and return false (0) otherwise.

	print "heavy word found !\n" if($package->is_heavy_word($request[$i]));

=cut

sub is_heavy_word
{
	my ($self,$w) = @_ ;
	return undef unless($w);
	foreach my $hw (@{$self->{STATS}->{hw}}){
		return 1 if($w eq $hw);
	}
	return 0;
}

=head2 get_statistic

Return a given statistic about the description of the package. Currently available are : dwc (description words count) and hw (heavy words,  a list of important words).

Those are for the optimisation of the search speed.

=cut

sub get_statistic
{
	my ($self,$w) = @_ ;
	return $self->{PACK}->{statistics}->{$w};
}

=head2 compare_version

This method take another Slackware::Slackget::Package as argument and compare it's version to the current object.

	if( $package->compare_version( $another_package ) == -1 )
	{
		print $another_package->get_id," is newer than ",$package->get_id ,"\n";
	}

Returned code :

	-1 => $package version is lesser than $another_package's one
	0 => $package version is equal to $another_package's one
	1 => $package version is greater than $another_package's one
	undef => an error occured.

=cut

sub compare_version
{
	my ($self,$o_pack) = @_ ;
# 	warn "$o_pack is not a Slackware::Slackget::Package !" if(ref($o_pack) ne 'Slackware::Slackget::Package') ;
	if($o_pack->can('version'))
	{
# 		print "compare_version ",$self->get_id()," v. ",$self->version()," and ",$o_pack->get_id()," v. ",$o_pack->version(),"\n";
		$o_pack->set_value('version','0.0.0') unless(defined($o_pack->version()));
		$self->set_value('version','0.0.0') unless(defined($self->version()));
		my @o_pack_version = split(/\./, $o_pack->version()) ;
		my @self_version = split(/\./, $self->version()) ;
		for(my $k=0; $k<=$#self_version; $k++)
		{
# 			print "\t cmp $self_version[$k] and $o_pack_version[$k]\n";
			$self_version[$k] = 0 unless(defined($self_version[$k]));
			$o_pack_version[$k] = 0 unless(defined($o_pack_version[$k]));
			if($self_version[$k] =~ /^\d+$/ && $o_pack_version[$k] =~ /^\d+$/)
			{
				if($self_version[$k] > $o_pack_version[$k])
				{
					print "\t",$self->get_id()," > ",$o_pack->get_id(),"\n" if($ENV{SG_DAEMON_DEBUG});
					return 1;
				}
				elsif($self_version[$k] < $o_pack_version[$k])
				{
					print "\t",$self->get_id()," < ",$o_pack->get_id(),"\n" if($ENV{SG_DAEMON_DEBUG});
					return -1;
				}
			}
			else
			{
				if($self_version[$k] gt $o_pack_version[$k])
				{
					print "\t",$self->get_id()," greater than ",$o_pack->get_id(),"\n" if($ENV{SG_DAEMON_DEBUG});
					return 1;
				}
				elsif($self_version[$k] lt $o_pack_version[$k])
				{
					print "\t",$self->get_id()," lesser than ",$o_pack->get_id(),"\n" if($ENV{SG_DAEMON_DEBUG});
					return -1;
				}
			}
		}
		if( $self->getValue('package-version') && $o_pack->getValue('package-version') ){
			if( $self->getValue('package-version') gt $o_pack->getValue('package-version') ){
				print "\t",$self->get_id()," greater than ",$o_pack->get_id()," (package-version)\n" if($ENV{SG_DAEMON_DEBUG});
				return 1;
			}
			elsif( $self->getValue('package-version') lt $o_pack->getValue('package-version') ){
				print "\t",$self->get_id()," lesser than ",$o_pack->get_id()," (package-version)\n" if($ENV{SG_DAEMON_DEBUG});
				return -1 ;
			}
		}
		print "\t",$self->get_id()," equal to ",$o_pack->get_id(),"\n" if($ENV{SG_DAEMON_DEBUG});
		return 0;
	}
	else
	{
		return undef;
	}
}

=head2 fill_object_from_package_name

Try to extract the maximum informations from the name of the package. The constructor automatically call this method.

	$package->fill_object_from_package_name();

=cut

sub fill_object_from_package_name{
	my $self = shift;
	if($self->{ROOT}=~ /^(.*)-([0-9].*)-(i[0-9]86|noarch)-(\d{1,2})(\.tgz)?$/)
	{
		print "Slackware::Slackget->fill_object_from_package_name() : rg1 matched\n" if($ENV{SG_DAEMON_DEBUG});
		$self->set_value('name',$1);
		$self->set_value('version',$2);
		$self->set_value('architecture',$3);
		$self->set_value('package-version',$4);
		$self->set_value('package-maintener','Slackware team') if(defined($self->{SOURCE}) && $self->{SOURCE}=~/^slackware$/i);
	}
	elsif($self->{ROOT}=~ /^(.*)-([0-9].*)-(i[0-9]86|noarch)-([^\-]+)(\.tgz)?$/)
	{
		print "Slackware::Slackget->fill_object_from_package_name() : rg2 matched\n" if($ENV{SG_DAEMON_DEBUG});
		$self->set_value('name',$1);
		$self->set_value('version',$2);
		$self->set_value('architecture',$3);
		$self->set_value('package-version',$4);
# 		$self->set_value('package-maintener',$5) if(!defined($self->getValue('package-maintener')));
	}
	elsif($self->{ROOT}=~ /^(.*)-([0-9].*)-(i[0-9]86|noarch)-(\d{1,2})(\w*)(\.tgz)?$/)
	{
		print "Slackware::Slackget->fill_object_from_package_name() : rg3 matched\n" if($ENV{SG_DAEMON_DEBUG});
		$self->set_value('name',$1);
		$self->set_value('version',$2);
		$self->set_value('architecture',$3);
		$self->set_value('package-version',$4);
# 		$self->set_value('package-maintener',$5) if(!defined($self->getValue('package-maintener')));
	}
	elsif($self->{ROOT}=~ /^(.*)-([^-]+)-(i[0-9]86|noarch)-(\d{1,2})(\.tgz)?$/)
	{
		print "Slackware::Slackget->fill_object_from_package_name() : rg4 matched\n" if($ENV{SG_DAEMON_DEBUG});
		$self->set_value('name',$1);
		$self->set_value('version',$2);
		$self->set_value('architecture',$3);
		$self->set_value('package-version',$4);
		$self->set_value('package-maintener','Slackware team') if(defined($self->{SOURCE}) && $self->{SOURCE}=~/^slackware$/i);
	}
	elsif($self->{ROOT}=~ /^(.*)-([^-]+)-(i[0-9]86|noarch)-(\d{1,2})(\w*)(\.tgz)?$/)
	{
		print "Slackware::Slackget->fill_object_from_package_name() : rg5 matched\n" if($ENV{SG_DAEMON_DEBUG});
		$self->set_value('name',$1);
		$self->set_value('version',$2);
		$self->set_value('architecture',$3);
		$self->set_value('package-version',$4);
# 		$self->set_value('package-maintener',$5) if(!defined($self->getValue('package-maintener')));
	}
	else
	{
		print "Slackware::Slackget->fill_object_from_package_name() : no regexp match possible !!\n" if($ENV{SG_DAEMON_DEBUG});
		$self->set_value('name',$self->{ROOT});
	}
	$self->{STATS}->{hw} = [split(/-/,$self->getValue('name'))];
}

=head2 extract_informations

Extract informations about a package from a string. This string must be a line of the description of a package.

	$package->extract_informations($data);

This method is designe to be called by the Slackware::Slackget::SpecialFiles::PACKAGES class, and automatically call the clean_description() method.

=cut

sub extract_informations {
	my $self = shift;
	my $raw_str = shift ;
	my $is_descr=0;
	my $have_sd=0;
	foreach (split(/\n/,$raw_str) ){
		chomp ;
		if($_ =~ /^\s*PACKAGE NAME\s*:\s*(.*)\.tgz\s*/)
		{
			$self->_setId($1);
# 			print "[Slackware::Slackget::Package] (debug) package name: $1\n" if($ENV{SG_DAEMON_DEBUG});
			$self->fill_object_from_package_name();
			
		}
		elsif($_ =~ /^\s*(COMPRESSED PACKAGE SIZE|PACKAGE SIZE \(compressed\))\s*:\s*(.*) K/)
		{
# 			print "[Slackware::Slackget::Package] (debug) compressed size: $2\n" if($ENV{SG_DAEMON_DEBUG});
			$self->set_value('compressed-size',$2);
		}
		elsif($_ =~ /^\s*(UNCOMPRESSED PACKAGE SIZE|PACKAGE SIZE \(uncompressed\))\s*:\s*(.*) K/)
		{
# 			print "[Slackware::Slackget::Package] (debug) uncompressed size: $2\n" if($ENV{SG_DAEMON_DEBUG});
			$self->set_value('uncompressed-size',$2);
		}
		elsif($_ =~ /^\s*PACKAGE LOCATION\s*:\s*(.*)\s*/)
		{
# 			print "[Slackware::Slackget::Package] (debug) package location: $1\n" if($ENV{SG_DAEMON_DEBUG});
			$self->set_value('package-location',$1);
		}
		elsif($_ =~ /^\s*PACKAGE REQUIRED\s*:\s*(.*)\s*/)
		{
# 			print "[Slackware::Slackget::Package] (debug) required packages: $1\n" if($ENV{SG_DAEMON_DEBUG});
			my $raw_deps = $1;
			my @dep=();
			foreach my $d ( split(/\s*,|;\s*/,$raw_deps) ){
				my $tmp_array = [];
				foreach my $i (split(/\s*\|\s*/,$d) ){
					if($i=~ /^\s*([^><=\s]+)\s*([><=]+)\s*(.+)\s*$/){
						 my $ref = {pkg_name => $1, comparison_type => $2, required_version => $3};
						 $ref->{required_version} = $1 if($ref->{required_version} =~ /^(.+)-(.+)-(.+)$/);
						push @{$tmp_array}, $ref;
					}elsif(defined($i) && $i !~ /(,|;|\|)/ ){
						push @{$tmp_array}, {pkg_name => $i};
					}
# 					else{
# 						print STDERR "[Slackware::Slackget::Package] (error) $d is not a valid dependency token for package $self->{ROOT} (",$self->getValue('package-source'),").\n";
# 					}
				}
				push @dep, $tmp_array;
			}
# 			print "==> dump for package $self->{ROOT}  (",$self->getValue('package-source'),") <==\n",Dumper(@dep); <STDIN>;
			$self->set_value('required',[@dep]);
		}
		elsif($_ =~ /^\s*PACKAGE SUGGESTS\s*:\s*([^\n]*)\s*/)
		{
			my $raw_deps = $1;
			my @dep=();
			foreach my $d ( split(/,|;/,$raw_deps) ){
				my $tmp_array = [];
				foreach my $i (split(/\|/,$d) ){
					if($i=~ /^\s*([^><=]+)\s*([><=]+)\s*(.+)\s*$/){
						 my $ref = {pkg_name => $1, comparison_type => $2, required_version => $3};
						 $ref->{required_version} = $1 if($ref->{required_version} =~ /^(.+)-(.+)-(.+)$/);
						 $ref->{comparison_type} = '=<' if($ref->{comparison_type} eq '<=');
						 $ref->{comparison_type} = '>=' if($ref->{comparison_type} eq '=>');
						push @{$tmp_array}, $ref;
					}elsif(defined($i) && $i !~ /(,|;|\|)/ ){
						push @{$tmp_array}, {pkg_name => $i};
					}
				}
				push @dep, $tmp_array;
			}
			$self->set_value('suggested',[@dep]);
			
		}
		elsif($_ =~ /^\s*PACKAGE CONFLICTS\s*:\s*([^\n]*)\s*/)
		{
			my $raw_deps = $1;
			my @dep=();
			foreach my $d ( split(/,|;/,$raw_deps) ){
				my $tmp_array = [];
				foreach my $i (split(/\|/,$d) ){
					if($i=~ /^\s*([^><=]+)\s*([><=]+)\s*(.+)\s*$/){
						 my $ref = {pkg_name => $1, comparison_type => $2, required_version => $3};
						 $ref->{required_version} = $1 if($ref->{required_version} =~ /^(.+)-(.+)-(.+)$/);
						 $ref->{comparison_type} = '=<' if($ref->{comparison_type} eq '<=');
						 $ref->{comparison_type} = '>=' if($ref->{comparison_type} eq '=>');
						push @{$tmp_array}, $ref;
					}elsif(defined($i) && $i !~ /(,|;|\|)/ ){
						push @{$tmp_array}, {pkg_name => $i};
					}
				}
				push @dep, $tmp_array;
			}
			$self->set_value('conflicts',[@dep]);
			
		}
		elsif($_=~/^\s*PACKAGE DESCRIPTION:\s*\n*(.*)/ms)
		{
# 			print "descr ";
			$self->set_value('description',$1);
			if(defined($1)){
				$self->set_value('shortdescription',$1);
			}
			$is_descr=1;

# 			print "[DEBUG] Slackware::Slackget::Package -> package ",$self->get_id()," ($self) have $self->{STATS}->{dwc} words in its description.\n";
# 			print Dumper($self);<STDIN>;
		}
		elsif($is_descr){
			if(/^\s*[^:]+\s*:\s*(.+)$/){
				$self->set_value('description', $self->getValue('description')."$1\n" );
				unless($have_sd){
					$self->set_value('shortdescription',$1);
					$have_sd=1;
				}
			}
		}
	}
	$self->clean_description ;
	my @t = split(/\s/,$self->get_value('description'));
	$self->{STATS}->{dwc} = scalar(@t);
# 	print "[Slackware::Slackget::Package] (debug) description:\n",$self->getValue('description'),"\n" if($ENV{SG_DAEMON_DEBUG});
}

=head2 clean_description

remove the "<package_name>: " string in front of each line of the description. Remove extra tabulation (for identation).

	$package->clean_description();

=cut

sub clean_description{
	my $self = shift;
	if($self->{PACK}->{name} && defined($self->{PACK}->{description}) && $self->{PACK}->{description})
	{
		$self->{PACK}->{description}=~ s/\s*\Q$self->{PACK}->{name}\E\s*:\s*/ /ig;
# 		my @descr  = split(/\s*\Q$self->{PACK}->{name}\E\s*:/,$self->{PACK}->{description});
# 		$self->{PACK}->{description} = join(' ',@descr);
		$self->{PACK}->{description}=~ s/\t{4,}/\t\t\t/g;
		$self->{PACK}->{description}=~ s/\n\s+\n/\n/g;
	}
	$self->{PACK}->{description}.="\n\t\t";
	return 1;
}

=head2 grab_info_from_description

Try to find some informations in the description. For example, packages from linuxpackages.net contain a line starting by Packager: ..., this method will extract this information and re-set the package-maintener tag.

The supported tags are: package-maintener, info-destination-slackware, info-packager-mail, info-homepage, info-packager-tool, info-packager-tool-version

	$package->grab_info_from_description();

=cut

sub grab_info_from_description
{
	my $self = shift;
	return unless( defined($self->{PACK}->{description}) );
	# NOTE: je remplace ici tout les elsif() par des if() histoire de voir si l'extraction d'information est plus interressante.
	if($self->{PACK}->{description}=~ /this\s+version\s+.*\s+was\s+comp(iled|lied)\s+for\s+([^\n]*)\s+(.|\n)*\s+by\s+([^\n\t]*)/i){
		$self->set_value('info-destination-slackware',$2);
		$self->set_value('package-maintener',$4);
	}
	if($self->{PACK}->{description}=~ /\s*(http:\/\/[^\s]+)/i){
		$self->set_value('info-homepage',$1);
	}
	if($self->{PACK}->{description}=~ /\s*([\w\.\-]+\@[^\s]+\.[\w]+)/i){
		$self->set_value('info-packager-mail',$1);
	}
	
	if($self->{PACK}->{description}=~ /Package\s+created\s+by:\s+(.*)\s+&lt;([^\n\t]*)&gt;/i){
		$self->set_value('info-pacdatekager-mail',$2);
		$self->set_value('package-maintener',$1);
	}
	elsif($self->{PACK}->{description}=~ /Packager:\s+(.*)\s+&lt;(.*)&gt;/i){
		$self->set_value('package-maintener',$1);
		$self->set_value('info-packager-mail',$2);
	}
	elsif($self->{PACK}->{description}=~ /Package\s+created\s+.*by\s+(.*)\s+\(([^\n\t]*)\)/i){
		$self->set_value('package-maintener',$1);
		$self->set_value('info-packager-mail',$2);
	}
	elsif ( $self->{PACK}->{description}=~ /Packaged by ([^\s]+) ([^\s]+) \((.*)\)/i)
	{
		$self->set_value('package-maintener',"$1 $2");
		$self->set_value('info-packager-mail',$3);
	}
	elsif($self->{PACK}->{description}=~ /\s*Package\s+Maintainer:\s+(.*)\s+\(([^\n\t]*)\)/i){
		$self->set_value('package-maintener',$1);
		$self->set_value('info-packager-mail',$2);
	}
	elsif($self->{PACK}->{description}=~ /Packaged\s+by\s+(.*)\s+&lt;([^\n\t]*)&gt;/i){
		$self->set_value('package-maintener',$1);
		$self->set_value('info-packager-mail',$2);
	}
	
	if ( $self->{PACK}->{description}=~ /Package created by ([^\s]+) ([^\s]+)/i)
	{
		$self->set_value('package-maintener',"$1 $2");
	}
	
	if($self->{PACK}->{description}=~ /Packaged\s+by:?\s+(.*)(\s+(by|for|to|on))?/i){
		$self->set_value('package-maintener',$1);
	}
	if($self->{PACK}->{description}=~ /Package\s+created\s+by:?\s+([^\n\t]*)/i){
		$self->set_value('package-maintener',$1);
	}
	
	if($self->{PACK}->{description}=~ /Package\s+created\s+by\s+(.*)\s+\[([^\n\t]*)\]/i){
		$self->set_value('info-homepage',$2);date
		$self->set_value('package-maintener',$1);
	}
	if($self->{PACK}->{description}=~ /Packager:\s+([^\n\t]*)/i){
		$self->set_value('package-maintener',$1);
	}
	if($self->{PACK}->{description}=~ /Packager\s+([^\n\t]*)/i){
		$self->set_value('package-maintener',$1);
	}
	if($self->{PACK}->{description}=~ /Home\s{0,1}page: ([^\n\t]*)/i){
		$self->set_value('info-homepage',$1);
	}
	if($self->{PACK}->{description}=~ /Package URL: ([^\n\t]*)/i){
		$self->set_value('info-homepage',$1);
	}
	
	if($self->{PACK}->{description}=~ /Package creat(ed|e) with ([^\s]*) ([^\s]*)/i){
		$self->set_value('info-packager-tool',$2);
		$self->set_value('info-packager-tool-version',$3);
	}
	
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
	
	my $xml = "\t<package id=\"$self->{ROOT}\">\n";
	if(defined($self->{STATUS}) && ref($self->{STATUS}) eq 'Slackware::Slackget::Status')
	{
		$xml .= "\t\t".$self->{STATUS}->to_xml()."\n";
	}
	if($self->{PACK}->{'package-date'}){
		$xml .= "\t\t".$self->{PACK}->{'package-date'}->to_xml();
		$self->{TMP}->{'package-date'}=$self->{PACK}->{'package-date'};
		delete($self->{PACK}->{'package-date'});
	}
	if($self->{PACK}->{'date'}){
		$xml .= "\t\t".$self->{PACK}->{'date'}->to_xml();
		$self->{TMP}->{'date'}=$self->{PACK}->{'date'};
		delete($self->{PACK}->{'date'});
	}
	if($self->{STATS}){
		if($self->{STATS}->{dwc} == 0 && scalar(@{$self->{STATS}->{hw}}) > 0 && defined($self->getValue('description')) ){
			my @t = split(/\s/,$self->getValue('description'));
			$self->{STATS}->{dwc} = scalar(@t);
		}
# 		print "[Slackware::Slackget::Package->to_xml] $self->{ROOT} ($self) : <statistics dwc=\"".$self->{STATS}->{dwc}."\" hw=\":".join(':',@{$self->{STATS}->{hw}}).":\" />\n";
# 		print Dumper($self);<STDIN>;
		
		$xml .= "\t\t<statistics dwc=\"".$self->{STATS}->{dwc}."\" hw=\":".join(':',@{$self->{STATS}->{hw}}).":\" />\n";
	}
	if($self->{PACK}->{'required'}){
		$xml .= "\t\t<required>\n";
		foreach my $dep ( @{$self->{PACK}->{'required'}} ){
			next if(ref($dep) ne 'ARRAY');
			$xml .= "\t\t\t<dependencies>\n";
			foreach my $ad (@{$dep}){
				$xml .= "\t\t\t\t<dependency name=\"$ad->{pkg_name}\"";
				$xml .= " required_version=\"$ad->{required_version}\"" if($ad->{required_version});
				$xml .= " comparison_type=\"$ad->{comparison_type}\"" if($ad->{comparison_type});
				$xml .= "/>\n";
			}
			$xml .= "\t\t\t</dependencies>\n";
		}
		$xml .= "\t\t</required>\n";
		$self->{TMP}->{'required'}=$self->{PACK}->{'required'};
		delete($self->{PACK}->{'required'});
	}
	if($self->{PACK}->{'suggested'}){
		$xml .= "\t\t<suggested>\n";
		foreach my $dep ( @{$self->{PACK}->{'suggested'}} ){
			next if(ref($dep) ne 'ARRAY');
			$xml .= "\t\t\t<dependencies>\n";
			foreach my $ad (@{$dep}){
				$xml .= "\t\t\t\t<dependency name=\"$ad->{pkg_name}\"";
				$xml .= " required_version=\"$ad->{required_version}\"" if($ad->{required_version});
				$xml .= " comparison_type=\"$ad->{comparison_type}\"" if($ad->{comparison_type});
				$xml .= "/>\n";
			}
			$xml .= "\t\t\t</dependencies>\n";
		}
		$xml .= "\t\t</suggested>\n";
		$self->{TMP}->{'suggested'}=$self->{PACK}->{'suggested'};
		delete($self->{PACK}->{'suggested'});
	}
	foreach (keys(%{$self->{PACK}})){
		next if(/^_[A-Z_]+$/);
		$xml .= "\t\t<$_><![CDATA[$self->{PACK}->{$_}]]></$_>\n" if(defined($self->{PACK}->{$_}));
	}
	$self->{PACK}->{'package-date'}=$self->{TMP}->{'package-date'};
	delete($self->{TMP});
	$xml .= "\t</package>\n";
	return $xml;
}

=head2 to_string

Return a string describing the package using the official Slackware text based semantic.

	my $text = $package->to_string();

In this case, $text contains something like that :

	PACKAGE NAME:  test_package-1.0-i486-1.tgz 
	PACKAGE LOCATION:  ./path/to/test_package/
	PACKAGE SIZE (compressed):  677 K
	PACKAGE SIZE (uncompressed):  1250 K
	PACKAGE REQUIRED:  acl >= 2.2.47_1-i486-1,attr >= 2.4.41_1-i486-1,cxxlibs >= 6.0.9-i486-1 | gcc-g++ >= 4.2.3-i486-1,expat >= 2.0.1-i486-1,fontconfig >= 2.4.2-i486-2,freetype >= 2.3.5-i486-1,
	PACKAGE CONFLICTS:  
	PACKAGE SUGGESTS:  
	PACKAGE DESCRIPTION:
	test_package: Test Package
	test_package:
	test_package: Test Package is a package for testing
	test_package: the slack-get API.
	test_package:

WARNING: This method behavior have changed compare to previous versions.

=cut

sub to_string{
	my $self = shift;
	my $text = '';
	$text .= "PACKAGE NAME: ".$self->get_id()."\n";
	$text .= "PACKAGE LOCATION: ".$self->location()."\n";
	$text .= "PACKAGE SIZE (compressed): ".$self->compressed_size()." K\n";
	$text .= "PACKAGE SIZE (uncompressed): ".$self->uncompressed_size()." K\n";
	if($self->{PACK}->{'required'}){
		$text .= "PACKAGE REQUIRED: ";
		foreach my $dep ( @{$self->{PACK}->{'required'}} ){
			next if(ref($dep) ne 'ARRAY');
			foreach my $ad (@{$dep}){
				$text .= "$ad->{pkg_name}";
				$text .= " $ad->{comparison_type}" if($ad->{comparison_type});
				$text .= " $ad->{required_version}" if($ad->{required_version});
				$text .= "|";
			}
			chop($text);
			$text .= ",";
		}
		chop($text);
		$text .= "\n";
	}
	if($self->{PACK}->{'suggested'}){
		$text .= "PACKAGE SUGGESTS: ";
		foreach my $dep ( @{$self->{PACK}->{'suggested'}} ){
			next if(ref($dep) ne 'ARRAY');
			foreach my $ad (@{$dep}){
				$text .= "$ad->{pkg_name}";
				$text .= " $ad->{comparison_type}" if($ad->{comparison_type});
				$text .= " $ad->{required_version}" if($ad->{required_version});
				$text .= "|";
			}
			chop($text);
			$text .= ",";
		}
		chop($text);
		$text .= "\n";
	}
	if($self->{PACK}->{'conflicts'}){
		$text .= "PACKAGE CONFLICTS: ";
		foreach my $dep ( @{$self->{PACK}->{'conflicts'}} ){
			next if(ref($dep) ne 'ARRAY');
			foreach my $ad (@{$dep}){
				$text .= "$ad->{pkg_name}";
				$text .= " $ad->{comparison_type}" if($ad->{comparison_type});
				$text .= " $ad->{required_version}" if($ad->{required_version});
				$text .= "|";
			}
			chop($text);
			$text .= ",";
		}
		chop($text);
		$text .= "\n";
	}
	my $short_name = lc( $self->name() );
	$text .= "PACKAGE DESCRIPTION:\n$short_name: ".$self->get_value('shortdescription')."\n$short_name: \n";
	foreach my $l ( split(/\.\s*/,$self->description() )){
		$text .= "$short_name: $l.\n";
	}
	$text .= "$short_name: \n";
	return $text;
}

=head2 to_HTML (deprecated)

Same as to_html(), provided for backward compatibility.

=cut

sub to_HTML {
	return to_html(@_);
}

=head2 to_html

return the package as an HTML string

	my $html = $package->to_html ;

Note: I have design this method for 2 reasons. First for an easy integration of the search result in a GUI, second for my website search engine. So this HTML may not satisfy you. In this case just generate new HTML from accessors ;-)

=cut

sub to_html
{
	my $self = shift;
	my $html = "\t<h3>$self->{ROOT}</h3>\n<p>";
	if(defined($self->{STATUS}) && ref($self->{STATUS}) eq 'Slackware::Slackget::Status')
	{
		$html .= "\t\t".$self->{STATUS}->to_html()."\n";
	}
	if($self->{PACK}->{'package-date'}){
		$html .= "\t\t".$self->{PACK}->{'package-date'}->to_html();
		$self->{TMP}->{'package-date'}=$self->{PACK}->{'package-date'};
		delete($self->{PACK}->{'package-date'});
	}
	if($self->{PACK}->{'date'}){
		$html .= "\t\t".$self->{PACK}->{'date'}->to_html();
		$self->{TMP}->{'date'}=$self->{PACK}->{'date'};
		delete($self->{PACK}->{'date'});
	}
	foreach (keys(%{$self->{PACK}})){
		if($_ eq 'package-source')
		{
			$html .= "<strong>$_ :</strong> <b style=\"color:white;background-color:#6495ed\">$self->{PACK}->{$_}</b><br/>\n" if(defined($self->{PACK}->{$_}));
		}
		else
		{
			$html .= "<strong>$_ :</strong> $self->{PACK}->{$_}<br/>\n" if(defined($self->{PACK}->{$_}));
		}
	}
	$self->{PACK}->{'package-date'}=$self->{TMP}->{'package-date'};
	delete($self->{TMP});
	$html .="\n</p>";
	return $html;
}

=head1 PRINTING METHODS

=head2 print_restricted_info

Print a part of package information.

	$package->print_restricted_info();

=cut

sub print_restricted_info {
	my $self = shift;
	print "Information on package ".$self->get_id." :\n".
	"\tshort name : ".$self->name()." \n".
	"\tArchitecture : ".$self->architecture()." \n".
	"\tDownload size : ".$self->compressed_size()." KB \n".
	"\tSource : ".$self->getValue('package-source')."\n".
	"\tPackage version : ".$self->version()." \n";
}

=head2 print_full_info

Print all informations found in the package.

	$package->print_full_info();

=cut

sub print_full_info {
	my $self = shift;
	print "Information on package ".$self->get_id." :\n";
	foreach (keys(%{$self->{PACK}})) {
		print "\t$_ : $self->{PACK}->{$_}\n";
	}
}

=head2 fprint_restricted_info

Same as print_restricted_info, but output in HTML

	$package->fprint_restricted_info();

=cut

sub fprint_restricted_info {
	my $self = shift;
	print "<u><li>Information on package ".$self->get_id." :</li></u><br/>\n".
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>short name : </strong> ".$self->name()." <br/>\n".
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>Architecture : </strong> ".$self->architecture()." <br/>\n".
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>Download size : </strong> ".$self->compressed_size()." KB <br/>\n".
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>Source : </strong> ".$self->getValue('package-source')."<br/>\n".
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>Package version : </strong> ".$self->version()." <br/>\n";
}

=head2 fprint_full_info

Same as print_full_info, but output in HTML

	$package->fprint_full_info();

=cut

sub fprint_full_info {
	my $self = shift;
	print "<u><li>Information on package ".$self->get_id." :</li></u><br/>\n";
	foreach (keys(%{$self->{PACK}})){
		print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>$_ : </strong> $self->{PACK}->{$_}<br/>\n";
	}
}

=head1 ACCESSORS

=head2 set_value

Set the value of a named key to the value passed in argument.

	$package->set_value($key,$value);

Return $value (for integrity check).

=cut

sub set_value {
	my ($self,$key,$value) = @_ ;
# 	print "Setting $key=$value for $self\n";
	$self->{PACK}->{$key} = $value ;
	return $self->{PACK}->{$key};
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

	$string = $package->get_value($key);

=cut

sub get_value {
	my ($self,$key) = @_ ;
	return $self->{PACK}->{$key};
}

=head2 status

Return the current status of the package object as a Slackware::Slackget::Status object. This object is set by other class, and in most case you don't have to set it by yourself.

	print "The current status for ",$package->name," is ",$package->status()->to_string,"\n";

You also can set the status, by passing a Slackware::Slackget::Status object, to this method.

	$package->status($status_object);

This method return 1 if all goes well and undef else.

=cut

sub status {
	my ($self,$status) = @_ ;
	if(defined($status))
	{
		return undef if(ref($status) ne 'Slackware::Slackget::Status');
		$self->{STATUS} = $status ;
	}
	else
	{
		return $self->{STATUS} ;
	}
	
	return 1;
}

=head2 add_dependency

Add a dependency to the package. Parameters are :

* the type of dependency between : required, suggested, conflicts
* the dependency as a hashref containing the following keys : pkg_name (mandatory),  comparison_type and required_version (optional).

	$package->add_dependency('required',{pkg_name => 'gcc', comparison_type => '>=', required_version => '4.2'}) ;

If you want to let a choice between 2 or more dependencies (like between cxxlibs and gcc-g++), use an arrayref which contains as mush hashref as needed :

	$package->add_dependency('required',[{pkg_name => 'gcc-g++', comparison_type => '>=', required_version => '4.2.3'},{pkg_name => 'cxxlibs', comparison_type => '>=', required_version => '6.0.9'}]) ;

=cut

sub add_dependency {
	my ($self,$type,$dep) = @_ ;
	if(defined($type) && ($type eq 'required' || $type eq 'suggested' || $type eq 'conflicts') ){
		my $deps_array = $self->get_value($type);
		if( ref($dep) eq 'HASH' ){
# 			print "Slackware::Slackget::Package->add_dependency(): adding a single dependency\n";
			push @{$deps_array},[$dep];
		}
		elsif( ref($dep) eq 'ARRAY' ){
# 			print "Slackware::Slackget::Package->add_dependency(): adding an array of dependencies\n";
			push @{$deps_array},$dep;
		}
	}
	else{
		return 0;
	}
}

=head2 _setId [PRIVATE]

set the package ID (normally the package complete name, like aaa_base-10.0.0-noarch-1). In normal use you don't need to use this method

	$package->_setId('aaa_base-10.0.0-noarch-1');

=cut

sub _setId{
	my ($self,$id)=@_;
	$self->{ROOT} = $id;
}

=head2 get_id

return the package id (full name, like aaa_base-10.0.0-noarch-1).

	$string = $package->get_id();

=cut

sub get_id {
	my $self= shift;
	return $self->{ROOT};
}

=head2 description

return the description of the package.

	$string = $package->description();

=cut

sub description{
	my $self = shift;
	return $self->{PACK}->{description};
}

=head2 filelist

return the list of files in the package. WARNING: by default this list is not included !

	$string = $package->filelist();

=cut

sub filelist{
	my $self = shift;
	return $self->{PACK}->{'file-list'};
}

=head2 name

return the name of the package. 
Ex: for the package aaa_base-10.0.0-noarch-1 name() will return aaa_base

	my $string = $package->name();

=cut

sub name{
	my $self = shift;
	return $self->{PACK}->{name};
}

=head2 compressed_size

return the compressed size of the package

	$number = $package->compressed_size();

=cut

sub compressed_size{
	my $self = shift;
	return $self->{PACK}->{'compressed-size'};
}

=head2 uncompressed_size

return the uncompressed size of the package

	$number = $package->uncompressed_size();

=cut

sub uncompressed_size{
	my $self = shift;
	return $self->{PACK}->{'uncompressed-size'};
}

=head2 location

return the location of the installed package.

	$string = $package->location();

=cut

sub location{
	my $self = shift;
	if(exists($self->{PACK}->{'package-location'}) && defined($self->{PACK}->{'package-location'}))
	{
		return $self->{PACK}->{'package-location'};
	}
	else
	{
		return $self->{PACK}->{location};
	}
	
}

=head2 conflicts

return the list of conflicting pakage.

	$string = $package->conflicts();

=cut

sub conflicts{
	my $self = shift;
	return $self->{PACK}->{conflicts};
}

=head2 suggested

return the suggested package related to the current package.

	$string = $package->suggested();

=cut

sub suggested{
	my $self = shift;
	return $self->{PACK}->{suggested};
}

=head2 required

return the required packages for installing the current package

	$string = $package->required();

=cut

sub required{
	my $self = shift;
	return $self->{PACK}->{required};
}

=head2 architecture

return the architecture the package is compiled for.

	$string = $package->architecture();

=cut

sub architecture {
	my $self = shift;
	return $self->{PACK}->{architecture};
}

=head2 version

return the package version.

	$string = $package->version();

=cut

sub version {
	my $self = shift;
	return $self->{PACK}->{version};
}

=head2 get_fields_list

return a list of all fields of the package. This method is suitable for example in GUI for displaying informations on packages.

	foreach my $field ( $package->get_fields_list )
	{
		qt_textbrowser->append( "<b>$field</b> : ".$package->getValue( $field )."<br/>\n" ) ;
	}

=cut

sub get_fields_list
{
	my $self = shift ;
	return keys(%{$self->{PACK}}) ;
}

# 
# =head2
# 
# return the 
# 
# =cut
# 
# sub {
# 	my $self = shift;
# 	return $self->{PACK}->{};
# }

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

    perldoc Slackware::Slackget::Package


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

1; # End of Slackware::Slackget::Package
