package Storm::Transaction;
{
  $Storm::Transaction::VERSION = '0.240';
}
use Moose;
use MooseX::StrictConstructor;

use Storm::Types qw( Storm );

has 'storm' => (
    is => 'rw',
    isa => Storm,
    required => 1,
);

has 'code' => (
    is => 'rw'      ,
    isa => 'CodeRef',
    required => 1   ,
);


sub BUILDARGS {
    my $class = shift;
    
    if (@_ == 2) {
        { storm => $_[0], code => $_[1] }
    }
    else {
        __PACKAGE__->SUPER::BUILDARGS(@_);
    }
}

sub commit {
    my $self = shift;
    my $dbh  = $self->storm->source->dbh;
    my $comvar = $dbh->{AutoCommit};
    
    $dbh->{AutoCommit} = 0;
    eval { &{ $self->code }( $self ) };
    $@ ? $dbh->rollback : $dbh->commit;
    $dbh->{AutoCommit} = $comvar;
    
    confess $@ if $@;
    return 1;
}



no Moose;
__PACKAGE__->meta->make_immutable;
1;



__END__

=head1 NAME

Storm::Transaction - Execute a code block in a database transaction

=head1 SYNOPSIS

 use Storm::Transaction;

 $txn = Storm::Transaction->new( $storm, sub {

    ... do work on $storm ...

 });

 eval { $source->commit };

 print "transaction successfull" if ! $@;
  
=head1 DESCRIPTION

C<Storm::Transaction> executes a block of code within a datbase transaction.
This requires that the database supports transactions. If the database does not
support transactions, the code block will simply be invoked.

=head1 ATTRIBUTES

=over 4

=item storm

The L<Storm> object to perform transactions on.

=item code

The code to be invoked within the transaction. If the code block finishes
without any errors, then the database changes are commited. If errors are
encountered, then the changes are rolled back. 

=back

=head1 METHODS

=over 4

=item commit

Begins a new transaction and then invokes the code block to perform the work.
Database changes are committed if the code block executes without any errors.
If errors are thrown, then the changes work are rolled back.

It is useful to call commit within an C<eval { }> block to trap any errors that
are thrown. Alternatively, use a module like L<TryCatch> or L<Try::Tiny>
and call commit within a C<try { }> block.

=back

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT

    Copyright (c) 2010 Jeffrey Ray Hallock. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut






