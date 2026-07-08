# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from that work are contained in the NOTICE
# file distributed with this work.
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

package OpenSearch::Client::Error;
$OpenSearch::Client::Error::VERSION = '3.007006';
our $DEBUG = 0;

@OpenSearch::Client::Error::Internal::ISA     = __PACKAGE__;
@OpenSearch::Client::Error::Param::ISA        = __PACKAGE__;
@OpenSearch::Client::Error::NoNodes::ISA      = __PACKAGE__;
@OpenSearch::Client::Error::Unauthorized::ISA = __PACKAGE__;
@OpenSearch::Client::Error::Forbidden::ISA    = __PACKAGE__;
@OpenSearch::Client::Error::Illegal::ISA      = __PACKAGE__;
@OpenSearch::Client::Error::Request::ISA      = __PACKAGE__;
@OpenSearch::Client::Error::Timeout::ISA      = __PACKAGE__;
@OpenSearch::Client::Error::Cxn::ISA          = __PACKAGE__;
@OpenSearch::Client::Error::Serializer::ISA   = __PACKAGE__;

@OpenSearch::Client::Error::Conflict::ISA
    = ( 'OpenSearch::Client::Error::Request', __PACKAGE__ );

@OpenSearch::Client::Error::Missing::ISA
    = ( 'OpenSearch::Client::Error::Request', __PACKAGE__ );

@OpenSearch::Client::Error::RequestTimeout::ISA
    = ( 'OpenSearch::Client::Error::Request', __PACKAGE__ );

@OpenSearch::Client::Error::ContentLength::ISA
    = ( __PACKAGE__, 'OpenSearch::Client::Error::Request' );

@OpenSearch::Client::Error::SSL::ISA
    = ( __PACKAGE__, 'OpenSearch::Client::Error::Cxn' );

@OpenSearch::Client::Error::BadGateway::ISA
    = ( 'OpenSearch::Client::Error::Cxn', __PACKAGE__ );

@OpenSearch::Client::Error::Unavailable::ISA
    = ( 'OpenSearch::Client::Error::Cxn', __PACKAGE__ );

@OpenSearch::Client::Error::GatewayTimeout::ISA
    = ( 'OpenSearch::Client::Error::Cxn', __PACKAGE__ );

use overload (
    '""'  => '_stringify',
    'cmp' => '_compare',
);

use Data::Dumper();

#===================================
sub new {
#===================================
    my ( $class, $type, $msg, $vars, $caller ) = @_;
    return $type if ref $type;
    $caller ||= 0;

    my $error_class = 'OpenSearch::Client::Error::' . $type;
    $msg = 'Unknown error' unless defined $msg;

    local $DEBUG = 2 if $type eq 'Internal';

    my $stack = $class->_stack;

    my $self = bless {
        type  => $type,
        text  => $msg,
        vars  => $vars,
        stack => $stack,
    }, $error_class;

    return $self;
}

#===================================
sub is {
#===================================
    my $self = shift;
    for (@_) {
        return 1 if $self->isa("OpenSearch::Client::Error::$_");
    }
    return 0;
}

#===================================
sub _stringify {
#===================================
    my $self = shift;
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = !!$DEBUG;

    unless ( $self->{msg} ) {
        my $stack  = $self->{stack};
        my $caller = $stack->[0];
        $self->{msg} = sprintf( "[%s] ** %s, called from sub %s at %s line %d.",
            $self->{type}, $self->{text}, @{$caller}[ 3, 1, 2 ] );

        if ( $self->{vars} ) {
            $self->{msg} .= sprintf( " With vars: %s\n",
                Data::Dumper::Dumper $self->{vars} );
        }

        if ( @$stack > 1 ) {
            $self->{msg}
                .= sprintf( "Stacktrace:\n%s\n", $self->stacktrace($stack) );
        }
    }
    return $self->{msg};

}

#===================================
sub _compare {
#===================================
    my ( $self, $other, $swap ) = @_;
    $self .= '';
    ( $self, $other ) = ( $other, $self ) if $swap;
    return $self cmp $other;
}

#===================================
sub _stack {
#===================================
    my $self = shift;
    my $caller = shift() || 2;

    my @stack;
    while ( my @caller = caller( ++$caller ) ) {
        next if $caller[0] eq 'Try::Tiny';

        if ( $caller[3] =~ /^(.+)::__ANON__\[(.+):(\d+)\]$/ ) {
            @caller = ( $1, $2, $3, '(ANON)' );
        }
        elsif ( $caller[1] =~ /^\(eval \d+\)/ ) {
            $caller[3] = "modified(" . $caller[3] . ")";
        }

        next
            if $caller[0] =~ /^OpenSearch::Client/
            and ( $DEBUG < 2 or $caller[3] eq 'Try::Tiny::try' );
        push @stack, [ @caller[ 0, 1, 2, 3 ] ];
        last unless $DEBUG > 1;
    }
    return \@stack;
}

