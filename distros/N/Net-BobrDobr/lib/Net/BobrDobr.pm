package Net::BobrDobr;

## Project: BobrDobr.ru
## File     BobrDobr.pm
## Creator: Artur Penttinen <artur.penttinen@scandicom.fi>
## Creation date: <Friday 06-June-2008 08:58 || Artur Penttinen>
## Last modified: <Friday 06-June-2008 12:28 || Artur Penttinen>
##
## Copyright (C) 2008 Artur Penttinen
##
## $Id:$
##

use 5.006;
use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use LWP::UserAgent;
use URI::Escape;
use IO::File;
use XML::Simple;

our $VERSION = (qw$Revision: $)[1] || "0.01";

my $agent = "NetBobrDobr/$VERSION (perl-agent)";
my $authurl = "http://bobrdobr.ru/";
my $requrl = "http://bobrdobr.ru/services/rest/" .
    "?method=%s&api_key=%s&%s&api_sig=%s";
my %commonhdr = ( 'accept' => "text/html, text/plain, text/css, */*;q=0.01",
		  'accept-encoding' => "gzip, bzip2",
		  'accept-language' => "ru, en",
		  'pragma' => "no-cache",
		  'cache-control' => "no-cache",
		  'accept-charset' => "utf8, iso-8859-1;q=0.01," );
my $error;

sub new ($%) {
    my ($class,%opt) = @_;
    my $self = {};

    $self = read_file ($opt{'api'}) if (exists $opt{'api'});

    $self->{'.api-key'} = $opt{'api-key'}
	if (exists $opt{'api-key'});
    $self->{'.api-secret'} = $opt{'api-secret'}
	if (exists $opt{'api-secret'});
    $self->{'.debug'} = exists $opt{'debug'} && $opt{'debug'} ? 1 : 0;

    unless (exists ($self->{'.api-key'}) ||
	    exists ($self->{'.api-secret'})) {
	$error = "not supplied api-key or api-secret";
	# return;
    }

    $self->{'.ua'} = new LWP::UserAgent ('agent' => $opt{'agent'} || $agent,
					 'timeout' => $opt{'timeout'} || 60,
					 'cookie_jar' => $opt{'cookie'} || {});
    $self->{'.ua'}->env_proxy;
    return bless $self,$class;
}

sub connect ($$$) {
    my ($self,$login,$password) = @_;

    unless (defined ($login) || defined ($password)) {
	$error = "not supplied login or password";
	return;
    }

    $self->{'.ua'}->get ($authurl)->is_success or return;

    my $auth = { 'username' => $login,
		 'password' => $password,
		 'remember_user' => "on",
		 'next' => "/" };
    my $ret = $self->{'.ua'}->post ($authurl . "login/",
				     %commonhdr,
				     'referer' => $authurl,
				     'content' => $auth);

    if ($ret->is_success || $ret->is_redirect) {
	return $self;
    }
    else {
	$error = $ret->status_line;
	return;
    }
}

## Call BD-method
sub call ($$;%) {
    my ($self,$method,%args) = @_;

    my $secret = join "",$self->{'.api-secret'},"api_key",$self->{'.api-key'},
	map { $_ eq "method" ? "method$method" : "$_$args{$_}" }
	    sort "method",keys %args;
    my $md5secret = md5_hex ($secret);
    my $args = join "&",map { join "=",uri_escape ($_),uri_escape ($args{$_}) }
	keys %args;
    my $url = sprintf $requrl,$method,$self->{'.api-key'},$args,$md5secret;
    $url =~ s#&&+#&#g;

    return $url if ($self->{'.debug'});

    my $ret = $self->{'.ua'}->get ($url);

    if ($ret->is_success) {
	return XMLin ($ret->content);
    }
    else {
	$error = $ret->status_line;
	return;
    }
}

## Call BD-method, return plain answer
sub plaincall ($$;%) {
    my ($self,$method,%args) = @_;

    my $secret = join "",$self->{'.api-secret'},"api_key",$self->{'.api-key'},
	map { $_ eq "method" ? "method$method" : "$_$args{$_}" }
	    sort "method",keys %args;
    my $md5secret = md5_hex ($secret);
    my $args = join "&",map { join "=",uri_escape ($_),uri_escape ($args{$_}) }
	keys %args;
    my $url = sprintf $requrl,$method,$self->{'.api-key'},$args,$md5secret;
    $url =~ s#&&+#&#g;

    return $url if ($self->{'.debug'});

    my $ret = $self->{'.ua'}->get ($url);

    if ($ret->is_success) {
	return $ret->content;
    }
    else {
	$error = $ret->status_line;
	return;
    }
}

sub read_file ($) {
    my ($file) = @_;
    my %ret;

    my $io = new IO::File $file or return;
    while (<$io>) {
	chomp;
	my ($a,$b) = split ":\\s*",$_,2;
	$ret{".$a"} = $b if ($a eq "api-key" || $a eq "api-secret");
    }
    $io->close;

    return \%ret;
}

sub error ($) {
    return $error;
}

1;

__END__

=head1 NAME

Net::BobrDobr - module for using http://bobrdobr.ru.

=head1 SYNOPSIS

  use Net::BobrDobr;
  my $bd = new Net::BobrDobr (...);
  $bd->connect (...) or die $bd->error;
  my $ret = $bd->call (...);

=head1 DESCRIPTION

This module intended for deplouing social bookmark network
L<http://BobrDobr.ru>. You can log in to site, retrieve bookmarks,
add bokmarks and remove bookmarks (list of all available operations
you can find at L<http://bobrdobr.ru/api.html>).

=head2 METHODS

=over 2

=item I<new()>

Create new instance of this module. Parameters for this call:

=over 4

=item I<'api' =E<gt> $file>

File with B<bobrdobr>-api keys, in format

  api-key: <api application key>
  api-secret: <api secret key>

=item I<'api-key' =E<gt> $api_key>

Manually supplied B<bobrdobr> api application key.

=item I<'api-secret' =E<gt> $api_secret>

Manually supplied B<bobrdobr> api secret key.

=item I<'agent' =E<gt> $agent>

Agent name for client, may be omitted.

=item I<'timeout' =E<gt> $timeout>

Timeout, default is 60 secs.

=item I<'cookie_jar' =E<gt> $file>

File for saving authentification cookies.

=back

Returns C<undef> if unsuccess, and C<$self> if success.

=item I<connect()>

This method perform all authentification operations.
It got only two parameters -- I<login> and I<password>:

  $bd->connect ($login,$password);

Returns C<undef> if unsuccess, and C<$self> if success.

=item I<call()>

Main method for call B<bobrdobr>-services. List of all available
methods you can find in L<http://bobrdobr.ru/api.html>.

First argument or this method is a name of B<bobrdobr> operation,
as a C<"test.echo">, and rest -- hash of named parameters for this
operations. E.g.:

  my $ret = $bd->call ("test.echo",'param1' => "one");

Return reference to hash from server, or empty if request fail.

Main field for return hash: C<$ret->{'stat'}>, it may be:C<"ok">
if operation success, or C<"fail"> in other case. Full description
see in L<http://bobrdobr.ru/api.html>.

=item I<plaincall()>

It is same method as call, but return raw content from server
(REST XML form).

=back

=head1 SEE ALSO

L<http://bobrdobr.ru/api.html>, L<XML::Simple>,
L<LWP::UserAgent>.

=head1 AUTHOR

Artur Penttinen, E<lt>artur+perl@niif.spb.suE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Artur Penttinen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

### That's all, folks!
