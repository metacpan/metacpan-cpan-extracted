#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dump qw(pp);
use Getopt::Long;
use File::Find;
use File::Slurp;
use FindBin qw($Bin);
use Path::Class;

# evil global for wanted() function used with File::Find
my %tpl_of;

# default options
my %cliopt = (
    language    => 'it',
);
# get overrides from cli
GetOptions(\%cliopt, "language=s");

# show the differences for the chosen language
token_diffs( $cliopt{language} );
template_diffs( $cliopt{language} );

sub token_diffs {
    my $target_lang = shift;

    # get the i_default list
    my $idefault_msgids = get_msgids(q{i_default});

    # get the target lang list
    my $targetlang_msgids = get_msgids($target_lang);
    #warn pp($targetlang_msgids); exit;

    # see what's missing from the target
    print "Missing phrases in '$target_lang' translation:\n\n";
    diffs($idefault_msgids, $targetlang_msgids);

    # see if we have anything extra in the target
    print "Additional phrases in '$target_lang' translation:\n\n";
    diffs($targetlang_msgids, $idefault_msgids);

    return;
}

sub template_diffs {
    my $target_lang = shift;

    # get the list of i_default email templates
    my %idefault_tpls = template_list( q{i_default} );

    # get the list of templates for the target language
    my %targetlang_tpls = template_list( $target_lang );

    # see what's missing from the target
    print "Missing templates in '$target_lang' translation:\n\n";
    tpl_diffs(\%idefault_tpls, \%targetlang_tpls);

    # see if we have anything extra in the target
    print "Additional templates in '$target_lang' translation:\n\n";
    tpl_diffs(\%targetlang_tpls, \%idefault_tpls);
    
    return;
}

# XXX sane people would probably have used List::Compare
# XXX unfortunately I didn't have it installed, and was working
# XXX without a 'net connection
sub diffs {
    my ($left, $right) = @_;

    my %left_copy = %{ $left };

    # see what's missing from the target
    map (
        delete $left_copy{$_},
        keys %{$right}
    );

    my @keys = sort keys %left_copy;
    if (@keys) {
        foreach my $key (@keys) {
            print "  $key\n    $left_copy{$key}\n\n";
        }
    }
    else {
        print " - NONE -\n\n";
    }

    return;
}

sub tpl_diffs {
    my ($left, $right) = @_;

    my %left_copy = %{ $left };

    # see what's missing from the target
    map (
        delete $left_copy{$_},
        keys %{$right}
    );

    my @keys = sort keys %left_copy;
    if (@keys) {
        foreach my $key (@keys) {
            print "  $key\n\n";
        }
    }
    else {
        print " - NONE -\n\n";
    }

    return;
}

# read in an i18n file
sub read_i18n {
    my $filename = shift;

    my $dir = dir(
        dir($Bin)->parent,
        q{lib},
        q{Parley},
        q{I18N}
    );

    my $file = file(
        $dir,
        $filename
    ) . q{}; # to stop read_file() throwing a strop

    my $filedata = read_file( $file )
        or die $!;

    return $filedata;
}

sub wanted {
    -f $_
    && $tpl_of{$_}++
}

sub template_list {
    my $target_lang = shift;

    my $dir = dir(
        dir($Bin)->parent,
        q{root},
        q{email_templates},
        $target_lang
    );

    %tpl_of = ();
    find( \&wanted, $dir );

    return %tpl_of;
}

# TODO - find a suitable "gettext" perl module to do this properly
# the regexp to match on .. it's easier to format outside the "while"
sub get_msgids {
    my $lang = shift;
    my ($data, %msg_of, @msgids, $regexp);

    $data = read_i18n(
        $lang . q{.po}
    );

    # (sorry!)
    $regexp = qr{
        (?:.+?)         # any preceding junk
        ^msgid
        \s+             # whitespace after first token
        "(.+?)"         # the token name
        \s* \n          # optional whitespace to EOL
        ^msgstr
        \s+             # whitespace after second token
        "(.+?)"         # the token name
    }xms;

    # get all the msgid/msgstr pairs and store the data in a hash
    while ($data =~ m{\G$regexp}g) {
        $msg_of{$1} = $2;
    }

    return \%msg_of;
}
