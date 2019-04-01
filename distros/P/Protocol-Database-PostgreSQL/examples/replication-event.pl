use strict;
use warnings;
use 5.010;

=pod

 Have copy data BEGIN 556
 Have copy data table public.jobs: INSERT: id[bigint]:1 method[text]:'sum' result[text]:null details[jsonb]:'{"x": 14, "y": 26}'
 Have copy data table public.jobs: UPDATE: id[bigint]:1 method[text]:'sum' result[text]:'40' details[jsonb]:'{"x": 14, "y": 26}'
 Have copy data COMMIT 556

=cut

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'trace';

use JSON::MaybeXS;
my $json = JSON::MaybeXS->new;
my @lines = split /\n/, <<'EOF';
table public.jobs: INSERT: id[bigint]:1 method[text]:'sum' result[text]:null details[jsonb]:'{"x": 14, "y": 26}'
table public.jobs: UPDATE: id[bigint]:1 method[text]:'sum' result[text]:'40' details[jsonb]:'{"x": 14, "y": 26}'
EOF
for (@lines) {
    if(s{^table ([^.])+\.([^:]+): (INSERT|UPDATE|DELETE): }{}) {
        my ($schema, $table, $action) = ($1, $2, $3);
        my %fields;
        while(s{\G([^\[]+)\[([^\]]+)\]:}{}) {
            my ($field, $type) = ($1, $2);
            my $val = do {
                if(s{^null ?}{}) {
                    undef
                } elsif($type =~ /^(?:big)?int$/) {
                    s{^([0-9e.-]) ?}{};
                    $1
                } elsif($type =~ /text|varchar|char/) {
                    s{^'}{};
                    s{^([^']*)' ?}{};
                    $1
                } elsif($type =~ /^jsonb?$/) {
                    s{^'}{};
                    $json->incr_reset;
                    my $data = $json->incr_parse($_);
                    $_ = $json->incr_text;
                    s{^' ?}{};
                    $data
                }
            };
            $fields{$field} = $val;
            $log->infof("Field [%s] is type %s and value [%s]", $field, $type, $val);
        }
        $log->infof("Action %s on %s.%s for %s", $action, $schema, $table, \%fields);
    }
}

