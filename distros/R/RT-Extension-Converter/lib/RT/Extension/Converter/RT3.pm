package RT::Extension::Converter::RT3;

use warnings;
use strict;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(config _merge_list));

use RT::Extension::Converter::RT3::Config;
use Encode;
use Date::Format;
use MIME::Parser;
use Carp;

=head1 NAME

RT::Extension::Converter::RT3 - Handle the RT3 side of a conversion


=head1 SYNOPSIS

    use RT::Extension::Converter::RT3;
    my $converter = RT::Extension::Converter::RT3->new;

=head1 DESCRIPTION

Object that should be used by converter scripts to 

=head1 METHODS

=head2 new

Returns a converter object after setting up things such as the config

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    $self->config(RT::Extension::Converter::RT3::Config->new);
    return $self;
}

=head2 config 

Returns a config object

=head2 create_user

Creates a new user, expects a hash of valid values for RT3's
User::Create method plus one special SuperUser argument
that will cause SuperUser rights to be granted after creation

returns an RT::User object, or undef on failure

=cut

sub create_user {
    my $self = shift;
    my %args = ( Privileged => 1, @_ );

    # this is very RT1'y, because we kept super user rights
    # in the users table
    my $is_superuser = delete $args{SuperUser};
    if ($args{Name} eq 'root') {
        $is_superuser = 1;
    }

    my $user = RT::User->new($RT::SystemUser);

    %args = %{$self->_encode_data(\%args)};
    $user->Load( $args{Name} );

    if ($user->Id) {
        print "\nLoaded ".$user->Name." from the database" if $self->config->debug;
        return $user;
    }
    
    local $RT::MinimumPasswordLength = 1; # some people from RT1 have short passwords
    my ($val, $msg) =  $user->Create( %args );

    if ($val) {
        print "\nAdded user ".$user->Name if $self->config->debug;
        if ($is_superuser) {
            $user->PrincipalObj->GrantRight( Right => 'SuperUser', Object => $RT::System );
            print " as superuser" if $self->config->debug;
        }
        return $user;
    } else {
        print "\nfailed to create user $args{Name}: $msg";
        return;
    }

}

=head2 create_queue

Creates a new queue, expects a hash of valid values for RT3's
Queue::Create method

returns an RT::Queue object, or undef on failure

=cut

sub create_queue {
    my $self = shift;
    my %args = @_;

    # RT3 really doesn't like undef arguments
    %args = map { $_ => $args{$_} } grep { defined $args{$_} } keys %args;

    my $queue = RT::Queue->new($RT::SystemUser);

    %args = %{$self->_encode_data(\%args)};
    # Try to load up the current queue by name. avoids duplication.
    $queue->Load($args{Name});
    
    #if the queue isn't there, create one.
    if ($queue->id) {
        print "\nLoaded queue ".$queue->Name." from the database" if $self->config->debug;
        return $queue;
    }

    my ($val, $msg) = $queue->Create(%args);

    if ($val) {
        print "\nAdded queue ".$queue->Name if $self->config->debug;
        return $queue;
    } else {
        print "\nfailed to create queue [$args{Name}]: $msg";
        return;
    }

}

=head3 create_queue_area

Takes 
 Queue => RT::Queue, Area => Area's name

Returns an error message if making the appropriate custom fields fails.
Otherwise returns the empty string

This is rather RT1 specific.  RT2 has a more hierarchical Keyword
option that translates into CFs.  Areas are the RT1 "custom field" 
but there was only one of them, so we just make an RT3 Custom Field
called Area and whack a simple select list into it

=cut

sub create_queue_area {
    my $self = shift;
    my %args = @_;
    my $queue = delete $args{Queue};

    %args = %{$self->_encode_data(\%args)};

    my $cf = $self->_create_queue_area_cf($queue);

    if ($self->config->debug) {
        print "\nAdding $args{Area} to the area for ".$queue->Name;
    }

    my ($val,$msg) = $cf->AddValue( Name => $args{Area} );
    return $val ? '' : $msg ;
}

=head3 _create_queue_area_cf

Wraps up the nasty logic of loading/creating a CF for the area

=cut

