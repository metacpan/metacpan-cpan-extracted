package Net::XRC::Data;

use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $data = shift;
  my $self = ref($data) ? $data : \$data;
  warn "$proto->($self [$data])\n"
    if $Net::XRC::DEBUG > 1;

  if ( $class eq 'Net::XRC::Data' ) { #take a guess
    if ( ref($self) eq 'HASH' ) {
      $class .= '::complex';
    } elsif ( ref($self) eq 'ARRAY' ) {
      $class .= '::list';
    } elsif ( !defined($$self) ) {
      $class .= '::null';

    # now just guess...  no good way to distinguish
    # (bool and bytes are never guessed)
    } elsif ( $$self =~ /^-?\d+$/ ) {
      $class .= '::int';
    } else {
      $class .= '::string';
    }
    eval "use $class;";
    die $@ if $@;
  }
  bless($self, $class);
}

1;
