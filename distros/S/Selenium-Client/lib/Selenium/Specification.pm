package Selenium::Specification;
$Selenium::Specification::VERSION = '2.01';
# ABSTRACT: Module for building a machine readable specification for Selenium

use strict;
use warnings;

use v5.28;

no warnings 'experimental';
use feature qw/signatures state unicode_strings/;

use List::Util qw{uniq};
use HTML::Parser();
use JSON::MaybeXS();
use File::HomeDir();
use File::Slurper();
use DateTime::Format::HTTP();
use HTTP::Tiny();
use File::Path qw{make_path};
use File::Spec();
use Encode             qw{decode};
use Unicode::Normalize qw{NFC};

#TODO make a JSONWire JSON spec since it's not changing

# URLs and the container ID
our %spec_urls = (
    unstable => {
        url        => 'https://w3c.github.io/webdriver/',
        section_id => 'endpoints',
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
our $method = {};


sub read ( $client_dir, $type = 'stable', $nofetch = 1, $hardcode = 1 ) {
    my $buf;
    state $static;
    if ( !$hardcode ) {
        my $dir  = File::Spec->catdir( $client_dir, "specs" );
        my $file = File::Spec->catfile( "$dir", "$type.json" );
        fetch( once => $nofetch, dir => $dir );
        die "could not write $file: $@" unless -f $file;
        $buf = File::Slurper::read_binary($file);
    }
    else {
        $static = readline(DATA) unless $static;
        $buf    = $static;
    }
    my $array = JSON::MaybeXS->new()->utf8()->decode($buf);
    my %hash;
    @hash{ map { $_->{name} } @$array } = @$array;
    return \%hash;
}


#TODO needs to grab args and argtypes still
sub fetch (%options) {
    my $dir = $options{dir};

    my $rc = 0;
    foreach my $spec ( sort keys(%spec_urls) ) {
        make_path($dir) unless -d $dir;
        my $file          = File::Spec->catfile( "$dir", "$spec.json" );
        my $last_modified = -f $file ? ( stat($file) )[9] : undef;

        if ( $options{once} && $last_modified ) {
            print STDERR "Skipping fetch, using cached result" if $options{verbose};
            next;
        }

        $last_modified = 0 if $options{force};

        my $spc = _build_spec( $last_modified, %{ $spec_urls{$spec} } );
        if ( !$spc ) {
            print STDERR "Could not retrieve $spec_urls{$spec}{url}, skipping" if $options{verbose};
            $rc = 1;
            next;
        }

        # Second clause is for an edge case -- if the header is not set for some bizarre reason we should obey force still
        if ( ref $spc ne 'ARRAY' && $last_modified ) {
            print STDERR "Keeping cached result '$file', as page has not changed since last fetch.\n" if $options{verbose};
            next;
        }

        _write_spec( $spc, $file );
        print "Wrote $file\n" if $options{verbose};
    }
    return $rc;
}

sub _write_spec ( $spec, $file ) {
    my $spec_json = JSON::MaybeXS->new()->utf8()->encode($spec);
    return File::Slurper::write_binary( $file, $spec_json );
}

sub _build_spec ( $last_modified, %spec ) {
    my $page = $browser->get( $spec{url} );
    return unless $page->{success};

    if ( $page->{headers}{'last-modified'} && $last_modified ) {
        my $modified = DateTime::Format::HTTP->parse_datetime( $page->{headers}{'last-modified'} )->epoch();
        return 'cache' if $modified < $last_modified;
    }

    my $html = NFC( decode( 'UTF-8', $page->{content} ) );

    $parse = [];
    %state = ( id => $spec{section_id} );
    my $parser = HTML::Parser->new(
        handlers => {
            start => [ \&_handle_open,  "tagname,attr" ],
            end   => [ \&_handle_close, "tagname" ],
            text  => [ \&_handle_text,  "text" ],
        }
    );
    $parser->parse($html);

    # Now that we have parsed the methods, let us go ahead and build the argspec based on the anchors for each endpoint.
    foreach my $m (@$parse) {
        $method = $m;
        %state  = ();
        my $mparser = HTML::Parser->new(
            handlers => {
                start => [ \&_endpoint_open,  "tagname,attr" ],
                end   => [ \&_endpoint_close, "tagname" ],
                text  => [ \&_endpoint_text,  "text" ],
            },
        );
        $mparser->parse($html);
    }

    return _fixup( \%spec, $parse );
}

sub _fixup ( $spec, $parse ) {
    @$parse = map {
        $_->{href} = "$spec->{url}$_->{href}";

        #XXX correct TYPO in the spec
        $_->{uri} =~ s/{sessionid\)/{sessionid}/g;
        @{ $_->{output_params} } = grep { $_ ne 'null' } uniq @{ $_->{output_params} };
        $_
    } @$parse;

    return $parse;
}

sub _handle_open ( $tag, $attr ) {

    if ( $tag eq 'section' && ( $attr->{id} || '' ) eq $state{id} ) {
        $state{active} = 1;
        return;
    }
    if ( $tag eq 'tr' ) {
        $state{method}  = 1;
        $state{headers} = [qw{method uri name}];
        $state{data}    = {};
        return;
    }
    if ( $tag eq 'td' ) {
        $state{heading} = shift @{ $state{headers} };
        return;
    }
    if ( $tag eq 'a' && $state{heading} && $attr->{href} ) {
        $state{data}{href} = $attr->{href};
    }
}

sub _handle_close ($tag) {
    if ( $tag eq 'section' ) {
        $state{active} = 0;
        return;
    }
    if ( $tag eq 'tr' && $state{active} ) {
        if ( $state{past_first} ) {
            push( @$parse, $state{data} );
        }

        $state{past_first} = 1;
        $state{method}     = 0;
        return;
    }
}

sub _handle_text ($text) {
    return unless $state{active} && $state{method} && $state{past_first} && $state{heading};
    $text =~ s/\s//gm;
    return unless $text;
    $state{data}{ $state{heading} } .= $text;
}

# Endpoint parsers

sub _endpoint_open ( $tag, $attr ) {
    my $id = $method->{href};
    $id =~ s/^#//;

    if ( $attr->{id} && $attr->{id} eq $id ) {
        $state{active} = 1;
    }
    if ( $tag eq 'ol' ) {
        $state{in_tag} = 1;
    }
    if ( $tag eq 'dt' && $state{in_tag} && $state{last_tag} eq 'dl' ) {
        $state{in_dt} = 1;
    }
    if ( $tag eq 'code' && $state{in_dt} && $state{in_tag} && $state{last_tag} eq 'dt' ) {
        $state{in_code} = 1;
    }

    $state{last_tag} = $tag;
}

sub _endpoint_close ($tag) {
    return unless $state{active};
    if ( $tag eq 'section' ) {
        $state{active} = 0;
        $state{in_tag} = 0;
    }
    if ( $tag eq 'ol' ) {
        $state{in_tag} = 0;
    }
    if ( $tag eq 'dt' ) {
        $state{in_dt} = 0;
    }
    if ( $tag eq 'code' ) {
        $state{in_code} = 0;
    }
}

sub _endpoint_text ($text) {
    if ( $state{active} && $state{in_tag} && $state{in_code} && $state{in_dt} && $state{last_tag} eq 'code' ) {
        $method->{output_params} //= [];
        $text =~ s/\s//gm;
        push( @{ $method->{output_params} }, $text ) if $text;
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Selenium::Specification - Module for building a machine readable specification for Selenium

=head1 VERSION

version 2.01

=head1 SUBROUTINES

=head2 read($client_dir STRING, $type STRING, $nofetch BOOL, $hardcoe BOOL)

Reads the copy of the provided spec type, and fetches it if a cached version is not available.

If hardcode is passed we use the JSON in the DATA section below.

=head2 fetch(%OPTIONS HASH)

Builds a spec hash based upon the WC3 specification documents, and writes it to disk.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Selenium::Client|Selenium::Client>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/troglodyne-internet-widgets/selenium-client-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

__DATA__
[{"output_params":["capabilities","sessionId"],"href":"https://www.w3.org/TR/webdriver1/#dfn-creating-a-new-session","uri":"/session","name":"NewSession","method":"POST"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-delete-session","output_params":[],"uri":"/session/{sessionid}","method":"DELETE","name":"DeleteSession"},{"method":"GET","name":"Status","uri":"/status","href":"https://www.w3.org/TR/webdriver1/#dfn-status","output_params":["ready"]},{"method":"GET","name":"GetTimeouts","uri":"/session/{sessionid}/timeouts","output_params":["script"],"href":"https://www.w3.org/TR/webdriver1/#dfn-get-timeouts"},{"output_params":["script"],"href":"https://www.w3.org/TR/webdriver1/#dfn-timeouts","name":"SetTimeouts","method":"POST","uri":"/session/{sessionid}/timeouts"},{"method":"POST","name":"NavigateTo","uri":"/session/{sessionid}/url","href":"https://www.w3.org/TR/webdriver1/#dfn-navigate-to","output_params":["https://example.com"]},{"href":"https://www.w3.org/TR/webdriver1/#dfn-get-current-url","output_params":[],"method":"GET","name":"GetCurrentURL","uri":"/session/{sessionid}/url"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-back","output_params":["window.history.back"],"uri":"/session/{sessionid}/back","method":"POST","name":"Back"},{"output_params":["pageHide"],"href":"https://www.w3.org/TR/webdriver1/#dfn-forward","name":"Forward","method":"POST","uri":"/session/{sessionid}/forward"},{"output_params":["file"],"href":"https://www.w3.org/TR/webdriver1/#dfn-refresh","method":"POST","name":"Refresh","uri":"/session/{sessionid}/refresh"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-get-title","output_params":["document.title"],"uri":"/session/{sessionid}/title","name":"GetTitle","method":"GET"},{"method":"GET","name":"GetWindowHandle","uri":"/session/{sessionid}/window","href":"https://www.w3.org/TR/webdriver1/#dfn-get-window-handle","output_params":[]},{"output_params":[],"href":"https://www.w3.org/TR/webdriver1/#dfn-close-window","name":"CloseWindow","method":"DELETE","uri":"/session/{sessionid}/window"},{"name":"SwitchToWindow","method":"POST","uri":"/session/{sessionid}/window","output_params":["handle"],"href":"https://www.w3.org/TR/webdriver1/#dfn-switch-to-window"},{"uri":"/session/{sessionid}/window/handles","name":"GetWindowHandles","method":"GET","output_params":[],"href":"https://www.w3.org/TR/webdriver1/#dfn-get-window-handles"},{"name":"SwitchToFrame","method":"POST","uri":"/session/{sessionid}/frame","output_params":["id"],"href":"https://www.w3.org/TR/webdriver1/#dfn-switch-to-frame"},{"uri":"/session/{sessionid}/frame/parent","name":"SwitchToParentFrame","method":"POST","href":"https://www.w3.org/TR/webdriver1/#dfn-switch-to-parent-frame","output_params":[]},{"uri":"/session/{sessionid}/window/rect","method":"GET","name":"GetWindowRect","output_params":[],"href":"https://www.w3.org/TR/webdriver1/#dfn-get-window-rect"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-set-window-rect","output_params":["width"],"name":"SetWindowRect","method":"POST","uri":"/session/{sessionid}/window/rect"},{"uri":"/session/{sessionid}/window/maximize","method":"POST","name":"MaximizeWindow","href":"https://www.w3.org/TR/webdriver1/#dfn-maximize-window","output_params":[]},{"output_params":[],"href":"https://www.w3.org/TR/webdriver1/#dfn-minimize-window","name":"MinimizeWindow","method":"POST","uri":"/session/{sessionid}/window/minimize"},{"method":"POST","name":"FullscreenWindow","uri":"/session/{sessionid}/window/fullscreen","href":"https://www.w3.org/TR/webdriver1/#dfn-fullscreen-window","output_params":[]},{"uri":"/session/{sessionid}/element/active","method":"GET","name":"GetActiveElement","href":"https://www.w3.org/TR/webdriver1/#dfn-get-active-element","output_params":[]},{"output_params":["#toremove"],"href":"https://www.w3.org/TR/webdriver1/#dfn-find-element","uri":"/session/{sessionid}/element","method":"POST","name":"FindElement"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-find-elements","output_params":["using"],"name":"FindElements","method":"POST","uri":"/session/{sessionid}/elements"},{"uri":"/session/{sessionid}/element/{elementid}/element","name":"FindElementFromElement","method":"POST","href":"https://www.w3.org/TR/webdriver1/#dfn-find-element-from-element","output_params":["using"]},{"method":"POST","name":"FindElementsFromElement","uri":"/session/{sessionid}/element/{elementid}/elements","output_params":["using"],"href":"https://www.w3.org/TR/webdriver1/#dfn-find-elements-from-element"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-is-element-selected","output_params":["input"],"uri":"/session/{sessionid}/element/{elementid}/selected","name":"IsElementSelected","method":"GET"},{"output_params":[],"href":"https://www.w3.org/TR/webdriver1/#dfn-get-element-attribute","method":"GET","name":"GetElementAttribute","uri":"/session/{sessionid}/element/{elementid}/attribute/{name}"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-get-element-property","output_params":[],"uri":"/session/{sessionid}/element/{elementid}/property/{name}","name":"GetElementProperty","method":"GET"},{"name":"GetElementCSSValue","method":"GET","uri":"/session/{sessionid}/element/{elementid}/css/{propertyname}","href":"https://www.w3.org/TR/webdriver1/#dfn-get-element-css-value","output_params":["xml"]},{"name":"GetElementText","method":"GET","uri":"/session/{sessionid}/element/{elementid}/text","href":"https://www.w3.org/TR/webdriver1/#dfn-get-element-text","output_params":["a"]},{"uri":"/session/{sessionid}/element/{elementid}/name","name":"GetElementTagName","method":"GET","output_params":[],"href":"https://www.w3.org/TR/webdriver1/#dfn-get-element-tag-name"},{"method":"GET","name":"GetElementRect","uri":"/session/{sessionid}/element/{elementid}/rect","href":"https://www.w3.org/TR/webdriver1/#dfn-get-element-rect","output_params":["x"]},{"method":"GET","name":"IsElementEnabled","uri":"/session/{sessionid}/element/{elementid}/enabled","href":"https://www.w3.org/TR/webdriver1/#dfn-is-element-enabled","output_params":["xml"]},{"output_params":["input"],"href":"https://www.w3.org/TR/webdriver1/#dfn-element-click","uri":"/session/{sessionid}/element/{elementid}/click","method":"POST","name":"ElementClick"},{"uri":"/session/{sessionid}/element/{elementid}/clear","name":"ElementClear","method":"POST","output_params":["innerHTML"],"href":"https://www.w3.org/TR/webdriver1/#dfn-element-clear"},{"method":"POST","name":"ElementSendKeys","uri":"/session/{sessionid}/element/{elementid}/value","href":"https://www.w3.org/TR/webdriver1/#dfn-element-send-keys","output_params":["type"]},{"href":"https://www.w3.org/TR/webdriver1/#dfn-get-page-source","output_params":["true"],"uri":"/session/{sessionid}/source","method":"GET","name":"GetPageSource"},{"method":"POST","name":"ExecuteScript","uri":"/session/{sessionid}/execute/sync","href":"https://www.w3.org/TR/webdriver1/#dfn-execute-script","output_params":[]},{"uri":"/session/{sessionid}/execute/async","name":"ExecuteAsyncScript","method":"POST","output_params":["unset"],"href":"https://www.w3.org/TR/webdriver1/#dfn-execute-async-script"},{"method":"GET","name":"GetAllCookies","uri":"/session/{sessionid}/cookie","href":"https://www.w3.org/TR/webdriver1/#dfn-get-all-cookies","output_params":[]},{"uri":"/session/{sessionid}/cookie/{name}","name":"GetNamedCookie","method":"GET","output_params":[],"href":"https://www.w3.org/TR/webdriver1/#dfn-get-named-cookie"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-adding-a-cookie","output_params":["cookie"],"method":"POST","name":"AddCookie","uri":"/session/{sessionid}/cookie"},{"uri":"/session/{sessionid}/cookie/{name}","name":"DeleteCookie","method":"DELETE","href":"https://www.w3.org/TR/webdriver1/#dfn-delete-cookie","output_params":[]},{"uri":"/session/{sessionid}/cookie","name":"DeleteAllCookies","method":"DELETE","output_params":[],"href":"https://www.w3.org/TR/webdriver1/#dfn-delete-all-cookies"},{"uri":"/session/{sessionid}/actions","name":"PerformActions","method":"POST","output_params":[],"href":"https://www.w3.org/TR/webdriver1/#dfn-perform-actions"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-release-actions","output_params":[],"name":"ReleaseActions","method":"DELETE","uri":"/session/{sessionid}/actions"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-dismiss-alert","output_params":[],"uri":"/session/{sessionid}/alert/dismiss","name":"DismissAlert","method":"POST"},{"output_params":[],"href":"https://www.w3.org/TR/webdriver1/#dfn-accept-alert","uri":"/session/{sessionid}/alert/accept","method":"POST","name":"AcceptAlert"},{"output_params":[],"href":"https://www.w3.org/TR/webdriver1/#dfn-get-alert-text","uri":"/session/{sessionid}/alert/text","name":"GetAlertText","method":"GET"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-send-alert-text","output_params":["prompt"],"uri":"/session/{sessionid}/alert/text","method":"POST","name":"SendAlertText"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-take-screenshot","output_params":["canvas"],"uri":"/session/{sessionid}/screenshot","name":"TakeScreenshot","method":"GET"},{"href":"https://www.w3.org/TR/webdriver1/#dfn-error-code","output_params":["error"],"uri":"/session/{sessionid}/element/{elementid}/screenshot","method":"GET","name":"TakeElementScreenshot"}]
