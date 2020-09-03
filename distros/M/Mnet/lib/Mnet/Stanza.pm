package Mnet::Stanza;

=head1 NAME

Mnet::Stanza - Manipulate stanza outline text

=head1 SYNOPSIS

    # use this module
    use Mnet::Stanza;

    # read current config from standard input, trim extra spaces
    my $sh_run = undef;
    $sh_run .= "$_\n" while <STDIN>;
    $sh_run = Mnet::Stanza::trim($sh_run);

    # parse existing version of secure acl from current config
    my $acl_old = Mnet::Stanza::parse($sh_run, qr/^ip access-list DMZ/);

    # note latest version of secure acl, trim extra spaces
    my $acl_new = Mnet::Stanza::trim("
        ip access-list DMZ
         permit 192.168.0.0 0.0.255.255
    ");

    # print config to update acl if current acl is different than latest
    if (Mnet::Stanza::diff($acl_old, $acl_new)) {
        print "no ip access-list DMZ\n" if $acl_old;
        print "$acl_new\n";
    }

    # print config applying acl to shutdown interfaces, if needed
    my @ints = Mnet::Stanza::parse($sh_run, qr/^interface/);
    foreach my $int (@ints) {
        next if $int !~ /^\s*shutdown/m;
        next if $int =~ /^\s*ip access-group DMZ in/m;
        die "error, $int" if $int !~ /^interface (\S+)/;
        print "interface $1\n";
        print " ip access-group DMZ in\n";
    }

=head1 DESCRIPTION

Mnet::Stanza can be used on text arranged in stanzas of indented lines or text
in outline format, such as the following:

    line
    stanza 1
     indented line
    stanza 2
     sub-stanza 1
      indented 1
      indented 2
      sub-sub-stanza 1
       indented 1
       indented 2
    end

In the above example the following would be true:

    stanza 1 contains a single indented line
    stanza 2 contains sub-stanza 1 and everything under sub-stanza 1
    sub-stanza 1 contains two indented lines and a sub-sub-stanza 1
    sub-sub-stanza 1 contains two indented lines

This can be used to parse cisco ios configs, amongst other things.

=head1 FUNCTIONS

Mnet::Stanza implements the functions listed below.

=cut

# required modules
use warnings;
use strict;
use Carp;



sub trim {

=head2 trim

    $output = Mnet::Stanza::trim($input)

The Mnet::Stanza::trim function can be used to normalize stanza spacing and may
be useful before calling the diff function or outputting a stanza to the user.

This function does the following:

    - replaces multiple spaces inside text with single spaces
    - removes spaces at the end of any line of input
    - removes blank lines and any linefeeds at end of input
    - removes extra leading spaces while preserving indentation

A null value will be output if the input is undefined.

Note that in some cases extra spaces in the input may be significant and it
may not be appropriate to use this trim function. This must be determined
by the developer. Also note that this function does not touch tabs.

=cut

    # read input stanza text
    my $input = shift;

    # init trimmed output text from input, null if undefined
    my $output = $input // "";

    # trim double spaces inside a line, trailing spaces, and blank lines
    $output =~ s/(\S)  +/$1 /g;
    $output =~ s/\s+$//m;
    $output =~ s/\n\n+/\n/g;
    $output =~ s/(^\n+|\n+$)//g;

    # determine smallest indent common to all lines
    my $indent_init = 999999999999;
    my $indent = $indent_init;
    foreach my $line (split(/\n/, $output)) {
        if ($line =~ /^(\s*)\S/ and length($1) < $indent) {
            $indent = length($1);
        }
    }

    # trim extra indent spaces from left of every line in output
    $output =~ s/^ {$indent}//mg if $indent and $indent < $indent_init;

    # finished trim function, return trimmed output text
    return $output;
}



sub parse {

=head2 parse

    @output = Mnet::Stanza::parse($input, qr/$match_re/)
    $output = Mnet::Stanza::parse($input, qr/$match_re/)

The Mnet::Stanza::parse function can be used to output one or more matching
stanza sections from the input text, either as a list of matching stanzas or
a single string.

Here's some sample input text:

    hostname test
    interface Ethernet1
     no ip address
     shutdown
    interface Ethernet2
     ip address 1.2.3.4 255.255.255.0

Using an input match_re of qr/^interface/ the following two stanzas are output:

    interface Ethernet1
     no ip address
     shutdown
    interface Ethernet2
     ip address 1.2.3.4 255.255.255.0

Note that blank lines don't terminate stanzas.

Refer also to the Mnet::Stanza::trim function in this module.

=cut

    # read input stanza text and match regular expression
    my $input = shift;
    my $match_re = shift // croak("missing match_re arg");

    # init list of matched output stanzas
    #   each output stanza will include lines indented under matched line
    my @output = ();

    # loop through lines, set matching output stanzas
    #   use indent var to track indent level of current matched stanza line
    #   if line matches current indent or is blank then append to output stanza
    #   elsif line matches input mathc_re then push to a new output stanza
    #   else reset current indet to undef, to wait for a new match_re line
    my $indent = undef;
    foreach my $line (split(/\n/, $input)) {
        if (defined $indent and $line =~ /^($indent|\s*$)/) {
            $output[-1] .= "$line\n";
        } elsif ($line =~ $match_re) {
            push @output, "$line\n";
            $indent = "$1 " if $line =~ /^(\s*)/;
        } else {
            $indent = undef;
        }
    }

    # remove last end of line from all output stanzas
    chomp(@output);

    # finished parse function, return output stanzas as list or string
    return wantarray ? @output : join("\n", @output);
}



sub diff {

=head2 diff

    $diff = Mnet::Stanza::diff($old, $new)

The Mnet::Stanza::diff function checks to see if the input old and new stanza
strings are the same.

The returned diff value will be set as follows:

    <null>      indicates old and new inputs match
    <undef>     indicates both inputs are undefined
    undef       indicates either new or old is undefined
    line        indicates mismatch line number and line text
    other       indicates mismatch such as extra eol chars at end

Note that blank lines and all other spaces are significant. To remove extra
spaces use the Mnet::Stanza::trim function before calling this function.

=cut

    # read input old and new stanzas
    my ($old, $new) = (shift, shift);
    my ($length_old, $length_new) = (length($old // ""), length($new // ""));

    # init output diff value
    my $diff = undef;

    # set diff undef if old and new are both undefined
    if (not defined $old and not defined $new) {
        $diff = undef;

    # set diff if old stanza is undefined
    } elsif (not defined $old) {
        $diff = "undef: old";

    # set diff if new stanza is undefined
    } elsif (not defined $new) {
        $diff = "undef: new";

    # set diff to null if old and new stanzas match
    } elsif ($old eq $new) {
        $diff = "";

    # set diff to first old or new line that doesn't match
    #   loop through old lines, looking for equivalant new lines
    #   look for additional new lines that are not present in old
    #   set diff to other if we don't know why old is not equal to new
    } else {
        my @new = split(/\n/, $new);
        my $count = 0;
        foreach my $line (split(/\n/, $old)) {
            $count++;
            if (defined $new[0] and $new[0] eq $line) {
                shift @new;
            } else {
                $diff = "line $count: $line";
                last;
            }
        }
        $count++;
        $diff = "line $count: $new[0]" if defined $new[0] and not defined $diff;
        $diff = "other" if not defined $diff;

    # finished setting output diff
    }

    # finished diff function, return diff text
    return $diff;
}



=head1 SEE ALSO

L<Mnet>

L<Mnet::Log>

=cut

# normal end of package
1;

