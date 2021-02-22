package Mnet::Stanza;

=head1 NAME

Mnet::Stanza - Manipulate stanza outline text such as ios configs

=head1 SYNOPSIS

    # use this module
    use Mnet::Stanza;

    # read current config from standard input, trim extra spaces
    my $sh_run = undef;
    $sh_run .= "$_\n" while <STDIN>;
    $sh_run = Mnet::Stanza::trim($sh_run);

    # remove and recreate acl if configured acl does not match below
    Mnet::Stanza::ios("
        =ip access-list DMZ
         =permit 192.168.0.0 0.0.255.255
    ", $sh_run);

    # print config applying acl to shutdown interfaces if not present
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
      indented line 1
      indented line 2
      sub-sub-stanza 1
       indented line 1
       indented line 2
    end

In the above example the following would be true:

    stanza 1 contains a single indented line
    stanza 2 contains sub-stanza 1 and everything under sub-stanza 1
    sub-stanza 1 contains two indented lines and a sub-sub-stanza 1
    sub-sub-stanza 1 contains two indented lines

This can be used to parse cisco ios configs, amongst other similar formats.

=head1 FUNCTIONS

Mnet::Stanza implements the functions listed below.

=cut

# required modules
use warnings;
use strict;
use Carp;
use Mnet;



sub trim {

=head2 trim

    $output = Mnet::Stanza::trim($input)

The Mnet::Stanza::trim function can be used to normalize stanza spacing and may
be useful before calling the diff function or otherwise processing the stanza.

This function modifies the input string as following:

    - remove trailing spaces at the end of all lines of text
    - remove blank lines before, after, and within text
    - remove extra leading spaces while preserving indentation
    - remove extra spaces inside non-description/remark lines
        dosn't modify ios description and remark command lines

A null value will be output if the input is undefined.

Note that in some cases extra spaces in the input may be significant and it
may not be appropriate to use this trim function. This must be determined
by the developer. Also note that this function does not touch tabs.

=cut

    # read input stanza text
    my $input = shift // "";

    # init output
    my $output = "";

    # replace multiple spaces inside text with single spaces
    #   preserve description/remark double spaces
    foreach my $line (split(/\n/, $input)) {
        $line =~ s/(\S)  +/$1 /g if $line !~ /^\s*(description|remark)\s/;
        $output .= "$line\n";
    }

    # remove trailing spaces at the end of all lines of text
    $output =~ s/\s+$//m;

    # remove blank lines before, after, and within text
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

    # remove extra leading spaces while preserving indentation
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

Note that blank lines are not considered to terminate stanzas.

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

    <null>          indicates old and new inputs match
    <undef>         indicates both inputs are undefined
    undef:$a        indicates either new or old input arg is undefined
    line $n: $t     indicates mismatch line number and line text
    other           indicates other mismatch such as extra eol chars

Note that blank lines and all other spaces are significant. Consider using the
Mnet::Stanza::trim function to normalize both inputs before calling this
function.

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
        my $num = 0;
        foreach my $line (split(/\n/, $old)) {
            $num++;
            if (defined $new[0] and $new[0] eq $line) {
                shift @new;
            } else {
                $diff = "line $num: $line";
                last;
            }
        }
        $num++;
        $diff = "line $num: $new[0]" if defined $new[0] and not defined $diff;
        $diff = "other" if not defined $diff;

    # finished setting output diff
    }

    # finished diff function, return diff text
    return $diff;
}



