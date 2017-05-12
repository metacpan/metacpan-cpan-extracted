package SWISH::Prog::Indexer;
use strict;
use warnings;
use base qw( SWISH::Prog::Class );
use Scalar::Util qw( blessed );
use Carp;
use Data::Dump qw( dump );
use SWISH::Prog::Config;

our $VERSION = '0.75';

__PACKAGE__->mk_accessors(
    qw( invindex config count clobber flush started test_mode ));

=pod

=head1 NAME

SWISH::Prog::Indexer - base indexer class

=head1 SYNOPSIS

 use SWISH::Prog::Indexer;
 my $indexer = SWISH::Prog::Indexer->new(
        invindex    => SWISH::Prog::InvIndex->new,
        config      => SWISH::Prog::Config->new,
        count       => 0,
        clobber     => 1,
        flush       => 10000,
        started     => time()
 );
 $indexer->start;
 for my $doc (@list_of_docs) {
    $indexer->process($doc);
 }
 $indexer->finish;
 
=head1 DESCRIPTION

SWISH::Prog::Indexer is a base class implementing the simplest of indexing
APIs. It is intended to be subclassed, along with InvIndex, for each
IR backend library.

=head1 METHODS

=head2 new( I<params> )

Constructor. See the SYNOPSIS for default options.

I<params> may include the following keys, each of which is also an
accessor method:

=over

=item clobber

Overrite any existing InvIndex.

=item config

A SWISH::Prog::Config object or file name.

=item flush

The number of indexed docs at which in-memory changes 
should be written to disk.

=item invindex

A SWISH::Prog::InvIndex object.

=item test_mode

Dry run mode, just prints info on stderr but does not
build index.

=back

=head2 init

Override base method to initialize object.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if (    exists $self->{config}
        and defined $self->{config}
        and !blessed( $self->{config} )
        and $self->{config} !~ m/<swish>|\.xml$/ )
    {
        $self->{config}
            = $self->verify_isa_swish_prog_config( $self->{config} );
    }
    $self->{config} ||= SWISH::Prog::Config->new;
    return $self;
}

=head2 start

Opens the invindex() object and sets the started() time to time().

Subclasses should always call SUPER::start() if they override
this method since it provides sanity checking on the InvIndex.

=cut

sub start {
    my $self = shift;
    if ( !defined $self->invindex ) {
        croak "Missing invindex object";
    }
    my $invindex = $self->invindex;
    if (   !blessed($invindex)
        or !$invindex->can('open') )
    {
        croak "Invalid invindex $invindex: "
            . "either not blessed object or does not implement 'open' method";
    }

    # sanity check. if this is an existing index
    # does our Format match what already exists?
    my $meta;
    eval { $meta = $invindex->meta; };
    if ( !$@ ) {
        my $format = $meta->Index->{Format};
        if ( !$self->isa( 'SWISH::Prog::' . $format . '::Indexer' ) ) {
            croak "Fatal error: found existing invindex '$invindex' "
                . "with format $format.\n"
                . "You tried to open it with "
                . ref($self);
        }

    }
    $self->invindex->open;
    $self->{started} = time();
    $self->invindex->path->file('swish_last_start')->touch();
}

=head2 process( I<doc> )

I<doc> should be a SWISH::Prog::Doc-derived object.

process() should implement whatever the particular IR library
API requires.

=cut

sub process {
    my $self = shift;
    my $doc  = shift;
    unless ( $doc && blessed($doc) && $doc->isa('SWISH::Prog::Doc') ) {
        croak "SWISH::Prog::Doc object required";
    }

    $self->start unless $self->started;

    $self->{count}++;

    return $doc;
}

=head2 finish

Closes the invindex().

=cut

sub finish {
    my $self = shift;
    $self->invindex->close;
}

=head2 count

Returns the number of documents processed.

=head2 started

The time at which the Indexer object was created. Returns a Unix epoch
integer.

=cut

# NOTE in _verify_swish3_config() below,
# if config is already in swish3 format, must
# override param value with SWISH::Prog::Config object
# after adding to SWISH::3::Config object so that the
# aggregator using this Indexer is happy.

sub _verify_swish3_config {
    my $self = shift;

    if ( !exists $self->{config} ) {
        return;
    }

    #carp dump $self->{config};

    # isa object
    if ( blessed( $self->{config} ) ) {
        $self->{config}
            = $self->verify_isa_swish_prog_config( $self->{config} );
        my $swish_3_config = $self->{config}->ver2_to_ver3();
        $self->{s3}->config->add($swish_3_config);
    }

    # xml string
    elsif ( $self->{config} =~ m/<swish>|[\n\r]/ ) {
        $self->{s3}->config->add( $self->{config} );
        $self->{config} = SWISH::Prog::Config->new();
    }

    # file
    elsif ( -r $self->{config} ) {

        # swish3 format
        if ( $self->{config} =~ m/\.xml/ ) {
            $self->{s3}->config->add( $self->{config} );
            $self->{config} = SWISH::Prog::Config->new();
        }

        # swish2 format
        else {
            $self->{config}
                = $self->verify_isa_swish_prog_config( $self->{config} );
            my $swish_3_config = $self->{config}->ver2_to_ver3();
            $self->{s3}->config->add($swish_3_config);
        }

    }

    # no support
    else {
        croak
            "Unsupported config format (not a XML string, filename or SWISH::Prog::Config object): $self->{config}";
    }

    return $self->{config};
}
1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
