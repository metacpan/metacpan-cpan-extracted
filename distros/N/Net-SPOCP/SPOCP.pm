package Net::SPOCP;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::SPOCP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
spocp_split_parts
spocp_map
SPOCP_PORT;
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '0.14';


use Net::SPOCP::SExpr;
use Net::SPOCP::Protocol;

my $SPOCP_PORT = 4751;

# Preloaded methods go here.

sub new
  {
    my $self = shift;
    my $class = ref $self || $self;

    my %args = @_;
    my $me = bless \%args,$class;
    $me->init();
    $me;
  }

sub rule
  {
    my $self = shift;

    my %args = @_;
    foreach my $tag (qw(resource action subject))
      {
	unshift(@{$args{$tag}},$tag);
      }

    Net::SPOCP::SExpr->create([spocp=>$args{resource},$args{action},$args{subject}]);
  }

# rule-utilities

sub spocp_split_parts
  {
    my $split = shift;
    my @out;
    foreach my $x (@_)
      {
	push(@out,split($split,$x));
      }
    \@out;
  }

sub spocp_map
  {
    my @out;
    while (@_)
      {
	my $k = shift;
	my $v = shift;
	push(@out,[$k,$v]);
      }
    \@out;
  }

sub l_encode
  {
    return "" unless $_[1];
    sprintf("%d:%s",length($_[1]),$_[1]);
  }


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::SPOCP - Perl implementation of the SPOCP protocol

=head1 SYNOPSIS

  use Net::SPOCP;

  my $client = Net::SPOCP::Protocol->new(server=>'host:port');
  my $res = $client->query([a => [ ru => 'le' ],[ another => 'rule']);
  print "%s\n",$res->is_error ? "denied (".$res->error.")" : 'authorized';

=head1 DESCRIPTION

Implements the protocol described at http://www.spocp.org.

=head1 AUTHOR

Leif Johansson <leifj@it.su.se>
Klas Lindfors <kllin@it.su.se>

=head1 BUGS

Only query is implemented currently

=head1 SEE ALSO

L<perl>. L<http://www.spocp.org>

=cut