sub _create_queue_area_cf {
    my $self = shift;
    my $queue = shift;

    # load up the custom field
    my $cf = RT::CustomField->new($RT::SystemUser);
    $cf->LoadByName(
        Name  => 'Area',
        Queue => $queue->Id
    );  

    # look for an existing cf not assigned to this queue yet
    unless ($cf->Id) {
        $cf->LoadByName( Name => 'Area' );
        if ($cf->Id) {
            $cf->AddToObject( $queue );
        }   
    }   

    unless ($cf->Id) {
        $cf->Create( 
            Name     => 'Area',
            Type     => 'SelectSingle',
            Queue    => $queue->Id
        );  
    }   
    unless ( $cf->Id ) {
        print "\nCouldn't create custom field Area for queue" . $queue->Name;
    }

    return $cf;

}

=head2 create_queue_acl 

Takes 
 Queue => RT::Queue
 Acl => acl data from RT1

Sets a number of new rights based on the old display/manipulate/admin 
categories.  This should probably be reworked manually to use groups
once RT3 is being tested.  But, if you have a lot of users, this will
at least get you converted.

XXX Possibly create 3 groups, granting rights on the queues and
adding users to the groups, rather than doing individual rights

=cut

sub create_queue_acl {
    my $self = shift;
    my %args = @_;

    my $queue    = $args{Queue};
    my $acl      = $args{Acl};
    my $username = delete $acl->{user_id};


    my %rightlist = (
       display    => [qw(SeeQueue ShowTemplate ShowScrips 
                         ShowTicket ShowTicketComments)],
       manipulate => [qw(CreateTicket ReplyToTicket CommentOnTicket 
                         OwnTicket ModifyTicket DeleteTicket)],
       admin      => [qw(ModifyACL ModifyQueueWatchers AdminCustomField
                         ModifyTemplate ModifyScrips)] 
    );

    my @rights = map { @{$rightlist{$_}||[]} } keys %$acl;

    return unless @rights;
    
    my $user = RT::User->new($RT::SystemUser);
    $user->Load($username);
    
    unless ($user->id) {
        return "\nCouldn't find user $username Not granting rights\n";
    }

    my $principal = $user->PrincipalObj;
    
    print "\nAdding rights for $username to ".$queue->Name if $self->config->debug;
    foreach my $right (@rights) {
        print "...$right" if $self->config->debug;
        my ($val,$msg) = $principal->GrantRight( Right  => $right,
                                                 Object  => $queue);
        unless ($val) {
            return "\nFailed to grant $right to $username: $msg\n";
        }
    }
    
    print "...adding as AdminCc." if $self->config->debug;
    my ($val,$msg) = $queue->AddWatcher( Type        => 'AdminCC', 
                                         PrincipalId => $principal->Id );
    unless ($val) {
        return "\nFailed to make $username an AdminCc: $msg\n";
    }

    return;
}

=head3 create_ticket 

Takes arguments similar to RT3::Ticket's Create.
Will take a Requestors argument and try to chop it up into
individual Requestor values.

=cut

sub create_ticket {
    my $self = shift;
    my %args = @_;

    # track what merges need to be done later, after all
    # the tickets are created (Rather than playing games
    # to see if the ticket we're merging into has been 
    # created yet)
    if ($args{EffectiveId} && $args{EffectiveId} != $args{id}) {
            print "merging into $args{EffectiveId}";
            $self->_merges( ticket => $args{id},
                            into   => $args{EffectiveId} );
            $args{Status} = 'resolved';
    }

    if ($args{Status} eq 'dead') {
        $args{Status} = 'resolved';
    }

    my @requestors = split(',',$args{Requestors});
        
    # if they had an old queue, stuff the new one into general
    my $queue = new RT::Queue($RT::SystemUser);
    $queue->Load($args{Queue});
    unless ($queue->id) {
        print "...can't find queue id for $args{id} queue $args{Queue} - using default";
        $queue->Load($self->config->default_queue);
    }
    $args{Queue} = $queue;
        
    # RT1 stored dates in "Seconds from the epoch" so we 
    # need to convert that to ISO so RT3 can grok it
    foreach my $type (qw(Due Told Created Updated)) {
        if (defined $args{$type} && $args{$type} =~ /^\d+$/) {
            my $date = new RT::Date($RT::SystemUser);
            $date->Set( Format => 'unix', Value => $args{$type} );
            $args{$type} = $date->ISO;
        } 
    }

    if ($args{Area} && (my $area = delete $args{Area})) {
        print "setting Area $area" if $self->config->debug;
        my $cf_obj = $queue->CustomField('Area');
        $args{'CustomField-'.$cf_obj->Id} = $area;;
    }

    my $ticket = new RT::Ticket($RT::SystemUser);
    my ($val, $msg) = $ticket->Import(Requestor => \@requestors, %args); 
    die $msg unless $val;

    if ($args{Told}) {
        # Create/Import doesn't bubble Told up properly in some RT3.6.3 and earlier
        $ticket->__Set( Field => 'Told', Value => $args{Told} );
    }

    return $ticket;
}