#===================================
sub stacktrace {
#===================================
    my $self = shift;
    my $stack = shift || $self->_stack();

    my $o = sprintf "%s\n%-4s %-50s %-5s %s\n%s\n",
        '-' x 80, '#', 'Package', 'Line', 'Sub-routine', '-' x 80;

    my $i = 1;
    for (@$stack) {
        $o .= sprintf "%-4d %-50s %4d  %s\n", $i++, @{$_}[ 0, 2, 3 ];
    }

    return $o .= ( '-' x 80 ) . "\n";
}

#===================================
sub TO_JSON {
#===================================
    my $self = shift;
    return $self->_stringify;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Error - Errors thrown by OpenSearch::Client

=head1 VERSION

version 3.007006

=head1 DESCRIPTION

Errors thrown by OpenSearch::Client are error objects, which can include
a stack trace and information to help debug problems. An error object
consists of the following:

    {
        type  => $type,              # eg Missing
        text  => 'Error message',
        vars  => {...},              # vars which may help to explain the error
        stack => [...],              # a stack trace
    }

The C<$OpenSearch::Client::Error::DEBUG> variable can be set to C<1> or C<2>
to increase the verbosity of errors.

Error objects stringify to a human readable error message when used in text
context (for example: C<print 'Oh no! '.$error>).  They also support the C<TO_JSON>
method to support conversion to JSON when L<JSON/convert_blessed> is enabled.

=head1 ERROR CLASSES

The following error classes are defined:

=over

=item * C<OpenSearch::Client::Error::Param>

A bad parameter has been passed to a method.

=item * C<OpenSearch::Client::Error::Request>

There was some generic error performing your request in OpenSearch.
This error is triggered by HTTP status codes C<400> and C<500>. This class
has the following sub-classes:

=over

=item * C<OpenSearch::Client::Error::Unauthorized>

Invalid (or no) username/password provided as C<userinfo> for a password
protected service. These errors are triggered by the C<401> HTTP status code.

=item * C<OpenSearch::Client::Error::Missing>

A resource that you requested was not found.  These errors are triggered
by the C<404> HTTP status code.

=item * C<OpenSearch::Error::Conflict>

Your request could not be performed because of some conflict.  For instance,
if you try to delete a document with a particular version number, and the
document has already changed, it will throw a C<Conflict> error.  If it can,
it will include the C<current_version> in the error vars. This error
is triggered by the C<409> HTTP status code.

=item * C<OpenSearch::Client::Error::ContentLength>

The request body was longer than the
L<max_content_length|OpenSearch::Client::Role::Cxn/max_content_length>.

=item * C<OpenSearch::Client::Error::RequestTimeout>

The request took longer than the specified C<timeout>.  Currently only
applies to the
L<cluster_health|OpenSearch::Client::Core::6_0::Direct::Cluster/cluster_health()>
request.

=back

=item * C<OpenSearch::Client::Error::Timeout>

The request timed out.

=item * C<OpenSearch::Client::Error::Cxn>

There was an error connecting to a node in the cluster.  This error
indicates node failure and will be retried on another node.
This error has the following sub-classes:

=over

=item * C<OpenSearch::Client::Error::Unavailable>

The current node is unable to handle your request at the moment. Your
request will be retried on another node.  This error is triggered by
the C<503> HTTP status code.

=item * C<OpenSearch::Client::Error::BadGateway>

A proxy between the client and OpenSearch is unable to connect to OpenSearch.
This error is triggered by the C<502> HTTP status code.

=item * C<OpenSearch::Client::Error::GatewayTimeout>

A proxy between the client and OpenSearch is unable to connect to OpenSearch
within its own timeout. This error is triggered by the C<504> HTTP status code.

=item * C<OpenSearch::Client::Error::SSL>

There was a problem validating the SSL certificate.  Not all
backends support this error type.

=back

=item * C<OpenSearch::Client::Error::Forbidden>

Either the cluster was unable to process the request because it is currently
blocking, eg there are not enough master nodes to form a cluster, or
because the authenticated user is trying to perform an unauthorized
action. This error is triggered by the C<403> HTTP status code.

=item * C<OpenSearch::Client::Error::Illegal>

You have attempted to perform an illegal operation.
For instance, you attempted to use a Scroll helper in a different process
after forking.

=item * C<OpenSearch::Client::Error::Serializer>

There was an error serializing a variable or deserializing a string.

=item * C<OpenSearch::Error::Internal>

An internal error occurred - please report this as a bug in
this module.

=back

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