sub ios {

=head2 ios

    $output = Mnet::Stanza::ios($template, $config)

The Mnet::Stanza::ios fucntion uses a template to check a config for needed
config changes, outputting a generated list of overlay config commands that can
be applied to the device to bring it into compliance.

The script dies with an error if the template argument is missing. The second
config argument is optional and can be set to the current device config.

The output from this function will be commands that need to be added and/or
removed from the input config, generated by comparing the input template to
the input config. It will be empty if the input config does not need to be
updated.

This function is designed to work on templates and configs made up of indented
stanzas, as in the following ios config example, showing a global snmp command
and a named access-list stanza:

    ! global commands are not indented
    snmp-server community global

    ! a stanza includes lines indented underneath
    ip access-list stanza
     permit ip any any
     deny ip any any

Template lines should start with one of the following characters:

    !   comment

            comments are ignored, they are not propagated to output

    +   add line

            config line should be added if not already present
            to add lines under a stanza refer to '>' below

    >   find stanza

            use to find or create a stanza in the input config
            found stanzas can have '+', '=', and/or '-' lines underneath
            found stanzas are output if child lines generate output

    =   match stanza

            output stanza if not already present and an exact match
            indented lines undeneath to match must also start with '='
            possible to '>' find a stanza and '=' match child sub-stanza

    -   remove line or stanza if present

            remove global command, command under a stanza, or a stanza
            wildcard '*!*' at end of line matches one or more characters
            does not remove lines already checked in the current stanza
            lines to be removed are prefixed by 'no' in the output
            lines already starting with 'no' get the 'no' removed
            to remove commands under a stanza refer above to '>'

Following is an example of how this function can be used to remediate complex
ios feature configs:

    # use this module
    use Mnet::Stanza;

    # read current config from standard input
    my $sh_run = undef;
    $sh_run .= "$_\n" while <STDIN>;

    # define ios feature update template string
    #   can be programmatically generated from parsed config
    my $update_remplate = "

        ! check numbered acl, ensure no extra lines
        +access-list 1 permit ip any any
        -access-list 1 *!*

        ! check that this stanza matches exactly
        =ip access-list test
         =permit ip any any

        ! find vlan stanza and ensure acls are applied
        >interface Vlan1
         +ip access-group 1 in
         +ip access-group test out
    ";

    # define ios feature remove template string
    #   used to remove any old config before applying update
    my $remove_template = "

        ! acl automatically removed from interface
        -access-list 1
        -ip access-list test

    ";

    # output overlay config if update is needed
    #   overlay will remove old config before updating with new config
    if (Mnet::Stanza::ios($update_template, $sh_run)) {
        print Mnet::Stanza::ios($remove_template, $sh_run);
        print Mnet::Stanza::ios($update_template);
    }

Note that extra spaces are removed from the template and config inputs using
the Mnet::Stanza::trim function. Refer to that function for more info.

=cut

    # read input template and config args
    my $template = shift // croak "missing template arg";
    my $config = shift // "";

    # note: this function is called recursively for each find stanza '>'
    #   processing starts with input template and config supplied by caller
    #   template lines with the same indent level are processed, top to bottom
    #   find sub-stanzas causes recursive calls with stanza subcommands inputs

    # indent arg used by recursive ios find calls, abort if set by other caller
    #   setup some things when initially called by user script, indent is undef
    #   set indent null, trim input/template, everything starts on left margin
    #   set template errors sub now, so die always refers to original caller
    #   croak with an error if called by user script with indent arg set
    my $indent = shift;
    if (not defined $indent) {
        $indent = "";
        $config = Mnet::Stanza::trim($config);
        $template = Mnet::Stanza::trim($template);
        sub _ios_error_in_template {
            my $template = shift // croak "undefined arg";
            $template =~ /^(\s*\S.*)/m;
            die "ios error in template line '$1'".Carp::shortmess()."\n";
        }
    } elsif (caller ne "Mnet::Stanza::_ios_find") {
        croak("Mnet::Stanza::ios called with too many args")
    }

    # init output config overlay
    my $output = "";

    # track lines checked in current stanza
    #   key is set for each line checked with add/find/match/remove operation
    #   used by _ios_remove sub to ensure lines already checked are not removed
    #   example, adds test 1-2, removes all others: +test 1, +test 2, -test *!*
    my $checked = {};

    # clear lines starting with the ios comment character from template
    $template =~ s/^\s*!.*//mg;

    # parse list of lines/stanzas from input config at current indent level
    my @template_stanzas = Mnet::Stanza::parse($template, qr/^$indent\S/);
    croak("no text at indent ".length($indent)) if not $template_stanzas[0];

    # loop to process parsed template stanzas
    foreach my $template_stanza (@template_stanzas) {

        # add line '+'
        if ($template_stanza =~ /^\+/) {
            $output .= _ios_add($template_stanza, $config, $checked, $indent);

        # find stanza '>'
        #   which recursively calls this function to process subcommands
        } elsif ($template_stanza =~ /^\>/) {
            $output .= _ios_find($template_stanza, $config, $checked, $indent);

        # match stanza '='
        } elsif ($template_stanza =~ /^\=/) {
            $output .= _ios_match($template_stanza, $config, $checked, $indent);

        # remove line or stanza '-'
        } elsif ($template_stanza =~ /^\-/) {
            $output .= _ios_remove($template_stanza, $config, $checked,$indent);

        # otherwise abort with template error
        } else {
            _ios_error_in_template($template_stanza);
        }

    # continue processing parsed template stanzas
    }

    # finished ios function, return output config overlay
    return $output;
}



sub _ios_add {

# $output = _ios_add($template, $config, \%checked, $indent)
# purpose: ios template '+' add line if missing
# $output: missing config commands that need to be added
# $template: current template line to add, expected to be on left margin
# $config: ios config to work on, expected to be on left margin
# \%checked: keys for each add/find/match/remove in current stanza
# $indent: current template indent, zero or more spaces

    # read input args and initialize output config overlay
    my ($template, $config, $checked, $indent) = (shift, shift, shift, shift);
    my $output = "";

    # parse single line to add
    _ios_error_in_template($template) if $template !~ /^\+(\S.*)$/;
    my $add_line = $1;

    # append line to output if not already present with same indent
    $output .= $indent.$add_line."\n" if $config !~ /^$indent\Q$add_line\E$/m;

    # note that this line was checked
    $checked->{$indent.$add_line}++;

    # finished _ios_add, return output config overlay
    return $output;
}