=head3 create_transactions

takes Path => /path/to/transaction/file, Ticket => RT::Ticket, 
Transactions => [arrayref of transaction data]

=cut

sub create_transactions {
    my $self = shift;
    my %args = @_;
    my $ticket = $args{Ticket};
    my $path = $args{Path};

    my $Status = "open";
    my $Queue = "(unknown)";
    my $Area = '';
    my $Subject = '';
    my $Owner = $RT::Nobody->Id;
    my $Requestor = $RT::Nobody->Id;
    my $Priority = $ticket->InitialPriority();
    my $FinalPriority = $ticket->Priority();

    foreach my $txn (@{$args{Transactions}}) {
        my (%trans_args, $MIMEObj);
        
        print "t";
        
        my $load_content = 0;
        $trans_args{'Type'} = '';
        $trans_args{'Field'} = '';
        
        if ( ( $txn->{type} eq 'create' ) or ($txn->{type} eq 'import') ) {
            $load_content = 1;
            $trans_args{'Type'} = "Create";
        } 
        elsif ( $txn->{type} eq 'status' ) {
            $trans_args{'Type'} = "Status";
            $trans_args{'Field'} = "Status";
            $trans_args{'OldValue'} = $Status;
            $trans_args{'NewValue'} = $txn->{trans_data};
            $Status = $txn->{trans_data};
        } 
        elsif ( $txn->{type} eq 'correspond' ) {
            $load_content = 1;
            $trans_args{'Type'} = "Correspond";
        } 
        elsif ( $txn->{type} eq 'comments' ) {
            $load_content = 1;
            $trans_args{'Type'} = "Comment";
        } 
        elsif ( $txn->{type} eq 'queue_id' ) {
            $trans_args{'Type'} = "Set";
            $trans_args{'Field'} = "Queue";
            $trans_args{'OldValue'} = $Queue;
            $trans_args{'NewValue'} = $txn->{trans_data};
            $Queue = $txn->{trans_data};
        } 
        elsif ( $txn->{type} eq 'owner' ) {

            $trans_args{'Type'} = "Owner";
            $trans_args{'Field'} ="Owner";
            $trans_args{'OldValue'} = $Owner;
            $txn->{trans_data} ||= 'Nobody';
            
            my $new_user = RT::User->new($RT::SystemUser);
            $new_user->Load($txn->{'trans_data'});
            $trans_args{'NewValue'} = $new_user->Id;
            
            my $actor = new RT::User($RT::SystemUser);
            $txn->{actor} = 'RT_System' if ($txn->{actor} eq '_rt_system');
            $actor->Load($txn->{actor});
            
            #take/give
        
            $Owner = $RT::Nobody->Id unless ($Owner);

            if ($Owner == $RT::Nobody->Id &&
                $txn->{trans_data} eq $txn->{actor} ) {
                $trans_args{'Type'} = 'Take';
            } elsif ( $Owner == $actor->Id  &&
                      $new_user->Id == $RT::Nobody->Id ) {
                $trans_args{'Type'} = 'Untake';
            } elsif ( $Owner != $RT::Nobody->Id) {
                $trans_args{'Type'} = 'Steal';
            } else {
                $trans_args{'Type'} = 'Give';
            }        
            
            $Owner = $new_user->Id;
            
        } 
        elsif ( $txn->{type} eq 'effective_sn' ) {
            $trans_args{'Type'} = "AddLink";
            $trans_args{'Field'} ="MemberOf";
            $trans_args{'Data'} = "Ticket ". $ticket->Id.
              " MergedInto ticket ". $txn->{trans_data};
            
        } 
        elsif ( $txn->{type} eq 'area' ) {
            $trans_args{'Type'} = "CustomField";
            $trans_args{'OldValue'} = $Area;
            $trans_args{'NewValue'} = $txn->{trans_data};
            $Area = $txn->{trans_data};
        } 
        elsif ( $txn->{type} eq 'requestors' ) {
            # RT1 removed requestors by recording a transaction with
            # '' for trans_data.  For RT3 we need to say "DelWatcher" 
            # AND tell RT which requestor we're nuking.
            $trans_args{'Field'} ="Requestor";

            if ($txn->{trans_data}) {
                $trans_args{'Type'} = "AddWatcher";
                # earlier RTs stored email addresses in the Transaction
                # RT3 calls Load on that address and goes splody
                # since Load only works on id/username
                my $user = $self->_load_or_create_user(EmailAddress => $txn->{trans_data});
                $trans_args{NewValue} = $user->Id;
                $Requestor = $user->Id;
            } else {
                $trans_args{Type} = "DelWatcher";
                $trans_args{OldValue} = $Requestor;
            }
        } 
        elsif ( $txn->{type} eq 'date_due' ) {
            $trans_args{'Type'} = "Set";
            $trans_args{'Field'} ="Due";
            my $date = new RT::Date($RT::SystemUser);
            $date->Set( Format=>'unix', Value=>$txn->{trans_data} );
            $trans_args{'NewValue'} = $date->ISO();
        } 
        elsif ( $txn->{type} eq 'subject' ) {
            $trans_args{'Type'} = "Set";
            $trans_args{'Field'} ="Subject";
            $trans_args{'OldValue'} = $Subject;
            $trans_args{'NewValue'} = $txn->{trans_data};
            $Subject = $txn->{trans_data};
            
        } 
        elsif ( $txn->{type} eq 'priority' ) {
            $trans_args{'Type'} = "Set";
            $trans_args{'Field'} ="Priority";
            $trans_args{'OldValue'} = $Priority;
            $trans_args{'NewValue'} = $txn->{'trans_data'};
            $Priority = $txn->{'trans_data'};
            
        } 
        elsif ( $txn->{type} eq 'final_priority' ) {
            $trans_args{'Type'} = "Set";
            $trans_args{'Field'} ="FinalPriority";
            $trans_args{'OldValue'} = $FinalPriority;
            $trans_args{'NewValue'} = $txn->{'trans_data'};
            $FinalPriority = $txn->{'trans_data'};
            
        } 
        elsif ( $txn->{type} eq 'date_told' ) {
            $trans_args{'Type'} = "Set";
            $trans_args{'Field'} = "Told";
            
            my $date = new RT::Date($RT::SystemUser);
            $date->Set( Format=>'unix', Value=>$txn->{trans_data} );
            $trans_args{'NewValue'} = $date->ISO();
            
        } else {
            die "unrecognized transaction type: $txn->{type}";
        }

        my $filename = $txn->{serial_num}.".".$txn->{id};
        
        if ( $load_content ) {
            if (my $trans_file = $self->_find_transaction_file(Path => $args{Path}, 
                                                               Date => $txn->{trans_date},
                                                               Filename => $filename ) ) {
                $MIMEObj = $self->_process_transaction_file(File => $trans_file);
            }
        }
        
        
        if ( $trans_args{'Type'} ) {
            
            my $User;
            if ($txn->{actor}) {
               $User = $self->_load_or_create_user(EmailAddress => $txn->{actor});
            } else {
                $User = RT::User->new($RT::System);
                $User->Load($RT::Nobody->Id);
            }
            my $created = new RT::Date($RT::SystemUser);
            $created->Set( Format=>'unix', Value=>$txn->{'trans_date'});
                
            my $trans = new RT::Transaction($User);
            
            # Allow us to set the 'Created' attribute. 
            $trans->{'_AccessibleCache'}{Created} = { 'read'=>1, 'write'=>1 };
            $trans->{'_AccessibleCache'}{Creator} = { 'read'=>1, 'auto'=>1 };
            
            my ($transaction, $msg) = 
              $trans->Create( Ticket => $ticket->Id,
                              Type => $trans_args{'Type'},
                              Data => $trans_args{'Data'},
                              Field => $trans_args{'Field'},
                              NewValue => $trans_args{'NewValue'},
                              OldValue => $trans_args{'OldValue'},
                              MIMEObj => $MIMEObj,
                              Created => $created->ISO,
                              ActivateScrips => 0
                            );
            
            unless ($transaction) {
                die("Couldn't create transaction for $txn->{id} $msg\n") 
            }
        } else {
            die "Couldn't parse ". $txn->{id};
        }
    }
    return $ticket;
}

