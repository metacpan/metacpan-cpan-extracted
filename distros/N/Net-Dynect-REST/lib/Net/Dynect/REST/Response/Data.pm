package Net::Dynect::REST::Response::Data;
# $Id: Data.pm 177 2010-09-28 00:50:02Z james $
use strict;
use warnings;
use overload '""' => \&_as_string;
use Carp;
our $AUTOLOAD;
our $VERSION = do { my @r = (q$Revision: 177 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME

Net::Dynect::REST::Response::Data - Data object returned as a result of a request

=head1 SYNOPSIS

 use Net::Dynect::REST::Response::Data;
 my $data = Net::Dynect::REST::Response::Data->new(data => $hashref);
 my @keys = $data->data_keys;
 print $data->some_key;

=head1 METHODS

=head2 Creating

=over 4

=item new

This constructor takes the data as decoded from the response.

=back

=cut 

sub new {
    my $proto = shift;
    my $self  = bless {}, ref($proto) || $proto;
    my %args  = @_;
    $self->{data} = $args{data} if defined $args{data};
    return $self;
}

sub _data {
    my $self = shift;
    if (@_) {
        my $new = shift;
        $self->{data} = $new;
    }
    return $self->{data};
}

=head2 Attributes

=over 4 

=item data_keys

This returns the names of the keys of the data returned. 

=item other, random, names

As the data varies depending on the request given, so does the value returned in the response. Hence the data may have a key of B<zone>, or B<ttl>, or anthing else.

=cut

sub data_keys {
    my $self = shift;
    return keys %{ $self->{data} };
}

sub AUTOLOAD {
    my $self = shift;
    if ( ref($self) ne "Net::Dynect::REST::Response::Data" ) {
        carp "This should be a Net::Dynect::REST::Response::Data";
        return;
    }
    my $name = $AUTOLOAD;
    return unless defined $self->{data};
    $name =~ s/.*://;    # strip fully-qualified portion
    return $self->{data}->{$name} if defined $self->{data}->{$name};
}

sub _as_string {
    my $self = shift;
    use Data::Dumper;
    $Data::Dumper::Terse = 1;
    return Dumper $self->{data};
}

=back

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::REST::Response>, L<Net::Dynect::REST::Response::Msg>.

=head1 AUTHOR

James bromberger, james@rcpt.to

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.





=cut

1;
