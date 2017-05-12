package Syndication::ESF;

=head1 NAME

Syndication::ESF - Create and update ESF files

=head1 SYNOPSIS

    use Syndication::ESF;

    my $esf = Syndication::ESF->new;

    $esf->parsefile( 'my.esf' );

    $esf->channel( title => 'My channel' );

    $esf->add_item(
        date  => time,
        title => 'new item',
        link  => 'http://example.org/#foo'
    );

    print "Channel: ", $esf->channel( 'title' ), "\n";
    print "Items  : ", scalar @{ $esf->{ items } }, "\n";

    my $output = $esf->as_string;

    $esf->save( 'my.esf' );

=head1 DESCRIPTION

This module is the basic framework for creating and maintaing Epistula Syndication
Format (ESF) files. More information on the format can be found at the Aquarionics
web site: http://www.aquarionics.com/article/name/esf

This module tries to copy the XML::RSS module's interface. All applicable methods
have been copied and should respond in the same manner.

Like in XML::RSS, channel data is accessed through the C<channel()> sub, and item
data is accessed straight out of the items array.

=head1 INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

=cut

use strict;
use warnings;
use Carp;

our $VERSION = '0.13';

# Defines the set of valid fields for a channel and its items
my @channel_fields = qw( title contact link );
my @item_fields    = qw( date title link );

=head1 METHODS

=head2 new()

Creates a new Syndication::ESF object. It currently does not accept any parameters.

=cut

sub new {
    my $class = shift;
    my $self  = {
        channel => {},
        items   => []
    };

    bless $self, $class;

    return $self;
}

=head2 channel(title => $title, contact => $contact, link => $link)

Supplying no parameters will give you a reference to the channel data. Specifying
a field name returns the value of the field. Giving it a hash will update the channel
data with the supplied values.

=cut

sub channel {
    my $self = shift;

    # accessor; if there's only one arg
    if ( @_ == 1 ) {
        return $self->{ channel }->{ $_[ 0 ] };
    }

    # mutator; if there's more than one arg
    elsif ( @_ > 1 ) {
        my %options = @_;

        for ( keys %options ) {
            $self->{ channel }->{ $_ } = $options{ $_ };

            # extract email and name from contact info
            if ( $_ eq 'contact' ) {
                my @contact = split( / /, $options{ $_ }, 2 );
                $contact[ 1 ] =~ s/[\(\)]//g;
                $self->channel(
                    'contact_name'  => $contact[ 1 ],
                    'contact_email' => $contact[ 0 ]
                );
            }
        }
    }

    return $self->{ channel };
}

=head2 contact_name()

shortcut to get the contact name

=cut

sub contact_name {
    my $self = shift;
    return $self->channel( 'contact_name' );
}

=head2 contact_email()

shortcut to get the contact email

=cut

sub contact_email {
    my $self = shift;
    return $self->channel( 'contact_email' );
}

=head2 add_item(date => $date, title => $title, link => $link, mode => $mode)

By default, this will append the new item to the end of the list. Specifying
C<'insert'> for the C<mode> parameter adds it to the front of the list.

=cut

sub add_item {
    my $self    = shift;
    my $options = { @_ };
    my $mode    = $options->{ mode };

    # depending on the mode, add the item to the
    # start or end of the feed
    if ( $mode and $mode eq 'insert' ) {
        unshift( @{ $self->{ items } }, $options );
    }
    else {
        push( @{ $self->{ items } }, $options );
    }

    return $self->{ items };
}

=head2 parse($string)

Parse the supplied raw ESF data.

=cut

sub parse {
    my $self = shift;
    my $data = shift;

    # boolean to indicate if we're parsing the meta data or the items.
    my $metamode = 1;

    foreach my $line ( split /(?:\015\012|\012|\015)/, $data ) {

        # skip to the next line if it's a comment
        next if $line =~ /^#/;

        chomp( $line );

        # if it's a blank line, get out of meta-mode.
        if ( $line eq '' ) {
            $metamode = 0;
            next;
        }

        my @data = split /\t/, $line;

        # depending on what mode we're in, insert the channel, or item data.
        if ( $metamode ) {
            $self->channel( $data[ 0 ] => $data[ 1 ] );
        }
        else {
            push @{ $self->{ items } },
                { map { $item_fields[ $_ ] => $data[ $_ ] }
                    0 .. $#item_fields };
        }
    }
}

=head2 parsefile($filename)

Same as C<parse()>, but takes a filename as input.

=cut

sub parsefile {
    my $self = shift;
    my $file = shift;

    open( my $esf, $file ) or croak "File open error ($file): $!";

    my $data = do { local $/; <$esf>; };

    close( $esf ) or carp( "File close error ($file): $!" );

    $self->parse( $data );
}

=head2 as_string()

Returns the current data stored in the object as a string.

=cut

sub as_string {
    my $self = shift;

    my $data;

    # append channel data
    $data .= "$_\t" . $self->channel( $_ ) . "\n" for @channel_fields;
    $data .= "\n";

    # append item data
    foreach my $item ( @{ $self->{ items } } ) {
        $data .= $item->{ $_ } . "\t" for @item_fields;
        $data =~ s/\t$/\n/;
    }

    return $data;
}

=head2 save($filename)

Saves the value of C<as_string()> to the supplied filename.

=cut

sub save {
    my $self = shift;
    my $file = shift;

    open( my $esf, ">$file" ) or croak "File open error ($file): $!";

    print { $esf } $self->as_string;

    close( $esf ) or carp( "File close error ($file): $!" );
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4

=item * L<XML::RSS>

=back

=cut

1;
