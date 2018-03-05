package Steemit::OperationSerializer;
use Modern::Perl;
use Carp;
use Data::Dumper;

sub new {
   my( $class, %params ) = @_;
   my $self = {};
   return bless $self, $class;

}


sub serialize_operation {
   my( $self, $operation_name, $operation_parameters ) = @_;
   ##operation id

   if( my $serializer_method = $self->can("serialize_$operation_name") ){
      return $serializer_method->($self,$operation_name,$operation_parameters);
   }else{
      die "operation $operation_name currently not support for serialisation";
   }

}

#let vote = new Serializer(
#    "vote", {
#    voter: string,
#    author: string,
#    permlink: string,
#    weight: int16
#}
#);

sub serialize_vote {
   my( $self, $operation_name, $operation_parameters ) = @_;

   my $serialized_operation = '';
   my $operation_id = $self->_index_of_operation($operation_name);
   $serialized_operation .= pack "C", $operation_id;

   $serialized_operation .= pack "C", length $operation_parameters->{voter};
   $serialized_operation .= pack "A*", $operation_parameters->{voter};

   $serialized_operation .= pack "C", length $operation_parameters->{author};
   $serialized_operation .= pack "A*", $operation_parameters->{author};

   $serialized_operation .= pack "C", length $operation_parameters->{permlink};
   $serialized_operation .= pack "A*", $operation_parameters->{permlink};

   $serialized_operation .= pack "s", $operation_parameters->{weight};


   return $serialized_operation;
}


#let comment = new Serializer(
#    "comment", {
#    parent_author: string,
#    parent_permlink: string,
#    author: string,
#    permlink: string,
#    title: string,
#    body: string,
#    json_metadata: string
#}
#);

sub serialize_comment {
   my( $self, $operation_name, $operation_parameters ) = @_;

   my $serialized_operation = '';
   my $operation_id = $self->_index_of_operation($operation_name);
   $serialized_operation .= pack "C", $operation_id;

   for my $field ( qw(parent_author parent_permlink author permlink title body json_metadata) ){
      confess "$field missing in parameters".Dumper($operation_parameters)   unless defined $operation_parameters->{$field};
      $serialized_operation .= pack "C", length $operation_parameters->{$field};
      $serialized_operation .= pack "A*", $operation_parameters->{$field};
   }

   return $serialized_operation;
}


#let delete_comment = new Serializer(
#    "delete_comment", {
#    author: string,
#    permlink: string
#}
#);

sub serialize_delete_comment {
   my( $self, $operation_name, $operation_parameters ) = @_;

   my $serialized_operation = '';
   my $operation_id = $self->_index_of_operation($operation_name);
   $serialized_operation .= pack "C", $operation_id;

   for my $field ( qw(author permlink) ){
      $serialized_operation .= pack "C", length $operation_parameters->{$field} or confess "$field missing in parameters".Dumper($operation_parameters);;
      $serialized_operation .= pack "A*", $operation_parameters->{$field};
   }

   return $serialized_operation;
}



sub _index_of_operation {
   my ( $self, $operation ) = @_;

   #https://github.com/steemit/steem-js/blob/master/src/auth/serializer/src/operations.js#L767
   my @operations = qw(
   vote
   comment
   transfer
   transfer_to_vesting
   withdraw_vesting
   limit_order_create
   limit_order_cancel
   feed_publish
   convert
   account_create
   account_update
   witness_update
   account_witness_vote
   account_witness_proxy
   pow
   custom
   report_over_production
   delete_comment
   custom_json
   comment_options
   set_withdraw_vesting_route
   limit_order_create2
   challenge_authority
   prove_authority
   request_account_recovery
   recover_account
   change_recovery_account
   escrow_transfer
   escrow_dispute
   escrow_release
   pow2
   escrow_approve
   transfer_to_savings
   transfer_from_savings
   cancel_transfer_from_savings
   custom_binary
   decline_voting_rights
   reset_account
   set_reset_account
   claim_reward_balance
   delegate_vesting_shares
   account_create_with_delegation
   fill_convert_request
   author_reward
   curation_reward
   comment_reward
   liquidity_reward
   interest
   fill_vesting_withdraw
   fill_order
   shutdown_witness
   fill_transfer_from_savings
   hardfork
   comment_payout_update
   return_vesting_delegation
   comment_benefactor_reward
   );
   unless( $self->{_op_index} ){
      my $count = 0;
      $self->{_op_index} = { map { $_ => $count++ } @operations };
   }
   return $self->{_op_index}{$operation} // die "$operation not defined";

}



1;
__END__

=head1 NAME

Steemit::OperationSerializer - perl library for serializing operations intended to be send a transaction to the steemit blockchain

=head1 SYNOPSIS

the module is internally used by the Steemit::WsClient::_serialize_transaction_message method and most likely not realy usefull to you
exept when you want to add more supported serialisations


=head1 REPOSITORY

L<https://github.com/snkoehn/perlSteemit>


=head1 AUTHOR

snkoehn, C<< <snkoehn at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-steemit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Steemit::WsClient>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Steemit::WsClient


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Steemit::WsClient>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Steemit::WsClient>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Steemit::WsClient>

=item * Search CPAN

L<http://search.cpan.org/dist/Steemit::WsClient/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 snkoehn.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut



