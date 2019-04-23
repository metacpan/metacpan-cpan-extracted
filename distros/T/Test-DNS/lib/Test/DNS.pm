package Test::DNS;
# ABSTRACT: Test DNS queries and zone configuration
$Test::DNS::VERSION = '0.203';
use Moose;
use Net::DNS;
use Test::Deep 'cmp_bag';
use parent 'Test::Builder::Module';

use constant {
    'MIN_HASH_ARGS' => 3,
    'MAX_HASH_ARGS' => 4,
};

has 'nameservers' => (
    'is'        => 'ro',
    'isa'       => 'ArrayRef',
    'predicate' => 'has_nameservers',
);

has 'object' => (
    'is'      => 'ro',
    'isa'     => 'Net::DNS::Resolver',
    'lazy'    => 1,
    'builder' => '_build_object',
);

has 'follow_cname' => (
    'is'      => 'ro',
    'isa'     => 'Bool',
    'default' => sub {0},
);

has 'warnings' => (
    'is'      => 'ro',
    'isa'     => 'Bool',
    'default' => sub {1},
);

my $CLASS = __PACKAGE__;

sub BUILD {
    $Test::Builder::Level += 1;
    return;
}

sub _build_object {
    my $self = shift;

    return Net::DNS::Resolver->new(
        # Only pass nameservers if we have nameservers
        ( 'nameservers' => $self->nameservers )x!! $self->has_nameservers,
    );
}

sub _is_hash_format {
    my ( $self, $type, $hashref, $test_name, $extra ) = @_;

    # special hash construct
    # $self, $type, $hashref
    # OR
    # $self, $type, $hashref, $test_name
    return
           @_ >= MIN_HASH_ARGS()
        && @_ <= MAX_HASH_ARGS()
        &&  ref $hashref eq 'HASH'
        && !ref $test_name
        &&  ref \$test_name eq 'SCALAR';
}

sub _handle_record { ## no critic (Subroutines::RequireArgUnpacking);
    my $self = shift;

    $self->_is_hash_format(@_)
        and return $self->_handle_hash_format(@_);

    return $self->is_record(@_);
}

sub _handle_hash_format {
    my ( $self, $type, $hashref, $test_name, $extra ) = @_;

    # $hashref is hashref
    # $test_name isn't a ref
    # \$test_name is a SCALAR ref
    my $all_passed = 1;
    foreach my $domain ( keys %{$hashref} ) {
        my $ips = $hashref->{$domain};
        $self->is_record( $type, $domain, $ips, $test_name )
            or $all_passed = 0;
    }

    return $all_passed;
}

# A -> IP
sub is_a {
    my $self = shift;
    return $self->_handle_record( 'A', @_ );
}

# PTR -> A
sub is_ptr {
    my $self = shift;
    return $self->_handle_record( 'PTR', @_ );
}

# Domain -> NS
sub is_ns {
    my $self = shift;
    return $self->_handle_record( 'NS', @_ );
}

# Domain -> MX
sub is_mx {
    my $self = shift;
    return $self->_handle_record( 'MX', @_ );
}

# Domain -> CNAME
sub is_cname {
    my $self = shift;
    return $self->_handle_record( 'CNAME', @_ );
}

# Domain -> TXT
sub is_txt {
    my $self = shift;
    return $self->_handle_record( 'TXT', @_ );
}

sub _get_method {
    my ( $self, $type ) = @_;
    my %method_by_type = (
        'A'     => 'address',
        'NS'    => 'nsdname',
        'MX'    => 'exchange',
        'PTR'   => 'ptrdname',
        'CNAME' => 'cname',
        'TXT'   => 'txtdata',
    );

    return $method_by_type{$type} || 0;
}

sub _recurse_a_records {
    my ( $self, $results, $rr ) = @_;
    my $res = $self->object;

    if ( $rr->type eq 'CNAME' ) {
        my $cname_method = $self->_get_method('CNAME');
        my $cname        = $rr->$cname_method;
        my $query        = $res->query( $cname, 'A' );

        if ($query) {
            my @records = $query->answer;
            foreach my $record (@records) {
                $self->_recurse_a_records( $results, $record );
            }
        }
    } elsif ( $rr->type eq 'A' ) {
        my $a_method = $self->_get_method('A');
        $results->{ $rr->$a_method } = 1;
    }

    return;
}

