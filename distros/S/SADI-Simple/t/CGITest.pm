package CGITest;

use strict;
use warnings;

use IO::String;
use URI::Escape;
use File::Slurp;
use CGI;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(simulate_cgi_request);

sub simulate_cgi_request
{
    no warnings 'redefine';

    my %args = @_;

    my @required_args = (
       'request_method',
       'cgi_script',
    );
    
    foreach my $arg (@required_args) {
        die "missing required arg '$arg'" unless grep($_ eq $arg, keys %args);
    }

    $args{request_method} = uc($args{request_method});

    local $ENV{REQUEST_METHOD} = $args{request_method} if $args{request_method};
    local $ENV{CONTENT_TYPE} = $args{content_type} if $args{content_type};
    local $ENV{HTTP_ACCEPT} = $args{http_accept} if $args{http_accept};
    local $ENV{QUERY_STRING} = _build_query_string($args{params}) if $args{params};

    local *STDIN;
    local *STDOUT;
    
    if ($args{request_method} eq 'POST') {
        die "missing required arg 'input_file'" unless $args{input_file};
        open(STDIN, '<', $args{input_file}) or die sprintf('couldn\'t open %s as STDIN: %s', $args{input_file}, $!);
    } 

    tie *STDOUT, 'IO::String', my $cgi_output or die "couldn\'t redirect STDOUT to variable: $!";
    
    my $code = read_file($args{cgi_script});
    
    # CGI.pm relies uses global state variables (e.g. @QUERY_PARAMS), based on the
    # assumption that only one CGI request will be handled per Perl script.
    # In order to work around this, we need to manually reset the global
    # variables.

    CGI::initialize_globals;

    { 
        no warnings 'redefine';
        eval $code; 

        if ($@) {
            warn sprintf('error executing \'%s\': %s', $args{cgi_script}, $@);
        }
    }   

    my ($headers, $output) = split(/\cM\cJ\cM\cJ/s, $cgi_output, 2);
    my $headers_hash = _parse_headers($headers);

    return wantarray ? ($output, $headers_hash) : $output;   
}

sub _build_query_string
{
    my $params = shift;

    my $query_string = '';        
    my $first_param = 1;

    foreach my $key (keys %$params) {
        $query_string .= '&' unless $first_param;
        $query_string .= sprintf('%s=%s', uri_escape($key), uri_escape($params->{$key}));
        $first_param = 0;
    }

    return $query_string;
}
 
sub _parse_headers
{
    print ".\n";
    my $headers = shift;
    print ".\n";
    my %hash = ();
    print ".\n";
    foreach my $header_line (split(/\cM\cJ/, $headers)) {
        print ".\n";
        my ($key, $value) = split(/:/, $header_line, 2);
        $value =~ s/^\s*(\S*)\s*$/$1/;
        $hash{$key} = $value;
    }

    print ".\n";
    return \%hash;
}

1;
