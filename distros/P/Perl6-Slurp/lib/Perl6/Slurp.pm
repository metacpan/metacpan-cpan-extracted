package Perl6::Slurp;

use warnings;
use strict;
use 5.008;
use Carp;
use Scalar::Util 'refaddr';

our $VERSION = '0.051005';

# Exports only the slurp() sub...
sub import {
    no strict 'refs';
    *{caller().'::slurp'} = \&slurp;
}

# Recognize mode arguments...
my $mode_pat = qr{
    ^ \s* ( (?: < | \+< | \+>>? ) &? ) \s*
}x;

# Recognize a mode followed by optional layer arguments...
my $mode_plus_layers = qr{
    (?: $mode_pat | ^ \s* -\| \s* )
    ( (?: :[^\W\d]\w* (?: \( .*? \) ?)? \s* )* )
    \s*
    \z
}x;

# Is this a pure number???
sub is_pure_num {
    return (~$_[0] & $_[0]) eq 0;  # ~ acts differently for numbers and strings
}

# The magic subroutine that does everything...
sub slurp {
    # Are we in a useful context???
    my $list_context = wantarray;
    croak "Useless use of &slurp in a void context"
        unless defined $list_context;

    # Missing args default to $_, so we need to catch that early...
    my $default = $_;

    # Remember any I/O layers and other options specified...
    my @layers_or_options;

    # Process the argument list...
    for (my $i=0; $i<@_; $i++) {
        # Ignore non-reference args...
        my $type = ref $_[$i] or next;

        # Hashes indicate extra layers; remove from @_, add them in sequence...
        if ($type eq 'HASH') {
            push @layers_or_options, splice @_, $i--, 1
        }

        # Arrays also indicate extra layers; remove from @_, convert to hash
        # form, and add them in sequence...
        elsif ($type eq 'ARRAY') {
            # Splice out the array and unpack it...
            my @array = @{splice @_, $i--, 1};

            # Verify and convert each layer specified to a one-key hash...
            while (@array) {
                my ($layer, $value) = splice @array, 0, 2;
                croak "Incomplete layer specification for :$layer",
                      "\n(did you mean: $layer=>1)\n "
                            unless $value;
                push @layers_or_options, { $layer=>$value };
            }
        }
    }

    # Any remaining args are the read mode, source file, and whatever...
    my ($mode, $source, @args) = @_;

    # If no arguments, use defaults...
    if (!defined $mode) {
        $mode = defined $default ? $default
            : @ARGV            ? \*ARGV
            :                    "<"
    }

    # If mode was a reference, it must really have been the source...
    if (ref $mode) {
        $source = $mode;
        $mode   = "<";
    }

    # If mode isn't a valid mode, it must actually have been the source...
    elsif ($mode !~ /$mode_plus_layers/x) {
        $source = $mode;
        $mode = $source =~ s/$mode_pat//x  ?  "$1"
              : $source =~ s/ \| \s* $//x  ?  "-|"
              :                               "<"
              ;
    }

    # Sources can be references, but only certain kinds of references...
    my $ref = ref $source;
    if ($ref) {
        croak "Can't use $ref as a data source"
                unless $ref eq 'SCALAR'
                    || $ref eq 'GLOB'
                    || eval { $source->isa('IO::Handle') };
    }

    # slurp() always uses \n as its input record separator (a la Perl 6)
    local $/ = "\n";

    # This track the various options slurp() allows...
    my ($chomp, $chomp_to, $layers) = (0, "", "");

    # Can this slurp be done in an optimized way (assume so initially)???
    my $optimized = 1;

    # Decode the layers and options...
    my $IRS = "\n";
    for (@layers_or_options) {
        # Input record separator...
        if (exists $_->{irs}) {
            $IRS = $_->{irs};
            $/ = $IRS if !ref($IRS);
            delete $_->{irs};
            $optimized &&= !ref($IRS);    # ...can't be optimized if irs is a regex
        }

        # Autochomp...
        if (exists $_->{chomp}) {
            $chomp = 1;

            # If the chomp value is a string, that becomes to replacement...
            if (defined $_->{chomp} && !is_pure_num($_->{chomp})) {
                $chomp_to = $_->{chomp}
            }
            delete $_->{chomp};
            $optimized = 0;             # ...chomped slurps can't be optimized
        }

        # Any other entries are layers...
        $layers .= join " ", map ":$_", keys %$_;
    }

    # Add any layers found to the mode specification...
    $mode .= " $layers";

    # Open the source as a filehandle...
    my $FH;

    # Source is a typeglob...
    if ($ref && $ref ne 'SCALAR') {
        $FH = $source;
    }

    # No source, specified: use *ARGV...
    elsif (!$source) {
        no warnings 'io';
        open $FH, '<-'
            or croak "Can't open stdin: $!";
    }

    # Source specified: open it...
    else {
        no warnings 'io';
        open $FH, $mode, $source, @args
            or croak "Can't open '$source': $!";
    }

    # Standardize chomp-converter sub...
    my $chomp_into = ref $chomp_to eq 'CODE' ? $chomp_to : sub{ $chomp_to };

    # Optimized slurp if possible in list context...
    if ($list_context && $optimized) {
        return <$FH>;
    }

    # Acquire data (working around bug between $/ and in magic ARGV)...
    my $data = refaddr($FH) == \*ARGV ? join("",<>) : do { local $/; <$FH> };

    # Prepare input record separator regex...
    my $irs = ref($IRS)     ? $IRS
            : defined($IRS) ? qr{\Q$IRS\E}
            :                 qr{(?!)};

    # List context may require input record separator processing...
    if ($list_context) {
        # No data --> nothing to return...
        return () unless defined $data;

        # Split acquired data into lines according to IRS...
        my @components = split /($irs)/, $data;
        my @lines;
        while (@components) {
            # Extract the next line and separator...
            my ($line, $sep) = splice @components, 0, 2;

            # Add the line...
            push @lines, $line;

            # Chomp as requested...
            if (defined $sep && length $sep) {
                $lines[-1] .= $chomp ? $chomp_into->($sep) : $sep;
            }
        }
        return @lines;
    }

    # Scalar context...
    else {
        # No data --> nothing to return...
        return q{} unless defined $data;

        # Otherwise, do any requested chomp-conversion...
        if ($chomp) {
            $data =~ s{($irs)}{$chomp_into->($1)}ge;
        }

        return $data;
    }
}

