package RT::Search::Googleish_Overlay;
our $VERSION = 0.05;

#Hook::LexWrap won't let us tweak @_ sufficiently

my $core = \&RT::Search::Googleish::QueryToSQL;
*RT::Search::Googleish::QueryToSQL = sub {
  my $self  = shift;
  my $query = shift || $self->Argument;

  my @CF;
  while( $query =~ s/(-)?\.(\w+):(\S+)// ){
    push @CF, ($1 ? "CF.{$2} NOT LIKE '$3'" : "CF.{$2} LIKE '$3'");
  }

  #Stupid space to overcome damn test for empty query in Googleish.pm
  my $ret = $core->($self, $query||' ', @_);
  $ret .= ' AND ' . join(' AND ', @CF) if scalar @CF;
  return $ret;
};

1;
__END__

=head1 NAME

RT::Search::Googleish_Local - Simple operator searching of custom fields

=head1 DESCRIPTION

Search for custom fields with C<.>I<CFName>C<:>I<value>, where I<CFName>
and I<value> match C<\S+>

Searches may be negated with a leading dash i.e; -.foo:bar finds objects
with foo different from bar.

=head1 LICENSE

The same terms as perl itself.
