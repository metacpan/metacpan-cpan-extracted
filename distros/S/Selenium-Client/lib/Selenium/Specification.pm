package Selenium::Specification;
$Selenium::Specification::VERSION = '1.0';
# ABSTRACT: Module for building a machine readable specification for Selenium

use strict;
use warnings;

no warnings 'experimental';
use feature qw/signatures/;

use List::Util qw{uniq};
use HTML::Parser();
use JSON::MaybeXS();
use File::HomeDir();
use File::Slurper();
use DateTime::Format::HTTP();
use HTTP::Tiny();
use File::Path qw{make_path};
use File::Spec();

#TODO make a JSONWire JSON spec since it's not changing

# URLs and the container ID
our %spec_urls = (
    unstable => {
       url         => 'https://w3c.github.io/webdriver/',
       section_id  => 'endpoints',
    },
    draft => {
        url        => "https://www.w3.org/TR/webdriver2/",
        section_id => 'endpoints',
    },
    stable => {
        url        => "https://www.w3.org/TR/webdriver1/",
        section_id => 'list-of-endpoints',
    },
);

our $browser = HTTP::Tiny->new();
my %state;
my $parse = [];
my $dir = File::Spec->catdir( File::HomeDir::my_home(),".selenium","specs" );
our $method = {};


sub read($type='stable', $nofetch=1) {
    my $file =  File::Spec->catfile( "$dir","$type.json");
    fetch( once => $nofetch );
    die "could not write $file: $@" unless -f $file;
    my $buf = File::Slurper::read_text($file);
    my $array = JSON::MaybeXS::decode_json($buf);
    my %hash;
    @hash{map { $_->{name} } @$array} = @$array;
    return \%hash;
}


#TODO needs to grab args and argtypes still
sub fetch (%options) {
    $dir = $options{dir} if $options{dir};

    my $rc = 0;
    foreach my $spec ( sort keys(%spec_urls) ) {
        make_path( $dir ) unless -d $dir;
        my $file =  File::Spec->catfile( "$dir","$spec.json");
        my $last_modified = -f $file ? (stat($file))[9] : undef;

        if ($options{once} && $last_modified) {
            print STDERR "Skipping fetch, using cached result" if $options{verbose};
            next;
        }

        $last_modified = 0 if $options{force};

        my $spc = _build_spec($last_modified, %{$spec_urls{$spec}});
        if (!$spc) {
            print STDERR "Could not retrieve $spec_urls{$spec}{url}, skipping" if $options{verbose};
            $rc = 1;
            next;
        }

        # Second clause is for an edge case -- if the header is not set for some bizarre reason we should obey force still
        if (ref $spc ne 'ARRAY' && $last_modified) {
            print STDERR "Keeping cached result '$file', as page has not changed since last fetch.\n" if $options{verbose};
            next;
        }

        _write_spec($spc, $file);
        print "Wrote $file\n" if $options{verbose};
    }
    return $rc;
}



sub _write_spec ($spec, $file) {
    my $spec_json = JSON::MaybeXS::encode_json($spec);
    return File::Slurper::write_text($file, $spec_json);
}

sub _build_spec($last_modified, %spec) {
    my $page = $browser->get($spec{url});
    return unless $page->{success};

    if ($page->{headers}{'last-modified'} && $last_modified ) {
        my $modified = DateTime::Format::HTTP->parse_datetime($page->{headers}{'last-modified'})->epoch();
        return 'cache' if $modified < $last_modified;
    }

    my $html = $page->{content};

    $parse = [];
    %state = ( id => $spec{section_id} );
    my $parser = HTML::Parser->new(
        handlers => {
            start => [\&_handle_open,  "tagname,attr"],
            end   => [\&_handle_close, "tagname"],
            text  => [\&_handle_text,  "text"],
        }
    );
    $parser->parse($html);

    # Now that we have parsed the methods, let us go ahead and build the argspec based on the anchors for each endpoint.
    foreach my $m (@$parse) {
        $method = $m;
        %state = ();
        my $mparser = HTML::Parser->new(
            handlers => {
                start => [\&_endpoint_open,  "tagname,attr"],
                end   => [\&_endpoint_close, "tagname"],
                text  => [\&_endpoint_text,  "text"],
            },
        );
        $mparser->parse($html);
    }

    return _fixup(\%spec,$parse);
}

