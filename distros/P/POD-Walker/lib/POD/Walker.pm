package POD::Walker;

use warnings;
use strict;
use Script::isAperlScript;
use Pod::Html;
use Pod::LaTeX;
use Pod::Man;
use Pod::Text;
use File::Copy;

=head1 NAME

POD::Walker - Walks a directory and runs any Perl files through the specified POD converter.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use POD::Walker;
    my $returned=POD::Walker->run({in=>"/input/path", out=>"/output/path", format=>"html" });
    if($returned->{error}){
        print "Error: ".$returned->{error}."\n";
    }

=head1 FUNCTION

=head2 run

Process a directory try and ignore any hidden directories or files.

The returned value is a hash. See the section "RETURN HASH" for more information.

=head3 args hash ref

=head4 changesCopy

This copies any "Changes" files.

This defaults to "1".

=head4 in

The directory to start in.

=head4 format

The output type. This can be any of the ones listed below.

    html
    latex
    man
    text

If one is not specified, 'html' will be used.

=head4 manifestCopy

This copies any "MANIFEST" files.

This defaults to "1".

=head4 readmeCopy

This copies any "README" files.

This defaults to "1".

=head4 out

This is the directory to output to.

=cut

sub run{
	#make sure we have something passed to us
	if (!defined($_[1])) {
		return {error=>1};
	}
	my %args=%{$_[1]};

	#make sure all arguements are defined
	if (!defined($args{in})) {
		return {error=>2};
	}
	if (!defined($args{out})) {
		return {error=>3};
	}
	if (!defined($args{format})) {
		$args{format}='html';
	}

	#make sure the input directory is usable
	if (! -d $args{in}) {
		return {error=>4};
	}
	if (! -r $args{in}) {
		return {error=>5};
	}

	#make sure the output directory is usable
	if (! -d $args{out}) {
		if (!mkdir($args{out})) {
			return {error=>6};
		}
	}
	if (! -w $args{out}) {
		return {error=>7};
	}	
	if (! -w $args{out}) {
		return {error=>8};
	}

	#default to 1 for MANIFEST copying
	if (!defined( $args{manifestCopy} )) {
		$args{manifestCopy}=1;
	}

	#default to 1 for README copying
	if (!defined( $args{readmeCopy} )) {
		$args{readmeCopy}=1;
	}

	#default to 1 for Changes copying
	if (!defined( $args{changesCopy} )) {
		$args{changesCopy}=1;
	}

	#starts processing and returns it
	return process(\%args);
}

=head2 process

This is a internal function.

=cut

