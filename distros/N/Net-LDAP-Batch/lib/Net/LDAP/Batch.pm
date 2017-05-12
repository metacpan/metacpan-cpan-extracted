package Net::LDAP::Batch;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( ldap debug ));
__PACKAGE__->mk_ro_accessors(qw( actions error ));
use Net::LDAP::Batch::Action::Add;
use Net::LDAP::Batch::Action::Update;
use Net::LDAP::Batch::Action::Delete;
use Scalar::Util qw( blessed );

our $VERSION = '0.02';

=head1 NAME

Net::LDAP::Batch - perform a batch of LDAP actions

=head1 SYNOPSIS

 use Net::LDAP::Batch;
 
 my $BaseDN = 'ou=People,dc=MyDomain';
 my $ldap   = make_and_bind_Net_LDAP_object();  # you write this
 
 my $batch = Net::LDAP::Batch->new( ldap => $ldap );
 $batch->add_actions(
    add => [
        {
            dn      => "cn=MyGroup,ou=Group,$BaseDN",
            attr    => [
                objectClass => [ 'top', 'posixGroup' ],
                cn          => 'MyGroup',
                gidNumber   => '1234'
            ]
        }
    ],
    delete => [
        {
            search  => [
                base    => "ou=Group,$BaseDN",
                scope   => 'sub',
                filter  => "(cn=MyOldGroup)"
            ]
        }
    ],
    update => [
        {
            search  => [
                base    => "ou=Group,$BaseDN",
                scope   => 'sub',
                filter  => "(cn=OtherGroup)"
            ],
            replace => { gidNumber => '5678' },
            delete  => { foo => [ 'bar' ] },
        }
    ]
 );

 $batch->do or die $batch->error;
 
=head1 DESCRIPTION

Net::LDAP::Batch performs a series of actions against a LDAP
server. If any of the actions fails, then all the actions in the batch
are reverted.

B<Be advised:> This is not a true ACID-compliant transaction feature, 
since no locking is performed. Instead it is simply a way to execute 
a series of actions without having to worry about checking return values, or
error codes, or un-doing the changes should any of them fail. Of course,
since no ACID compliance is claimed, anything could (and likely will)
happen if there is more than one client attempting to make changes
on the same server at the same time. B<You have been warned.>

=head1 METHODS

=head2 new

Create a batch instance.

You must pass in a valid Net::LDAP object that has 
already been bound to the server with whatever credentials are necessary 
to complete the actions you will specify.

You may optionally pass in an array ref of actions. See also the add_actions()
method.

=cut

sub new {
    my $class = shift;
    my $opts  = ref( $_[0] ) ? $_[0] : {@_};
    my $self  = $class->SUPER::new($opts);
    $self->_setup;
    return $self;
}

sub _setup {
    my $self = shift;
    if ( $self->{actions} ) {
        my $actions = $self->clear_actions;
        $self->add_actions($actions);
    }
    $self->debug( $ENV{PERL_DEBUG} ) unless defined $self->debug;
}

=head2 actions

Get the array ref of Net::LDAP::Batch::Action objects in the batch.
To set the array, use add_actions().

=head2 add_actions( I<actions> )

Set the array of actions to be executed. I<actions> may be either
an array or array ref, and may either be key/value pairs as in
the SYNOPSIS or Net::LDAP::Batch::Action objects. You may not mix
the two types of values.

Returns the total number of actions in batch.

=cut

my %action_classes = (
    'add'    => 'Net::LDAP::Batch::Action::Add',
    'update' => 'Net::LDAP::Batch::Action::Update',
    'delete' => 'Net::LDAP::Batch::Action::Delete',
);

sub add_actions {
    my $self = shift;
    my @arg;
    if ( @_ == 1 && ref( $_[0] ) eq 'ARRAY' ) {
        @arg = @{ $_[0] };
    }
    else {
        @arg = @_;
    }

    if ( blessed( $arg[0] ) && $arg[0]->isa('Net::LDAP::Batch::Action') ) {
        push( @{ $self->{actions} }, @arg );
    }
    else {
        if ( @arg % 2 ) {
            croak "uneven number of action key/value pairs";
        }
        while ( scalar(@arg) ) {
            my $what = shift(@arg);
            my $todo = shift(@arg);
            if ( !exists $action_classes{$what} ) {
                croak "unsupported action: $what";
            }
            my $class = $action_classes{$what};
            my @todo;
            if ( ref($todo) eq 'ARRAY' ) {
                @todo = @$todo;
            }
            else {
                @todo = ($todo);
            }
            for my $params (@todo) {
                $params->{ldap}  = $self->ldap;
                $params->{debug} = $self->debug;
                push( @{ $self->{actions} }, $class->new($params) );
            }
        }
    }
    return scalar( @{ $self->{actions} } );
}

=head2 clear_actions

Sets the number of actions to zero. Returns the former contents
of actions().

=cut

sub clear_actions {
    my $self    = shift;
    my $actions = $self->{actions};
    $self->{actions} = [];
    return $actions;
}

=head2 do

Perform the actions and rollback() if any are fatal. Same thing as calling:

 eval { $batch->execute };
 if ($@) {
     warn "batch failed: $@";
     $batch->rollback;  # could be fatal
 }

The code above is nearly verbatim what do() actually does.

=cut

sub do {
    my $self = shift;
    eval { $self->execute };
    if ($@) {
        $self->{error} = $@;
        $self->rollback;
        return 0;
    }
    return 1;
}

=head2 execute

Calls execute() method on each action.

=cut

sub execute {
    my $self = shift;
    if ( !$self->actions or !scalar( @{ $self->actions } ) ) {
        croak "no actions to execute";
    }
    for my $action ( @{ $self->actions } ) {
        warn "executing $action\n" if $self->debug;
        $action->execute;
    }
    return 1;
}

=head2 rollback

Calls rollback() method on each action.

=cut

sub rollback {
    my $self = shift;
    if ( !$self->actions or !scalar( @{ $self->actions } ) ) {
        croak "no actions to rollback";
    }
    for my $action ( reverse @{ $self->actions } ) {
        next unless $action->complete;
        warn "rolling back $action\n" if $self->debug;
        $action->rollback;
    }
    return 1;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-ldap-batch at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-Batch>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::Batch

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-Batch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-Batch>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-Batch>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-Batch>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT

Copyright 2008 by the Regents of the University of Minnesota.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Net::LDAP

=cut


