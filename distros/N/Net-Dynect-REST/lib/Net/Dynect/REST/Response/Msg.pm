package Net::Dynect::REST::Response::Msg;
# $Id: Msg.pm 128 2010-09-24 05:15:58Z james $
use strict;
use warnings;
use overload '""' => \&_as_string;
use Carp;
our $VERSION = do { my @r = (q$Revision: 128 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME

Net::Dynect::REST::Response::Msg - A message about the data that was returned.

=head1 SYNOPSIS

 use Net::Dynect::REST::Response::Msg;
 $msg = Net::Dynect::REST::Response::Msg->new();
 $source = $msg->source;

=head1 METHODS

=head2 Creating

=over 4

=item new

This constructor takes the fields as returned by the response from Dynect to populate the attributes. As this matches the Dynect case and spelling, these are a hash ref with keys:

=over 4

=item * SOURCE

=item * LVL

=item * INFO

=item * ERR_CD

=back

=back

=cut

sub new {
    my $proto = shift;
    my $self  = bless {}, ref($proto) || $proto;
    my $data  = shift;

    $self->source( $data->{SOURCE} ) if defined $data->{SOURCE};
    $self->level( $data->{LVL} )     if defined $data->{LVL};
    $self->info( $data->{INFO} )     if defined $data->{INFO};
    $self->err_cd( $data->{ERR_CD} ) if defined $data->{ERR_CD};

    return $self;
}

=head2 Attributes

=over 4

=item source

A debugging field. If reporting an error to your Dynect Concierge, be sure to include this.

=cut

sub source {
    my $self = shift;
    if (@_) {
        my $new = shift;
        $self->{source} = $new;
    }
    return $self->{source};
}

=item level 

The severity of the message. One of: 'FATAL', 'ERROR', 'WARN', or 'INFO'

=cut

sub level {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~ /^FATAL|ERROR|WARN|INFO$/ ) {
            print "Unknown level: $new\n";
            return;
        }
        $self->{level} = $new;
    }
    return $self->{level};
}

=item info 

The actual message itself. Human readable (English) text.

=cut

sub info {
    my $self = shift;
    if (@_) {
        my $new = shift;
        $self->{info} = $new;
    }
    return $self->{info};
}

=item err_cd

An error code (if appropriate) regarding the message. See the Dynect manual for the set of valid codes.

=cut

sub err_cd {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~
/^ILLEGAL_OPERATION|INTERNAL_ERROR|INVALID_DATA|INVALID_REQUEST|INVALID_VERSION|MISSING_DATA|NOT_FOUND|OPERATION_FAILED|PERMISSION_DENIED|SERVICE_UNAVAILABLE|TARGET_EXISTS|UNKNOWN_ERROR$/
          )
        {
            print "Unknown err_cd: $new\n";
            return;
        }
        $self->{err_cd} = $new;
    }
    return $self->{err_cd};
}

sub _as_string {
    my $self = shift;
    my @texts;
    push @texts, sprintf "Source: '%s'", $self->source if defined $self->source;
    push @texts, sprintf "Level: '%s'",  $self->level  if defined $self->level;
    push @texts, sprintf "Info: '%s'",   $self->info   if defined $self->info;
    push @texts, sprintf "Err_CD: '%s'", $self->err_cd if defined $self->err_cd;
    return join( ', ', @texts );
}

=back

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::REST::Response>, L<Net::Dynect::REST::Response::Data>.

=head1 AUTHOR

James bromberger, james@rcpt.to

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.




=cut 

1;
