package Sanitize;

use 5.016003;
use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = qw(sanitize validate);
our @EXPORT = qw(sanitize validate);
our $VERSION = '1.00';

sub sanitize
{
	my ($s, @args) = @_;
	if(!$s) { return ""; }
	my ($state, $result) = _process(@_);
	return $result;
}

sub validate
{
	my ($s) = @_;
	if(!$s) { return 0; }
	my ($state, $result) = _process(@_);
	return $state;
}

sub _process
{
	my ($s, %opts) = @_;

	if($opts{lc('alpha')})
	{
		$s =~ s/[^A-Za-z0-9]//g;
	}
	if($opts{lc('hex')})
	{
		$s =~ s/[^A-Fa-f0-9]//g;
	}
	if($opts{lc('number')})
	{
		$s =~ s/[^0-9]//g;
	}
	if($opts{lc('html')})
	{
		$s =~ s/</&lt;/g;
		$s =~ s/>/&gt;/g;
	}
	if($opts{lc('ltrim')})
	{
		$s =~ s/^\s+//g; 
	}
	if($opts{lc('rtrim')})
	{
		$s =~ s/\s+$//g;
	}
	if($opts{lc('trim')} || $opts{lc('nospace')})
	{
		$s =~ s/\s+//g;
	}
	if($opts{lc('noquotes')} || $opts{lc('noquote')})
	{
		$s =~ s/"//g;
		$s =~ s/'//g;
	}
	if($opts{lc('noencodings')} || $opts{lc('noencoding')})
	{
		$s =~ s/%[0-9A-Fa-f]{2}//g;
	}
	if($opts{lc('password')})
	{
		$s =~ s/./*/g;
	}
	if($opts{lc('email')})
	{
		my ($name, $host) = split('@', $s);
		if(!$name || !$host) { return (0, ""); }
		$name = (split(' ', $name))[-1];
		$host = (split(' ', $host))[0];
		$name =~ s/[^A-Za-z0-9\.\!\#\$\%\&\'\*\+\-\/\=\?\^\_\`\{\|\}~]//g;
		$host =~ s/[^A-Za-z0-9\.\-]//g;
		$host =~ s/[\.\-]$//g;
		$s = $name . '@' . $host;
	}
	if($opts{lc('ip')} && $opts{lc('port')})
	{
		if($s =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d{1,5})/)
		{
			$s = $1;
		}
		else { $s = ""; }	
	}
	if($opts{lc('ip')} && !$opts{lc('port')})
	{
		if($s =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/)
		{
			$s = $1;
		}
		else { $s = ""; }
	}
	if($opts{lc('port')} && !$opts{lc('ip')})
	{
		if($s =~ /(\:\d{1,5})/)
		{
			$s = $1;
			$s =~ s/\://g;
		}
		else { $s = ""; }
	}
	return ($s eq $_[0] ? 1 : 0, $s);
}

1;
__END__

=head1 NAME

Sanitize - Returns a sanitized version of strings

=head1 SYNOPSIS

	use Sanitize;

	sanitize("fd gfd*#(sd)", alpha => 1);  # Returns: "fggfdsd"
	
	sanitize("The ip is 192.168.3.53:80", ip => 1);  # Returns: "192.168.3.53"
	
	sanitize("The ip is 192.168.3.53:80", port => 1);  # Returns: "80"
	
	sanitize("The ip is 192.168.3.53:80", ip => 1, port => 1);  # Returns: "192.168.3.53:80"
	
	sanitize("Blah", password => 1);  # Returns: "****"
	
	sanitize("sf d54_d <script>alert('test');", html => 1);  # Returns: "sf d54_d &lt;script&gt;alert('test');"
	
	sanitize("Some email is: joe@test.com, email me now", email => 1);  # Returns: "joe@test.com"
	
	sanitize(" some thing  ", rtrim => 1);  # Returns: " some thing"
	
	sanitize(" some thing  ", ltrim => 1);  # Returns: "some thing  "
	
	sanitize(" some thing  ", nospace => 1);  # Returns: "something"
	
	sanitize("This is a %3Cscript%3Ealert('test');", noquote => 1, noencoding => 1);  # Returns: "This is a scriptalert(test);"
	
	validate("invalid email@some!host", email => 1);  # Returns: 0
	
	validate("10.0.0.1", ip => 1);  # Returns: 1
	
	validate("invalid.ip.7.4", ip => 1);  # Returns: 0


=head1 DESCRIPTION

This module offers simple ways to sanitize or validate string inputs against a number of possible criteria.

=head1 METHODS

=item $output = sanitize($input, criteria1 => 0|1, criteria2 => 0|1, ..)

Returns a sanitized version of the input.

=item $boolean = validate($input, criteria1 => 0|1, criteria2 => 0|1, ..)

Validates whether the input matches the provided criteria.

=head1 CRITERIA

=item alpha

Matches alphanumeric characters.

=item hex

Matches hexadecimal characters.

=item number

Matches numbers, either an integer value or string containing nothing but numbers.

=item html

Replaces any "<" and ">" with the encoded values "&lt;" and "&gt;".

=item email

Matches a valid "name"@"host" string, including valid characters for both the name and host parts.

=item nospace

Matches any space.

=item rtrim

Matches any space at the end of the string.

=item ltrim

Matches any space at the beginning of the string.

=item noquote

Matches any single or double quotes.

=item noencoding

Matches any URL encoding such as "%00" or "%3F".

=item password

Replaces all characters with "*".

=item ip

Matches a valid "xxx.xxx.xxx.xxx" IPv4 address.

=item port

Matches the port part of "host":"port".

=head1 AUTHOR

Patrick Lambert, E<lt>dendory@live.caE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Patrick Lambert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
