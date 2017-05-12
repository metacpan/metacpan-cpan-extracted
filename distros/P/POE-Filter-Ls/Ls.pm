package POE::Filter::Ls;

use POE::Filter::Line;

$VERSION = 0.01;

sub new {
  my $class = shift; 

  return bless [ new POE::Filter::Line( Literal => "\015\012" ) ],
    ref($class)||$class;
}

sub put {
  my ($self, $lines) = @_;
  return $self->[0]->put($lines);
}

sub get {
  my ($self, $lines) = @_;
 
  return [ map {
    my %info;
    if (/^(.|-)(.{9})\s+(\d+)\s+(\w+)\s+(\w+)\s+(\d+)\s+(\w{3}\s+\d+\s+\d+:\d+)\s+(.*?)(?:\s+->\s+(.*))?$/) {
      @info{"type","perms","links","owner","group","size","date","filename","link"} = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
    }
    \%info;
  } @{ $self->[0]->get($lines) } ];
}

1;

__END__

=head1 NAME

POE::Filter::Ls - translates common ls formats into a hashref

















