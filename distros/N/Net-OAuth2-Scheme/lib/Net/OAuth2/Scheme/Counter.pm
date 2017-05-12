use warnings;
use strict;

package Net::OAuth2::Scheme::Counter;
BEGIN {
  $Net::OAuth2::Scheme::Counter::VERSION = '0.03';
}
# ABSTRACT: a host-wide counter
use Carp;
use Thread::IID 'interpreter_id';

my %current = ();
my %refs = ();  # how many objects have been created for a given tag
my $p_id = -1;
my $i_id;
my $start;

# This counter rolls over every 200 days
# (token lifetimes should not be ANYWHERE NEAR this long)
sub _mk_start {
    $start = pack "Cw2a3", 0x3f, ($i_id = interpreter_id), ($p_id = $$), pack('V',time());
}

sub suffix {
    my $value = shift;
    return (unpack 'w3a3a*', (ord($value)&0x40) ? chr(0xc0)^$value : $value)[4];
}

sub next {
    my $self = shift;
    my $tag = $$self;

    # check for fork()
    ref($self)->CLONE unless $$ == $p_id;

    my $s0 = ord($current{$tag});
    my ($n,$s) = unpack 'wa*',
      ((ord($current{$tag}) & 0x40) ? chr(0x80)^$current{$tag} : $current{$tag});
    my $ns = pack 'w', $n+1;
    return $current{$tag} =
      (
       !(ord($ns) & 0x40) ? $ns :
       (ord($ns) & 0x80) ? chr(0x80).$ns :
       chr(0x80)^$ns
#      ((ord($ns) & 0xc0)==0x80 ? chr(0xc0)^$ns :
#       (ord($ns) & 0x40) ? chr(0x40).$ns :
#       $ns
      ).$s;
}

sub new {
    my $class = shift;
    my $tag = shift || '';

    # check for fork()
    $class->CLONE unless $$ == $p_id;

    $current{$tag} = $start
      unless ($current{$tag});

    ++$refs{$tag};
    return bless \( $tag ), $class;
}

sub DESTROY {
    my $self = shift;
    --$refs{$$self};
    # this routine only exists for the sake of being able to detect
    # unused tags upon interpreter clone or process fork.
    #
    # once a counter for a given tag is created, it's best to keep it
    # around; we risk repeats if we get rid of a tag and recreate it
    # within a second of its original creation in the same process/thread
}

sub CLONE {
    my $class = shift;
    return if $p_id == $$ && $i_id == interpreter_id;
    _mk_start();
    for my $tag (keys %refs) {
        if ($refs{$tag} <= 0) {
            # nobody is currently using it
            # therefore it has not been used yet in this thread
            # therefore we can safely ignore it
            delete $refs{$tag};
            delete $current{$tag};
        }
        else {
            $current{$tag} = $start;
        }
    }
}

1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Counter - a host-wide counter

=head1 VERSION

version 0.03

=head1 DESCRIPTION

internal module.

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

