package RTF::HTML::Converter::API;
use Carp;
use strict;
use warnings;
use RTF::HTML::Converter;

our $VERSION = 0.1;
our $CHAT = 0;

=head1 NAME

RTF::HTML::Converter::API - OO API to Philippe Verdret's RTF::HTML::Convertor

=head1 SYNOPSIS

	use RTF::HTML::Converter::API;

	my $rtf = new RTF::HTML::Converter::API (dir => "D:/temp/",);
	$rtf->process;
	foreach (@{$rtf->{files}}){
		warn $_;
		warn $_->{filename};
		warn $_->{html},"//end//";
		warn "\n";
	}

	my $rtf = new RTF::HTML::Converter::API;
	warn $rtf->convert_file("D:/temp/rtf-test.rtf");
	foreach (@{$rtf->{files}}){
		warn $_;
		warn $_->{filename};
		warn $_->{html},"//end//";
		warn "\n";
	}
	exit;

=head1 DESCRIPTION

An OO API to Philippe Verdret's L<RTF::HTML::Convertor|RTF::HTML::Convertor> module.

Note that C<RTF::HTML::Convertor> produces invalid HTML: see the test for details.

Define the class variable C<CHAT> to have a value if you wish realtime output of what's going on.

=head1 CONSTRUCTOR new

Arguments in C<key=>value> pairs:

=over 4

=item dir:

the directory to process.

=back

=cut

sub new { my $class = shift;
	warn "Making new __PACKAGE__" if $CHAT;
    unless (defined $class) {
    	carp "Usage: ".__PACKAGE__."->new( {key=>value} )\n";
    	return undef;
	}
	my %args;

	# Take parameters and place in object slots/set as instance variables
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }
	else {
		carp "Usage: $class->new( { key=>values, } )";
		return undef;
	}
	my $self = bless {}, $class;

	# Set/overwrite public slots with user's values
	foreach (keys %args) {
		$self->{lc $_} = $args{$_};
		warn "$_ => $args{$_}\n"  if $CHAT;
	}

	$self->{files} = [];	# Array holding hashes, keys of which are filename, html

	if (exists $self->{dir} and not -e $self->{dir}){
		croak "The directory you supplied, <$self->{dir}>, does not exist.";
	}
	if (exists $self->{dir} and not -d $self->{dir}){
		croak "The path you supplied is not a directory.";
	}

	return $self;
}

=head2 METHOD process

Does everything in one method call.

=cut

sub process { my $self=shift;
 	warn "Processing" if $CHAT;
	$self->get_filenames;
	$self->convert_files;
}

=head2 METHOD get_filenames

Optional argument is a directory to process: default
is in C<$self->{dir}> required at construction time.

=cut

sub get_filenames { my ($self,$dir) = (shift,shift);
	$dir = $self->{dir} if not defined $dir;
 	warn "Getting filenames from directory <$dir>" if $CHAT;
	local *DIR;
	opendir DIR,$dir
		or carp "Couldn't open directory <$dir> to read: $!."
		and return undef;

	foreach (grep /.*?\.rtf$/, readdir DIR){
		push @{$self->{files}}, {filename=>$_, html=>'',};
		warn "\tfilename: <$_>" if $CHAT;
	}
	closedir DIR;
}

=head2 METHOD convert_files

Calls the C<RTF::HTML::Converter> (see L<RTF::HTML::Converter>) on
every file in our C<files> list: takes the filenames from the
C<filename> slot of each hash, and placing the resulting HTML into
the C<html> slot fo each hash.

=cut

sub convert_files { my $self = shift;
	warn "Converting all files" if $CHAT;
	foreach (@{$self->{files}} ){
		warn "Converting <$_->{filename}>" if $CHAT;
		my $rtf = new RTF::HTML::Converter(Output => \$_->{html});
		$rtf->parse_stream($self->{dir}."/".$_->{filename});
	}
}

=head2 METHOD convert_file

Accepts the object reference and the path to a file to convert.
Pushes into the object's C<files> array a hash with a key C<filename>
against the passed filename, and a key C<html> with the value returned
by the C<RTF::HTML::Converter> (see L<RTF::HTML::Converter>).

Incidentally returns a reference to the HTML created.

Does not check to see if the object already contains the processed result.

Does not use the object's C<dir> slot.

=cut

sub convert_file { my ($self,$filepath) = (shift,shift);
	croak "No filepath passed" if not defined $filepath;
	croak "No such file as the passed <$filepath>" if not -e $filepath;
	warn "Converting <$filepath>" if $CHAT;
	my $html;
	my $rtf = new RTF::HTML::Converter(Output => \$html);
	$rtf->parse_stream($filepath);
	push @{$self->{files}}, {filename=>$filepath, html=>$html, };
	return \$_->{html};
}

1; # Return cleanly

=head1 AUTHOR

L<Lee Goddard|lgoddard@CPAN.org> (L<lgoddard@CPAN.org|lgoddard@CPAN.org>).

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 2002. All rights reserved.
This software is made available under the same terms
as Perl itself.
