package Slackware::Slackget::Status;

use warnings;
use strict;

=head1 NAME

Slackware::Slackget::Status - A class for returning a status code with its explanations

=head1 VERSION

Version 1.0.100

=cut

our $VERSION = '1.0.100';

=head1 SYNOPSIS

This class is used at a status object which can tell more informations to user. In this object are stored couples of integer (the return code of the function which return the status object), and string (the human readable description of the error)

    use Slackware::Slackget::Status;

    my $status = Slackware::Slackget::Status->new(
    	codes => {
		0 => "All operations goes well",
		1 => "Parameters unexpected",
		2 => "Network error"
	}
    );
    print "last error message was: ",$status->to_string,"\n";
    if($status->is_error)
    {
    	die "Error: ",$status->to_string,"\n";
    }
    elsif($status->is_success)
    {
    	print $status->to_string,"\n";
    }

Please note that you must see at the documentation of a class to know the returned codes.

=cut

sub new
{
	my ($class,%arg) = @_ ;
	my $self={ CURRENT_CODE => undef };
# 	return undef if(!defined($arg{'codes'}) && ref($arg{codes}) ne 'HASH');
	$self->{CODES} = $arg{'codes'} ;
	$self->{ERROR_CODES} = $arg{'error_codes'} if($arg{'error_codes'}) ;
	$self->{SUCCESS_CODES} = $arg{'success_codes'} if($arg{'success_codes'}) ;
	bless($self,$class);
	return $self;
}

=head1 CONSTRUCTOR

=head2 new

You need to pass to the constructor a parameter 'codes' wich contain a hashref with number return code as keys and explanation strings as values :

	my $status = new Slackware::Slackget::Status (
		codes => {
			0 => "All good\n",
			1 => "Network unreachable\n",
			2 => "Host unreachable\n",
			3 => "Remote file seems not exist\n"
		}
	);

You can, optionnally, give to more parameters : success_codes and error_codes within the same format than codes. It'll allow you to control the current status via the is_success() and is_error() methods.

=head1 FUNCTIONS

=head2 to_string

Return the explanation string of the current status.

	if($connection->fetch_file($remote_file,$local_file) > 0)
	{
		print "ERROR : ",$status->to_string ;
		return undef;
	}
	else
	{
		...
	}

=cut

sub to_string {
	my $self = shift;
	return $self->{SUCCESS_CODES}->{$self->{CURRENT_CODE}} if($self->{SUCCESS_CODES}->{$self->{CURRENT_CODE}}) ;
	return $self->{ERROR_CODES}->{$self->{CURRENT_CODE}} if($self->{ERROR_CODES}->{$self->{CURRENT_CODE}}) ;
	return $self->{CODES}->{$self->{CURRENT_CODE}} ;
}

=head2 to_int

Same as to_string but return the code number.

=cut

sub to_int {
	my $self = shift;
	return $self->{CURRENT_CODE} ;
}

=head2 to_XML (deprecated)

Same as to_xml(), provided for backward compatibility.

=cut

sub to_XML {
	return to_xml(@_);
}

=head2 to_xml

return an xml ecoded string, represented the current status. The XML string will be like that :

	<status code="0" description="All goes well" />

	$xml_file->Add($status->to_xml) ;

=cut

sub to_xml
{
	my $self = shift ;
	return "<status code=\"".$self->to_int()."\" description=\"".$self->to_string()."\" />";
}

=head2 to_HTML (deprecated)

Same as to_html(), provided for backward compatibility.

=cut

sub to_HTML {
	return to_html(@_);
}

=head2 to_html

return the status as an HTML encoded string

=cut

sub to_html
{
	my $self = shift ;
	return "<p id=\"status\"><h3>Status</h3><strong>code :</strong> ".$self->to_int()."<br/><strong>description :</strong> ".$self->to_string()."<br/>\n</p>\n";
}

=head2 current

Called wihtout argument, just call to_int(), call with an integer argument, set the current status code to this int.

	my $code = $status->current ; # same effect as my $code = $status->to_int ;
	or
	$status->current(12);
	
Warning : call current() with a non-integer argument will fail ! The error code MUST BE AN INTEGER.

=cut

sub current
{
	my ($self,$code) = @_;
	if(!defined($code))
	{
		return $self->to_int ;
	}
	else
	{
		if($code=~ /^\d+$/)
		{
			print "[Slackware::Slackget::Status] (debug) setting current status code to $code.\n" if($ENV{SG_DAEMON_DEBUG});
			$self->{CURRENT_CODE} = $code;
			return 1;
		}
		else
		{
			warn "[Slackware::Slackget::Status] '$code' is not an integer.\n";
			return undef;
		}
	}
}

=head2 is_success

return true (1) if the current() code is declared as a success code (constructor's parameter: success_codes). Return false otherwise (particularly if you have only set codes and not success_codes).

=cut

sub is_success {
	my $self = shift;
# 	return 1 if($self->{SUCCESS_CODES}->{$self->{CURRENT_CODE}});
	foreach my $code ( keys(%{$self->{SUCCESS_CODES}}) ){
# 		print "[Slackware::Slackget::Status] comparing success code '$code' to current status code '".$self->{CURRENT_CODE}."'.\n";
		return 1 if($code == $self->{CURRENT_CODE})
	}
	return 0;
}


=head2 is_error

return true (1) if the current() code is declared as an error code (constructor's parameter: error_codes). Return false otherwise (particularly if you have only set codes and not error_codes).

=cut

sub is_error {
	my $self = shift;
	return 1 if($self->{ERROR_CODES}->{$self->{CURRENT_CODE}});
	return 0;
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

    perldoc Slackware::Slackget::Status


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

1; # End of Slackware::Slackget::Status