sub process{
	my %args=%{$_[0]};

	#inits the return value
	my %toreturn;
	$toreturn{error}=undef;

	#holds any thing that errored
	my @errored;

	#make sure all arguements are defined
	if (!defined($args{in})) {
		$toreturn{errored}=\@errored;
		$toreturn{error}=2;
		return \%toreturn;
	}
	if (!defined($args{out})) {
		$toreturn{errored}=\@errored;
		$toreturn{error}=3;
		return \%toreturn;
	}
	if (!defined($args{format})) {
		$args{format}='html';
	}

	#make sure the input directory is usable
	if (! -d $args{in}) {
		$toreturn{errored}=\@errored;
		$toreturn{error}=4;
		return \%toreturn;
	}
	if (! -r $args{in}) {
		$toreturn{errored}=\@errored;
		$toreturn{error}=5;
		return \%toreturn;
	}

	#make sure the output directory is usable
	if (! -d $args{out}) {
		if (!mkdir($args{out})){		
			$toreturn{errored}=\@errored;
			$toreturn{error}=6;
			return \%toreturn;
		}
	}
	if (! -w $args{out}) {
		$toreturn{errored}=\@errored;
		$toreturn{error}=7;
		return \%toreturn;
	}	
	if (! -w $args{out}) {
		$toreturn{errored}=\@errored;
		$toreturn{error}=8;
		return \%toreturn;
	}

	#processes the input directory
	my $dir;
	if (opendir($dir, $args{in})) {
		#removes hidden files/directories
		my @dirEntries=grep(!/^\./ , readdir($dir));
		closedir($dir);

		#process each entry
		my $int=0;
		while (defined( $dirEntries[$int] )) {
			my %newArgs=%args;
			$newArgs{in}=$args{in}.'/'.$dirEntries[$int];
			$newArgs{out}=$args{out}.'/'.$dirEntries[$int];
			
			#The directory and file stuff like this is split to simplify handling odd stuff the path in question.
			#handles directories
			if (-d $newArgs{in}) {
				#process it if it was a directory
				my $returned=process(\%newArgs);
				#push what failed onto the list, if needed
				if ($returned->{error}) {
					my @errors=@{$returned->{errored}};

					print $returned->{error}." ".$newArgs{in}."\n";

					push(@errored, @errors);
					push(@errored, $newArgs{in});
				}
			}
			#handles files
			if (-f $newArgs{in}) {
				#we don't process a file by default
				my $process=0;

				#checks if we should process a file
				if ( $newArgs{in} =~ /\.[Pp][Mm]$/ ) {
					$process=1;
				}
				if ( ( $newArgs{in} =~ /\.[Pp][Ll]$/ ) && (!$process) ) {
					$process=1;
				}
				if ( ( $newArgs{in} =~ /\.[Pp][Oo][Dd]$/ ) && (!$process) ) {
					$process=1;
				}
				if ( ( -x $newArgs{in} ) && (!$process) ) {
					if ( !isAperlScript( $newArgs{in} ) ) {
						$process=1;
					}
				}

				#handles it if it is one of the copy types
				if ($dirEntries[$int] eq "Changes") {
					if ($args{changesCopy}) {
						copy($newArgs{in}, $newArgs{out});
					}
				}
				if ($dirEntries[$int] eq "README") {
					if ($args{readmeCopy}) {
						copy($newArgs{in}, $newArgs{out});
					}
				}
				if ($dirEntries[$int] eq "MANIFEST") {
					if ($args{manifestCopy}) {
						copy($newArgs{in}, $newArgs{out});
					}
				}

				#process a file if needed
				if ($process) {
					if ($args{format} eq "html") {
						pod2html("--flush", "--infile=".$newArgs{in}, "--outfile=".$newArgs{out}.".html");
						if (-f "pod2htmd.tmp") {
							unlink("pod2htmd.tmp");
						}
						if (-f "pod2htmi.tmp") {
							unlink("pod2htmi.tmp");
						}
					}

					if ($args{format} eq "latex") {
						my $parser = Pod::LaTeX->new;
						$parser->parse_from_file ($newArgs{in}, $newArgs{out}.".latex");
					}

					if ($args{format} eq "man") {
						my $parser = Pod::Man->new;
						$parser->parse_from_file ($newArgs{in}, $newArgs{out}.".man");
					}

					if ($args{format} eq "text") {
						my $parser = Pod::Text->new;
						$parser->parse_from_file ($newArgs{in}, $newArgs{out}.".text");
					}

				}

			}

			$int++;
		}

	}else {
		$toreturn{errored}=\@errored;
		$toreturn{error}=9;
		return \%toreturn;
	}	

	$toreturn{errored}=\@errored;

	return \%toreturn;
}

=head1 RETURN HASH

=head2 error

This integer represents if there is a error or note.

This is set to true if there was an error is set to a
integet greater than or equal to "1".

=head3 error codes

=head4 1

No arguements passed.

=head4 2

No in directory specified.

=head4 3

No in directory specified.

=head4 4

The input directory does not exist or is not a directory.

=head4 5

The input directory is not readable.

=head4 6

The specified outpbut directory does not exist, is is not
a directory, or could not be created.

=head4 7

The output directory is not readable.

=head4 8

The output directory is not writable.

=head4 9

Failed to open the input directory.

=head2 errored

This contains a list of files or directories that could not be processed.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pod-walker at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POD-Walker>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POD::Walker


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POD-Walker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POD-Walker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POD-Walker>

=item * Search CPAN

L<http://search.cpan.org/dist/POD-Walker/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of POD::Walker