sub is_record {
    my ( $self, $type, $input, $expected, $test_name ) = @_;

    my $res       = $self->object;
    my $tb        = $CLASS->builder;
    my $method    = $self->_get_method($type);
    my $query_res = $res->query( $input, $type );
    my $results   = {};

    ref $expected eq 'ARRAY'
        or $expected = [$expected];

    $test_name ||= "[$type] $input -> " . join ', ', @{$expected};

    if (!$query_res) {
        $self->_warn( $type, "'$input' has no query result" );
        $tb->ok( 0, $test_name );
        return;
    }

    my @records = $query_res->answer;

    foreach my $rr (@records) {
        if ( $rr->type ne $type ) {
            if ( $rr->type eq 'CNAME' && $self->follow_cname ) {
                $self->_recurse_a_records( $results, $rr );
            } else {
                $self->_warn( $type, 'got incorrect RR type: ' . $rr->type );
            }
        } else {
            $results->{ $rr->$method } = 1;
        }
    }

    return cmp_bag( [ keys %{$results} ], $expected, $test_name );
}

sub _warn {
    my ( $self, $type, $msg ) = @_;

    $self->warnings
        or return;

    chomp $msg;
    my $tb = $CLASS->builder;
    $tb->diag("!! Warning: [$type] $msg !!");

    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DNS - Test DNS queries and zone configuration

=head1 VERSION

version 0.203

=head1 SYNOPSIS

This module helps you write tests for DNS queries. You could test your domain
configuration in the world or on a specific DNS server, for example.

    use Test::DNS;
    use Test::More tests => 4;

    my $dns = Test::DNS->new();

    $dns->is_ptr( '1.2.3.4' => 'single.ptr.record.com' );
    $dns->is_ptr( '1.2.3.4' => [ 'one.ptr.record.com', 'two.ptr.record.com' ] );
    $dns->is_ns( 'google.com' => [ map "ns$_.google.com", 1 .. 4 ] );
    $dns->is_a( 'ns1.google.com' => '216.239.32.10' );

    ...

=head1 DESCRIPTION

Test::DNS allows you to run tests which translate as DNS queries. It's simple to
use and abstracts all the difficult query checks from you. It has a built-in
tests naming scheme so you don't have to name your tests (as shown in all
the examples) even though it supports the option.

    use Test::DNS;
    use Test::More tests => 1;

    my $dns = Test::DNS->new( nameservers => [ 'my.dns.server' ] );
    $dns->is_ptr( '1.1.1.1' => 'my_new.mail.server' );

That was a complete test script that will fetch the PTR (if there is one), warns
if it's missing one (an option you can remove via the I<warnings> attribute) and
checks against the domain you gave. You could also give for each test an
arrayref of expected values. That's useful if you want to check multiple values.
For example:

    use Test::DNS;
    use Test::More tests => 1;

    my $dns = Test::DNS->new();
    $dns->is_ns( 'my.domain' => [ 'ns1.my.domain', 'ns2.my.domain' ] );
    # or
    $dns->is_ns( 'my.domain' => [ map "ns$_.my.domain", 1 .. 5 ] );

You can set the I<follow_cname> option if your PTR returns a CNAME instead of an
A record and you want to test the A record instead of the CNAME. This happened
to me at least twice and fumbled my tests. I was expecting an A record, but got
a CNAME to an A record. This is obviously legal DNS practices, so using the
I<follow_cname> attribute listed below, the test went with flying colors. This
is a recursive CNAME to A record function so you could handle multiple CNAME
chaining if one has such an odd case.

New in version 0.04 is the option to give a hashref as the testing values (not
including a test name as well), which makes things much easier to test if you
want to run multiple tests and don't want to write multiple lines. This helps
connect L<Test::DNS> with freshly-parsed data (YAML/JSON/XML/etc.).

    use Test::DNS;
    use YAML 'LoadFile';
    use Test::More tests => 2;

    my $dns = Test::DNS->new();
    # running two DNS tests in one command!
    $dns->is_ns( {
        'first.domain'  => [ map { "ns$_.first.domain"  } 1 .. 4 ],
        'second.domain' => [ map { "ns$_.second.domain" } 5, 6   ],
    } );

    my $tests = LoadFile('tests.yaml');
    $dns->is_a( $tests, delete $tests->{'name'} ); # $tests is a hashref

=head1 EXPORT

This module is completely Object Oriented, nothing is exported.

=head1 ATTRIBUTES

=head2 nameservers($arrayref)

Same as in L<Net::DNS>. Sets the nameservers, accepts an arrayref.

    my $dns = Test::DNS->new(
        'nameservers' => [ 'IP1', 'DOMAIN' ],
    );

=head2 warnings($boolean)

Do you want to output warnings from the module (in valid TAP), such as when a
record doesn't a query result or incorrect types?

