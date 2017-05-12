package Net::DNS::Match;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::DNS::Match ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.05';
$VERSION = eval $VERSION;

# Preloaded methods go here.

sub new {
	my $class = shift;
	my $args = shift;
	
	my $self = {};
	bless($self,$class);
	
	return $self;
}

sub add {
    my $self    = shift;
    my $array   = shift;
    
    $array = [ $array ] unless(ref($array) eq 'ARRAY');
    
    # sort this first, make sure the top level fqdn's come first.
    # in the event anyone puts in both test.example.com, test2.example.com AND example.com
    # this should make sure the top-level 'example.com' makes it in first, and the rest are
    # rejected
    @{$array} = sort { length $a <=> length $b } @$array;
    
    foreach (@$array){
        $self->_add($_,$_);
    }
}

sub _add {
    my $self    = shift;
    my $string  = shift;
    my $data    = shift;
    
    my @bits    = split('\.',$string);
    my $tld     = $bits[$#bits];
    pop(@bits);

    my $rest    = join('.',@bits);
    
    $self->{'children'} = {} unless(defined($self->{'children'}));
    my $children = $self->{'children'};
    
    unless(exists($children->{$tld})){
        $children->{$tld} = Net::DNS::Match->new();
    }
    
    my $child = $children->{$tld};
    if($#bits > -1){
        # recursive, unless we've already got a leaf that accounts for this
        # node, then bypass it
        $child->_add($rest,$data) unless($child->{'value'});
    } else {
        $child->{'data'} = $data;
        $child->{'value'} = 1;
    }

    return 1;
}

sub match { 
    my $self    = shift;
    my $string  = shift;
    
    my ($res,$data) = $self->_match($string);
    return $string if($res);
    
    my @bits = split('\.',$string);
    return 0 if($#bits < 2); # we're tld, no match, move on...
    
    # work our way back through the address
    my $t = $bits[$#bits-1].'.'.$bits[$#bits];

    ($res,$data) = $self->_match($t);
    return $data if($res);
    
    # pop the top-level
    pop(@bits); pop(@bits);
    @bits = reverse(@bits);
    foreach my $b (@bits){
        $t = $b.'.'.$t;
        ($res,$data) = $self->_match($t);
        return $data if($res);
    }
    return 0;
}

sub _match {
    my $self    = shift;
    my $string  = shift;
    
    my @bits    = split('\.',$string);
    my $tld     = $bits[$#bits];
    my $size    = $#bits;
    pop(@bits);

    my $rest = join('.',@bits);
    
    $self->{'children'} = {} unless(defined($self->{'children'}));
    my $children = $self->{'children'};
    
    return 0 unless(exists($children->{$tld}));
    if($size == 0){
        return ($children->{$tld}->{'value'},$children->{$tld}->{'data'});
    } else {
        return $children->{$tld}->_match($rest);
    }
}

1;
__END__

=head1 NAME

Net::DNS::Match - Perl extension for testing domains against another list of domains (similar to Net::Patricia but for FQDNs)

=head1 SYNOPSIS

  use Net::DNS::Match;
  use Data::Dumper;
  my $addr = 'img.yahoo.com';

  my $obj = Net::DNS::Match->new();
  $obj->add([
      'yahoo.com',
      'google.com',
      'www.facebook.com',
   ]);
 
 die Dumper($obj->match($addr));

=head1 DESCRIPTION

This module was initially created to test a list of domains against a whitelist (eg: the Alexa top 1000 list). 

=head2 EXPORT

None by default.

=head1 SEE ALSO

github.com/csirtgadgets

=head1 AUTHOR

Wesley Young, E<lt>wes@barely3am.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Wesley Young

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