=head3 _find_transaction_file

RT1 would sometimes get confused about timezones and store
a file in tomorrow or yesterday's path.  Go find the file.

=cut

sub _find_transaction_file {
    my $self = shift;
    my %args = @_;

    my @files;
    foreach my $date ($args{Date},$args{Date}+43200,$args{Date}-43200) {

        my $file = time2str("$args{Path}/%Y/%b/%e/",$date,'PST');
        $file .= $args{Filename};
        $file =~ s/ //;

        print "\nTesting $file" if $self->config->debug;
        if (-e $file) {
            return $file
        } else {
            push @files,$file;
        }
    }
    warn "none of @files exist\n";
    return;
}

=head3 _process_transaction_file

We need to turn the RT1 files back into MIME objects
This means converting the old Headers Follow line and
the broken MIME headers into something MIME::Parser
won't choke on.

=cut

sub _process_transaction_file {
    my $self = shift;
    my %args = @_;
    my $trans_file = $args{File};

    print "\nprocessing file $trans_file" if $self->config->debug;
            
    open (FILE,"<$trans_file") or die "can't open [$trans_file] $!";
            
            
    my(@headers, @body);
    my $headers = 0;
    while (<FILE>) {
        if ( /^--- Headers Follow ---$/ ) {
            $headers = 1;
            next;
        } elsif ( $headers ) {
            next if /^\s*$/;
            next if /^>From /;
            push @headers, $_;
        } else {
            push @body, $_;
        }
    }
            
    #clean up files with false multipart Content-type
    my @n_headers;
    while ( my $header = shift @headers ) {
        if ( $header =~ /^content-type:\s*multipart\/(alternative|mixed|report|signed|digest|related)\s*;/i ) {
            my $two = 0;
            my $boundary;
            if ( $header =~ /;\s*boundary=\s*"?([\-\w\.\=\/\+\%\#]+)"?/i ) {
                $boundary = $1;
            } elsif (( $header =~ /;\s*boundary=\s*$/i ) and  ($headers[0] =~ /\s*"?([\-\w\.\=\/\+\%\#]+)"?/i)) {
                #special case for actual boundary on next line
                $boundary = $1;
                $two = 1;
            } elsif ( $headers[0] =~ /(^|;)\s*boundary=\s*"([ \-\w\.\=\/\+\%\#]+)"/i ) { #embedded space, quotes not optional
                $boundary = $2;
                $two = 1;
            } elsif ( $headers[0] =~ /(^|;)\s*boundary=\s*"?([\-\w\.\=\/\+\%\#]+)"?/i ) {
                $boundary = $2;
                $two = 1;
            } elsif ( $headers[1] =~ /(^|;)\s*boundary=\s*"?([\-\w\.\=\/\+\%\#]+)"?/i ) {
                $boundary = $2;
                $two = 2;
            } elsif ( $headers[2] =~ /(^|;)\s*boundary=\s*"?([\-\w\.\=\/\+\%\#]+)"?/i ) {
                #terrible false laziness.
                $boundary = $2;
                $two = 3;
            } else {
                warn "can\'t parse $header for boundry";
            }
            print "looking for $boundary in body\n" if $self->config->debug;
            unless ( grep /^(\-\-)?\Q$boundary\E(\-\-)?$/, @body ) {
                splice(@headers, 0, $two);
                until ( !scalar(@headers) || $headers[0] =~ /^\S/ ) {
                    warn "**WARNING throwing away header fragment: ". shift @headers;
                }
                warn "false Content-type: header removed\n";
                push @n_headers, "Content-Type: text/plain\n";
                push @n_headers, "X-Content-Type-Munged-By: RT import tool\n";

                next; #This is here so we don't push into n_headers
            }
        }
        push @n_headers, $header;
    }
            
    print "..parsing.." if $self->config->debug;
    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    $parser->extract_nested_messages(0);
    my $MIMEObj = $parser->parse_data( [ @n_headers, "\n", "\n", @body ] );
    print "parsed.." if $self->config->debug;
    return $MIMEObj;
} 