This helps avoid common misconfigurations. You should probably keep it, but if
it bugs you, you can stop it using:

    my $dns = Test::DNS->new(
        'warnings' => 0,
    );

Default: 1 (on).

=head2 follow_cname($boolean)

When fetching an A record of a domain, it may resolve to a CNAME instead of an A
record. That would result in a false-negative of sorts, in which you say "well,
yes, I meant the A record the CNAME record points to" but L<Test::DNS> doesn't
know that.

If you want want Test::DNS to follow every CNAME recursively till it reaches the
actual A record and compare B<that> A record, use this option.

    my $dns = Test::DNS->new(
        'follow_cname' => 1,
    );

Default: 0 (off).

=head1 SUBROUTINES/METHODS

=head2 is_a( $domain, $ips, [$test_name] )

Check the A record resolving of domain or subdomain.

C<$ip> can be an arrayref.

C<$test_name> is not mandatory.

    $dns->is_a( 'domain' => 'IP' );

    $dns->is_a( 'domain', [ 'IP1', 'IP2' ] );

Returns false if the assertion fails.

=head2 is_ns( $domain, $ips, [$test_name] )

Check the NS record resolving of a domain or subdomain.

C<$ip> can be an arrayref.

C<$test_name> is not mandatory.

    $dns->is_ns( 'domain' => 'IP' );

    $dns->is_ns( 'domain', [ 'IP1', 'IP2' ] );

Returns false if the assertion fails.

=head2 is_ptr( $ip, $domains, [$test_name] )

Check the PTR records of an IP.

C<$domains> can be an arrayref.

C<$test_name> is not mandatory.

    $dns->is_ptr( 'IP' => 'ptr.records.domain' );

    $dns->is_ptr( 'IP', [ 'first.ptr.domain', 'second.ptr.domain' ] );

Returns false if the assertion fails.

=head2 is_mx( $domain, $domains, [$test_name] )

Check the MX records of a domain.

C<$domains> can be an arrayref.

C<$test_name> is not mandatory.

    $dns->is_mx( 'domain' => 'mailer.domain' );

    $dns->is_ptr( 'domain', [ 'mailer1.domain', 'mailer2.domain' ] );

Returns false if the assertion fails.

=head2 is_cname( $domain, $domains, [$test_name] )

Check the CNAME records of a domain.

C<$domains> can be an arrayref.

C<$test_name> is not mandatory.

    $dns->is_cname( 'domain' => 'sub.domain' );

    $dns->is_cname( 'domain', [ 'sub1.domain', 'sub2.domain' ] );

Returns false if the assertion fails.

=head2 is_txt( $domain, $txt, [$test_name] )

Check the TXT records of a domain.

C<$txt> can be an arrayref.

C<$test_name> is not mandatory.

    $dns->is_txt( 'domain' => 'v=spf1 -all' );

    $dns->is_txt( 'domain', [ 'sub1.domain', 'sub2.domain' ] );

Returns false if the assertion fails.

=head2 is_record( $type, $input, $expected, [$test_name] )

The general function all the other is_* functions run.

C<$type> is the record type (CNAME, A, NS, PTR, MX, etc.).

C<$input> is the domain or IP you're testing.

C<$expected> can be an arrayref.

C<$test_name> is not mandatory.

    $dns->is_record( 'CNAME', 'domain', 'sub.domain', 'test_name' );

Returns false if the assertion fails.

=head2 BUILD

L<Moose> builder method. Do not call it or override it. :)

=head1 HASH FORMAT

The hash format option (since version 0.04) allows you to run the tests using a
single hashref with an optional parameter for the test_name. The count is no
longer 1 (as it is with single tests), but each key/value pair represents a test
case.

    # these are 2 tests
    $dns->is_ns( {
        'first.domain'  => [ map { "ns$_.first.domain"  } 1 .. 4 ],
        'second.domain' => [ map { "ns$_.second.domain" } 5, 6   ],
    } );

    # number of tests: keys %{$tests}, test name: $tests->{'name'}
    $dns->is_a( $tests, delete $tests->{'name'} ); # $tests is a hashref

=head1 DEPENDENCIES

L<Moose>

L<Net::DNS>

L<Test::Deep>

=head1 AUTHOR

Sawyer X, C<< <xsawyerx at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-dns at rt.cpan.org>, or
through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-DNS>. I will be notified,
and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::DNS

You can also look for information at:

=over 4

=item * Github

L<http://github.com/xsawyerx/test-dns>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-DNS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-DNS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-DNS>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-DNS/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Sawyer X.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
