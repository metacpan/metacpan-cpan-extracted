package Net::SSL::AutoCA;

use warnings;
use strict;

=head1 NAME

Net::SSL::AutoCA - Provides a automated method for locating CA bundle file/directory.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Net::SSL::AutoCA;

    my $autoca = Net::SSL::AutoCA->new();

    if( defined( $autoca->{CAfile} ) || defined( $autoca->{CApath} ) ){
        if( defined( $autoca->{CAfile} ) ){
            print 'CA file: '.$autoca->{CAfile}."\n";
        }

        if( defined( $autoca->{CApath} ) ){
            print 'CA path: '.$autoca->{CApath}."\n";

            #as it currently stands, this will always be true if
            #$autoca->{CApath} is defined, unless done via a
            #enviromental variable
            if( $autoca->{checkCRL} ){
                print "Check CRL\n";
            }

        }
    }

=head1 METHODS

=head2 new

=head3 args hash

=head4 methods

This is the methods it should us.

The value taken is a camma seperated list. The
default value is 'path,env'.

The supported values listed below

    env
    path

=head4 userssl

If set to 1, '~/.sslca' will be check.

This requires $ENV{USER} to be defined.

=head4 prefix

This allows adds a addiontal prefix to check instead of
just '/usr' and '/usr/local'.

=head4 prefixByEnv

If set to 1, it will populate the prefix info
via $ENV{'Net::SSL::AutoCA-prefix'}.

=cut

sub new{
	my %args;
	if (defined( $_[1] )) {
		%args=%{$_[1]};
	}

	my $self={error=>undef, CAfile=>undef, CApath=>undef, checkCRL=>undef};
	bless $self;

	#get the methods to use
	if (defined( $args{methods} )) {
		$self->{methods}=$args{methods};
	}else {
		$self->{methods}='path,env';
	}

	#gets the prefix to use, if needed
	if (defined( $args{prefix} )) {
		$self->{prefix}=$args{prefix};
	}

	#set the prefix by env variable
	if ( defined( $args{prefixByEnv} ) ) {
		$self->{prefixByEnv}=$args{prefixByEnv};
	}else {
		$self->{prefixByEnv}=1;
	}

	#get the prefix by env if needed
	if ($self->{prefixByEnv}) {
		if (defined( $ENV{'Net::SSL::AutoCA-prefix'} )) {
			$self->{prefix}=$ENV{'Net::SSL::AutoCA-prefix'};
		}
	}

	#runs through the methodes and finds one to use
	my @split=split(/,/, $self->{methods}); #splits them apart at every ','
	my $splitInt=0;
	while (defined($split[$splitInt])){
		#handles it via the env method
		if ($split[$splitInt] eq "path") {
			
		}

		$splitInt++;
	}

	$self->byPath;

	return $self;
}

=head2 clear

This clears the selections.

    my $autoca->clear;

=cut

sub clear{
	my $self=$_[0];

	$self->{CAfile}=undef;
	$self->{CApath}=undef;
	$self->{checkCRL}=undef;

	return 1;
}

=head2 byPath

This fetches it by the path.

=head3 args hash

=head4 userssl

If set to 1, '~/.sslca/' and '~/.sslca.bundle' will
be check.

This requires $ENV{USER} to be defined.

=head3 PATH ORDER

=head4 dir

    ~/.sslca/
    /etc/ssl/ca/
    /usr/local/etc/ssl/ca/
    $prefix/etc/ssl/ca/

=head4 file

    ~/.sslca.bundle
    /etc/ssl/ca.bundle
    /usr/local/etc/ssl/ca.bundle
    /usr/share/certs/ca-root-nss.crt
    /usr/local/share/certs/ca-root-nss.crt
    $prefix/etc/ssl/ca.bundle
    $prefix/share/certs/ca-root-nss.crt

    my $returned=$autoca->byPath({userssl=>1});
    if($returned){
        print "Nothing matched.
    }

=cut

sub byPath{
	my $self=$_[0];
	my %args;
	if (defined( $_[1] )) {
		%args=%{$_[1]};
	}

	my @dircheck;
	my @filecheck;

	#prepents the user stuff first.
	if ($args{userssl}) {
		if (defined( $ENV{USER} )) {

			my ($name,$passwd,$uid,$gid,
				$quota,$comment,$gcos,$dir,$shell,$expire)=getpwnam($ENV{USER});

			push(@dircheck, $dir.'/.sslca');
			push(@filecheck, $dir.'/.sslca.bundle');
		}
	}

	my @dircheck2=(
				   '/etc/ssl/ca/',
				   '/usr/local/etc/ssl/ca/',
				   );
	my @filecheck2=(
					'/etc/ssl/ca.bundle',
					'/usr/local/etc/ssl/ca.bundle',
					'/usr/share/certs/ca-root-nss.crt',
					'/usr/local/share/certs/ca-root-nss.crt',
					);

	#append the prefix stuff if needed
	if (defined( $self->{prefix} )) {
		push(@dircheck, $self->{prefix}.'/etc/ssl/ca/');
		push(@filecheck, $self->{prefix}.'/etc/ssl/ca.bundle');
		push(@filecheck, $self->{prefix}.'/share/certs/ca-root-nss.crt');
	}

	push(@dircheck, @dircheck2);
	push(@filecheck, @filecheck2);

	#run through each one for directories
	my $int=0;
	my $matched=undef;
	while (defined( $dircheck[$int] )){
		if (-d $dircheck[$int]) {
			$self->{CApath}=$dircheck[$int];
			$self->{checkCRL}=1;
			$matched=1;
		}

		$int++;
	}

	#run through each one for files
	$int=0;
	$matched=undef;
	while (defined($filecheck[$int])){
		if (-f $filecheck[$int]) {
			$self->{CAfile}=$filecheck[$int];
			$matched=1;
		}

		$int++;
	}

	return $matched;
}

=head2 byEnv

This fetches it via a enviromental variables.

    Net::LDAP::AutoCA-CAfile
    Net::LDAP::AutoCA-CApath
    Net::LDAP::AutoCA-checkCRL

=cut

sub byEnv{
	my $self=$_[0];

	my $matched=undef;

	if (defined($ENV{'Net::LDAP::AutoCA-CAfile'})) {
		$self->{CAfile}=$ENV{'Net::LDAP::AutoCA-CAfile'};
		$matched=1;
	}

	if (defined($ENV{'Net::LDAP::AutoCA-CApath'})) {
		$self->{CApath}=$ENV{'Net::LDAP::AutoCA-CApath'};
		$matched=1;
	}

	if (defined($ENV{'Net::LDAP::AutoCA-checkCRL'})) {
		$self->{checkCRL}=$ENV{'Net::LDAP::AutoCA-checkCRL'};
	}

	return $matched;
}

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ssl-autoca at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SSL-AutoCA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SSL::AutoCA


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SSL-AutoCA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SSL-AutoCA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SSL-AutoCA>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SSL-AutoCA/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::SSL::AutoCA