sub _fixup($spec,$parse) {
    @$parse = map {
        $_->{href}    = "$spec->{url}$_->{href}";
        #XXX correct TYPO in the spec
        $_->{uri} =~ s/{sessionid\)/{sessionid}/g;
        @{$_->{output_params}} = grep { $_ ne 'null' } uniq @{$_->{output_params}};
        $_
    } @$parse;

    return $parse;
}

sub _handle_open($tag,$attr) {

    if ( $tag eq 'section' && ($attr->{id} || '') eq $state{id} ) {
        $state{active} = 1;
        return;
    }
    if ($tag eq 'tr') {
        $state{method}  = 1;
        $state{headers} = [qw{method uri name}];
        $state{data}    = {};
        return;
    }
    if ($tag eq 'td') {
        $state{heading} = shift @{$state{headers}};
        return;
    }
    if ($tag eq 'a' && $state{heading} && $attr->{href}) {
        $state{data}{href} = $attr->{href};
    }
}

sub _handle_close($tag) {
    if ($tag eq 'section') {
        $state{active} = 0;
        return;
    }
    if ($tag eq 'tr' && $state{active}) {
        if ($state{past_first}) {
            push(@$parse, $state{data});
        }

        $state{past_first} = 1;
        $state{method} = 0;
        return;
    }
}

sub _handle_text($text) {
    return unless $state{active} && $state{method} && $state{past_first} && $state{heading};
    $text =~ s/\s//gm;
    return unless $text;
    $state{data}{$state{heading}} .= $text;
}

# Endpoint parsers

sub _endpoint_open($tag,$attr) {
    my $id = $method->{href};
    $id =~ s/^#//;

    if ($attr->{id} && $attr->{id} eq $id) {
        $state{active} = 1;
    }
    if ($tag eq 'ol') {
        $state{in_tag} = 1;
    }
    if ($tag eq 'dt' && $state{in_tag} && $state{last_tag} eq 'dl') {
        $state{in_dt} = 1;
    }
    if ($tag eq 'code' && $state{in_dt} && $state{in_tag} && $state{last_tag} eq 'dt') {
        $state{in_code} = 1;
    }

    $state{last_tag} = $tag;
}

sub _endpoint_close($tag) {
    return unless $state{active};
    if ($tag eq 'section') {
        $state{active} = 0;
        $state{in_tag} = 0;
    }
    if ($tag eq 'ol') {
        $state{in_tag} = 0;
    }
    if ($tag eq 'dt') {
        $state{in_dt} = 0;
    }
    if ($tag eq 'code') {
        $state{in_code} = 0;
    }
}

sub _endpoint_text($text) {
    if ($state{active} && $state{in_tag} && $state{in_code} && $state{in_dt} && $state{last_tag} eq 'code') {
        $method->{output_params} //= [];
        $text =~ s/\s//gm;
        push(@{$method->{output_params}},$text) if $text;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Specification - Module for building a machine readable specification for Selenium

=head1 VERSION

version 1.0

=head1 SUBROUTINES

=head2 read($type STRING, $nofetch BOOL)

Reads the copy of the provided spec type, and fetches it if a cached version is not available.

=head2 fetch(%OPTIONS HASH)

Builds a spec hash based upon the WC3 specification documents, and writes it to disk.

=head1 AUTHOR

George S. Baugh <george@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by George S. Baugh.

This is free software, licensed under:

  The MIT (X11) License

=cut
