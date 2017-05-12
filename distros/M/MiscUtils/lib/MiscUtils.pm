package MiscUtils;
$VERSION = '1.0.0';

use strict;
require Exporter;
require Carp;

our @ISA = qw(Exporter);
our @EXPORT = qw(rindent indent mkdirs swap_dirs filter_text debug);

=head1 NAME

MiscUtils - Miscellanous Utitlies. Provided in hopes that you will add your own functions.

=head1 SYNOPSIS

    use MiscUtils;

    print rindent(4).'I am 4 tabs over!';

    mkdirs('/xtra/shared/mp3s/by/author/m/mo/mono/life_in_mono.mp3');

    # hypothetical - see discussion below
    this_useful_function_I_wrote_and_use_constantly ('I added it in myself');

=head1 DESCRIPTION

MiscUtils is a collection of utility functions I found myself using
in alot of my scripts. Then I thought it would be better to just
throw them all into one huge unrelated, incoherant module. Then
I thought it would be good to share with the world. Then I thought
the world would benifit even more if they threw in thier own
functions they constantly use.

=head2 DISCLAIMER

This module is mostly provided as a means of making quick hacks quicker. For a serious
or distributed script you should not rely on or require anyone to have 
this module. To get the functions out of this module into your
serious or distributed scripts, just cut and paste directly into
your script or module(s). The module is nothing special, so don't be afraid to hack it up.

=head1 PROVIDED FUNCTIONS

=head2 rindent

Returns x number of tabs.

Arguments

=over

=item 1

The number of spaces to indent.

=back

Returns: (string) argument number of tabs

Example:
    print rindent(4).'I am 4 tabs over!';

=cut

sub rindent {
	my $ident = shift();
	my $tmp = '';

	while ($ident--) {
		$tmp .= "\t";
	}

	return $tmp;
}

=head2 indent 

Prints onto a filehandle or stdout x number of tabs.

Arguments

=over

=item 1

The number of spaces to indent.

=item 2

A reference to a filehandle [optional] [default:STDOUT]

=back

Returns: nothing

Example:
    indent(4);
    print "I am 4 tabs over!\n";

=cut

sub indent {
	my ($indent, $fh) = @_;

	if ($fh) { print $fh rindent ($indent); }
	else { print rindent ($indent); }
}

=head2 mkdirs

Makes the directories specified in the path.

Arguments

=over

=item 1

The full file/path name to be made if it does not exist.

=back

Returns: 1 upon success, 0 upon failure.

Example:
    if (mkdirs('/xtra/shared/mp3s/by/author/m/mo/mono/life_in_mono.mp3')) {
        # /xtra/shared/mp3s/by/author/m/mo/mono/ will definitaly exist.
    }

=cut

sub mkdirs {
    my $full_path = shift();
    return if (-d $full_path);
    $full_path =~ s-^((?:/)?.+)/.+?$-$1/-;
    my @all_dirs = split(/\//, $full_path);
    my ($dir, $tmp_dir) = ();
    foreach $dir (@all_dirs) {
	$tmp_dir .= "$dir/";
	if (!-e $tmp_dir) {
	    if (!mkdir($tmp_dir)) {
		return 0;
	    }
	}
    }

    return 1;
}

=head2 swap_dirs

Simplify relative path, path blending.

Arguments

=over

=item 1

The full file/path name

=item 2

The first part of the path that will be swapped.

=item 3

The first part of the path that you want to swap with.

=back

Returns: The new path.

Example:
    print swap_dirs('/publicwww/oldsite/index.php', '/publicwww/', 'http://lackluster.tzo.com:1024/');
    # prints http://lackluster.tzo.com:1024/oldsite/index.php

=cut 

sub swap_dirs {
	my ($path, $from, $to) = @_;
	$path =~ s/^$from/$to/i;
	return 	($path);
}

=head2 debug

Debug (pretty print) array ref, hash ref, or scalar. Not as cool as L<Data::Dumper>

Arguments

=over

=item 1

The item to be debugged. Arrays and Hashes must be in reference form.

=item 2

Variable/Output name.

=item 3

Indentation level [optional|internal]

=back

Returns: nothing

Example:
    my @words = qw(a ab abc abcd);
    debug (\@words, 'my words');

=cut 

sub debug {
	my ($whatnot, $name, $indent) = @_;

	$name = 'VARIABLE' if (!$name);
	$whatnot = '(empty)' if (!$whatnot);

	if (ref($whatnot) eq 'ARRAY') {
		$indent++;
		for (my $i = 0; $i < scalar(@{ $whatnot }); $i++) {
			debug ($whatnot->[$i], "${name}\[$i\]", $indent);
		}
		$indent--;
	}
	elsif (ref($whatnot) eq 'HASH') {
		$indent++;
		foreach my $item (keys %{ $whatnot }) {
			debug ($whatnot->{$item}, "${name}\{$item\}", $indent);
		}
		$indent--;
	}
	elsif (ref($whatnot) eq 'SCALAR') {
		debug ($$whatnot, $name, $indent);
	}
	elsif (ref($whatnot) eq 'CODE') {
		debug ('a code reference', $name, $indent);
	}
	else {
		print ("debug: ");
		while ($indent--) { print "\t"; }
		print ("$name is $whatnot\n");
	}
}

=head2 filter_text

Transforms non-XML-data elements to useful stoarge.

Arguments

=over

=item 1

Text to transform.

=back

Returns: Transformed Text.

Example:
    print $some_var_with_smart_quotes_and_punctuation;

=cut 

sub filter_text {
	my $dirty_text = shift();

	# trim
	$dirty_text =~ s/^ +//;		$dirty_text =~ s/ +$//;

	# "smart" quotes X{
	$dirty_text =~ tr/\x93\x94/"/;	$dirty_text =~ tr/\x92/'/;

	# convert special chars
	$dirty_text =~ s/&/&amp;/g;
	$dirty_text =~ s/</&lt;/g;	$dirty_text =~ s/>/&gt;/g;
	$dirty_text =~ s/"/&quot;/g;	$dirty_text =~ s/'/&#39;/g;

	return $dirty_text;
}

1;

__END__

=head1 BUGS

Uh.... are you sure they aren't yours? Let me know if you find any.

=head1 AUTHOR

BPrudent (Brandon Prudent)

email: L<xlacklusterx@hotmail.com>
