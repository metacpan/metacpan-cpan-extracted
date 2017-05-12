package Slackware::Slackget::Local;

use warnings;
use strict;

require Slackware::Slackget::File ;
require XML::Simple;
$XML::Simple::PREFERRED_PARSER='XML::Parser' ;

=head1 NAME

Slackware::Slackget::Local - A class to load the locales

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

This class' purpose is to load and export the local.

    use Slackware::Slackget::Local;

    my $local = Slackware::Slackget::Local->new();
    $local->load('/usr/local/share/slack-get/local/french.xml');
    print $local->get('__SETTINGS') ;

=cut

sub new
{
	my ($class,$file) = @_ ;
	my $self={};
	bless($self,$class);
	if(defined($file) && -e $file)
	{
		$self->Load($file);
	}
	return $self;
}

=head1 CONSTRUCTOR

=head2 new

Can take an argument : the LC_MESSAGES file. In this case the constructor automatically call the Load() method.

	my $local = new Slackware::Slackget::Local();
	or
	my $local = new Slackware::Slackget::Local('/usr/local/share/slack-get/local/french.xml');

=head1 FUNCTIONS

=head2 Load (deprecated)

Same as load(), provided for backward compatibility.

=cut

sub Load {
	return load(@_);
}

=head2 load

Load the local from a given file

	$local->load('/usr/local/share/slack-get/local/french.xml') or die "unable to load local\n";

Return undef if something goes wrong, 1 else.

=cut

sub load {
	my ($self,$file) = @_ ;
	return undef unless(defined($file) && -e $file);
	print "[Slackware::Slackget::Local] loading file \"$file\"\n";
	my $data = XML::Simple::XMLin( $file , KeyAttr=> {'message' => 'id'}) ;
	$self->{DATA} = $data->{'message'} ;
	$self->{LP_NAME} = $data->{name} ;
	return 1;
}

=head2 get_indexes

Return the list of all index of the current loaded local. Dependending of the context, this method return an array or an arrayref.

	# Return a list
	foreach ($local->get_indexes) {
		print "$_ : ",$local->Get($_),"\n";
	}
	
	# Return an arrayref
	my $index_list = $local->get_indexes ;

=cut

sub get_indexes
{
	my $self = shift;
	my @a = keys( %{$self->{DATA} });
	return wantarray ? @a : \@a;
}

=head2 Get (deprecated)

Same as get(), provided for backward compatibility.

=cut

sub Get {
	return get(@_);
}

=head2 get

Return the localized message of a given token :

	my $error_on_modification = $local->get('__ERR_MOD') ;

Return undef if the token doesn't exist.

You can also pass extra arguments to this method, and if their is wildcards in the token they will be replace by those values. Wildcards are %1, %2, ..., %x.

Here is and example :
 
	# The token is :
	# __NETWORK_CONNECTION_ERROR = Error, cannot connect to %1, the server said ``%2''.
	my $localized_token = $local->get('__NETWORK_CONNECTION_ERROR', '192.168.0.42', 'Connection not authorized');
	print "$localized_token\n";
	# $localized_token contains the string "Error, cannot connect to 192.168.0.42, the server said ``Connection not authorized''."


=cut

sub get {
	my ($self,$token,@args) = @_ ;
	if(@args)
	{
		@args = (0,@args);
		my $tmp = $self->{DATA}->{$token}->{'content'};
		for(my $k=1;$k<=$#args; $k++)
		{
			$tmp =~ s/%$k/$args[$k]/g ;
		}
		return $tmp;
	}
	else
	{
		return $self->{DATA}->{$token}->{'content'};
	}
}

=head2 to_XML (deprecated)

Same as to_xml(), provided for backward compatibility.

=cut

sub to_XML {
	return to_xml(@_);
}

sub to_xml
{
	my $self = shift;
	my @msg = sort {$a cmp $b} keys(%{ $self->{DATA} });
	my $xml = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n<local name=\"$self->{LP_NAME}\">\n";
	foreach my $token (@msg)
	{
		unless(defined( $self->{DATA}->{$token}->{content} ))
		{
			print "token \"$token\" have no associate value.\n";
			next;
		}
		
		$xml .= "\t<message id=\"$token\"><![CDATA[$self->{DATA}->{$token}->{content}]]></message>\n";
	}
	$xml .= "</local>";
}

=head2 name

Accessor for the name of the Local (langpack).

	print "The current langpack name is : ", $local->name,"\n";
	$local->name('Japanese'); # Set the name of the langpack to 'Japanese'.

=cut

sub name
{
	my $self = shift;
	my $name = shift;
	return $name ? ($self->{LP_NAME}=$name) : $self->{LP_NAME};
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

    perldoc Slackware::Slackget::Local


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

1; # End of Slackware::Slackget::Local
