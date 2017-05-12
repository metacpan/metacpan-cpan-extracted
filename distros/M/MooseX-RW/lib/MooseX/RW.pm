package MooseX::RW;
{
  $MooseX::RW::VERSION = '0.003';
}
# ABSTRACT: Moose::Role reader/writer

use Moose::Role;


has count => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);



sub begin {}



sub end {}


1;

__END__
=pod

=encoding UTF-8

=head1 NAME

MooseX::RW - Moose::Role reader/writer

=head1 VERSION

version 0.003

=head1 SYNOPSIS

Let suppose you have a voice box on you phone. You want to display all number
of your messages.

 package VoiceBox::Reader;
 
 use Moose;
 use Phone;
 
 with MooseX::RW::Reader;
 
 # VoIP phone
 has phone => ( is => 'rw', isa => 'Phone', required => 1 );
 
 sub read {
    my $self = shift;
    my $vb = $phone->voicebox;
    my $count = $self->count;
    return if $vb->count >= $count;
    my $msg = $phone->voicebox->get_msg($count);
    $self->count($count+1);
    return $msg;
 }
 
 package Main;
 
 my $phone = Phone->new( url => 'a.b.c.d' );
 my $reader = VoiceBox::Reader->new( phone => $phone );
 while ( $msg = $reader->read() ) {
    say $msg->count, ": ", $msg->from;
 }

=head1 ATTRIBUTES

=head2 count

Count of items/records which have been handled by reader/writer.

=head1 METHODS

=head2 begin

Not required method which could be called by a processor at the begining of a
process.

=head2 end

Not required method which could be called by a processor at the end of a process.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

