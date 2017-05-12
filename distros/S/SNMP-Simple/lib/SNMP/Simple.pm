package SNMP::Simple;
use strict;
use warnings;

use Carp;

=head1 NAME

SNMP::Simple - shortcuts for when using SNMP

=cut

our $VERSION = 0.02;

use SNMP;

$SNMP::use_enums = 1;    # can be overridden with new(UseEnums=>0)

=head1 SYNOPSIS

    use SNMP::Simple;

    $name     = $s->get('sysName');       # same as sysName.0
    $location = $s->get('sysLocation');

    @array    = $s->get_list('hrPrinterStatus');
    $arrayref = $s->get_list('hrPrinterStatus');

    @list_of_lists = $s->get_table(
        qw(
            prtConsoleOnTime
            prtConsoleColor
            prtConsoleDescription
            )
    );

    @list_of_hashes = $s->get_named_table(
        name   => 'prtInputDescription',
        media  => 'prtInputMediaName',
        status => 'prtInputStatus',
        level  => 'prtInputCurrentLevel',
        max    => 'prtInputMaxCapacity',
    );

=head1 DESCRIPTION

This module provides shortcuts when performing repetitive information-retrieval
tasks with L<SNMP>.

Instead of this:

    use SNMP;
    $vars = new SNMP::VarList( ['prtConsoleOnTime'], ['prtConsoleColor'],
        ['prtConsoleDescription'], );
    my ( $light_status, $light_color, $light_desc ) = $s->getnext($vars);
    die $s->{ErrorStr} if $s->{ErrorStr};
    while ( !$s->{ErrorStr} and $$vars[0]->tag eq "prtConsoleOnTime" ) {
        push @{ $data{lights} },
            {
            status => ( $light_status ? 0 : 1 ),
            color       => SNMP::mapEnum( $$vars[1]->tag, $light_color ),
            description => $light_desc,
            };
        ( $light_status, $light_color, $light_desc ) = $s->getnext($vars);
    }

...you can do this:

    use SNMP::Simple;
    $data{lights} = $s->get_named_table(
        status => 'prtConsoleOnTime',
        color  => 'prtConsoleColor',
        name   => 'prtConsoleDescription',
    );

=head2 SNMP Beginners, read me first!

Please, please, B<please> do not use this module as a starting point for
working with SNMP and Perl. Look elsewhere for starting resources:

=over 4

=item * The L<SNMP> module

=item * The Net-SNMP web site (L<http://www.net-snmp.org/>) and tutorial (L<http://www.net-snmp.org/tutorial-5/>)

=item * Appendix E of Perl for System Administration (L<http://www.amazon.com/exec/obidos/tg/detail/-/1565926099>) by David N. Blank-Edelman

=back

=head2 SNMP Advanced and Intermediate users, read me first!

I'll admit this is a complete slaughtering of SNMP, but my goals were precise.
If you think SNMP::Simple could be refined in any way, feel free to send me
suggestions/fixes/patches.

=cut

=head1 METHODS

=head2 new( @args )

Creates a new SNMP::Simple object. Arguments given are passed directly to
C<SNMP::Session-E<gt>new>. See L<SNMP/"SNMP::Session"> for details.

Example:

    use SNMP::Simple
    
    my $s = SNMP::Simple->new(
        DestHost  => 'host.example.com',
        Community => 'public',
        Version   => 1,
    ) or die "couldn't create session";
    
    ...

=cut

sub new {
    my ( $class, @args ) = @_;
    my $session = SNMP::Session->new(@args)
        or croak "Couldn't create session";
    bless \$session, $class;
}

=head2 get( $oid )

Gets the named variable and returns its value. If no value is returned,
C<get()> will try to retrieve a list named C<$name> and return its first vlaue.
Thus, for convenience, 

    $s->get('sysDescr')

..should be the same as:

    $s->get('sysDescr.0')

Numbered OIDs are fine, too, with or without a leading dot:

    $s->get('1.3.6.1.2.1.1.1.0')

C<SNMP::mapEnum()> is automatically used on the result.

=cut

sub get {
    my ( $self, $name ) = @_;
    my $result = $$self->get($name) || ( $self->get_list($name) )[0];
    my $enum = SNMP::mapEnum( $name, $result );
    return defined $enum ? $enum : $result;
}

=head2 get_list( $oid )

Returns leaves of the given OID.

If called in array context, returns an array. If called in scalar context,
returns an array reference.

=cut

sub get_list {
    my ( $self, $oid ) = @_;
    my @table = $self->get_table($oid);
    my @output = map { $_->[0] } @table;
    return wantarray ? @output : \@output;
}

=head2 get_table( @oids )

Given a list of OIDs, this will return a list of lists of all of the values of
the table.

For example, to get a list of all known network interfaces on a machine and
their status:

    $s->get_table('ifDescr', 'ifOperStatus')

Would return something like the following:

    [ 'lo',   'up'   ], 
    [ 'eth0', 'down' ], 
    [ 'eth1', 'up'   ],
    [ 'sit0', 'down' ]

If called in array context, returns an array (of arrays). If called in scalar
context, returns an array reference.

=cut

sub get_table {
    my ( $self, @oids ) = @_;
    my @output = ();

    # build our varlist, the fun VarList way
    my $vars = new SNMP::VarList( map { [$_] } @oids );

    # get our initial results, assume that we should be able to get at least
    # *one* row back
    my @results = $$self->getnext($vars);
    croak $$self->{ErrorStr} if $$self->{ErrorStr};

    # dNb's recipe for iteration: make sure that there's no error and that the
    # OID name of the first cell is actually what we want
    while ( !$$self->{ErrorStr} and $$vars[0]->tag eq $oids[0] ) {
        push @output, [@results];
        @results = $$self->getnext($vars);
    }

    return wantarray ? @output : \@output;
}

=head2 get_named_table( %oids_by_alias )

Like L<"get_table">, but lets you rename ugly OID names on the fly.  To get
a list of all known network interfaces on a machine and their status:

    $s->get_table( name => 'ifDescr', status => 'ifOperStatus' )

Would return something like the following:

        {   
            status => 'up',
            name   => 'lo'
        },
        {
            status => 'down',
            name   => 'eth0'
        },
        {
            status => 'up',
            name   => 'eth1'
        },
        {
            status => 'down',
            name   => 'sit0'
        }

If called in array context, returns an array (of hashes). If called in scalar
context, returns an array reference.

=cut

sub get_named_table {
    my $self        = shift;
    my %oid_to_name = reverse @_;
    my @oids        = keys %oid_to_name;

    # remap table so it's a list of hashes instead of a list of lists
    my @table = $self->get_table( keys %oid_to_name );
    my @output;
    foreach my $row (@table) {
        my %data = ();
        for ( my $i = 0; $i < @oids; $i++ ) {
            $data{ $oid_to_name{ $oids[$i] } } = $row->[$i];
        }
        push @output, \%data;
    }

    return wantarray ? @output : \@output;
}

=head1 EXAMPLES

A sample script F<examples/printerstats.pl> is included with this distribution.

=head1 SEE ALSO

L<SNMP>

=head1 AUTHOR

Ian Langworth, C<< <ian@cpan.org> >>

=head1 BUGS

=over 4

=item * There are no real tests.

=item * I haven't tested this with v3.

=back

Please report any bugs or feature requests to
C<bug-snmp-simple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ian Langworth, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
