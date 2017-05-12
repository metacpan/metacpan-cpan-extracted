package SVN::Dump;

use strict;
use warnings;
use Carp;

use SVN::Dump::Reader;

our $VERSION = '0.06';

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {}, $class;

    # FIXME - croak() if incompatible options

    # we have a reader
    if ( exists $args->{fh} || exists $args->{file} ) {
        my ( $fh, $file ) = delete @{$args}{qw( fh file )};
        if ( !$fh ) {
            open $fh, $file or croak "Can't open $file: $!";
        }
        $self->{reader} = SVN::Dump::Reader->new( $fh, $args );
    }
    # we don't have a reader
    else {
        if( exists $args->{version} ) {
            $self->{format} = SVN::Dump::Record->new();
            $self->{format}->set_header(
                'SVN-fs-dump-format-version' => $args->{version} );
        }
        if( exists $args->{uuid} ) {
            $self->{uuid} = SVN::Dump::Record->new();
            $self->{uuid}->set_header( 'UUID' => $args->{uuid} );
        }
    }

    return $self;
}

sub next_record {
    my ($self) = @_;
    my $record;

RECORD: {
        $record = $self->{reader}->read_record();
        return unless $record;

        # keep the first records in the dump itself
        my $type = $record->type();
        if ( $type =~ /\A(?:format|uuid)\z/ ) {
            $self->{$type} = $record;
        }
    }

    return $record;
}

sub version {
    my ($self) = @_;
    return $self->{format}
        ? $self->{format}->get_header('SVN-fs-dump-format-version')
        : '';
}
*format = \&version;

sub uuid {
    my ($self) = @_;
    return $self->{uuid} ? $self->{uuid}->get_header('UUID') : '';
}

sub as_string {
    return join '', map { $_[0]->{$_}->as_string() } qw( format uuid );
}

1;

__END__

=head1 NAME

SVN::Dump - A Perl interface to Subversion dumps

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use warnings;
    use SVN::Dump;
    
    my $file = shift;
    my $dump = SVN::Dump->new( { file => $file } );
    
    # compute some stats
    my %type;
    my %kind;
    while ( my $record = $dump->next_record() ) {
        $type{ $record->type() }++;
        $kind{ $record->get_header('Node-action') }++
            if $record->type() eq 'node';
    }
    
    # print the results
    print "Statistics for dump $file:\n",
          "  version:   ", $dump->version(), "\n",
          "  uuid:      ", $dump->uuid(), "\n",
          "  revisions: ", $type{revision}, "\n",
          "  nodes:     ", $type{node}, "\n";
    print map { sprintf "  - %-7s: %d\n", $_, $kind{$_} } sort keys %kind;
    
=head1 DESCRIPTION

An SVN::Dump object represents a Subversion dump.

This module follow the semantics used in the reference document
(the file F<notes/fs_dumprestore.txt> in the Subversion source tree):

=over 4

=item *

A dump is a collection of records (L<SVN::Dump::Record> objects).

=item *

A record is composed of a set of headers (a L<SVN::Dump::Headers> object),
a set of properties (a L<SVN::Dump::Property> object) and an optional
bloc of text (a L<SVN::Dump::Text> object).

=item *

Some special records (C<delete> records with a C<Node-kind> header)
recursively contain included records.

=back

Each class has a C<as_string()> method that prints its content
in the dump format.

The most basic thing you can do with SVN::Dump is simply copy
a dump:

    use SVN::Dump;

    my $dump = SVN::Dump->new( 'mydump.svn' );
    print $dump->as_string(); # only print the dump header

    while( $rec = $dump->next_record() ) {
        print $rec->as_string();
    }

After the operation, the resulting dump should be identical to the
original dump.

=head1 METHODS

SVN::Dump provides the following methods:

=over 4

=item new( \%args )

Return a new SVN::Dump object.

The argument list is a hash reference.

If the SVN::Dump object will read information from a file,
the arguments C<file> is used (as usal, C<-> means C<STDIN>);
if the dump is read from a filehandle, C<fh> is used.

Extra options will be passed to the L<SVN::Dump::Reader> object
that is created.

If the SVN::Dump isn't used to read information, the parameters
C<version> and C<uuid> can be used to initialise the values
of the C<SVN-fs-dump-format-version> and C<UUID> headers.

=item next_record()

Return the next record read from the dump.
This is a L<SVN::Dump::Record> object.

=item version()

=item format()

Return the dump format version, if the version record has already been read,
or if it was given in the constructor.

=item uuid()

Return the dump UUID, if there is an UUID record and it has been read,
or if it was given in the constructor.

=item as_string()

Return a string representation of the dump specific blocks
(the C<format> and C<uuid> blocks only).

=back

=head1 SEE ALSO

L<SVN::Dump::Reader>, L<SVN::Dump::Record>.

The reference document for Subversion dumpfiles is at:
L<http://svn.apache.org/repos/asf/subversion/trunk/notes/dump-load-format.txt>

=head1 COPYRIGHT

Copyright 2006-2013 Philippe Bruhat (BooK), All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