1;
__END__


=head1 NAME

Perl6::Slurp - Implements the Perl 6 'slurp' built-in


=head1 SYNOPSIS

    use Perl6::Slurp;

    # Slurp a file by name...

    $file_contents = slurp 'filename';
    $file_contents = slurp '<filename';
    $file_contents = slurp '<', 'filename';
    $file_contents = slurp '+<', 'filename';


    # Slurp a file via an (already open!) handle...

    $file_contents = slurp \*STDIN;
    $file_contents = slurp $filehandle;
    $file_contents = slurp IO::File->new('filename');


    # Slurp a string...

    $str_contents = slurp \$string;
    $str_contents = slurp '<', \$string;


    # Slurp a pipe (not on Windows, alas)...

    $str_contents = slurp 'tail -20 $filename |';
    $str_contents = slurp '-|', 'tail', -20, $filename;


    # Slurp with no source slurps from whatever $_ indicates...

    for (@files) {
        $contents .= slurp;
    }

    # ...or from the entire ARGV list, if $_ is undefined...

    $_ = undef;
    $ARGV_contents = slurp;


    # Specify I/O layers as part of mode...

    $file_contents = slurp '<:raw', $file;
    $file_contents = slurp '<:utf8', $file;
    $file_contents = slurp '<:raw :utf8', $file;


    # Specify I/O layers as separate options...

    $file_contents = slurp $file, {raw=>1};
    $file_contents = slurp $file, {utf8=>1};
    $file_contents = slurp $file, {raw=>1}, {utf8=>1};
    $file_contents = slurp $file, [raw=>1, utf8=>1];


    # Specify input record separator...

    $file_contents = slurp $file, {irs=>"\n\n"};
    $file_contents = slurp '<', $file, {irs=>"\n\n"};
    $file_contents = slurp {irs=>"\n\n"}, $file;


    # Input record separator can be regex...

    $file_contents = slurp $file, {irs=>qr/\n+/};
    $file_contents = slurp '<', $file, {irs=>qr/\n+|\t{2,}};


    # Specify autochomping...

    $file_contents = slurp $file, {chomp=>1};
    $file_contents = slurp {chomp=>1}, $file;
    $file_contents = slurp $file, {chomp=>1, irs=>"\n\n"};
    $file_contents = slurp $file, {chomp=>1, irs=>qr/\n+/};


    # Specify autochomping that replaces irs
    # with another string...

    $file_contents = slurp $file, {irs=>"\n\n", chomp=>"\n"};
    $file_contents = slurp $file, {chomp=>"\n\n"}, {irs=>qr/\n+/};


    # Specify autochomping that replaces
    # irs with a dynamically computed string...

    my $n = 1;
    $file_contents = slurp $file, {chomp=>sub{ "\n#line ".$n++."\n"};


    # Slurp in a list context...

    @lines = slurp 'filename';
    @lines = slurp $filehandle;
    @lines = slurp \$string;
    @lines = slurp '<:utf8', 'filename', {irs=>"\x{2020}", chomp=>"\n"};


=head1 DESCRIPTION

C<slurp> takes:

=over

=item *

a filename,

=item *

a filehandle,

=item *

a typeglob reference,

=item *

an IO::File object, or

=item *

a scalar reference,

=back

converts it to an input stream (using C<open()> if necessary), and reads
in the entire stream. If C<slurp> fails to set up or read the stream, it
throws an exception.

If no data source is specified C<slurp> uses the value of C<$_> as the
source. If C<$_> is undefined, C<slurp> uses the C<@ARGV> list,
and magically slurps the contents of I<all> the sources listed in C<@ARGV>.
Note that the same magic is also applied if you explicitly slurp <*ARGV>, so
the following three input operations:

    $contents = join "", <ARGV>;

    $contents = slurp \*ARGV;

    $/ = undef;
    $contents = slurp;

are identical in effect.

In a scalar context C<slurp> returns the stream contents as a single string.
If the stream is at EOF, it returns an empty string.
In a list context, it splits the contents after the appropriate input
record separator and returns the resulting list of strings.

You can set the input record separator (S<< C<< { irs => $your_irs_here}
>> >>) for the input operation. The separator can be specified as a
string or a regex. Note that an explicit input record separator has no
input-terminating effect in a scalar context; C<slurp> always
reads in the entire input stream, whatever the C<'irs'> value.

In a list context, changing the separator can change how the input is
broken up within the list that is returned.

If an input record separator is not explicitly specified, C<slurp>
defaults to C<"\n"> (I<not> to the current value of C<$/> E<ndash> since
Perl 6 doesn't I<have> a C<$/>);

You can also tell C<slurp> to automagically C<chomp> the input as it is
read in, by specifying: (S<< C<< { chomp => 1 } >> >>)

Better still, you can tell C<slurp> to automagically
C<chomp> the input and I<replace> what it chomps with another string,
by specifying: (S<< C<< { chomp => "another string" } >> >>)

You can also tell C<slurp> to compute the replacement string on-the-fly
by specifying a subroutine as the C<chomp> value:
(S<< C<< { chomp => sub{...} } >> >>). This subroutine is passed the string
being chomped off, so for example you could squeeze single newlines to a
single space and multiple consecutive newlines to a two newlines with:

    sub squeeze {
        my ($removed) = @_;
        if ($removed =~ tr/\n/\n/ == 1) { return " " }
        else                            { return "\n\n"; }
    }

    print slurp(\*DATA, {irs=>qr/[ \t]*\n+/, chomp=>\&squeeze}), "\n";

Which would transform:

    This is the
    first paragraph


    This is the
    second
    paragraph

    This, the
    third




    This one is
    the
    very
    last

to:

    This is the first paragraph

    This is the second paragraph

    This, the third

    This one is the very last


Autochomping works in both scalar and list contexts. In scalar contexts every
instance of the input record separator will be removed (or replaced) within
the returned string. In list context, each list item returned with its
terminating separator removed (or replaced).

You can specify I/O layers, either using the Perl 5 notation:

    slurp "<:layer1 :layer2 :etc", $filename;

or as an array of options:

    slurp $filename, [layer1=>1, layer2=>1, etc=>1];
    slurp [layer1=>1, layer2=>1, etc=>1], $filename;

or as individual options (each of which must be in a separate hash):

    slurp $filename, {layer1=>1}, {layer2=>1}, {etc=>1};
    slurp {layer1=>1}, {layer2=>1}, {etc=>1}, $filename;

(...which, of course, would look much cooler in Perl 6:

    # Perl 6 only :-(

    slurp $filename, :layer1 :layer2 :etc;
    slurp :layer1 :layer2 :etc, $filename;

)

A common mistake is to put all the options together in one hash:

    slurp $filename, {layer1=>1, layer2=>1, etc=>1};

This is almost always a disaster, since the order of I/O layers is usually
critical, and placing them all in one hash effectively randomizes that order.
Use an array instead:

    slurp $filename, [layer1=>1, layer2=>1, etc=>1];


=head1 WARNINGS

The syntax and semantics of Perl 6 is still being finalized
and consequently is at any time subject to change. That means the
same caveat applies to this module.

When called with a filename or piped shell command, C<slurp()> uses
Perl's built- in C<open()> to access the file. This means that it
is subject to the same platform-specific limitations as C<open()>.
For example, slurping from piped shell commands may not work 
under Windows.


=head1 DEPENDENCIES

Requires: Perl 5.8.0


=head1 AUTHOR

Damian Conway (damian@conway.org)


=head1 COPYRIGHT

 Copyright (c) 2003-2012, Damian Conway. All Rights Reserved.
 This module is free software. It may be used, redistributed
    and/or modified under the same terms as Perl itself.
