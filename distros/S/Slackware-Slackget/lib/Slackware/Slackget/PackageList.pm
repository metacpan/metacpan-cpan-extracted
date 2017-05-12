package Slackware::Slackget::PackageList;

use warnings;
use strict;

require Slackware::Slackget::Package;
require Slackware::Slackget::List ;
require Slackware::Slackget::Date ;

=head1 NAME

Slackware::Slackget::PackageList - This class is a container of Slackware::Slackget::Package object

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';
our @ISA = qw( Slackware::Slackget::List );

=head1 SYNOPSIS

This class is a container of Slackware::Slackget::Package object, and allow you to perform some operations on this packages list. As the Package's list class, it is a slack-get's internal representation of data.

    use Slackware::Slackget::PackageList;

    my $packagelist = Slackware::Slackget::PackageList->new();
    $packagelist->add($package);
    $packagelist->get($index);
    my $package = $packagelist->Shift();


=head1 CONSTRUCTOR

=head2 new

This class constructor don't take any parameters to works properly, but you can eventually disable the root tag <packagelist> by using 'no-root-tag' => 1, and modify the default encoding (utf8) by passing an 'encoding' => <your encoding> parameter. Thoses options are only related to the export functions.

	my $PackageList = new Slackware::Slackget::PackageList ();
	my $PackageList = new Slackware::Slackget::PackageList ('no-root-tag' => 1);

=cut

sub new
{
	my ($class,%args) = @_ ;
	my $encoding = 'utf8';
	if(defined($args{'encoding'}) && $args{'encoding'} !~ /^\s*$/)
	{
		$encoding = $args{'encoding'} ;
		delete($args{'encoding'}) ;
	}
	my $self={list_type => 'Slackware::Slackget::Package','root-tag' => 'package-list',ENCODING => $encoding};
	foreach (keys(%args))
	{
		$self->{$_} = $args{$_};
	}
	bless($self,$class);
	return $self;
}

=head1 FUNCTIONS

This class inheritate from Slackware::Slackget::List (L<Slackware::Slackget::List>), so you may want read the Slackware::Slackget::List documentation for the supported methods of this class.

The present documentation present only methods that differs from the Slackware::Slackget::List class.

=cut

=head2 fill_from_xml

Fill the Slackware::Slackget::PackageList from the XML data passed as argument.

	$packagelist->fill_from_xml(
		'<choice action="installpkg">
			<package id="gcc-objc-3.3.4-i486-1">
				<date hour="12:32:00" day-number="12" month-number="06" year="2004" />
				<compressed-size>1395</compressed-size>
				<location>./slackware/d</location>
				<package-source>slackware</package-source>
				<version>3.3.4</version>
				<name>gcc-objc</name>
				<uncompressed-size>3250</uncompressed-size>
				<description>gcc-objc (Objective-C support for GCC)
					Objective-C support for the GNU Compiler Collection.
					This package contains those parts of the compiler collection needed to
				compile code written in Objective-C.  Objective-C was originally
				developed to add object-oriented extensions to the C language, and is
				best known as the native language of the NeXT computer.
		
				</description>
				<signature-checksum>565a10ce130b4287acf188a6c303a1a4</signature-checksum>
				<checksum>23bae31e3ffde5e7f44617bbdc7eb860</checksum>
				<architecture>i486</architecture>
				<package-location>slackware/d/</package-location>
				<package-version>1</package-version>
				<referer>gcc-objc</referer>
			</package>
		
			<package id="gcc-objc-3.4.3-i486-1">
				<date hour="18:24:00" day-number="21" month-number="12" year="2004" />
				<compressed-size>1589</compressed-size>
				<package-source>slackware</package-source>
				<version>3.4.3</version>
				<name>gcc-objc</name>
				<signature-checksum>1027468ed0d63fcdd584f74d2696bf99</signature-checksum>
				<architecture>i486</architecture>
				<checksum>5e659a567d944d6824f423d65e4f940f</checksum>
				<package-location>testing/packages/gcc-3.4.3/</package-location>
				<package-version>1</package-version>
				<referer>gcc-objc</referer>
			</package>
		</choice>'
	);

