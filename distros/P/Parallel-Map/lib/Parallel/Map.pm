package Parallel::Map;

our $VERSION = '0.000002'; # v0.0.2

$VERSION = eval $VERSION;

use strict;
use warnings;
use IO::Async::Function;
use IO::Async::Loop;
use Exporter 'import';

our @EXPORT = qw(pmap_void pmap_scalar pmap_concat);

sub _pmap {
  my ($type, $code, %args) = @_;

  return "Invalid type ${type}" unless $type =~ /^(?:void|scalar|concat)$/;

  $args{concurrent} = delete $args{forks} if $args{forks};

  my $par = $args{concurrent} ||= 5;

  my $func = IO::Async::Function->new(code => $code);
  $func->configure(max_workers => $par||$func->{max_workers});

  (my $loop = IO::Async::Loop->new)->add($func);

  my $fmap = Future::Utils->can("fmap_${type}");

  my $done_f = $fmap->(
    sub { $func->call(args => [ @_ ]) },
    %args,
  );

  my $final_f = $loop->await($done_f);
  $loop->await($func->stop);
  $loop->remove($func);

  return $final_f->get;
}

sub pmap_void   (&;@) { _pmap void => @_ }
sub pmap_scalar (&;@) { _pmap scalar => @_ }
sub pmap_concat (&;@) { _pmap concat => @_ }

1;

=head1 NAME

Parallel::Map - Multi processing parallel map code

=head1 SYNOPSIS

  use Parallel::Map;
  
  pmap_void {
    sleep 1;
    warn "${_}\n";
    Future->done;
  } foreach => \@choices, forks => 5;

=head1 DESCRIPTION

All subroutines match L<Future::Utils> C<fmap_> subroutines of the same name.

=head2 pmap_void

  pmap_void { <block returning future> } foreach => \@input;
  pmap_void { <block returning future> } generate => sub { <iterator> }

=head2 pmap_scalar

  pmap_scalar { <block returning future> } foreach => \@input;
  pmap_scalar { <block returning future> } generate => sub { <iterator> }

=head2 pmap_concat

  pmap_concat { <block returning future> } foreach => \@input;
  pmap_concat { <block returning future> } generate => sub { <iterator> }

=head1 AUTHOR

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2020 the Parallel::Map L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
