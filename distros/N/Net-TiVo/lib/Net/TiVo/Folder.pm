# $Id: Folder.pm 57 2007-01-12 19:26:09Z boumenot $
# Author: Christopher Boumenot <boumenot@gmail.com>
######################################################################
#
# Copyright 2006-2007 by Christopher Boumenot.  This program is free 
# software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
#
######################################################################

package Net::TiVo::Folder;

use strict;
use warnings;

use Text::Wrap;
use Log::Log4perl qw(:easy get_logger);

# Should be read as a poor man's XPath
our %DEFAULT_ATTRIBUTES_XPATH = (
    content_type => [qw(Details ContentType)],
    format       => [qw(Details SourceFormat)],
    change_date  => [qw(Details LastChangeDate)],
    name         => [qw(Details Title)],
    total_items  => [qw(Details TotalItems)],
    # Is this the same thing as total_items()?
    item_count   => [qw(ItemCount)],
    # What value is this?
    item_start   => [qw(ItemStart)],
    global_sort  => [qw(GlobalSort)],
    sort_order   => [qw(SortOrder)],
    # Due to the way folders are created it is difficult
    # to get the url of the folder.  I could add it easily
    # enough, but it would be a hack, and I'm not sure 
    # that you really need the url of the folder.  I need
    # to fix the code.
    #url
);

__PACKAGE__->make_accessor($_) for keys %DEFAULT_ATTRIBUTES_XPATH;
__PACKAGE__->make_accessor($_) for qw(size);
__PACKAGE__->make_array_accessor($_) for qw(shows);

sub TIVO_MIME_TYPES { qw(video/x-tivo-mpeg video/x-tivo-raw-pes video/x-tivo-raw-tts) }

sub new {
    my ($class, %options) = @_;
    
    unless ($options{xmlref}) {
        die __PACKAGE__ . ": Mandatory param xmlref missing\n";
    }

    my $self = {
        %options,
    };

    bless $self, $class;

    for my $attr (keys %DEFAULT_ATTRIBUTES_XPATH) {
        my $value = __PACKAGE__->walk_hash_ref($options{xmlref}, $DEFAULT_ATTRIBUTES_XPATH{$attr});
        $self->$attr($value);
    }

    $self->change_date(hex($self->change_date()));

#    DEBUG(sub { Data::Dumper::Dumper($options{xmlref}) });

    my ($size, @shows);
    for my $show (@{$options{xmlref}->{Item}}) {
        if (grep {$show->{Links}->{Content}->{ContentType} eq $_} TIVO_MIME_TYPES) {
            push @shows, Net::TiVo::Show->new(xmlref => $show);
            INFO("added the show " . $shows[-1]->name());
            $size += $shows[-1]->size();
        } 
    }

    $self->size($size);
    $self->shows(\@shows);
    
    return $self;
}

sub _commify {
    my ($self, $num) = @_;
    $num = reverse $num;
    $num =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1,>g;
    $num = reverse $num;
    return $num;
}

sub as_string {
    my $self = shift;

    $Text::Wrap::columns = 72;

    my @a;
    push @a, $self->name();
    push @a, sprintf("%d %s", $self->total_items(), (($self->total_items() > 1) ? "episodes" : "episode"));
    push @a, sprintf("%s bytes", $self->_commify($self->size()));
    my $s = wrap("", "      ", join(", ", @a));
    return $s;
}

# cmb - taken from the excellent Net::Amazon!
sub make_accessor {
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
    *{"$package\\::$name"} = sub {
        my(\$self, \$value) = \@_;

        if(defined \$value) {
            \$self->{$name} = \$value;
        }
        if(exists \$self->{$name}) {
            return (\$self->{$name});
        } else {
            return "";
        }
    }
EOT
    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

# cmb - taken from the excellent Net::Amazon!
sub make_array_accessor {
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
    *{"$package\\::$name"} = sub {
        my(\$self, \$nameref) = \@_;
        if(defined \$nameref) {
            if(ref \$nameref eq "ARRAY") {
                \$self->{$name} = \$nameref;
            } else {
                \$self->{$name} = [\$nameref];
            }
        }
        # Return a list
        if(exists \$self->{$name} and
           ref \$self->{$name} eq "ARRAY") {
            return \@{\$self->{$name}};
        }

        return undef;
    }
EOT

    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

sub walk_hash_ref {
    my ($package, $href, $aref) = @_;

    return $href if scalar(@$aref) == 0;

    my @a;
    push @a, $_ for @$aref;

    my $tail = pop @a;
    my $ref = $href;

    for my $part (@a) {
        $ref = $ref->{$part};
    }
    
    return $ref->{$tail};
}

1;

__END__

=head1 NAME

Net::TiVo::Folder - Class that wraps the XML description that defines a TiVo
folder.

=head1 SYNOPSIS

    use Net::TiVo;
	
    my $tivo = Net::TiVo->new(
        host => '192.168.1.25', 
        mac  => 'MEDIA_ACCESS_KEY'
    );
        
    for my $folder ($tivo->folders()) {
        print $folder->as_string(), "\n";
    }

=head1 DESCRPTION

C<Net::TiVo::Folder> provides an object-oriented interface to an XML
description of a TiVo show.  It provides the necessary accessors to read
the XML data.

=head2 METHODS

=over 4

=item content_type()

Returns TiVo's mime type for a folder (x-tivo-container/tivo-videos).

=item format()

Returns TiVo's mime type for the format of the folder
(x-tivo-container/tivo-dvr).

=item change_date()

Returns the last time the folder was changed.  The value is in seconds
since the epoch.

=item name()

Returns the name of the folder.

=item total_items()

Returns the number of shows contained in this folder.

=item global_sort()

Returns a boolean (Yes or No) indicating if the folder is globally
sorted.

=item sort_order()

Returns the sort order of the folder.

=item size()

Returns the size in bytes of this folder.  This value is calculated by
summing the individual shows contained in this folder.

=item shows()

Returns an array of the shows contained in this folder.

=item as_string()

Returns a pretty print of this folder's information, including name,
number of show, size, and a list of shows contained in the folder.

=back

=head1 SEE ALSO

L<Net::TiVo>, L<Net::TiVo::Show>

=head1 AUTHOR

Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

=cut