=cut

sub fill_from_xml
{
	my ($self,@xml) = @_ ;
	my $xml = '';
	foreach (@xml)
	{
		$xml .= $_ ;
	}
	require XML::Simple ;
	$XML::Simple::PREFERRED_PARSER='XML::Parser' ;
	my $xml_in = XML::Simple::XMLin($xml,KeyAttr => {'package' => 'id'});
# 	use Data::Dumper ;
# 	print Data::Dumper::Dumper($xml_in);
	foreach my $pack_name (keys(%{$xml_in->{'package'}})){
		my $package = new Slackware::Slackget::Package ($pack_name);
		foreach my $key (keys(%{$xml_in->{'package'}->{$pack_name}})){
			if($key eq 'date')
			{
				$package->setValue($key,Slackware::Slackget::Date->new(%{$xml_in->{'package'}->{$pack_name}->{$key}}));
			}
			else
			{
				$package->setValue($key,$xml_in->{'package'}->{$pack_name}->{$key}) ;
			}
			
		}
		$self->add($package);
	}
}

=head2 Sort

Apply the Perl built-in function sort() on the PackageList. This method return nothing.

	$list->Sort() ;

=cut

sub Sort
{
	my $self = shift ;
	$self->{LIST} = [ sort {$a->{ROOT} cmp $b->{ROOT} } @{ $self->{LIST} } ] ;
}

=head2 index_list

Create an index on the PackageList. This index don't take many memory but speed a lot search, especially when you already have the package id !

The index is build with the Package ID.

=cut

sub index_list
{
	my $self = shift ;
	$self->{INDEX} = {} ;
	foreach my $pkg (@{$self->{LIST}})
	{
# 		print "[Slackware::Slackget::PackageList] indexing package: ",$pkg->get_id(),"\n";
		$self->{INDEX}->{$pkg->get_id()} = $pkg ;
	}
	return 1;
}

=head2 get_indexed

Return a package, as well as Get() do but use the index to return it quickly. You must provide a package ID to this method.

	my $pkg = $list->get_indexed($qlistviewitem->text(5)) ;

=cut

sub get_indexed
{
	my ($self, $id) = @_ ;
	return $self->{INDEX}->{$id} ;
}

=head2 get_indexes

Return the list of all indexes

	my @indexes = $list->get_indexes() ;

=cut

sub get_indexes
{
	my ($self, $id) = @_ ;
	return keys(%{$self->{INDEX}}) ;
}

sub __to_string {
	my $self = shift ;
# 	PACKAGES.TXT;  Tue Aug 26 23:19:17 CEST 2008
# 	
# 	This file provides details on the packages found on this site
# 	Total size of all packages (compressed) :  4002 MB
# 	Total size of all packages (uncompressed) :  10091 MB
	my $now_string = localtime;
	my $text = "PACKAGES.TXT; $now_string\n\nThis file provides details on the packages found on this site\n";
	my $tsc = 0; # total size compressed
	my $tsu = 0; # total size uncompressed
	my $tmp_text = '';
	foreach (@{$self->{LIST}}){
		$tmp_text .= $_->to_string()."\n";
		$tsc += $_->compressed_size();
		$tsu += $_->uncompressed_size();
	}
	$tmp_text =~ s/\n{3,}/\n\n/g;
	$tsc = int( $tsc / 1024 );
	$tsu = int( $tsu / 1024 );
	$text .= "Total size of all packages (compressed) :  $tsc MB\nTotal size of all packages (uncompressed) :  $tsu MB\n\n";
	$text .= "$tmp_text\n";
}

=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis@infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-slackget10@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=slackget10>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

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

1; # End of Slackware::Slackget::PackageList
