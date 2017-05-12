#
# This file is part of TBX-Checker
#
# This software is copyright (c) 2013 by Alan K. Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TBX::Checker;
use strict;
use warnings;
use autodie;
use File::ShareDir 'dist_dir';
use Exporter::Easy (
	OK => [ qw(check) ],
);
use Path::Tiny;
use Carp;
use feature 'state';
use Capture::Tiny 'capture_merged';
our $VERSION = '0.03'; # VERSION

my $TBXCHECKER = path( dist_dir('TBX-Checker'),'tbxcheck-1_2_9.jar' );

# ABSTRACT: Check TBX validity using TBXChecker

#When run as a script instead of used as a module: check the input file and print the results
_run(@ARGV) unless caller;
sub _run {
	my ($tbx) = @_;
	my ($passed, $messages) = check($tbx);
	($passed && print 'ok!')
		or print join (qq{\n}, @$messages);
	return;
}


sub check {
	my ($data, @args) = @_;

    croak 'missing data argument. Usage: TBX::Checker::check($data, %args)'
        unless $data;

    my $file = _get_file($data);
    #due to TBXChecker bug, file must be relative to cwd
    my $rel_file = $file->relative;
    my $arg_string = _get_arg_string(@args);

    my $command = qq{java -cp ".;$TBXCHECKER" org.ttt.salt.Main } .
        qq{$arg_string "$rel_file"};

	# capture STDOUT and STDERR from jar call into $output
	my $output = capture_merged {system($command)};
	my @messages = split /\v+/, $output;
	my $valid = _is_valid(\@messages);
	return ($valid, \@messages);
}

# get a Path::Tiny object for the file to give to the TBXChecker
sub _get_file {
    my ($data) = @_;
    my $file;
    #pointers are string data
    if(ref $data eq 'SCALAR'){
        $file = Path::Tiny->tempfile;
        #TODO: will this get encodings right?
        $file->append_raw($$data);
    #everything else should be string paths
    }else{
        $file = path($data);
        croak "$file doesn't exist!"
            unless $file->exists;
    }
    return $file;
}

# process arguments and return the command to be run and the file
# being processed (so temp files aren't destroyed by leaving scope)
sub _get_arg_string {
	my (%args) = @_;

	# check the parameters.
    # TODO: use a module or something for param checking
    state $allowed_params = [ qw(
        loglevel lang country variant system version environment) ];
	state $allowed_levels = [ qw(
		OFF SEVERE WARNING INFO CONFIG FINE FINER FINEST ALL) ];
    foreach my $param (keys %args){
        croak "unknown paramter: $param"
            unless grep { $_ eq $param } @$allowed_params;
    }
	if(exists $args{loglevel}){
		grep { $_ eq $args{loglevel} } @$allowed_levels
			or croak "Loglevel doesn't exist: $args{loglevel}";
	}
	$args{loglevel} ||= q{OFF};

	#combine the options into a string that TBXChecker will understand
	return join q{ }, map {"--$_=$args{$_}"} keys %args;
}

#return a boolean indicating the validity of the file, given the messages
#remove the message indicating that the file is valid (if it exists)
sub _is_valid {
	my ($messages) = @_;
	#locate index of "Valid file:" message
	my $index = 0;
	while($index < @$messages){
		last if $$messages[$index] =~ /^Valid file: /;
		$index++;
	}
	#if message not found, file was invalid
	if($index > $#$messages){
		return 0;
	}
	#remove message and return true
	splice(@$messages, $index, 1);
	return 1;
}

1;

__END__

=pod

=head1 NAME

TBX::Checker - Check TBX validity using TBXChecker

=head1 VERSION

version 0.03

=head1 SYNOPSIS

	use TBX::Checker qw(check);
	my ($passed, $messages) = check('/path/to/file.tbx');
	$passed && print 'ok!'
		or print join (qq{\n}, @$messages);

=head1 DESCRIPTION

This modules allows you to use the Java TBXChecker utility from Perl.
It has one function, C<check> which returns the errors found by the
TBXChecker (hopefully none!).

=head1 METHODS

=head2 C<check>

Checks the validity of the given TBX file. Returns 2 elements: a
boolean representing the validity of the input TBX, and an array reference
containing messages returned by TBXChecker.

Arguments: a string containing a TBX file path, or a string pointer containing
TBX data to be checked, followed by named arguments accepted by TBXChecker.
For example: C<check('file.tbx', loglevel => 'ALL')>. The allowed parameters
are listed below:

    loglevel      Increase level of output while processing.
                         OFF     => Error code only.
                         SEVERE  => Error code only.
                         WARNING => Valid or invalid message (default).
                         INFO    => Location of files used in processing.
                         CONFIG  => .
                         FINE    => .
                         FINER   => .
                         FINEST  => .
                         ALL     => All logging messages.
    lang           ISO-639 lowercase two-letter language code.
    country      ISO-3166 uppercase two-letter country code.
    variant
    system       System ID to use for relative paths in document.
                         Default: Uses the directory where the file is located.
    version       Displays version information and quits.
    environment    Adds the environmental conditions on startup to the messages.

Keep in mind that if you use a string pointer instead of a file name, all
relative URI's will be resolved from the current working directory.

=head1 SEE ALSO

The TBXChecker project is located on SourceForge in a
project called L<tbxutil|http://sourceforge.net/projects/tbxutil/>.

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alan K. Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
