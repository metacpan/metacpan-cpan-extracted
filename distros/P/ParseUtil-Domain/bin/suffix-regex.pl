use Modern::Perl;
use charnames ':full';
use Net::IDN::Encode; 
use Regexp::Assemble::Compressed;

use Getopt::Long;
my $tld_file;  
GetOptions(
    "tld_file=s" => \$tld_file
);

process_tld_data_files($tld_file);

sub process_tld_data_files {
    my $tld_data_file = shift;
    open my $fh, "<:encoding(utf8)", $tld_data_file;
    my @content = grep { $_ !~ /^(?:\s+|\/)/ } <$fh>;
    chomp @content;
    close $fh;
    my @processed_tlds = map { reverse_puny_encode($_) } @content;

    my $wildcards  = {};
    my $regexp_obj = Regexp::Assemble::Compressed->new();

    foreach my $processed_tld (@processed_tlds) {
        my ($object, $has_wildcard, $has_exclusion) =
            @{$processed_tld}{qw/object has_wildcard has_exclusion/};
        my $regexp_chunk = '';
        if ($has_wildcard && !defined $wildcards->{$object}) {
            $wildcards->{$object} = [];
        }
        elsif ($has_exclusion) {
            my @segments = split /\./, $object;
            my $exclude  = pop(@segments);
            my $wildcard = join "." => @segments;
            if (!defined $wildcards->{$wildcard}) {
                $wildcards->{$wildcard} = [];
            }
            my $exclusions = $wildcards->{$wildcard};
            push(@$exclusions, $exclude);
        }
        else {
            $regexp_chunk = '\Q' . $object . '\E';
            $regexp_obj->add($regexp_chunk);
        }
    }

    # special rules for wildcards
    foreach my $wildcard (keys %$wildcards) {
        my $exclusions   = $wildcards->{$wildcard};
        my $regexp_chunk = '\Q' . $wildcard . '\E\.';
        foreach my $exclusion (@$exclusions) {
            $regexp_chunk .= '(?!' . $exclusion . '$)';
        }
        $regexp_chunk .= '[^\.]+';
        $regexp_obj->add($regexp_chunk);

        # still need to match on the actual wildcard
        $regexp_chunk = '\Q' . $wildcard . '\E';
        $regexp_obj->add($regexp_chunk);

    }
    my $regex = $regexp_obj->re();
    say $regex;
}

sub reverse_puny_encode {
    my $object        = shift;
    my $has_wildcard  = 0;
    my $has_exclusion = 0;
    $has_wildcard  = $object =~ s/\*\.//;    # remove leading "*." and flag
    $has_exclusion = $object =~ s/\!//;      # remove leading "!." and flag

    $object =~ s/^[\P{Alnum}\s]*([\p{Alnum}\.]+)[\P{Alnum}\s]*$/$1/;
    my @segments = split /\./, $object;
    my @reversed_segments;

    # puny encode everything
    eval {
        @reversed_segments =
            map { Net::IDN::Encode::domain_to_ascii($_) } reverse @segments;
    };
    if (my $e = $@) {
        my @components = split //, $object;
        map { print $_. " " . charnames::viacode(ord($_)) . "\n" }
            @components;
        warn "Unable to process $object.\n"
            . "Please report this error to package author.";
    }

    my $reverse_joined = join "." => @reversed_segments;
    return {
        object        => $reverse_joined,
        has_wildcard  => $has_wildcard,
        has_exclusion => $has_exclusion
    };
}
