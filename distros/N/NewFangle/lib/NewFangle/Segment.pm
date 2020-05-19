package NewFangle::Segment 0.01 {

  use strict;
  use warnings;
  use 5.020;
  use NewFangle::FFI;
  use Carp ();

# ABSTRACT: NewRelic application class


  sub transaction { shift->{txn} }


  $ffi->attach( [ end_segment => 'end' ] => ['newrelic_txn_t', 'opaque*'] => 'bool' => sub {
    my($xsub, $self) = @_;
    my $txn = $self->{txn};
    $xsub->($self->{txn}, \$self->{ptr});
  });


  $ffi->attach( [ set_segment_parent      => 'set_parent'      ] => [ 'newrelic_segment_t', 'newrelic_segment_t' ] => 'bool' );
  $ffi->attach( [ set_segment_parent_root => 'set_parent_root' ] => [ 'newrelic_segment_t'                       ] => 'bool' );
  $ffi->attach( [ set_segment_timing      => 'set_timing'      ] => [ 'newrelic_segment_t', 'newrelic_time_us_t',
                                                                      'newrelic_time_us_t'                       ] => 'bool' );

  sub DESTROY
  {
    my($self) = @_;
    $self->end if defined $self->{ptr};
  }

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NewFangle::Segment - NewRelic application class

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use NewFangle;
 my $app = NewFangle::App->new;
 my $txn = $app->start_web_transaction("txn_name");
 my $seg = $txn->start_segment("seg_name");

=head1 DESCRIPTION

NewRelic transaction class

=head1 METHODS

=head2 transaction

 my $txn = $seg->transaction

Returns the transaction for this segment.

=head2 end

 my $bool = $seg->end;

Ends the segment.

(csdk: newrelic_end_segment)

=head2 set_parent

 my $bool = $seg->set_parent($seg2);

(csdk: newrelic_set_segment_parent)

=head2 set_parent_root

 my $bool = $seg->set_parent_root;

(csdk: newrelic_set_segment_parent_root)

=head2 set_timing

 my $bool = $seg->set_timing($start_time, $duration);

(csdk: newrelic_set_segment_timing)

=head1 SEE ALSO

=over 4

=item L<NewFangle>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