sub _ios_find {

# $output = _ios_find($template, $config, \%checked, $indent)
# purpose: ios template '>' find stanza
# $output: missing config commands that need to be added
# $template: current template line to find, expected to be on left margin
# $config: ios config to work on, expected to be on left margin
# \%checked: keys for each add/find/match/remove in current stanza
# $indent: current template indent, zero or more spaces

    # read input args and initialize output config overlay
    my ($template, $config, $checked, $indent) = (shift, shift, shift, shift);
    my $output = "";

    # parse template first line to find
    _ios_error_in_template($template) if $template !~ /^\>(\S.*)$/m;
    my $find_line = $1;

    # parse template subcommands under first line to find
    my $find_subcommands = undef;
    foreach my $line (split(/\n/, $template)) {
        $find_subcommands .= "$line\n" if defined $find_subcommands;
        $find_subcommands = "" if not defined $find_subcommands
    }

    # process find template stanza, assuming subcommands under first line
    if ($find_subcommands =~ /\S/) {

        # parse template indent level of subcommands
        my $indent_subcommands = "";
        $indent_subcommands = $1 if $template =~ /\n(\s*)/;

        # parse config looking for stanza that matched first line of template
        my $config_stanza = Mnet::Stanza::parse($config, qr/^\Q$find_line\E$/);

        # look for matching stanza subcommands from config
        my $config_subcommands = undef;
        foreach my $line (split(/\n/, $config_stanza)) {
            $config_subcommands .= "$line\n" if defined $config_subcommands;
            $config_subcommands = "" if not defined $config_subcommands
        }

        # resursive compare found template subcommands to config subcommands
        my $output_subcommands = Mnet::Stanza::ios(
            Mnet::Stanza::trim($find_subcommands),
            Mnet::Stanza::trim($config_subcommands),
        );

        # append found stanza with stanza output sub-commands
        if ($output_subcommands =~ /\S/) {
            $output .= $indent.$find_line."\n";
            foreach my $line (split(/\n/, $output_subcommands)) {
                $output .= $indent_subcommands.$line."\n";
            }
        }

    # finished processing find template stanza
    }

    # note that template find stanza first line was checked
    $checked->{$indent.$find_line}++;

    # finished _ios_find, return output config overlay
    return $output;
}



sub _ios_match {

# $output = _ios_match($template, $config, \%checked, $indent)
# purpose: ios template '=' match stanza
# $output: missing config commands that need to be added
# $template: current template line to match, expected to be on left margin
# $config: ios config to work on, expected to be on left margin
# \%checked: keys for each add/find/match/remove in current stanza
# $indent: current template indent, zero or more spaces

    # read input args and initialize output config overlay
    my ($template, $config, $checked, $indent) = (shift, shift, shift, shift);
    my $output = "";

    # parse first line to match
    _ios_error_in_template($template) if $template !~ /^\=(\S.*)$/m;
    my $match_line = $1;

    # parse entire stanza to match
    my $match_stanza = "";
    foreach my $line (split(/\n/, $template)) {
        _ios_error_in_template($line) if $line !~ /^(\s*)=(\S.*)$/;
        $match_stanza .= $1.$2."\n";
    }

    # look for matching stanza in config
    my $config_stanza = Mnet::Stanza::parse($config,qr/^\Q$match_line\E$/)."\n";

    # append match stanza to output if not already present with same indent
    $output .= $indent.$match_stanza if $config_stanza ne $match_stanza;

    # note that this line was checked
    $checked->{$indent.$match_line}++;

    # finished _ios_stanza, return output config overlay
    return $output;
}



sub _ios_remove {

# $output = _ios_remove($template, $config, \%checked, $indent)
# purpose: ios template '-' remove line or stanza
# $output: extra config commands that need to be removed
# $template: current template line to remove, expected to be on left margin
# $config: ios config to work on, expected to be on left margin
# \%checked: keys for each add/find/match/remove in current stanza
# $indent: current template indent, zero or more spaces

    # read input args and initialize output config overlay
    my ($template, $config, $checked, $indent) = (shift, shift, shift, shift);
    my $output = "";

    # parse single line to remove
    _ios_error_in_template($template) if $template !~ /^\-(\S.*)$/;
    my $remove_line = $1;

    # set regex to match line, with optional '*!*' wildcard at end
    my ($regex_line, $regex_wildcard) = ($remove_line, "");
    ($regex_line, $regex_wildcard) = ($1, ".*")
        if $remove_line =~ /^(.*)\*\!\*$/;

    # check each config line for a match to remove line regex/wildcard
    #   ensure line was not already checked by add/find/match/remove operations
    #   skip line removal if it was already checked, otherwise note as checked
    #   lines matched in the config are output with a 'no' in front of them
    #   lines matched already starting with 'no' are output without the 'no'
    foreach my $config_line (split(/\n/, $config)) {
        if ($config_line =~ /^$indent(\Q$regex_line\E$regex_wildcard)$/m) {
            my $match_line = $1;
            if (not $checked->{$indent.$match_line}) {
                $checked->{$indent.$match_line}++;
                my $no_line = "no $match_line";
                $no_line =~ s/^no no //;
                $output .= $indent.$no_line."\n";
            }
        }
    }

    # finished _ios_remove, return output config overlay
    return $output;
}



=head1 SEE ALSO

L<Mnet>

L<Mnet::Log>

=cut

# normal end of package
1;