=head3 _load_or_create_user

Given an EmailAddress, Name (username)
will try to load the user by username first and
then by EmailAddress.  If that fails, a new unprivileged 
user will be created with Name => Name|EmailAddress

Will carp if loading AND creating fail
Otherwise returns a valid user object

=cut

sub _load_or_create_user {
    my $self = shift;
    my %args = @_;
    $args{Name} ||= $args{EmailAddress};

    my $user_obj = RT::User->new($RT::SystemUser);

    $user_obj->Load( $args{Name} );
    unless ($user_obj->Id) {
        $user_obj->LoadByEmail($args{EmailAddress});
    }
    unless ($user_obj->Id) {
        my ($val, $msg) = $user_obj->Create(%args,
                                            Password => undef,
                                            Privileged => 0,
                                            Comments => undef
        );

        unless ($val) {
            die "couldn't create user_obj for %args{Name}: $msg\n";
        }
    }

    unless ($user_obj->Id) {
        carp "We couldn't find or create $args{Name}. This should never happen"
    }
    return $user_obj;
}
            
=head3 create_links 

creates all accumulated links.
We do this at the end so that all the tickets will exist, rather
than doing it during ticket creation and having to work around
future tickets not being imported yet.

=cut

sub create_links {
    my $self = shift;

    my $merges = $self->_merges;
    
    foreach my $ticket (keys %$merges) {
        my $into = $merges->{$ticket};
        if ($self->config->debug) {
            print "\nMerging $ticket into $into" 
        } else {
            print ".";
        }

        my $mergeinto = RT::Ticket->new($RT::SystemUser);
        $mergeinto->Load($into);

        unless ($mergeinto->Id) {
            print "Skipping $ticket => $into because $into doesn't exist";
            next;
        }

        # Store the link in the DB.
        my $link = RT::Link->new($RT::SystemUser);
        my ($linkid) = $link->Create(Target => $into,
                                     Base => $ticket, 
                                     Type => 'MergedInto');
        
        my $ticket_obj = RT::Ticket->new($RT::SystemUser);
        $ticket_obj->Load($ticket);
        
        if ($ticket_obj->id != $ticket) {
            die "Ticket mismatch ".$ticket_obj->id ." and $ticket\n";
        }
        my ($val, $msg) = $ticket_obj->__Set( Field => 'EffectiveId', Value => $into );
    
        print " couldn't set EffectiveId: $msg\n" unless ($val);
    }

}

