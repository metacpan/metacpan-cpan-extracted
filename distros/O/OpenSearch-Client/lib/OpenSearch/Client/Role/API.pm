# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from the original work are contained in the
# NOTICE file distributed with this work.
#
#-----------------------------------------------------------------------
# OpenSearch::Client
#-----------------------------------------------------------------------
# Copyright 2026 Mark Dootson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


package OpenSearch::Client::Role::API;
$OpenSearch::Client::Role::API::VERSION = '3.007007';
use Moo::Role;
requires 'api_version';
requires 'api';

use Scalar::Util qw(looks_like_number);
use OpenSearch::Client::Util qw(throw);
use namespace::clean;

our %Handler = (
    string  => \&_string,
    time    => \&_string,
    date    => \&_string,
    list    => \&_list,
    boolean => \&_bool,
    enum    => \&_list,
    number  => \&_num,
    int     => \&_num,
    float   => \&_num,
    double  => \&_num,
    'number|string'  => \&_numOrString,
    'boolean|string' => \&_boolOrString,
    'boolean|number' => \&_boolOrNumber,
    
);

#===================================
sub _bool {
#===================================
    my $val = _detect_bool(@_);
    return ( $val && $val ne 'false' ) ? 'true' : 'false';
}

#===================================
sub _detect_bool {
#===================================
    my $val = shift;
    return '' unless defined $val;
    if ( ref $val eq 'SCALAR' ) {
        return 'false' if $$val eq 0;
        return 'true'  if $$val eq 1;
    }
    elsif ( UNIVERSAL::isa( $val, "JSON::PP::Boolean" ) ) {
        return "$val" ? 'true' : 'false';
    }
    return "$val";
}

#===================================
sub _list {
#===================================
    return join ",", map { _detect_bool($_) }    #
        ref $_[0] eq 'ARRAY' ? @{ $_[0] } : $_[0];
}

#===================================
sub _num {
#===================================
    return 0 + $_[0];
}

#===================================
sub _string {
#===================================
    return "$_[0]";
}

#===================================
sub _numOrString {
#===================================
    if (looks_like_number($_[0])) {
        return _num($_[0]);
    }
    return _string($_[0]);
}

#===================================
sub _boolOrString {
#===================================
    return _detect_bool( @_ );
}

#===================================
sub _boolOrNumber {
#===================================
    my $val = _detect_bool(@_);
    return _numOrString($val);
}

#===================================
sub _qs_init {
#===================================
    my $class = shift;
    my $API   = shift;
    for my $spec ( keys %$API ) {
        my $qs = $API->{$spec}{qs};
        for my $param ( keys %$qs ) {
            my $handler = $Handler{ $qs->{$param} }
                or throw( "Internal",
                      "Unknown type <"
                    . $qs->{$param}
                    . "> for param <$param> in API <$spec>" );
            $qs->{$param} = $handler;
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Role::API - Provides common functionality for API implementations

=head1 VERSION

version 3.007007

=head1 MANUAL

Documentation index L<OpenSearch::Client::Manual>

=head1 HISTORY

This distribution is derived from L<Search::Elasticsearch> version 7.714.
All subsequent changes are unique to this distribution.

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt> ( current maintainer )

=head1 CREDITS

L<OpenSearch::Client> is based on L<Search::Elasticsearch> version 7.714
by Enrico Zimuel E<lt>enrico.zimuel@elastic.coE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson ( this distribution )

Copyright (C) 2021 by Elasticsearch BV ( original distribution ) 

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
