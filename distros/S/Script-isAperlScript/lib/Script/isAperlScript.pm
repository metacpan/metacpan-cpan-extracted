package Script::isAperlScript;

use warnings;
use strict;
use base 'Error::Helper';

=head1 NAME

Script::isAperlScript - This does a basic check if something is a perl script or not.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

This module does a basic check to see if something is a perl script.

By default it checks for the paths below.

    /^\#\!\/usr\/bin\/perl/
    /^\#\!\/usr\/bin\/suidperl/
    /^\#\!\/usr\/local\/bin\/perl/
    /^\#\!\/usr\/local\/bin\/suidperl/

This will also match stuff like "#!/usr/local/bin/perl5.8.9".

If {env=>1} is given to the new method, the checks below are done.

    /^\#!\/usr\/bin\/env.*perl/

If {any=>1} is given to the new method, the checks below are done.

    /^\#!\/.*perl/

=head1 METHODS

=head2 new

This initiates the object.

=head3 args hash

=head4 env

Allow env based scripts.

By default this is false as it can't be trusted.

=head4 any

This does very loose matching.

By default this is false as it can't be trusted.

    my $checker=Script::isAperlScript->new( \%args );

=cut

sub new{
	my %args;
	if ( defined( $_[1] ) ){
		%args=%{$_[1]};
	}

	my $self={
		error=>0,
		errorString=>0,
		env=>0,
		any=>0,
		errorExtra=>{
			flags=>{
				2=>'noString',
				3=>'doesNotExist',
				4=>'notReadable',
				5=>'fileNotSpecified',
				6=>'noFile',
				7=>'notAfile',
			},
		},
	};
	bless $self;

	if ( $args{env} ){
		$self->{env}=1;
	}

	if ( $args{any} ){
		$self->{any}=1;
	}

	return $self;
}

=head2 isAperlScript

This checks if a file is a Perl script.

Only one arguement is taken and it is the string in question.

In regards to the returned value, see the section "RETURN" for more information.

    my $returned=isAperlScript($file);
    if(!$returned){
        print "It returned false so there for it is a perl script.\n";
    }

=cut

sub isAperlScript{
	my $self=$_[0];
	my $file=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	#make sure a file is specified
	if (!defined($file)) {
		$self->{error}=5;
		$self->{errorString}='No file defined';
		return undef;
	}
	#make sure it exists
	if (! -e $file) {
		$self->{error}=3;
		$self->{errorString}='The file, "'.$file.'", does not exist';
		return undef;
	}

	#it is not a file
	if (! -f $file) {
		$self->{error}=7;
		$self->{errorString}='"'.$file.'" is not a file';
		return undef;
	}

	#make sure it is readable
	if (! -r $file) {
		$self->{error}=4;
		$self->{errorString}='"'.$file.'" is not readable';
		return undef;
	}

	#try to open it
	if (open(THEFILE, '<', $file )) {
		my $string=join("", <THEFILE>);
		close(THEFILE);
		return $self->stringIsAperlScript($string);
	}

	#it could not be opened
	$self->{error}=6;
	$self->{errorString}='"'.$file.'" could not be opened';
	return undef;
}

=head2 stringIsAperlScript

This checks if a string is a Perl script.

Only one arguement is taken and it is the string in question.

In regards to the returned value, see the section "RETURN" for more information.

    my $returned=stringIsAperlScript($string);
    if(!$returned){
        print "It returned false so there for it is a perl script.\n";
    }

=cut

sub stringIsAperlScript{
	my $self=$_[0];
	my $string=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	#make sure a string is specified
	if (!defined( $string )) {
		$self->{error}=2;
		$self->{errorString}='No string defined';
		return undef;
	}

	#check if it should possibly do the any check
	if ( $self->{any} ){
		if ($string =~ /^\#\!\/.*perl/) {
			return 1;
		}
	}
	
	#checks if it makes #!/usr/bin/perl
	if ($string =~ /^\#\!\/usr\/bin\/perl/) {
		return 1;
	}

	#checks if it makes #!/usr/bin/suidperl
	if ($string =~ /^\#\!\/usr\/bin\/suidperl/) {
		return 1;
	}

	#checks if it makes #!/usr/local/bin/perl
	if ($string =~ /^\#\!\/usr\/local\/bin\/perl/) {
		return 1;
	}

	#checks if it makes #!/usr/local/bin/suidperl
	if ($string =~ /^\#\!\/usr\/local\/bin\/suidperl/) {
		return 1;
	}

	#check if it should possibly do the env check
	if ( $self->{env} ){
		if ( $string =~ /^\#!\/usr\/bin\/env.*perl/ ) {
			return 1;
		}
	}

	#not a perl script
	return undef;
}

=head1 ERROR CODES/FLAGS/HANDLING

The easiest way to check is to verify the returned value is false.

Error handling is provided by L<Error::Helper>.

=head2 2, noString

The string is not defined.

=head2 3, doesNotExist

The file does not exist.

=head2 4, notReadable

The file is not readable.

=head2 5, fileNotSpecified

No file specified.

=head2 6, noFile

The file could not be opened.

=head2 7, notAfile

The specified file is not a file.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-script-isaperlscript at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Script-isAperlScript>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Script::isAperlScript


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Script-isAperlScript>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Script-isAperlScript>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Script-isAperlScript>

=item * Search CPAN

L<http://search.cpan.org/dist/Script-isAperlScript/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2012 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Script::isAperlScript