=head3 _merge_list

private data storage routine to hold what tickets are merged where

=head3 _merges

takes ticket => id, into => otherid
tracks what merges need doing after we're done
creating all the tickets.

When called without arguments, returns a hashref
containing ticketid => ticket to merge into

=cut

sub _merges {
    my $self = shift;

    unless (@_) {
        return $self->_merge_list;
    } 

    my %args = @_;
    my $list = $self->_merge_list;
    $list->{$args{ticket}} = $args{into};
    $self->_merge_list($list);
    return;
}

=head3 _encode_data

Used to make sure data gets properly unicode'd for RT3.6.
Failure to use this in places will make non-americans unhappy

Takes a hashref of arguments, returns an encoded hashref.

=cut

sub _encode_data {
    my $self = shift;
    my %args = %{shift||{}};

    foreach my $key ( keys %args ) {
        if ( !ref( $args{$key} ) ) {
            $args{$key} = decode( $self->config->encoding, $args{$key} );
        }
        elsif ( ref( $args{$key} ) eq 'ARRAY' ) {
            my @temp = @{ $args{$key} };
            undef $args{$key};
            foreach my $var (@temp) {
                if ( ref($var) ) {

                    push( @{ $args{$key} }, $var );
                }
                else {
                    push( @{ $args{$key} }, decode( $self->config->encoding, $var ) );
                }
            }
        }
        else {
            die "What do I do with $key for %args. It is a "
              . ref( { $args{$key} } );
        }
    }

    return \%args;
}

=head1 AUTHOR

Kevin Falcone  C<< <falcone@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Best Practical Solutions, LLC.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
