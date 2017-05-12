package Slackware::Slackget::Config;

use warnings;
use strict;

$XML::Simple::PREFERRED_PARSER='XML::Parser';
use XML::Simple;

=head1 NAME

Slackware::Slackget::Config - An interface to the configuration file

=head1 VERSION

Version 1.0.1

=cut

our $VERSION = '1.0.1';

=head1 SYNOPSIS

This class is use to load a configuration file (config.xml) and the servers list file (servers.xml). It only encapsulate the XMLin() method of XML::Simple, there is no accessors or treatment method for this class.
There is only a constructor which take only one argument : the name of the configuration file.

After loading you can acces to all values of the config file in the same way that with XML::Simple.

The only purpose of this class, is to allow other class to check that the config file have been properly loaded.

    use Slackware::Slackget::Config;

    my $config = Slackware::Slackget::Config->new('/etc/slack-get/config.xml') or die "cannot load config.xml\n";
    print "I will use the encoding: $config->{common}->{'file-encoding'}\n";
    print "slack-getd is configured as: $config->{daemon}->{mode}\n" ;

This module needs XML::Simple to work.

=cut

=head1 CONSTRUCTOR

=head2 new

The constructor take the config file name as argument.

	my $config = Slackware::Slackget::Config->new('/etc/slack-get/config.xml') or die "cannot load config.xml\n";

=cut

sub new
{
	my ($class,$file) = @_ ;
	return undef unless(-e $file && -r $file);
	my $self= XMLin($file , ForceArray => ['li']) or return undef;
# 	use Data::Dumper;
# 	print "[Slackware::Slackget::Config]",Dumper($self);
	return undef unless(defined($self->{common}));
	if(exists($self->{'plugins'}->{'list'}->{'plug-in'}->{'id'}) && defined($self->{'plugins'}->{'list'}->{'plug-in'}->{'id'}))
	{
		my $tmp = $self->{'plugins'}->{'list'}->{'plug-in'};
		delete($self->{'plugins'}->{'list'}->{'plug-in'});
		$self->{'plugins'}->{'list'}->{'plug-in'}->{$tmp->{'id'}} = $tmp;
		delete($self->{'plugins'}->{'list'}->{'plug-in'}->{$tmp->{'id'}}->{'id'});
	}
	if($ENV{SG_DAEMON_DEBUG}){
		require Data::Dumper;
		print "[Slackware::Slackget::Config]",Data::Dumper::Dumper( $self ),"\n";
	}
	bless($self,$class);
	return $self;
}

=head2 get_token

Return the value associated to the given token.

Tokens are requested through a path like syntax. For example, the following XML :

  <xml>
    <item>
      <key>value</key>
    </item>
  </xml>

The <key> element's value is accessed throught :

  print $config->get_token("/item/key"); # the root key is not kept by this class


**WARNING** even if it could look like XPath : IT IS NOT !

=cut


sub get_token {
	my ($self,$req) = @_ ;
	my @R = split(/\//,$req);
	my $token;
	my $ref = $self;
	while(@R){
		$token = shift(@R);
		next if($token =~ /^\s*$/);
		$ref = $ref->{$token};
	}
	return $ref;
}

=head2 set_token

Following the same syntax as the get_token() method, it allows you to set a configuration token.

  $config->set_token("/item/key", "new value");

The value can be anything fitting a scalar (number, strings, array ref, hash ref, etc.)

=cut

sub set_token {
	my ($self,$req,$data) = @_ ;
	my @R = split(/\//,$req);
	my $token;
	my $ref = $self;
	my $c;
	while(@R){
		$token = shift(@R);
		next if(!defined($token) || $token =~ /^\s*$/);
		print "$c- $token ",scalar(@R)," ";
		$c .= "  ";
		if(scalar(@R) >= 1){
			$ref->{$token} = {} unless( defined($ref->{$token}) );
			$ref = $ref->{$token} ;
			print "(not last token)";
		}else{
			$ref->{$token} = $data;
			print "(is the last token)";
		}
		print "\n";
	}
	
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

1; # End of Slackware::Slackget::Config
